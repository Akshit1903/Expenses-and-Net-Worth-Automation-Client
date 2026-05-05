import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AppsScriptsClient {
  final AppsScriptType _appsScriptType;
  final AuthService _authService;
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();

  AppsScriptsClient(this._appsScriptType) : _authService = getIt<AuthService>();

  Future<String?> callAppsScripts(
    final String functionName,
    final List<dynamic> parameters,
    BuildContext? context,
    String? successMessage,
    String? errorMessage,
  ) async {
    try {
      final host = await _homeServerClient.getHostName(_appsScriptType);
      final Uri uri = Uri.parse(host);
      final accessToken = await _authService.getAccessToken();
      var headers = {
        'Authorization': "Bearer $accessToken",
        'Content-Type': 'application/json',
      };
      var body = json.encode({
        "function": functionName,
        "parameters": parameters,
      });

      final response = await http.post(uri, headers: headers, body: body);

      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (responseJson["error"] != null &&
            responseJson["error"]["details"] != null) {
          String errorDetails = responseJson["error"]["details"].toString();
          Utils.showSnackBar('Error: $errorDetails', context);
          return null;
        }
        assert(responseJson["done"] as bool);
        String result = responseJson["response"]["result"].toString();
        if (context != null && context.mounted && successMessage != null) {
          Utils.showSnackBar(successMessage, context);
        }
        return result;
      } else {
        if (context != null && context.mounted && errorMessage != null) {
          Utils.showSnackBar(
            '$errorMessage Status: ${response.statusCode.toString()}  Message: ${(response.reasonPhrase ?? "")}',
            context,
          );
        }
      }
    } catch (e) {
      if (context != null && context.mounted) {
        Utils.showSnackBar("Error: ${e.toString()}", context);
      }
    }
    return null;
  }
}
