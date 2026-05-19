import 'package:expense_and_net_worth_automation/src/utils/constants.dart';

/// Date-related utility functions.
///
/// Extracted from Utils to follow Single Responsibility Principle.
class AppDateUtils {
  AppDateUtils._(); // Prevent instantiation

  /// Returns the previous month and year as a formatted string
  /// (e.g., "April 2026").
  ///
  /// Uses day=1 to avoid day-overflow bugs (BUG-3).
  /// For example, if today is March 31, `DateTime(2026, 2, 31)` would
  /// overflow to March 3. Using day=1 prevents this.
  static String getPreviousMonthYear() {
    final DateTime now = DateTime.now();
    // Dart's DateTime constructor handles month=0 correctly
    // (wraps to December of previous year), so no special January logic needed.
    final DateTime previousMonth = DateTime(now.year, now.month - 1, 1);

    final String monthName = AppConstants.months[previousMonth.month - 1];
    return '$monthName ${previousMonth.year}';
  }
}
