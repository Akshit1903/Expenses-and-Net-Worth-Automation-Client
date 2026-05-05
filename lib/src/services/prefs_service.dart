import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  final SharedPreferences _prefs;

  PrefsService(this._prefs);

  Future<String?> getAppsScriptURL(AppsScriptType appsScriptType) async {
    return _prefs.getString(getHostKey(appsScriptType));
  }

  Future<void> setAppsScriptURL(
      AppsScriptType appsScriptType, String appsScriptURL) async {
    await _prefs.setString(getHostKey(appsScriptType), appsScriptURL);
  }

  String getHostKey(AppsScriptType appsScriptType) {
    return "${appsScriptType.sheetName}_HOST";
  }
}
