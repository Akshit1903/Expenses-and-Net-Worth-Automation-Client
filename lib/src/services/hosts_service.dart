import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/services/prefs_service.dart';

class HostsService {
  final PrefsService _prefsService;
  final HomeServerClient _homeServerClient;

  HostsService(this._prefsService, this._homeServerClient);

  Future<String> getAppsScriptHost(AppsScriptType appsScriptType) async {
    String? appsScriptURL =
        await _prefsService.getAppsScriptURL(appsScriptType);
    if (appsScriptURL == null) {
      await refreshHosts();
      appsScriptURL = await _prefsService.getAppsScriptURL(appsScriptType);
    }
    if (appsScriptURL == null) {
      throw Exception("Unreachable state. Please set hosts in settings.");
    }
    return appsScriptURL;
  }

  Future<void> refreshHosts() async {
    for (final AppsScriptType appsScriptType in AppsScriptType.values) {
      String host = await _homeServerClient.getHostName(appsScriptType);
      await _prefsService.setAppsScriptURL(appsScriptType, host);
    }
  }

  Future<void> setAppsScriptHost(
      AppsScriptType appsScriptType, String host) async {
    await _prefsService.setAppsScriptURL(appsScriptType, host);
  }
}
