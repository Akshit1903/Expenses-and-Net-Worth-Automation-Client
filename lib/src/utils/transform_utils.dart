import 'package:expense_and_net_worth_automation/src/utils/constants.dart';
import 'package:intl/intl.dart';

class TransformUtils {
  TransformUtils._();

  static String getGoogleSheetsUrl(String sheetId) {
    return '${AppConstants.googleSheetsBaseUrl}$sheetId/edit?usp=sharing';
  }

  static String extractSheetsId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(url);
    return (match != null && match.group(1) != null)
        ? match.group(1).toString()
        : '';
  }

  static String resolveDriveFileUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) {
      return 'File ID is null or empty';
    }
    return '${AppConstants.googleDriveFileBaseUrl}$fileId/view?usp=sharing';
  }

  static bool isValidGoogleSheetsUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'https') return false;
    if (!uri.host.endsWith('google.com')) return false;
    return true;
  }

  static String formatMoneyNumber(double value, {int? decimalDigits}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimalDigits ?? (value == value.roundToDouble() ? 0 : 2),
    );

    return formatter.format(value).trim();
  }

  static String formatMoneyString(String value, {int? decimalDigits}) {
    double? parsedValue = double.tryParse(value.replaceAll(',', ''));
    if (parsedValue == null) {
      return value; // Return original string if parsing fails
    }
    return formatMoneyNumber(parsedValue, decimalDigits: decimalDigits);
  }
}
