import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

extension CustomPoseLandmark on PoseLandmark {
  Map<String, dynamic> toMap() => {
        'type': type.toString(),
        'x': x,
        'y': y,
        'z': z,
        'likelihood': likelihood,
      };
}

// Class to store pose estimation data
class PoseEstimationData {
  // Timestamp of the frame
  final DateTime timestamp;
  // ID of each pose
  final int id;
  // List of landmarks detected in the frame
  final List<PoseLandmark> landmarks;

  PoseEstimationData({required this.timestamp, required this.id, required this.landmarks});
}

// Function to extract the landmark data from the list
List<Map<String, dynamic>> convertPoseLandmarkData(
    List<PoseEstimationData> poses) {
  // Create a new list to store the converted data.
  final List<Map<String, dynamic>> convertedPoses = [];

  // Iterate through the poses.
  for (final pose in poses) {
    // Extract the timestamp and id.
    final timestamp = pose.timestamp;
    final id = pose.id;

    // Extract the landmarks.
    final landmarks = pose.landmarks;

    // Iterate through the landmarks and extract the x, y, z, and likelihood values.
    for (final landmark in landmarks) {
      final type = landmark.type;
      final x = landmark.x;
      final y = landmark.y;
      final z = landmark.z;
      final likelihood = landmark.likelihood;

      // Convert the type to a string.
      final typeString = type.toString().split('.').last;

      // Add the landmark data to the converted data map.
      final presentableData = <String, dynamic>{
        'id': id,
        'timestamp': timestamp,
        'body_part': typeString,
        'x': x,
        'y': y,
        'z': z,
        'likelihood': likelihood,
      };
      convertedPoses.add(presentableData);
    }
  }

  return convertedPoses;
}
