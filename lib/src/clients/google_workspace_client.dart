import 'dart:convert';
import 'dart:io';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GoogleWorkspaceClient {
  final AuthService _authService;
  GoogleWorkspaceClient() : _authService = getIt<AuthService>();

  Future<String> createSpreadSheetByUploadingCSVFile(String filePath) async {
    var headers = {
      'Authorization': 'Bearer ${await _authService.getAccessToken()}',
      'Content-Type': 'multipart/related; boundary=boundary_string'
    };
    File file = File(filePath);
    String fileContents = await file.readAsString();
    var metadata = '''{
    "name": "${Utils.getPreviousMonthYear()}",
    "mimeType": "application/vnd.google-apps.spreadsheet",
    "parents": ["1MIXsdv1PjLztvCGfRFitk6UqykCNbw-Y"]
  }''';

    var body = '''--boundary_string
Content-Type: application/json; charset=UTF-8

$metadata

--boundary_string
Content-Type: text/csv

$fileContents
--boundary_string--''';

    final response = await http.post(
      Uri.parse(Utils.UPLOAD_DOCUMENT_TO_DRIVE_URI),
      headers: headers,
      body: body,
    );
    return response.body;
  }

  Future<String?> uploadDocumentToDrive({
    required String path,
    required String fileName,
    required String folderId,
    required BuildContext context,
  }) async {
    final uri = Uri.parse(
      Utils.UPLOAD_DOCUMENT_TO_DRIVE_URI,
    );

    final request = http.MultipartRequest("POST", uri);

    // Set auth header
    request.headers["Authorization"] =
        "Bearer ${await _authService.getAccessToken()}";

    // --- Metadata part ---
    final metadataJson = '''
  {
    "name": "$fileName",
    "parents": ["$folderId"]
  }
  ''';

    request.files.add(
      http.MultipartFile.fromString(
        'metadata',
        metadataJson,
      ),
    );

    // --- File part ---
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        path,
      ),
    );

    // Send request
    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(body);
      return jsonResponse["id"];
    } else {
      final body = await response.stream.bytesToString();
      Utils.showSnackBar(
          "Failed to upload document: ${response.statusCode}: $body", context);
      return null;
    }
  }
}
