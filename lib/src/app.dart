import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:expense_and_net_worth_automation/src/views/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home/main_scaffold.dart';
import 'settings/settings_controller.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;
  final AuthService _authService = getIt<AuthService>();
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          supportedLocales: const [
            Locale('en', ''),
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                return FutureBuilder(
                    future: _authService.silentSignIn(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (authProvider.isAuthenticated == false) {
                          return AuthPage();
                        }
                        switch (routeSettings.name) {
                          case MainScaffold.routeName:
                            return MainScaffold();
                          case SettingsView.routeName:
                            return SettingsView(controller: settingsController);
                          case UnprocessedTransactionsPage.routeName:
                            return UnprocessedTransactionsPage();
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
        );
      },
    );
  }
}
