import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:image/image.dart' as img_lib;
import '../utils/mp_camera_input_utils.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

Future<Tensor?> imageToTensor(CameraImage image) async {
  try {
    final InputImage? inputImage = inputImageFromCameraImage(image);
    if (inputImage == null) {
      throw Exception('Failed to create InputImage');
    }

    final img_lib.Image? processedImage = await inputImageToImage(inputImage);
    if (processedImage == null) {
      throw Exception('Failed to process InputImage');
    }

    // Resize the image to 640x640
    img_lib.Image resizedImage = img_lib.copyResize(
      processedImage,
      width: 640,
      height: 640,
      interpolation: img_lib.Interpolation.linear,
    );

    // Convert to float32 and normalize to [0, 1]
    Float32List buffer = Float32List(1 * 640 * 640 * 3);
    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        img_lib.Pixel pixel = resizedImage.getPixel(x, y);
        buffer[pixelIndex++] = pixel.r / 255.0;
        buffer[pixelIndex++] = pixel.g / 255.0;
        buffer[pixelIndex++] = pixel.b / 255.0;
      }
    }

    // Create a Tensor from the buffer
    //return Tensor.fromList(buffer, [1, 640, 640, 3]);
    return null;
  } catch (e) {
    print('Error converting image to tensor: $e');
    return null;
  }
}

Future<img_lib.Image?> inputImageToImage(InputImage inputImage) async {
  if (inputImage.bytes == null || inputImage.metadata == null) {
    return null;
  }

  final bytes = inputImage.bytes!;
  final metadata = inputImage.metadata!;

  final width = metadata.size.width.toInt();
  final height = metadata.size.height.toInt();

  late img_lib.Image image;
  if (metadata.format == InputImageFormat.bgra8888) {
    image = img_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
      order: img_lib.ChannelOrder.bgra,
    );
  } else if (metadata.format == InputImageFormat.nv21) {
    image = img_lib.Image.fromBytes(
        width: width, height: height, bytes: bytes.buffer);
  } else {
    throw Exception('Unsupported image format: ${metadata.format}');
  }

  // Apply rotation if needed
  switch (metadata.rotation) {
    case InputImageRotation.rotation90deg:
      image = img_lib.copyRotate(image, angle: 90);
      break;
    case InputImageRotation.rotation180deg:
      image = img_lib.copyRotate(image, angle: 180);
      break;
    case InputImageRotation.rotation270deg:
      image = img_lib.copyRotate(image, angle: 270);
      break;
    default:
      // No rotation needed
      break;
  }

  return image;
}
