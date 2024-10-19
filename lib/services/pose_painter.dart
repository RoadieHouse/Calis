import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../utils/mp_pose_class_custom.dart';
import 'package:camera/camera.dart';

class PosePainterMediapipe extends CustomPainter {
  final PoseEstimationData pose;
  final Size imageSize;
  final CameraLensDirection lensDirection;

  PosePainterMediapipe(
      {required this.pose,
      required this.imageSize,
      required this.lensDirection});

  @override
  void paint(Canvas canvas, Size size) {
    final headPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.blue;

    final upperBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = Colors.green;

    final lowerBodyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.red;

    for (final landmark in pose.landmarks) {
      final x = landmark.x * size.width / imageSize.width;
      final y = landmark.y * size.height / imageSize.height;

      final position = Offset(
        lensDirection == CameraLensDirection.front ? size.width - x : x,
        y,
      );
      canvas.drawCircle(position, 4, headPaint);
    }

    // Draw connections between landmarks
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.leftEyeInner, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftEyeInner,
        PoseLandmarkType.leftEye, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftEye,
        PoseLandmarkType.leftEyeOuter, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.rightEyeInner, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightEyeInner,
        PoseLandmarkType.rightEye, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightEye,
        PoseLandmarkType.rightEyeOuter, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.leftEar, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.rightEar, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.leftMouth, headPaint);
    _drawConnection(canvas, size, PoseLandmarkType.nose,
        PoseLandmarkType.rightMouth, headPaint);

    _drawConnection(canvas, size, PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftPinky, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftIndex, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftThumb, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightWrist,
        PoseLandmarkType.rightPinky, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightWrist,
        PoseLandmarkType.rightIndex, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightWrist,
        PoseLandmarkType.rightThumb, upperBodyPaint);

    _drawConnection(canvas, size, PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightHip,
        PoseLandmarkType.leftHip, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftShoulder, upperBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftAnkle,
        PoseLandmarkType.leftHeel, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightAnkle,
        PoseLandmarkType.rightHeel, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.leftHeel,
        PoseLandmarkType.leftFootIndex, lowerBodyPaint);
    _drawConnection(canvas, size, PoseLandmarkType.rightHeel,
        PoseLandmarkType.rightFootIndex, lowerBodyPaint);
  }

  void _drawConnection(Canvas canvas, Size size, PoseLandmarkType start,
      PoseLandmarkType end, Paint paint) {
    final startLandmark = pose.landmarks.firstWhere((lm) => lm.type == start);
    final endLandmark = pose.landmarks.firstWhere((lm) => lm.type == end);

    final startX = startLandmark.x * size.width / imageSize.width;
    final startY = startLandmark.y * size.height / imageSize.height;
    final endX = endLandmark.x * size.width / imageSize.width;
    final endY = endLandmark.y * size.height / imageSize.height;

    final startPosition = Offset(
      lensDirection == CameraLensDirection.front ? size.width - startX : startX,
      startY,
    );
    final endPosition = Offset(
      lensDirection == CameraLensDirection.front ? size.width - endX : endX,
      endY,
    );

    canvas.drawLine(startPosition, endPosition, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
