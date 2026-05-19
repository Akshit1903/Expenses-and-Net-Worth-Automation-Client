import 'package:expense_and_net_worth_automation/src/clients/base/apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/utils/constants.dart';

class ConfigStateAppsScriptsClient extends AppsScriptsClient {
  ConfigStateAppsScriptsClient() : super(AppsScriptType.stateConfig);

  Future<AppsScriptResult> getDocumentFolderId(String documentId) async {
    return callAppsScripts(
        "getAccountStatementFolderId", [documentId]);
  }

  Future<AppsScriptResult> getAppsScriptClientUrl() async {
    return callAppsScripts(
        "getAppsScriptClientUrl", [AppConstants.eanwAutomation]);
  }

  Future<AppsScriptResult> getDocumentPassword(String documentId) async {
    return callAppsScripts("getDocumentPassword", [documentId]);
  }
}
