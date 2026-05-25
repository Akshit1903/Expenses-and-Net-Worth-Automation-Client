import 'dart:io';

import 'package:expense_and_net_worth_automation/src/features/document_upload/document_upload_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// View for the document upload journey step.
///
/// Shows upload cards for each document type with status indicators.
/// Already-uploaded documents (from journey context) are disabled.
class DocumentUploadView extends StatefulWidget {
  final JourneyStep step;

  /// When true, renders without its own Scaffold (for embedding in Action tab).
  final bool embedded;

  const DocumentUploadView({
    super.key,
    required this.step,
    this.embedded = false,
  });

  @override
  State<DocumentUploadView> createState() => _DocumentUploadViewState();
}

class _DocumentUploadViewState extends State<DocumentUploadView> {
  late final DocumentUploadViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final uploadStatus = widget.step.context['isAccountStatementUploaded']
            as Map<String, dynamic>? ??
        {};
    _viewModel = DocumentUploadViewModel(
      isAccountStatementUploaded: uploadStatus,
      onUploadComplete: () {
        // Refresh journey state after uploads
        context.read<JourneyProvider>().fetchJourney();
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => _buildBody(context),
    );

    if (widget.embedded) return body;

    return Scaffold(
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        if (_viewModel.isLoading) const LinearProgressIndicator(),

        // Error messages
        if (_viewModel.errors.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Text(
              _viewModel.errors.join('\n'),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),

        // Document list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _viewModel.documents.length + 1, // +1 for button
            itemBuilder: (context, index) {
              if (index < _viewModel.documents.length) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      _buildDocumentCard(context, _viewModel.documents[index]),
                );
              }
              // Upload All button at the bottom
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: FilledButton.icon(
                  onPressed:
                      (!_viewModel.hasSelectedDocuments || _viewModel.isLoading)
                          ? null
                          : _viewModel.uploadAllDocuments,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload All'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context, UploadDocument doc) {
    final isDisabled = _viewModel.isAlreadyUploaded(doc);
    final isSelected = doc.uploadStatus == UploadStatus.SELECTED;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: isDisabled
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        enabled: !isDisabled,
        leading: Icon(
          doc.icon,
          color: isDisabled
              ? theme.colorScheme.outline
              : isSelected
                  ? Colors.green
                  : theme.colorScheme.primary,
        ),
        title: Text(
          doc.title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDisabled ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: Text(
          _resolveSubtitle(doc),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDisabled ? theme.colorScheme.outline : null,
          ),
        ),
        trailing: doc.uploadStatus.icon,
        onTap: isDisabled ? null : () => _handleTap(doc),
      ),
    );
  }

  String _resolveSubtitle(UploadDocument doc) {
    if (_viewModel.isAlreadyUploaded(doc)) return 'Already uploaded';
    switch (doc.uploadStatus) {
      case UploadStatus.NOT_INITIATED:
        return 'Tap to select file';
      case UploadStatus.SELECTED:
        return doc.path!.split(Platform.pathSeparator).last;
      case UploadStatus.QUEUED:
        return 'Queued...';
      case UploadStatus.DECRYPTING:
        return 'Decrypting...';
      case UploadStatus.RESOLVE_FOLDER_ID:
        return 'Resolving folder...';
      case UploadStatus.UPLOADING:
        return 'Uploading...';
      case UploadStatus.SUCCESS:
        return 'Uploaded successfully';
      case UploadStatus.FAILURE:
        return 'Upload failed — tap to retry';
    }
  }

  void _handleTap(UploadDocument doc) async {
    switch (doc.uploadStatus) {
      case UploadStatus.SUCCESS:
        // Copy Drive URL to clipboard
        final url = TransformUtils.resolveDriveFileUrl(doc.uploadedFileId);
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          SnackbarService.showSnackBar('Drive URL copied', context);
        }
      case UploadStatus.NOT_INITIATED || UploadStatus.FAILURE:
        _viewModel.pickDocument(doc);
      case UploadStatus.SELECTED:
        _viewModel.deselectDocument(doc);
      default:
        break;
    }
  }
}
