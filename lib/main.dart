import 'dart:async';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

Future<void> main() async {
  // ARCH-10: Global error handling — catches uncaught Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // ARCH-10: Global error handling — catches uncaught async errors
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    setUpLocators();

    final settingsController = SettingsController(SettingsService());
    await settingsController.loadSettings();

    // BUG-1 FIX: Perform silent sign-in once at startup,
    // not inside a FutureBuilder that re-runs on every rebuild.
    final authService = getIt<AuthService>();
    await authService.silentSignIn();

    runApp(ChangeNotifierProvider(
        create: (context) => AuthProvider(),
        child: MyApp(settingsController: settingsController)));
  }, (error, stackTrace) {
    debugPrint('Uncaught error: $error');
    debugPrint('Stack trace: $stackTrace');
  });
}
