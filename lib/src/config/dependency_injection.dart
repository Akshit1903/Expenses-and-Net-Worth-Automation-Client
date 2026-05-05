import 'package:expense_and_net_worth_automation/src/clients/config_state_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/google_workspace_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/auth_config.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/services/hosts_service.dart';
import 'package:expense_and_net_worth_automation/src/services/prefs_service.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt getIt = GetIt.instance;

void setUpLocators() {
  // Clients
  getIt.registerLazySingleton<GoogleWorkspaceClient>(
    () => GoogleWorkspaceClient(),
  );
  getIt.registerLazySingleton<ConfigStateAppsScriptsClient>(
    () => ConfigStateAppsScriptsClient(),
  );
  getIt.registerLazySingleton<EanwAppsScriptsClient>(
    () => EanwAppsScriptsClient(),
  );
  // Services
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(AuthConfig.getSignInClient()),
  );
  getIt.registerSingleton<HomeServerClient>(
    HomeServerClient(),
  );
  getIt.registerSingletonAsync<PrefsService>(() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    return PrefsService(sharedPrefs);
  });
  getIt.registerSingletonWithDependencies<HostsService>(
    () => HostsService(getIt<PrefsService>(), getIt<HomeServerClient>()),
    dependsOn: [PrefsService],
  );
}
