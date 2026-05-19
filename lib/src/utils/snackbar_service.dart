import 'package:expense_and_net_worth_automation/src/utils/constants.dart';
import 'package:flutter/material.dart';

/// Centralized snackbar display and history tracking.
///
/// Separates UI notification concerns from business logic utilities.
/// History is capped at [AppConstants.maxSnackbarHistorySize] entries
/// to prevent unbounded memory growth (SEC-7).
class SnackbarService {
  SnackbarService._(); 

  static final ValueNotifier<List<String>> snackbarHistory =
      ValueNotifier<List<String>>([]);

  /// Shows a snackbar message and records it in history.
  static void showSnackBar(String message, BuildContext? context) {
    _addToHistory(message);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
      ));
    }
  }

  static void _addToHistory(String message) {
    final history = List<String>.from(snackbarHistory.value);
    history.add(message);

    if (history.length > AppConstants.maxSnackbarHistorySize) {
      history.removeRange(
          0, history.length - AppConstants.maxSnackbarHistorySize);
    }

    snackbarHistory.value = history;
  }
}
