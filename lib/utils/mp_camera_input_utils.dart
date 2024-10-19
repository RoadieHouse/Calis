import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

List<CameraDescription> cameras = [];
CameraDescription? camera;
CameraController? controller;

final _orientations = {
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

InputImage? inputImageFromCameraImage(CameraImage image) {
  // get image rotation
  // it is used in android to convert the InputImage from Dart to Java
  // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C
  // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas
  final camera = cameras[0];
  final sensorOrientation = camera.sensorOrientation;
  InputImageRotation? rotation;
  if (Platform.isIOS) {
    rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  } else if (Platform.isAndroid) {
    var rotationCompensation =
        _orientations[controller?.value.deviceOrientation];
    if (rotationCompensation == null) return null;
    if (camera.lensDirection == CameraLensDirection.front) {
      // front-facing
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
    } else {
      // back-facing
      rotationCompensation =
          (sensorOrientation + rotationCompensation) % 360;
    }
    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    
  }
  
  if (rotation == null) return null;

  // get image format
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  // validate format depending on platform
  // only supported formats:
  // * nv21 for Android
  // * bgra8888 for iOS
  if (format == null ||
      (Platform.isAndroid && format != InputImageFormat.nv21) ||
      (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

  // since format is constraint to nv21 or bgra8888, both only have one plane
  if (image.planes.length != 1) return null;
  final plane = image.planes.first;

  // compose InputImage using bytes
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation, // used only in Android
      format: format, // used only in iOS
      bytesPerRow: plane.bytesPerRow, // used only in iOS
    ),
  );
}

// Function to request camera permission
Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();
  if (status.isGranted) {
    // Camera permission is granted; continue with initializing the camera.
    return;
  } else {
    // Handle the case where camera permission is not granted.
    Fluttertoast.showToast(
        msg: "Camera Permission denied, please try again",
        backgroundColor: Colors.red,
        textColor: Colors.white);
  }
}
