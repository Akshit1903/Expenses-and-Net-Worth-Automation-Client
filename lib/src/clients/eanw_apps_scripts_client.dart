import 'package:expense_and_net_worth_automation/src/clients/base/apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';

class EanwAppsScriptsClient extends AppsScriptsClient {
  EanwAppsScriptsClient() : super(AppsScriptType.eanw);

  Future<AppsScriptResult> triggerExpenseAndNetWorthAutomationAppsScript(
      String spreadSheetId) async {
    return await callAppsScripts(
        "createRecurringExpensesSheet", [spreadSheetId]);
  }
}
