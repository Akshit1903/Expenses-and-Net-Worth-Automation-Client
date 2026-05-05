import 'package:expense_and_net_worth_automation/src/clients/base/apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:flutter/material.dart';

class EanwAppsScriptsClient extends AppsScriptsClient {
  EanwAppsScriptsClient() : super(AppsScriptType.eanw);

  Future<String?> triggerExpenseAndNetWorthAutomationAppsScript(
      String spreadSheetId, BuildContext? context) async {
    return await callAppsScripts(
        "createRecurringExpensesSheet",
        [spreadSheetId],
        context,
        "Expense and Net Worth Automation script triggered successfully!",
        "Failed to trigger Expense and Net Worth Automation script");
  }
}
