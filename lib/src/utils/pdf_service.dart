import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for PDF manipulation: encryption detection, decryption,
/// and ZIP extraction.
///
/// Extracted from Utils to follow Single Responsibility Principle.
/// Tracks created temp files for cleanup (SEC-4).
class PdfService {
  PdfService._(); // Prevent instantiation

  /// Tracks temporary file paths created during processing
  /// so they can be cleaned up after upload (SEC-4).
  static final List<String> _tempFiles = [];

  /// Returns the list of temp file paths created by this service.
  static List<String> get tempFiles => List.unmodifiable(_tempFiles);

  /// Checks if a PDF file at [filePath] is password-protected.
  static Future<bool> isPdfEncrypted(String filePath) async {
    final file = File(filePath);
    final List<int> bytes = await file.readAsBytes();
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      document.dispose();
      return false;
    } catch (e) {
      return true;
    }
  }

  /// Decrypts a password-protected PDF and writes the result
  /// to a temporary file.
  ///
  /// Returns the path to the decrypted temporary PDF file.
  /// Call [cleanupTempFiles] after uploads complete (SEC-4).
  static Future<String> getDecryptedPdf(
      String filePath, String password) async {
    final file = File(filePath);
    final List<int> bytes = await file.readAsBytes();
    final PdfDocument document =
        PdfDocument(inputBytes: bytes, password: password);
    // Remove password protection
    document.security.userPassword = '';
    document.security.ownerPassword = '';

    final directory = await getTemporaryDirectory();
    final tempPath =
        '${directory.path}/${filePath.split(Platform.pathSeparator).last}';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(await document.save());
    document.dispose();

    _tempFiles.add(tempPath);
    return tempPath;
  }

  /// Extracts a PDF file from a ZIP archive.
  ///
  /// Optionally accepts a [password] for encrypted ZIP files.
  /// Returns the path to the extracted temporary PDF file.
  /// Call [cleanupTempFiles] after uploads complete (SEC-4).
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
            '${directory.path}/${archiveFile.name.split('/').last}';
        final tempFile = File(tempPath);
        final data = archiveFile.content as List<int>;
        await tempFile.writeAsBytes(data);

        _tempFiles.add(tempPath);
        return tempPath;
      }
    }
    throw Exception('No PDF file found in Zip archive');
  }

  /// Deletes all temporary files created during PDF processing (SEC-4).
  ///
  /// Should be called after document uploads complete or on page dispose.
  static Future<void> cleanupTempFiles() async {
    for (final path in _tempFiles) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Best-effort cleanup; don't crash on failure
      }
    }
    _tempFiles.clear();
  }
}
