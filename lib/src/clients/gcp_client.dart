import 'dart:convert';
import 'dart:io';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GcpClient {
  final AuthProvider _authProvider;
  GcpClient(this._authProvider);

  Future<String?> _getStateConfigVar(String functionName, String stateVarId,
      [BuildContext? context = null, String errorMessagePrefix = ""]) async {
    try {
      final Uri uri = Uri.parse(Utils.STATE_CONFIG_APPS_SCRIPT_URI);

      var headers = {
        'Authorization': 'Bearer ${await _authProvider.getAccessToken}',
        'Content-Type': 'application/json'
      };
      var body = json.encode({
        "function": "$functionName",
        "parameters": [stateVarId]
      });

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse["response"]["result"];
    } catch (e) {
      if (context != null) {
        Utils.snackbar(context, "$errorMessagePrefix $e");
      }
      return null;
    }
  }

  Future<String> triggerExpenseAndNetWorthAutomationAppsScript(
      String spreadSheetId) async {
    final Uri uri = Uri.parse(Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI);

    var headers = {
      'Authorization': 'Bearer ${await _authProvider.getAccessToken}',
      'Content-Type': 'application/json'
    };
    var body = json.encode({
      "function": "createRecurringExpensesSheet",
      "parameters": [spreadSheetId]
    });

    final response = await http.post(
      uri,
      headers: headers,
      body: body,
    );

    return response.body;
  }

  Future<String> createSpreadSheetByUploadingCSVFile(String filePath) async {
    var headers = {
      'Authorization': 'Bearer ${await _authProvider.getAccessToken}',
      'Content-Type': 'multipart/related; boundary=boundary_string'
    };
    File file = File(filePath);
    String fileContents = await file.readAsString();
    var metadata = '''{
    "name": "${Utils.getPreviousMonthYear()}",
    "mimeType": "application/vnd.google-apps.spreadsheet",
    "parents": ["1MIXsdv1PjLztvCGfRFitk6UqykCNbw-Y"]  // Specify the target folder
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

  Future<String?> uploadDocument({
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
        "Bearer ${await _authProvider.getAccessToken}";

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
      Utils.snackbar(
          context, "Failed to upload document: ${response.statusCode}: $body");
      return null;
    }
  }

  Future<String?> getDocumentFolderId(
      String documentId, BuildContext context) async {
    return _getStateConfigVar("getAccountStatementFolderId", documentId,
        context, "Error getting folder ID:");
  }

  Future<String?> getAppsScriptClientUrl(BuildContext context) async {
    return _getStateConfigVar("getAppsScriptClientUrl", Utils.EANW_AUTOMATION,
        context, "Error getting apps script URL:");
  }
}
