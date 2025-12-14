import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Utils {
  static const String EANW_AUTOMATION = 'EANW_AUTOMATION';
  static const String UPLOAD_DOCUMENT_TO_DRIVE_URI =
      'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart';

  static const EMAIL = "email";
  static const _SCOPES = [
    "https://www.googleapis.com/auth/script.projects",
    "https://www.googleapis.com/auth/spreadsheets",
    'https://www.googleapis.com/auth/drive.file',
  ];
  static const MONTHS = [
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
    'December'
  ];

  static const STATE_CONFIG_APPS_SCRIPT_URI_PREFS_KEY =
      "STATE_CONFIG_APPS_SCRIPT";
  static String STATE_CONFIG_APPS_SCRIPT_URI = "";

  static const EANW_AUTOMATION_APPS_SCRIPTS_URI_PREFS_KEY =
      "EANW_AUTOMATION_APPS_SCRIPTS_URI";
  static String EANW_AUTOMATION_APPS_SCRIPTS_URI = "";

  static final ValueNotifier<List<String>> snackbarHistory =
      ValueNotifier<List<String>>([]);

  static late GoogleSignIn _googleSignIn;
  static late SharedPreferencesWithCache _prefs;

  static SharedPreferencesWithCache get prefs => _prefs;
  static GoogleSignIn get googleSignIn => _googleSignIn;

  static Future<void> init() async {
    _prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: <String>{EMAIL, STATE_CONFIG_APPS_SCRIPT_URI_PREFS_KEY},
      ),
    );
    _googleSignIn = GoogleSignIn(scopes: _SCOPES);
    if (Utils.prefs.containsKey(Utils.EMAIL)) {
      await Utils.googleSignIn.signInSilently();
    }
    if (Utils.prefs.containsKey(STATE_CONFIG_APPS_SCRIPT_URI_PREFS_KEY)) {
      STATE_CONFIG_APPS_SCRIPT_URI =
          await Utils.prefs.getString(STATE_CONFIG_APPS_SCRIPT_URI_PREFS_KEY)!;
    }
    // EANW_AUTOMATION_APPS_SCRIPTS_URI =
  }

  static snackbar(BuildContext context, String message) {
    final history = List<String>.from(snackbarHistory.value);
    history.add(message);
    snackbarHistory.value = history;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  static String getPreviousMonthYear() {
    DateTime now = DateTime.now();
    DateTime previousMonth = DateTime(now.year, now.month - 1, now.day);

    // Handle January correctly by adjusting the year
    if (now.month == 1) {
      previousMonth = DateTime(now.year - 1, 12, now.day);
    }

    String monthName = MONTHS[previousMonth.month - 1]; // Get month name
    return "$monthName ${previousMonth.year}";
  }

  static Future<bool?> showBackDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Are you sure you want to leave this page?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.labelLarge),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  static String getGoogleSheetsUrl(String sheetId) {
    return "https://docs.google.com/spreadsheets/d/$sheetId/edit?usp=sharing";
  }

  static String extractSheetsId(String url) {
    final regex = RegExp(r'/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(url);
    return (match != null && match.group(1) != null)
        ? match.group(1).toString()
        : "";
  }

  static String resolveDriveFileUrl(String? fileId) {
    if (fileId == null || fileId.isEmpty) {
      return "File ID is null or empty";
    }
    return "https://drive.google.com/file/d/$fileId/view?usp=sharing";
  }

  static Future<bool> isPdfEncrypted(String filePath) async {
    final file = File(filePath);
    List<int> bytes = await file.readAsBytes();
    try {
      PdfDocument document = PdfDocument(inputBytes: bytes);
      document.dispose();
      return false;
    } catch (e) {
      return true;
    }
  }

  static Future<String> getDecryptedPdf(
      String filePath, String password) async {
    final file = File(filePath);
    List<int> bytes = await file.readAsBytes();
    PdfDocument document = PdfDocument(inputBytes: bytes, password: password);
    // Remove password protection
    document.security.userPassword = '';
    document.security.ownerPassword = '';

    final directory = await getTemporaryDirectory();
    final tempPath =
        '${directory.path}/${filePath.split(Platform.pathSeparator).last}';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(await document.save());
    document.dispose();
    return tempPath;
  }

  static Future<String> extractPdfFromZip(String filePath,
      {String? password}) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, password: password);

    for (final archiveFile in archive) {
      if (archiveFile.isFile &&
          archiveFile.name.toLowerCase().endsWith('.pdf')) {
        final directory = await getTemporaryDirectory();
        final tempPath =
            '${directory.path}/${archiveFile.name.split('/').last}'; // handle potential path in zip
        final tempFile = File(tempPath);
        final data = archiveFile.content as List<int>;
        await tempFile.writeAsBytes(data);
        return tempPath;
      }
    }
    throw Exception('No PDF file found in Zip archive');
  }
}
