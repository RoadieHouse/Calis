import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';
import 'package:logger/logger.dart';
import 'package:my_app/utils/mp_camera_input_utils.dart';
import 'dart:async';
import '../utils/mp_pose_class_custom.dart';

// Create a logger instance
var logger = Logger(printer: PrettyPrinter());

// Class to handle pose estimation
class PoseEstimationMediapipe {
  // List of the last detected landmarks
  final List<PoseEstimationData> completePoseData = [];

  // Create a pose detector
  final poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );

  // Function to enable pose estimation
  Future<void> enableMPPoseEstimation(VoidCallback updateUI) async {
    // Create ID's for each pose
    int idCounter = 0;
    // Initialize the camera controller
    await controller?.initialize();

    // implement skip frame
    int frameCount = 0;
    // Start the camera image stream
    await controller?.startImageStream((CameraImage image) async {
      frameCount++;

      if (frameCount % 3 == 0) {
        try {
          // Convert the camera image to an input image
          final inputImage = inputImageFromCameraImage(image);

          // Check if the input image is null
          if (inputImage == null) {
            // Log an error message
            logger.e('Failed to convert CameraImage to InputImage');

            // Return from the function
            return;
          }

          // Perform pose estimation on the input image
          final poses = await poseDetector.processImage(inputImage);

          // Check if any poses were detected
          if (poses.isNotEmpty) {
            // Get the first pose (as we only track one person)
            final pose = poses.first;
            print(pose.landmarks[PoseLandmarkType.nose]);

            // Create a PoseEstimationData object using a constructor for clarity
            final poseEstimationData = PoseEstimationData(
                timestamp: DateTime.now(),
                id: ++idCounter,
                landmarks: pose.landmarks.entries
                    .map((entry) => PoseLandmark(
                        type: entry.key,
                        x: entry.value.x,
                        y: entry.value.y,
                        z: entry.value.z,
                        likelihood: entry.value.likelihood))
                    .toList());

            // Add the PoseFrameData object to the lastDetectedLandmarks list
            completePoseData.add(poseEstimationData);
            updateUI();
          }
        } catch (e) {
          // Log the error
          logger.e('Failed to detect pose: $e');
        }
      }
    }).catchError((error) {
      logger.e('Error starting camera stream: $error');
    });
  }

  void disableMPPoseEstimation() {
    controller?.stopImageStream();
    poseDetector.close();
  }

  void clearPoseData() {
    completePoseData.clear();
  }
}
