import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';

class UploadDocument {
  String id;
  String title;
  IconData icon;
  String? path;
  String? uploadedFileId;
  UploadStatus uploadStatus = UploadStatus.NOT_INITIATED;
  UploadDocument({required this.id, required this.title, required this.icon});
}
