import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:my_app/utils/mp_pose_class_custom.dart';
import '../models/mp_pose_estimation.dart';
import 'package:csv/csv.dart';
import 'dart:async';

// Required instance variables
PoseEstimationMediapipe poseEstimationMediapipe = PoseEstimationMediapipe();
const csvConverter = ListToCsvConverter();

// Function to transform the data into motion capture data structure for exporting
String poseDataToCSV(List<PoseEstimationData> poseData) {
  final bodyParts = [
    for (final type in PoseLandmarkType.values) type.toString().split('.')[1],
  ];
  final columnHeaders = [
    'id',
    'timestamp',
    ...bodyParts.expand((part) => [
          '${part}_x',
          '${part}_y',
          '${part}_z',
          '${part}_likelihood',
        ]),
  ];

  final transformedData = <List<dynamic>>[];
  transformedData.add(columnHeaders);

  for (var pose in poseData) {
    // Extract ID and timestamp once for the entire poseList
    var id = pose.id;
    var timestamp = pose.timestamp.toString();

    // Create a single row for the poseList
    var row = [id, timestamp];

    // Iterate through each pose and append body part data
    for (var landmark in pose.landmarks) {
      row.addAll([landmark.x, landmark.y, landmark.z, landmark.likelihood]);
    }

    // Add the completed row to the transformed data
    transformedData.add(row);
  }

  String csvData = const ListToCsvConverter().convert(transformedData);
  return csvData;
}

Future<String?> promptUserForString(BuildContext context) async {
  String userInput = "Unnamed file - ${DateTime.now()}"; // Set default name
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'File Name',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.left,
        ),
        content: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter a name for your file',
              border:
                  UnderlineInputBorder(), // Use UnderlineInputBorder for bottom line
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(189, 0, 0, 0), width: 2.0),
              ),
            ),
            onChanged: (String value) {
              userInput =
                  value.isEmpty ? userInput : value; // Update only if not empty
            }),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        backgroundColor: const Color.fromARGB(228, 255, 253, 253),
        actionsPadding: const EdgeInsets.all(0.0), // Add padding to the actions
        actions: <Widget>[
          Container(
            height: 45,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 2.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: TextButton(
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color.fromARGB(255, 36, 101, 253),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(color: Colors.grey, thickness: 2.0),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: Center(
                      child: TextButton(
                        child: const Text(
                          'Submit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 36, 101, 253),
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop(userInput);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
