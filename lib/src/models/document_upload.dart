import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';

/// Model representing a document to be uploaded.
class UploadDocument {
  final String id;
  final String title;
  final IconData icon;
  String? path;
  String? uploadedFileId;
  UploadStatus uploadStatus;

  UploadDocument({
    required this.id,
    required this.title,
    required this.icon,
    this.path,
    this.uploadedFileId,
    this.uploadStatus = UploadStatus.NOT_INITIATED,
  });

  /// Resets the document to its initial state.
  void reset() {
    path = null;
    uploadedFileId = null;
    uploadStatus = UploadStatus.NOT_INITIATED;
  }

  /// Whether this document has a file selected for upload.
  bool get hasFile => path != null;
}
