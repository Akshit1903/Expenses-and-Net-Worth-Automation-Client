/// Re-export barrel file for backward compatibility.
///
/// The original Utils God Class has been decomposed into:
/// - [AppConstants] — static constants
/// - [SnackbarService] — snackbar display and history
/// - [AppDateUtils] — date formatting
/// - [UrlUtils] — URL construction and parsing
/// - [PdfService] — PDF encryption/decryption and ZIP extraction
/// - [DialogUtils] — confirmation dialogs
///
/// New code should import these directly rather than through this barrel.
export 'constants.dart';
export 'snackbar_service.dart';
export 'app_date_utils.dart';
export 'url_utils.dart';
export 'pdf_service.dart';
export 'dialog_utils.dart';
