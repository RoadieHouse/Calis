/*import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:async';
import 'dart:typed_data';
import '../utils/mp_pose_class_custom.dart';
import '../utils/yolo_camera_input_utils.dart';

var logger = Logger(printer: PrettyPrinter());

class PoseEstimationYolo {
  final List<PoseEstimationData> completePoseData = [];
  late Interpreter _interpreter;
  bool _isInitialized = false;

  Future<void> initializeInterpreter() async {
    if (!_isInitialized) {
      _interpreter = await Interpreter.fromAsset('yolov8n-pose_float16.tflite');
      _isInitialized = true;
    }
  }

  Future<void> runInterpreter(Uint8List input) async {
    if (!_isInitialized) {
      await initializeInterpreter();
    }

    var inputTensor = _interpreter.getInputTensor(0);
    inputTensor.copyFrom(input);

    _interpreter.invoke();

    var outputTensor = _interpreter.getOutputTensor(0);
    List<dynamic> outputValues = outputTensor.data;

    print('Output Values: $outputValues');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var poseEstimationYolo = PoseEstimationYolo();
  await poseEstimationYolo.initializeInterpreter();

  // Example input data, replace with actual input
  Uint8List inputData = Uint8List.fromList([/* your input data here */]);
  await poseEstimationYolo.runInterpreter(inputData);
}
*/