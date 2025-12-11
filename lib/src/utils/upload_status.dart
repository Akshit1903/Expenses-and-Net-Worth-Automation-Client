import 'package:flutter/material.dart';

enum UploadStatus {
  NOT_INITIATED(Icon(Icons.upload_file)),
  SELECTED(Icon(Icons.close)),
  QUEUED(Icon(Icons.hourglass_bottom_rounded)),
  RESOLVE_FOLDER_ID(Icon(Icons.drive_folder_upload_rounded)),
  UPLOADING(Icon(Icons.upload_rounded)),
  SUCCESS(Icon(Icons.check_circle, color: Colors.green)),
  FAILURE(Icon(Icons.error, color: Colors.red));

  final Icon icon;
  const UploadStatus(this.icon);
}
