/// Application-wide constants.

class AppConstants {
  AppConstants._();

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

  static const int maxSnackbarHistorySize = 100;

  static const String googleSheetsBaseUrl =
      'https://docs.google.com/spreadsheets/d/';

  static const String googleDriveFileBaseUrl =
      'https://drive.google.com/file/d/';
}
