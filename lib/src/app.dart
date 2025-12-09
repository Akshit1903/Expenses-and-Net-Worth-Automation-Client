import 'package:expense_and_net_worth_automation/src/auth/auth_page.dart';
import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/home/vars_config/vars_config_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings/settings_controller.dart';
import 'home/main_scaffold.dart';


/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return ChangeNotifierProvider(
          create: (context) => AuthProvider(),
          child: MaterialApp(
            // Providing a restorationScopeId allows the Navigator built by the
            // MaterialApp to restore the navigation stack when a user leaves and
            // returns to the app after it has been killed while running in the
            // background.
            restorationScopeId: 'app',

            // Provide the generated AppLocalizations to the MaterialApp. This
            // allows descendant Widgets to display the correct translations
            // depending on the user's locale.

            supportedLocales: const [
              Locale('en', ''), // English, no country code
            ],

            // Use AppLocalizations to configure the correct application title
            // depending on the user's locale.
            //
            // The appTitle is defined in .arb files found in the localization
            // directory.

            // Define a light and dark color theme. Then, read the user's
            // preferred ThemeMode (light, dark, or system default) from the
            // SettingsController to display the correct theme.
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: settingsController.themeMode,

            // Define a function to handle named routes in order to support
            // Flutter web url navigation and deep linking.
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) {
                  return FutureBuilder(
                      future: context.watch<AuthProvider>().isAuthenticated(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data == false) {
                            return AuthPage();
                          }
                          switch (routeSettings.name) {
                            case MainScaffold.routeName:
                              return MainScaffold();
                            case SettingsView.routeName:
                              return SettingsView(
                                  controller: settingsController);
                            case UnprocessedTransactionsPage.routeName:
                              return UnprocessedTransactionsPage();
                            case VarsConfigPage.routeName:
                              return VarsConfigPage();
                            default:
                              return MainScaffold();
                          }
                        }
                        return const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      });
                },
              );
            },
          ),
        );
      },
    );
  }
}
