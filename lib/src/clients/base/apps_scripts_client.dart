import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Result type for Apps Script API calls.
class AppsScriptResult<T> {
  final T? data;
  final String? errorMessage;

  const AppsScriptResult.success(this.data) : errorMessage = null;
  const AppsScriptResult.failure(this.errorMessage) : data = null;

  bool get isSuccess => errorMessage == null;
}

class AppsScriptsClient {
  final AppsScriptType _appsScriptType;
  final AuthService _authService = getIt<AuthService>();
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();

  AppsScriptsClient(this._appsScriptType);
  Future<AppsScriptResult<T>> callAppsScripts<T>(
    final String functionName,
    final List<dynamic> parameters,
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
          return AppsScriptResult.failure('Apps Script error: $errorDetails');
        }

        final bool isDone = responseJson["done"] as bool? ?? false;
        if (!isDone) {
          return const AppsScriptResult.failure(
              'Apps Script execution did not complete');
        }

        T? result = responseJson["response"]["result"] as T?;
        return AppsScriptResult.success(result);
      } else {
        return AppsScriptResult.failure(
          'Request failed. Status: ${response.statusCode} '
          'Message: ${response.reasonPhrase ?? ""}',
        );
      }
    } catch (e) {
      return AppsScriptResult.failure(
        'An error occurred while calling $functionName. '
        'Please check your connection and try again.',
      );
    }
  }
}
