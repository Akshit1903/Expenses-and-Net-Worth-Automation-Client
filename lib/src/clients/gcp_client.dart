import 'dart:convert';
import 'dart:io';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:http/http.dart' as http;

class GcpClient {
  final AuthProvider _authProvider;
  GcpClient(this._authProvider);
  Future<String> triggerExpenseAndNetWorthAutomationAppsScript(
      String spreadSheetId) async {
    print('Triggering Expense and Net Worth Automation Apps Script');
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
      Uri.parse(Utils.CREATE_SPREADSHEET_BY_UPLOADING_CSV_FILE_URI),
      headers: headers,
      body: body,
    );
    return response.body;
  }
}
