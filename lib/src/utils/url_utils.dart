import 'package:expense_and_net_worth_automation/src/utils/constants.dart';

/// URL construction and parsing utilities for Google Workspace resources.
///
/// Extracted from Utils to follow Single Responsibility Principle.
class UrlUtils {
  UrlUtils._(); // Prevent instantiation

  /// Constructs a Google Sheets edit URL from a sheet ID.
  static String getGoogleSheetsUrl(String sheetId) {
    return '${AppConstants.googleSheetsBaseUrl}$sheetId/edit?usp=sharing';
  }

  /// Extracts the Google Sheets ID from a full URL.
  ///
  /// Returns an empty string if the URL doesn't contain a valid sheet ID.
  static String extractSheetsId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(url);
    return (match != null && match.group(1) != null)
        ? match.group(1).toString()
        : '';
  }

  /// Constructs a Google Drive file view URL from a file ID.
  ///
  /// Returns an error description if [fileId] is null or empty.
  static String resolveDriveFileUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) {
      return 'File ID is null or empty';
    }
    return '${AppConstants.googleDriveFileBaseUrl}$fileId/view?usp=sharing';
  }

  /// Validates that a URL is a well-formed HTTPS Google Sheets URL (SEC-5).
  ///
  /// Returns true if the URL is safe to launch.
  static bool isValidGoogleSheetsUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'https') return false;
    if (!uri.host.endsWith('google.com')) return false;
    return true;
  }
}
