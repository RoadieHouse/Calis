import 'dart:async';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import "package:http/http.dart" as http;
import 'package:googleapis_auth/auth_io.dart';
import '../services/data_csv_export.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<http.Client> obtainCredentials() async {
  // Load the service account credentials
  final accountCredentials = ServiceAccountCredentials.fromJson({dotenv.env['GOOGLE_SERVICE_ACCOUNT_JSON']
  });
  var scopes = [drive.DriveApi.driveFileScope];
  AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);

  return client;
}

Future<void> uploadFiletoDrive(String csvFile, BuildContext context) async {
  String? userInput = await promptUserForString(context);
  if (userInput == null) {
    // User canceled the upload
    return;
  }

  final fileName = userInput.trim().isNotEmpty
      ? userInput.trim()
      : "Unnamed - ${DateTime.now().toString()}";

  // Create a Drive API instance
  var httpclient = await obtainCredentials();
  final driveApi = drive.DriveApi(httpclient);

  // Create a new file
  drive.File file = drive.File()
    ..name = '$fileName.csv'
    ..mimeType = 'text/csv'
    ..parents = [dotenv.env['GOOGLE_DRIVE_FOLDER_ID']!];
  // File contents in bytes form and then turned into a stream for google drive
  List<int> csvBytes = csvFile.codeUnits;
  Stream<List<int>> csvStream = Stream.fromIterable([csvBytes]);

  // Upload the CSV content
  drive.Media uploadMedia = drive.Media(csvStream, csvFile.length);

  try {
    await driveApi.files.create(file, uploadMedia: uploadMedia);
    // ignore: use_build_context_synchronously
    _showFloatingSnackBar(context);
  } on drive.DetailedApiRequestError catch (e) {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'There was an issue with the Google Drive API',
          style: TextStyle(color: Colors.white54),
        ),
        backgroundColor: Color.fromARGB(255, 72, 5, 0)));
    Fluttertoast.showToast(
        msg: "$e", backgroundColor: Colors.red, textColor: Colors.white);
  }
}

void _showFloatingSnackBar(BuildContext context) {
  final snackBar = SnackBar(
    content: const Text('Uploaded \u{1F973}', textAlign: TextAlign.center),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    duration: const Duration(seconds: 3),
    width: 120,
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
