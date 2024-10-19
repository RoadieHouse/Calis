import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import '../utils/mp_camera_input_utils.dart';
import '../utils/yolo_camera_input_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class PoseEstimationYOLO {
  final List<List<dynamic>> completeOutputData = [];
  late Interpreter _interpreter;
  late IsolateInterpreter _isolateInterpreter;
  bool _isInitialized = false;

  Future<void> initializeInterpreter() async {
    if (!_isInitialized) {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/yolov8n-pose_float16.tflite');
      _isolateInterpreter =
          await IsolateInterpreter.create(address: _interpreter.address);
      _isInitialized = true;
    }
  }

  Future<void> enableYOLOPoseEstimation(VoidCallback updateUI) async {
    await initializeInterpreter();
    //int idCounter = 0;
    await controller?.initialize();

    int frameCount = 0;
    await controller?.startImageStream((CameraImage image) async {
      frameCount++;

      if (frameCount % 3 == 0) {
        try {
          print(_interpreter.getInputTensor(0).shape);
          print(_interpreter.getOutputTensor(0).shape);
          final inputImage = await imageToTensor(image);

          if (inputImage == null) {
            logger.e('Failed to convert CameraImage to input tensor');
            return;
          }

          // Adjust these values based on your YOLOv8 model's output shape
          var outputShape = [1, 56, 8400];
          var outputBuffer =
              List.filled(outputShape.reduce((a, b) => a * b), 0.0)
                  .reshape(outputShape);

          await _isolateInterpreter.run(inputImage, outputBuffer);

          // Process the output
          final processedOutput = processYoloOutput(outputBuffer[0]);

          completeOutputData.add(processedOutput);
          logger.i('YOLO Output: $processedOutput');
          updateUI();
        } catch (e) {
          logger.e('Failed to run inference: $e');
        }
      }
    }).catchError((error) {
      logger.e('Error starting camera stream: $error');
    });
  }

  void disableYOLOPoseEstimation() {
    controller?.stopImageStream();
    _isolateInterpreter.close();
    _interpreter.close();
  }

  void clearOutputData() {
    completeOutputData.clear();
  }

  List<dynamic> processYoloOutput(List<List<double>> output) {
    // This is a placeholder function. You'll need to implement the actual
    // processing logic based on your YOLO model's output format.
    // For now, we'll just return the raw output.
    return output;
  }
}
