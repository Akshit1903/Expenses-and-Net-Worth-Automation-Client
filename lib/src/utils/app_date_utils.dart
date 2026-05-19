import 'package:expense_and_net_worth_automation/src/utils/constants.dart';

/// Date-related utility functions.
class AppDateUtils {
  AppDateUtils._(); 

  /// Returns the previous month and year as a formatted string
  /// (e.g., "April 2026").

  static String getPreviousMonthYear() {
    final DateTime now = DateTime.now();
    final DateTime previousMonth = DateTime(now.year, now.month - 1, 1);

    final String monthName = AppConstants.months[previousMonth.month - 1];
    return '$monthName ${previousMonth.year}';
  }
}
