import 'package:expense_and_net_worth_automation/src/clients/base/apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';

class ConfigStateAppsScriptsClient extends AppsScriptsClient {
  ConfigStateAppsScriptsClient() : super(AppsScriptType.stateConfig);

  Future<String?> getDocumentFolderId(
      String documentId, BuildContext? context) async {
    return callAppsScripts(
        "getAccountStatementFolderId",
        [documentId],
        context,
        "Account statement folder ID retrieved successfully!",
        "Error getting folder ID: $documentId");
  }

  Future<String?> getAppsScriptClientUrl(BuildContext? context) async {
    return callAppsScripts(
        "getAppsScriptClientUrl",
        [Utils.EANW_AUTOMATION],
        context,
        "Apps script URL retrieved successfully!",
        "Error getting apps script URL:");
  }

  Future<String?> getDocumentPassword(
      String documentId, BuildContext? context) async {
    return callAppsScripts(
        "getDocumentPassword",
        [documentId],
        context,
        "Document password retrieved successfully!",
        "Error getting document password for: $documentId");
  }
}
