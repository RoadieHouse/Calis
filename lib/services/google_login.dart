import 'dart:io' as io;
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import "package:http/http.dart" as http;

// Use the google apis
// ignore: library_prefixes
import 'package:googleapis/drive/v3.dart' as gApi;
// ignore: library_prefixes
import 'package:googleapis_auth/googleapis_auth.dart' as gAuth;


// The saved file
const fileName = 'privateFile';
const fileMime = 'application/vnd.google-apps.document';

// The App's specific folder
const appDataFolderName = 'appDataFolder';
const folderMime = 'application/vnd.google-apps.folder';


// This is the Http client that carries the calls with the needed headers
class AuthClient extends http.BaseClient {
  final http.Client _baseClient;
  final Map<String, String> _headers;

  AuthClient(this._baseClient, this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _baseClient.send(request);
  }
}

class GoogleDriveClient {
  late String _accessToken;
  late GoogleSignInAccount _googleAccount;
  late gApi.DriveApi _driveApi;

  GoogleDriveClient._create(
      GoogleSignInAccount googleAccount, String accessToken) {
    _googleAccount = googleAccount;
    _accessToken = accessToken;
  }

  static Future<GoogleDriveClient> create(
      GoogleSignInAccount googleAccount, String accessToken) async {
    var component = GoogleDriveClient._create(googleAccount, accessToken);
    await component._initGoogleDriveApi();

    return component;
  }

  // Attach the needed headers to the http client.
  // Initializes the DriveApi with the auth client
  Future<void> _initGoogleDriveApi() async {
    final gAuth.AccessCredentials credentials = gAuth.AccessCredentials(
      gAuth.AccessToken(
        'Bearer',
        _accessToken,
        DateTime.now().toUtc().add(const Duration(days: 365)),
      ),
      null, // We don't have a refreshToken at this example
      [gApi.DriveApi.driveAppdataScope],
    );
    var client = gAuth.authenticatedClient(http.Client(), credentials);
    var localAuthHeaders = await _googleAccount.authHeaders;
    var headers = localAuthHeaders;
    var authClient = AuthClient(client, headers);
    _driveApi = gApi.DriveApi(authClient);
  }

  // Download the wanted file to the device in the specified folder
  Future<String?> _downloadFileToDevice(String fileId) async {
    gApi.Media? file = (await _driveApi.files.get(fileId,
        downloadOptions: gApi.DownloadOptions.fullMedia)) as gApi.Media?;
    if (file != null) {
      final directory = await getApplicationDocumentsDirectory();
      final saveFile = io.File('${directory.path}/$fileName');
      final first = await file.stream.first;
      saveFile.writeAsBytes(first);
      return saveFile.readAsString();
    }
    return null;
  }

  // Gets the id of the file from Google Drive
  // If the file doesn't exist it returns null
  Future<String?> _getFileIdFromGoogleDrive(String fileName) async {
    gApi.FileList found = await _driveApi.files.list(
      q: "name = '$fileName'",
    );
    final files = found.files;
    if (files == null) {
      return null;
    }

    if (files.isNotEmpty) {
      return files.first.id;
    }
    return null;
  }

  // Creates a file with the content, and uploads it to google drive
  Future<String?> _createFileOnGoogleDrive(String fileName,
      {String? mimeType,
      String? content,
      List<String> parents = const []}) async {
    gApi.Media? media;

    // Checks if the file already exists on Google Drive.
    // If it does, we delete it here and create a new one.
    var currentFileId = await _getFileIdFromGoogleDrive(fileName);
    if (currentFileId != null) {
      await _driveApi.files.delete(currentFileId);
    }

    if (fileName == fileName && content != null) {
      final directory = await getApplicationDocumentsDirectory();
      var created = io.File("${directory.path}/$fileName");
      created.writeAsString(content);
      var bytes = await created.readAsBytes();
      media = gApi.Media(created.openRead(), bytes.lengthInBytes);
    }

    gApi.File file = gApi.File();
    file.name = fileName;
    file.mimeType = mimeType;
    file.parents = parents;

    // The acual file creation on Google Drive
    final fileCreation = await _driveApi.files.create(file, uploadMedia: media);
    if (fileCreation.id == null) {
      throw PlatformException(
        code: 'Error remoteStorageException',
        message: 'unable to create file on Google Drive',
      );
    }

    print("Created File ID: ${fileCreation.id} on RemoteStorage");
    return fileCreation.id!;
  }

  // Public client API:
  uploadFile(String fileContent) async {
    try {
      String? folderId = await _createFileOnGoogleDrive(appDataFolderName,
          mimeType: folderMime);
      if (folderId != null) {
        await _createFileOnGoogleDrive(fileName,
            content: fileContent, parents: [folderId]);
      }
    } catch (e) {
      print("GoogleDrive, uploadfileContent $e");
    }
  }
}





/*import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive3;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<http.Client> getAuthenticatedHttpClient() async {
  final GoogleSignIn googleSignIn = GoogleSignIn.standard(scopes: [
    drive3.DriveApi.driveFileScope,
  ]);
  final GoogleSignInAccount? account = await googleSignIn.signIn();
  final authHeaders = await account?.authHeaders;
  if (authHeaders == null) {
    throw Exception('Failed to get authentication headers.');
  }
  return GoogleHttpClient(authHeaders);
}

final driveApi = drive3.DriveApi(getAuthenticatedHttpClient() as http.Client);


Future<void> googleSignIn() async {
  final GoogleSignIn googleSignIn = GoogleSignIn(scopes: [
    drive3.DriveApi.driveFileScope,
  ]);

  try {
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    if (account == null) {
      print("Sign-in canceled or failed.");
      return;
    }

    final httpClient = await googleSignIn.authenticatedClient();
    if (httpClient == null) {
      print("Failed to get authenticated client.");
      return;
    }

    var driveApi = drive3.DriveApi(httpClient);
    // Use the driveApi instance as needed
  } catch (e) {
    print("Error signing in: $e");
  }
}
*/