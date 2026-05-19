import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expense_and_net_worth_automation/src/clients/config_state_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/google_workspace_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/models/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:expense_and_net_worth_automation/src/utils/pdf_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:expense_and_net_worth_automation/src/utils/url_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  // loading vars
  bool _isUploadingCSVToCreateSheet = false;
  bool _isRunningAppsScriptAutomation = false;

  String _csvFilePath = '';
  String _createSpreadSheetByUploadingCSVFileResponse = '{}';
  String? _appsScriptResponse = '{}';
  List<List<String>> _unprocessedTransactions = [];

  List<UploadDocument> documentsToUpload = [
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

  final TextEditingController _spreadSheetUrlController =
      TextEditingController();
  final GoogleWorkspaceClient _googleWorkspaceClient =
      getIt<GoogleWorkspaceClient>();
  final EanwAppsScriptsClient _eanwAppsScriptsClient =
      getIt<EanwAppsScriptsClient>();
  final ConfigStateAppsScriptsClient _configStateAppsScriptsClient =
      getIt<ConfigStateAppsScriptsClient>();
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();
    _spreadSheetUrlController.addListener(() {
      setState(() {});
    });

    // Intent handling (kept from original)
    void setFilePath(List<SharedMediaFile> value) {
      if (value.length == 1 && value[0].path.split('.').last == 'csv') {
        setState(() {
          _csvFilePath = value[0].path;
        });
      }
    }

    _intentSub =
        ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      setFilePath(value);
      Future.delayed(Duration.zero).then((value) {
        // Need to check if can pop, or just handle it.
        // In the original code it popped, assuming it was a modal or pushed page.
        // Since this is now a tab, we probably shouldn't pop the whole app.
        // leaving as is for now but might need adjustment if this was intended to close a dialog.
      });
    }, onError: (err) {
      SnackbarService.showSnackBar(
          "getIntentDataStream error: $err", context);
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      setFilePath(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _intentSub.cancel();
    _spreadSheetUrlController.dispose();
    // SEC-4 FIX: Clean up temp files created during document processing
    PdfService.cleanupTempFiles();
    super.dispose();
  }

  List<List<String>> _getUnprocessedTransactions(
      String? unprocessedTransactionsResponse) {
    if (unprocessedTransactionsResponse == null) {
      return [];
    }
    final jsonResponse = jsonDecode(unprocessedTransactionsResponse);
    return (jsonResponse['unprocessedTransactions'] as List)
        .map<List<String>>((row) =>
            (row as List).map<String>((item) => item.toString()).toList())
        .toList();
  }

  Future<void> _triggerAutomationButtonHandler() async {
    try {
      if (_spreadSheetUrlController.text.isEmpty && _csvFilePath.isNotEmpty) {
        setState(() {
          _isUploadingCSVToCreateSheet = true;
        });
        String response = await _googleWorkspaceClient
            .createSpreadSheetByUploadingCSVFile(_csvFilePath);
        setState(() {
          _createSpreadSheetByUploadingCSVFileResponse = response;
          String spreadSheetId =
              jsonDecode(_createSpreadSheetByUploadingCSVFileResponse)['id'];
          _spreadSheetUrlController.text =
              UrlUtils.getGoogleSheetsUrl(spreadSheetId);
          _isUploadingCSVToCreateSheet = false;
        });
      }
      if (_spreadSheetUrlController.text.isNotEmpty) {
        await Clipboard.setData(
            ClipboardData(text: _spreadSheetUrlController.text));
        String spreadSheetId =
            UrlUtils.extractSheetsId(_spreadSheetUrlController.text);

        setState(() {
          _isRunningAppsScriptAutomation = true;
        });

        // ARCH-2 FIX: Handle AppsScriptResult from client
        final result = await _eanwAppsScriptsClient
            .triggerExpenseAndNetWorthAutomationAppsScript(spreadSheetId);

        if (result.isSuccess) {
          setState(() {
            _appsScriptResponse = result.data;
            _unprocessedTransactions =
                _getUnprocessedTransactions(_appsScriptResponse);
            _isRunningAppsScriptAutomation = false;
          });
          if (mounted) {
            SnackbarService.showSnackBar(
                'Automation script triggered successfully!', context);
          }
        } else {
          setState(() {
            _isRunningAppsScriptAutomation = false;
          });
          if (mounted) {
            SnackbarService.showSnackBar(
                result.errorMessage ?? 'Unknown error', context);
          }
        }
      }

      for (final UploadDocument document in documentsToUpload) {
        if (document.path != null) {
          setState(() {
            document.uploadStatus = UploadStatus.QUEUED;
          });
        }
      }
      List<Future<void>> documentUploadFutures = [];
      for (final UploadDocument document in documentsToUpload) {
        Future<void> resolveDocumentUploadFuture() async {
          // Check for Zip file
          setState(() {
            document.uploadStatus = UploadStatus.DECRYPTING;
          });
          if (document.path!.toLowerCase().endsWith('.zip')) {
            try {
              // Try to extract without password first
              final String extractedPdfPath =
                  await PdfService.extractPdfFromZip(document.path!);
              document.path = extractedPdfPath;
            } catch (e) {
              // If failed, assume it needs password
              try {
                final passwordResult = await _configStateAppsScriptsClient
                    .getDocumentPassword(document.id);
                if (!passwordResult.isSuccess ||
                    passwordResult.data == null ||
                    passwordResult.data!.isEmpty) {
                  throw 'Password not found for zip';
                }
                document.path = await PdfService.extractPdfFromZip(
                    document.path!,
                    password: passwordResult.data!);
              } catch (e) {
                if (mounted) {
                  SnackbarService.showSnackBar(
                      'Failed to extract PDF from Zip for ${document.title}: $e',
                      context);
                }
                setState(() {
                  document.uploadStatus = UploadStatus.FAILURE;
                });
                return;
              }
            }
          } else if (document.path!.toLowerCase().endsWith('.pdf') &&
              await PdfService.isPdfEncrypted(document.path!)) {
            try {
              final passwordResult = await _configStateAppsScriptsClient
                  .getDocumentPassword(document.id);
              if (!passwordResult.isSuccess ||
                  passwordResult.data == null ||
                  passwordResult.data!.isEmpty) {
                throw 'Password not found';
              }
              document.path = await PdfService.getDecryptedPdf(
                  document.path!, passwordResult.data!);
            } catch (e) {
              if (mounted) {
                SnackbarService.showSnackBar(
                    'Failed to decrypt PDF for ${document.title}: $e',
                    context);
              }
              setState(() {
                document.uploadStatus = UploadStatus.FAILURE;
              });
              return;
            }
          }

          setState(() {
            document.uploadStatus = UploadStatus.RESOLVE_FOLDER_ID;
          });

          // ARCH-2 FIX: Handle AppsScriptResult
          final folderResult = await _configStateAppsScriptsClient
              .getDocumentFolderId(document.id);
          if (!folderResult.isSuccess ||
              folderResult.data == null ||
              folderResult.data!.isEmpty) {
            setState(() {
              document.uploadStatus = UploadStatus.FAILURE;
            });
            if (mounted) {
              SnackbarService.showSnackBar(
                  'Folder ID not found for ${document.title}', context);
            }
            return;
          }

          setState(() {
            document.uploadStatus = UploadStatus.UPLOADING;
          });
          final now = DateTime.now();
          final oneMonthAgo = DateTime(
            now.year,
            now.month - 1,
            1, // BUG-3 analogy: use day=1 to avoid overflow
          );

          // ARCH-2 FIX: Handle WorkspaceResult
          final uploadResult =
              await _googleWorkspaceClient.uploadDocumentToDrive(
                  path: document.path.toString(),
                  fileName: "${oneMonthAgo.year}-${oneMonthAgo.month}.pdf",
                  folderId: folderResult.data!);

          setState(() {
            if (uploadResult.isSuccess) {
              document.uploadedFileId = uploadResult.data;
              document.uploadStatus = UploadStatus.SUCCESS;
            } else {
              document.uploadStatus = UploadStatus.FAILURE;
              if (mounted) {
                SnackbarService.showSnackBar(
                    uploadResult.errorMessage ?? 'Upload failed', context);
              }
            }
          });
        }

        if (document.path != null) {
          documentUploadFutures.add(resolveDocumentUploadFuture());
        }
      }
      await Future.wait(documentUploadFutures);
    } catch (e) {
      if (mounted) {
        SnackbarService.showSnackBar('Error: ${e.toString()}', context);
      }
    }
  }

  Future<void> _pickCSVFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String filePath = file.path;
      if (filePath.split('.').last != 'csv') {
        if (mounted) {
          SnackbarService.showSnackBar('Invalid file type', context);
        }
        return;
      }
      setState(() {
        _csvFilePath = filePath;
      });
    } else {
      if (mounted) {
        SnackbarService.showSnackBar('No file selected', context);
      }
    }
  }

  Future<void> _pickDocument(UploadDocument document) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) {
      if (mounted) {
        SnackbarService.showSnackBar(
            'No file selected for ${document.title}', context);
      }
      return;
    }
    setState(() {
      document.path = result.files.single.path;
      document.uploadStatus = UploadStatus.SELECTED;
    });
  }

  /// SEC-5 FIX: Validate URL before launching to prevent
  /// opening malicious or non-HTTPS URLs.
  Future<void> _launchSheet() async {
    final urlText = _spreadSheetUrlController.text;
    if (!UrlUtils.isValidGoogleSheetsUrl(urlText)) {
      SnackbarService.showSnackBar(
          'Invalid URL. Only HTTPS Google URLs are allowed.', context);
      return;
    }
    Uri url = Uri.parse(urlText);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackbarService.showSnackBar('Could not open the sheet', context);
      }
    }
  }

  Widget _buildFileUploadCard(UploadDocument uploadDocument) {
    String? path = uploadDocument.path;
    bool isSelected =
        path != null && uploadDocument.uploadStatus == UploadStatus.SELECTED;

    void resolveOnTapHandler() async {
      switch (uploadDocument.uploadStatus) {
        case UploadStatus.SUCCESS:
          String fileIdUrl =
              UrlUtils.resolveDriveFileUrl(uploadDocument.uploadedFileId);
          await Clipboard.setData(ClipboardData(text: fileIdUrl));
          if (mounted) {
            SnackbarService.showSnackBar(
                'Drive file URL copied: $fileIdUrl', context);
          }
        case UploadStatus.NOT_INITIATED || UploadStatus.FAILURE:
          _pickDocument(uploadDocument);
          return;
        case UploadStatus.SELECTED:
          setState(() {
            uploadDocument.path = null;
            uploadDocument.uploadStatus = UploadStatus.NOT_INITIATED;
          });
          return;
        default:
          return;
      }
    }

    String resolveSubtitle() {
      switch (uploadDocument.uploadStatus) {
        case UploadStatus.NOT_INITIATED:
          return 'Tap to select file';
        case UploadStatus.SELECTED:
          return path!.split(Platform.pathSeparator).last;
        case UploadStatus.QUEUED:
          return 'Upload Queued';
        case UploadStatus.DECRYPTING:
          return 'Decrypting...';
        case UploadStatus.RESOLVE_FOLDER_ID:
          return 'Resolving Folder ID...';
        case UploadStatus.UPLOADING:
          return 'Uploading...';
        case UploadStatus.SUCCESS:
          return 'Uploaded Successfully';
        case UploadStatus.FAILURE:
          return 'Upload Failed';
      }
    }

    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(uploadDocument.icon,
            color: isSelected
                ? Colors.green
                : Theme.of(context).colorScheme.primary),
        title: Text(uploadDocument.title,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          resolveSubtitle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: uploadDocument.uploadStatus.icon,
        onTap: resolveOnTapHandler,
      ),
    );
  }

  Widget _getJsonWidget(String jsonString) => Flexible(
        flex: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
          ),
          child: JsonConfig(
              data: JsonConfigData(
                  animation: true,
                  animationDuration: const Duration(milliseconds: 300),
                  animationCurve: Curves.ease,
                  itemPadding: const EdgeInsets.only(left: 8),
                  color: JsonColorScheme(
                    stringColor: Theme.of(context).colorScheme.primary,
                    numColor: Theme.of(context).colorScheme.tertiary,
                    boolColor: Theme.of(context).colorScheme.error,
                  ),
                  style: const JsonStyleScheme(
                    arrow: Icon(Icons.arrow_right, size: 16),
                  )),
              child: JsonView(json: jsonDecode(jsonString))),
        ),
      );

  bool _isTriggerAutomationButtonDisabled() {
    return (_isLoading ||
            (_csvFilePath == '' && _spreadSheetUrlController.text.isEmpty)) &&
        !_isDocumentUploadPending();
  }

  bool _isDocumentUploadPending() {
    for (final UploadDocument document in documentsToUpload) {
      if (document.path != null) {
        return true;
      }
    }
    return false;
  }

  bool get _isLoading {
    if (_isUploadingCSVToCreateSheet || _isRunningAppsScriptAutomation) {
      return true;
    }
    for (final UploadDocument document in documentsToUpload) {
      if (document.uploadStatus == UploadStatus.QUEUED ||
          document.uploadStatus == UploadStatus.RESOLVE_FOLDER_ID ||
          document.uploadStatus == UploadStatus.UPLOADING) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trigger Automation Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Automation Trigger',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _pickCSVFile,
                    icon: const Icon(Icons.table_view),
                    label: const Text('Select CSV File'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  if (_csvFilePath.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Selected: ${_csvFilePath.split(Platform.pathSeparator).last}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  CustomTextField(
                      hintText: 'Enter Sheets URL',
                      controller: _spreadSheetUrlController),
                  const SizedBox(height: 8),
                  Text(
                    "Sheets ID: ${UrlUtils.extractSheetsId(_spreadSheetUrlController.text)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isUploadingCSVToCreateSheet)
                    const Text("Creating sheet by uploading CSV file..."),
                  if (_isRunningAppsScriptAutomation)
                    const Text("Parsing data using EANW automation..."),
                  ...documentsToUpload
                      .where((doc) => doc.uploadStatus == UploadStatus.QUEUED)
                      .map((doc) => Text("Queued ${doc.title}...")),
                  ...documentsToUpload
                      .where(
                          (doc) => doc.uploadStatus == UploadStatus.DECRYPTING)
                      .map((doc) => Text(
                          "Decrypting document to simple PDF: ${doc.title}...")),
                  ...documentsToUpload
                      .where((doc) =>
                          doc.uploadStatus == UploadStatus.RESOLVE_FOLDER_ID)
                      .map((doc) =>
                          Text("Resolving folder id for ${doc.title}...")),
                  ...documentsToUpload
                      .where(
                          (doc) => doc.uploadStatus == UploadStatus.UPLOADING)
                      .map((doc) => Text("Uploading ${doc.title}...")),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Documents',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...documentsToUpload
                      .map((uploadDocument) => Column(
                            children: [
                              const SizedBox(height: 8),
                              _buildFileUploadCard(uploadDocument),
                            ],
                          ))
                      .toList(),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isTriggerAutomationButtonDisabled()
                        ? null
                        : _triggerAutomationButtonHandler,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                        (_createSpreadSheetByUploadingCSVFileResponse == '{}')
                            ? 'Trigger Automation'
                            : 'ReRun Script'),
                  ),
                ],
              ),
            ),
          ),

          // Results Section
          if (_createSpreadSheetByUploadingCSVFileResponse != '{}' ||
              _appsScriptResponse != '{}')
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_createSpreadSheetByUploadingCSVFileResponse != '{}') ...[
                  Text("Spreadsheet Response:",
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(
                      height: 150,
                      child: _getJsonWidget(
                          _createSpreadSheetByUploadingCSVFileResponse)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _launchSheet(),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Sheet'),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_appsScriptResponse != '{}') ...[
                  Text("Apps Script Response:",
                      style: Theme.of(context).textTheme.labelLarge),
                  SizedBox(
                      height: 200,
                      child: _getJsonWidget(_appsScriptResponse ?? "{}")),
                ],
                if (_unprocessedTransactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pushNamed(
                            UnprocessedTransactionsPage.routeName,
                            arguments: _unprocessedTransactions.sublist(1)),
                        child: Text(
                            "View Unprocessed Transactions (${_unprocessedTransactions.length})")),
                  ),
              ],
            )
        ],
      ),
    );
  }
}
