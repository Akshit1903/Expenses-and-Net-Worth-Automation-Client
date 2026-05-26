import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/views/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home/main_scaffold.dart';
import 'settings/settings_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

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
                bool? isAuthenticated = authProvider.isAuthenticated;
                if (isAuthenticated == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!isAuthenticated) {
                  return const AuthPage();
                }
                switch (routeSettings.name) {
                  case MainScaffold.routeName:
                    return const MainScaffold();
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case UnprocessedTransactionsPage.routeName:
                    return const UnprocessedTransactionsPage();
                  case ExternalTransactionsPage.routeName:
                    return const ExternalTransactionsPage();
                  default:
                    return const MainScaffold();
                }
              },
            );
          },
        );
      },
    );
  }
}
