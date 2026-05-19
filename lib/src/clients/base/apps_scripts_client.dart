import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Result type for Apps Script API calls.
///
/// ARCH-2 FIX: Clients now return structured results instead of
/// accepting BuildContext and showing snackbars directly. The UI
/// layer is responsible for displaying messages.
class AppsScriptResult {
  final String? data;
  final String? errorMessage;

  const AppsScriptResult.success(this.data) : errorMessage = null;
  const AppsScriptResult.failure(this.errorMessage) : data = null;

  bool get isSuccess => errorMessage == null;
}

class AppsScriptsClient {
  final AppsScriptType _appsScriptType;
  final AuthService _authService;
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();

  AppsScriptsClient(this._appsScriptType) : _authService = getIt<AuthService>();

  /// Calls an Apps Script function and returns a structured result.
  ///
  /// ARCH-2: No longer accepts BuildContext. Returns [AppsScriptResult]
  /// so the calling UI layer can handle success/error display.
  ///
  /// BUG-2 FIX: Replaced `assert(responseJson["done"])` with a proper
  /// runtime check that works in release mode.
  ///
  /// SEC-3 FIX: Error messages are sanitized — raw exception strings
  /// (which may contain tokens) are not exposed.
  Future<AppsScriptResult> callAppsScripts(
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
          return AppsScriptResult.failure(
              'Apps Script error: $errorDetails');
        }

        // BUG-2 FIX: Runtime check instead of assert (stripped in release)
        final bool isDone = responseJson["done"] as bool? ?? false;
        if (!isDone) {
          return const AppsScriptResult.failure(
              'Apps Script execution did not complete');
        }

        String result = responseJson["response"]["result"].toString();
        return AppsScriptResult.success(result);
      } else {
        return AppsScriptResult.failure(
          'Request failed. Status: ${response.statusCode} '
          'Message: ${response.reasonPhrase ?? ""}',
        );
      }
    } catch (e) {
      // SEC-3 FIX: Sanitize error message — don't expose raw exception
      // which may contain bearer tokens or internal details
      return AppsScriptResult.failure(
        'An error occurred while calling $functionName. '
        'Please check your connection and try again.',
      );
    }
  }
}
