import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:expense_and_net_worth_automation/src/models/transaction.dart';

class HomeServerClient {
  final AuthService _authService;
  HomeServerClient()
      : _host = dotenv.get('HOME_SERVER_HOST'),
        _authService = getIt<AuthService>();

  final String _host;

  Uri _getUri(String endpoint) {
    return Uri.https(_host, endpoint);
  }

  Future<Map<String, String>> _getRequestHeaders() async {
    final accessToken = await _authService.getAccessToken();
    final idToken = await _authService.getIDToken();
    return {
      'Authorization': "Bearer $idToken",
      'X-ACCESS-TOKEN': accessToken,
      'Content-Type': 'application/json',
    };
  }

  Future<String> getHostName(AppsScriptType appsScriptType) async {
    try {
      final Uri uri = _getUri("/hosts/host/${appsScriptType.sheetName}");
      var headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        final String? host = responseJson["host"];
        if (host == null || host.isEmpty) {
          throw Exception("Host is null or empty");
        }
        return host;
      } else {
        throw Exception(
          'Failed to get host name. Status: ${response.statusCode}, Message: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception("Error getting host name: ${e.toString()}");
    }
  }

  /// Fetches the current journey state from the backend.
  /// Returns the parsed 'data' field from the journey API response.
  Future<Map<String, dynamic>> getJourney() async {
    try {
      final Uri uri = _getUri("/finance/journey");
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data'] as Map<String, dynamic>;
        }
        throw Exception('Journey API returned success=false');
      } else {
        throw Exception(
          'Failed to get journey. Status: ${response.statusCode}, '
          'Message: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching journey: ${e.toString()}');
    }
  }

  /// Fetches prefilled external transactions from the backend.
  Future<List<Transaction>> fetchPrefilledExternalTransactions() async {
    try {
      final Uri uri = _getUri("/finance/prefilled-external-transactions");
      final headers = await _getRequestHeaders();
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> dataList = body['data'] as List<dynamic>;
          return dataList
              .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        throw Exception('External transactions API returned success=false');
      } else {
        throw Exception(
          'Failed to get external transactions. Status: ${response.statusCode}, '
          'Message: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching external transactions: ${e.toString()}');
    }
  }
}
