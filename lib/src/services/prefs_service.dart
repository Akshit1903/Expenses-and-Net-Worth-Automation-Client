import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;
  PrefsService(this._prefs);

  static const String _externalTransactionsKey = 'external_transactions';

  Future<String?> getAppsScriptURL(AppsScriptType appsScriptType) async {
    return _prefs.getString(_getHostKey(appsScriptType));
  }

  Future<void> setAppsScriptURL(
      AppsScriptType appsScriptType, String appsScriptURL) async {
    await _prefs.setString(_getHostKey(appsScriptType), appsScriptURL);
  }

  String? getExternalTransactions() {
    return _prefs.getString(_externalTransactionsKey);
  }

  Future<void> setExternalTransactions(String value) async {
    await _prefs.setString(_externalTransactionsKey, value);
  }

  Future<void> removeExternalTransactions() async {
    await _prefs.remove(_externalTransactionsKey);
  }

  String _getHostKey(AppsScriptType appsScriptType) {
    return "${appsScriptType.sheetName}_HOST";
  }
}
