import 'dart:convert';
import 'dart:io';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/app_date_utils.dart';
import 'package:expense_and_net_worth_automation/src/utils/constants.dart';
import 'package:http/http.dart' as http;

/// Result type for Google Workspace API calls.
class WorkspaceResult {
  final String? data;
  final String? errorMessage;

  const WorkspaceResult.success(this.data) : errorMessage = null;
  const WorkspaceResult.failure(this.errorMessage) : data = null;

  bool get isSuccess => errorMessage == null;
}

/// Client for Google Workspace APIs (Drive, Sheets).
///
/// ARCH-2 FIX: No longer accepts BuildContext. Returns [WorkspaceResult]
/// so the calling UI layer handles success/error display.
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
    "name": "${AppDateUtils.getPreviousMonthYear()}",
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
      Uri.parse(AppConstants.uploadDocumentToDriveUri),
      headers: headers,
      body: body,
    );
    return response.body;
  }

  /// Uploads a document to Google Drive.
  ///
  /// ARCH-2 FIX: Returns [WorkspaceResult] instead of accepting BuildContext.
  Future<WorkspaceResult> uploadDocumentToDrive({
    required String path,
    required String fileName,
    required String folderId,
  }) async {
    final uri = Uri.parse(
      AppConstants.uploadDocumentToDriveUri,
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
      return WorkspaceResult.success(jsonResponse["id"]);
    } else {
      final body = await response.stream.bytesToString();
      return WorkspaceResult.failure(
          "Failed to upload document: ${response.statusCode}: $body");
    }
  }
}
