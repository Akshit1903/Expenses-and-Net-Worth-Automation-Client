import 'package:expense_and_net_worth_automation/src/clients/config_state_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/google_workspace_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/pdf_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// ViewModel for the document upload step.
///
/// Manages the list of documents, upload logic, and progress state.
/// Documents that are already uploaded (from journey context) are
/// marked as SUCCESS and non-interactable.
class DocumentUploadViewModel extends ChangeNotifier {
  final JourneyProvider _journeyProvider;
  final GoogleWorkspaceClient _workspaceClient = getIt<GoogleWorkspaceClient>();
  final ConfigStateAppsScriptsClient _configClient =
      getIt<ConfigStateAppsScriptsClient>();

  /// Error messages collected during uploads.
  final List<String> errors = [];

  final List<UploadDocument> documents = [
    UploadDocument(
        id: 'HDFC', title: 'HDFC Statement', icon: Icons.account_balance),
    UploadDocument(
        id: 'SBI_CC', title: 'SBI CC Statement', icon: Icons.credit_card),
    UploadDocument(
        id: 'HDFC_CC', title: 'HDFC CC Statement', icon: Icons.credit_card),
    UploadDocument(
        id: 'SBI', title: 'SBI Statement', icon: Icons.account_balance),
    UploadDocument(id: 'PAYSLIP', title: 'Payslip', icon: Icons.receipt_long),
  ];

  DocumentUploadViewModel({
    required Map<String, dynamic> isAccountStatementUploaded,
    required JourneyProvider journeyProvider,
  }) : _journeyProvider = journeyProvider {
    // Mark already-uploaded documents as non-interactable
    for (final doc in documents) {
      if (isAccountStatementUploaded[doc.id] == true) {
        doc.uploadStatus = UploadStatus.SUCCESS;
      }
    }
  }

  /// Whether the document was already uploaded before this session.
  bool isAlreadyUploaded(UploadDocument doc) {
    return doc.uploadStatus == UploadStatus.SUCCESS && doc.path == null;
  }

  /// Whether any document is currently being uploaded.
  bool get isLoading => documents.any((d) =>
      d.uploadStatus == UploadStatus.QUEUED ||
      d.uploadStatus == UploadStatus.DECRYPTING ||
      d.uploadStatus == UploadStatus.RESOLVE_FOLDER_ID ||
      d.uploadStatus == UploadStatus.UPLOADING);

  /// Whether any document has been selected for upload.
  bool get hasSelectedDocuments =>
      documents.any((d) => d.uploadStatus == UploadStatus.SELECTED);

  /// Opens file picker for a specific document.
  Future<void> pickDocument(UploadDocument doc) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) return;
    doc.path = result.files.single.path;
    doc.uploadStatus = UploadStatus.SELECTED;
    notifyListeners();
  }

  /// Deselects a previously selected document.
  void deselectDocument(UploadDocument doc) {
    doc.reset();
    notifyListeners();
  }

  /// Uploads all selected documents in parallel.
  Future<void> uploadAllDocuments() async {
    errors.clear();

    // Queue all selected documents
    for (final doc in documents) {
      if (doc.uploadStatus == UploadStatus.SELECTED) {
        doc.uploadStatus = UploadStatus.QUEUED;
      }
    }
    notifyListeners();

    // Upload in parallel
    final futures = documents
        .where((d) => d.uploadStatus == UploadStatus.QUEUED)
        .map((d) => _uploadSingleDocument(d))
        .toList();

    await Future.wait(futures);

    await _journeyProvider.fetchJourney();
    notifyListeners();
  }

  /// Handles the full upload pipeline for a single document:
  /// DECRYPT → RESOLVE_FOLDER_ID → UPLOAD
  Future<void> _uploadSingleDocument(UploadDocument doc) async {
    try {
      // Step 1: Decrypt if needed (zip or encrypted PDF)
      doc.uploadStatus = UploadStatus.DECRYPTING;
      notifyListeners();
      await _handleDecryption(doc);

      // Step 2: Resolve the Drive folder ID
      doc.uploadStatus = UploadStatus.RESOLVE_FOLDER_ID;
      notifyListeners();
      final folderResult = await _configClient.getDocumentFolderId(doc.id);
      if (!folderResult.isSuccess || folderResult.data == null) {
        throw 'Folder ID not found for ${doc.title}';
      }

      // Step 3: Upload to Google Drive
      doc.uploadStatus = UploadStatus.UPLOADING;
      notifyListeners();
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final uploadResult = await _workspaceClient.uploadDocumentToDrive(
        path: doc.path!,
        fileName:
            '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}.pdf',
        folderId: folderResult.data!,
      );

      if (uploadResult.isSuccess) {
        doc.uploadedFileId = uploadResult.data;
        doc.uploadStatus = UploadStatus.SUCCESS;
      } else {
        throw uploadResult.errorMessage ?? 'Upload failed';
      }
    } catch (e) {
      doc.uploadStatus = UploadStatus.FAILURE;
      errors.add('${doc.title}: $e');
    }
    notifyListeners();
  }

  /// Handles zip extraction and PDF decryption.
  Future<void> _handleDecryption(UploadDocument doc) async {
    final path = doc.path!;

    if (path.toLowerCase().endsWith('.zip')) {
      try {
        // Try extracting without password first
        doc.path = await PdfService.extractPdfFromZip(path);
      } catch (_) {
        // Needs password — fetch from server
        final pwResult = await _configClient.getDocumentPassword(doc.id);
        if (!pwResult.isSuccess || pwResult.data == null) {
          throw 'Password not found for zip';
        }
        doc.path =
            await PdfService.extractPdfFromZip(path, password: pwResult.data!);
      }
    } else if (path.toLowerCase().endsWith('.pdf') &&
        await PdfService.isPdfEncrypted(path)) {
      final pwResult = await _configClient.getDocumentPassword(doc.id);
      if (!pwResult.isSuccess || pwResult.data == null) {
        throw 'Password not found';
      }
      doc.path = await PdfService.getDecryptedPdf(path, pwResult.data!);
    }
  }

  @override
  void dispose() {
    PdfService.cleanupTempFiles();
    super.dispose();
  }
}
