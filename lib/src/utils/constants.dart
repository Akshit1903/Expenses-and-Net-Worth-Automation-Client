/// Application-wide constants.
///
/// Centralizes magic strings and configuration values
/// to avoid scattering them across the codebase.
class AppConstants {
  AppConstants._(); // Prevent instantiation

  static const String eanwAutomation = 'EANW_AUTOMATION';

  static const String uploadDocumentToDriveUri =
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';

  static const String email = 'email';

  static const List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Maximum number of snackbar history entries to retain.
  static const int maxSnackbarHistorySize = 100;

  /// Google Sheets base URL pattern.
  static const String googleSheetsBaseUrl =
      'https://docs.google.com/spreadsheets/d/';

  /// Google Drive file view base URL.
  static const String googleDriveFileBaseUrl =
      'https://drive.google.com/file/d/';
}
