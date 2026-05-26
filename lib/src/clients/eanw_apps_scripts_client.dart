import 'package:expense_and_net_worth_automation/src/clients/base/apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';

/// Client for the EANW (Expenses & Net Worth) Apps Script backend.
class EanwAppsScriptsClient extends AppsScriptsClient {
  EanwAppsScriptsClient() : super(AppsScriptType.eanw);

  /// Triggers the main automation script with a spreadsheet ID.
  Future<AppsScriptResult<String>>
      triggerExpenseAndNetWorthAutomationAppsScript(
          String spreadSheetId, Map<String, dynamic> externalMeta) async {
    return await callAppsScripts("triggerEANW", [spreadSheetId, externalMeta]);
  }

  /// Fetches the working EANW sheet financial details.
  Future<AppsScriptResult<Map<String, dynamic>>> getWorkingEANWDetails() async {
    return await callAppsScripts("getWorkingEANWDetails", []);
  }

  /// Copies the working EANW sheet to the main sheet.
  Future<AppsScriptResult<Null>> copyEANWToMainSheet() async {
    return await callAppsScripts("copyEANWToMainSheet", []);
  }

  /// Fetches the main EANW sheet financial details.
  Future<AppsScriptResult<Map<String, dynamic>>> getMainEANWDetails() async {
    return await callAppsScripts("getMainEANWDetails", []);
  }

  /// Overwrites net worth and updates the finance log.
  Future<AppsScriptResult<Null>>
      overwriteNetWorthAndUpdateEANWFinanceLog() async {
    return await callAppsScripts(
        "overwriteNetWorthAndUpdateEANWFinanceLog", []);
  }

  /// Fetches the latest finance log entry.
  Future<AppsScriptResult<Map<String, dynamic>>> getLatestFinanceLog() async {
    return await callAppsScripts("getLatestFinanceLog", []);
  }
}
