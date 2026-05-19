import 'package:expense_and_net_worth_automation/src/utils/constants.dart';

class UrlUtils {
  UrlUtils._(); 

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
}
