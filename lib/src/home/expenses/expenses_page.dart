import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expense_and_net_worth_automation/src/clients/gcp_client.dart';
import 'package:expense_and_net_worth_automation/src/home/expenses/document_upload.dart';
import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:expense_and_net_worth_automation/src/utils/upload_status.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_view/json_view.dart';
import 'package:provider/provider.dart';
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
  String _appsScriptResponse = '{}';
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

  TextEditingController _spreadSheetUrlController = TextEditingController();
  late GcpClient _gcpClient;
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();
    _spreadSheetUrlController.addListener(() {
      setState(() {});
    });

    // Intent handling (kept from original)
    void _setFilePath(List<SharedMediaFile> value) {
      if (value.length == 1 && value[0].path.split('.').last == 'csv') {
        setState(() {
          _csvFilePath = value[0].path;
        });
      }
    }

    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _setFilePath(value);
      Future.delayed(Duration(milliseconds: 0)).then((value) {
        // Need to check if can pop, or just handle it.
        // In the original code it popped, assuming it was a modal or pushed page.
        // Since this is now a tab, we probably shouldn't pop the whole app.
        // leaving as is for now but might need adjustment if this was intended to close a dialog.
      });
    }, onError: (err) {
      Utils.snackbar(context, "getIntentDataStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _setFilePath(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getGcpClientAndSetAppsScriptUrl();
  }

  @override
  void dispose() {
    _intentSub.cancel();
    _spreadSheetUrlController.dispose();
    super.dispose();
  }

  Future<void> _getGcpClientAndSetAppsScriptUrl() async {
    _gcpClient = GcpClient(context.read<AuthProvider>());
    String? appsScriptUrl = await _gcpClient.getAppsScriptClientUrl(context);
    if (appsScriptUrl != null &&
        Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI.isEmpty) {
      if (mounted) {
        setState(() {
          Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI = appsScriptUrl;
        });
      }
    }
  }

  List<List<String>> _getUnprocessedTransactions(
      String unprocessedTransactionsResponse) {
    final jsonResponse = jsonDecode(unprocessedTransactionsResponse);
    return (jsonResponse['unprocessedTransactions'] as List)
        .map<List<String>>((row) =>
            (row as List).map<String>((item) => item.toString()).toList())
        .toList();
  }

  Future<void> _triggerAutomationButtonHandler() async {
    try {
      if (_spreadSheetUrlController.text.isEmpty && !_csvFilePath.isEmpty) {
        setState(() {
          _isUploadingCSVToCreateSheet = true;
        });
        String response =
            await _gcpClient.createSpreadSheetByUploadingCSVFile(_csvFilePath);
        setState(() {
          _createSpreadSheetByUploadingCSVFileResponse = response;
          String spreadSheetId =
              jsonDecode(_createSpreadSheetByUploadingCSVFileResponse)['id'];
          _spreadSheetUrlController.text =
              Utils.getGoogleSheetsUrl(spreadSheetId);
          _isUploadingCSVToCreateSheet = false;
        });
      }
      if (!_spreadSheetUrlController.text.isEmpty) {
        await Clipboard.setData(
            ClipboardData(text: _spreadSheetUrlController.text));
        String spreadSheetId =
            Utils.extractSheetsId(_spreadSheetUrlController.text);

        setState(() {
          _isRunningAppsScriptAutomation = true;
        });
        String response = await _gcpClient
            .triggerExpenseAndNetWorthAutomationAppsScript(spreadSheetId);
        setState(() {
          _appsScriptResponse = response;
          _unprocessedTransactions = _getUnprocessedTransactions(
              jsonDecode(_appsScriptResponse)['response']['result']);
          _isRunningAppsScriptAutomation = false;
        });
      }

      for (final UploadDocument document in documentsToUpload) {
        if (document.path != null) {
          setState(() {
            document.uploadStatus = UploadStatus.QUEUED;
          });
        }
      }

      for (final UploadDocument document in documentsToUpload) {
        if (document.path != null) {
          // Check for Zip file
          setState(() {
            document.uploadStatus = UploadStatus.DECRYPTING;
          });
          if (document.path!.toLowerCase().endsWith('.zip')) {
            try {
              // Try to extract without password first
              final String extractedPdfPath =
                  await Utils.extractPdfFromZip(document.path!);
              document.path = extractedPdfPath;
            } catch (e) {
              // If failed, assume it needs password
              try {
                String? password =
                    await _gcpClient.getDocumentPassword(document.id, context);
                if (password == null || password.isEmpty) {
                  throw 'Password not found for zip';
                }
                document.path = await Utils.extractPdfFromZip(document.path!,
                    password: password);
              } catch (e) {
                Utils.snackbar(context,
                    'Failed to extract PDF from Zip for ${document.title}: $e');
                setState(() {
                  document.uploadStatus = UploadStatus.FAILURE;
                });
                continue;
              }
            }
          } else if (document.path!.toLowerCase().endsWith('.pdf') &&
              await Utils.isPdfEncrypted(document.path!)) {
            try {
              String? password =
                  await _gcpClient.getDocumentPassword(document.id, context);
              if (password == null || password.isEmpty) {
                throw 'Password not found';
              }
              document.path =
                  await Utils.getDecryptedPdf(document.path!, password);
            } catch (e) {
              Utils.snackbar(
                  context, 'Failed to decrypt PDF for ${document.title}: $e');
              setState(() {
                document.uploadStatus = UploadStatus.FAILURE;
              });
              continue;
            }
          }

          setState(() {
            document.uploadStatus = UploadStatus.RESOLVE_FOLDER_ID;
          });
          String? folderId =
              await _gcpClient.getDocumentFolderId(document.id, context);
          if (folderId == null) {
            setState(() {
              document.uploadStatus = UploadStatus.FAILURE;
            });
            Utils.snackbar(
                context, 'Folder ID not found for ${document.title}');
            continue;
          }
          setState(() {
            document.uploadStatus = UploadStatus.UPLOADING;
          });
          final now = DateTime.now();
          final oneMonthAgo = DateTime(
            now.year,
            now.month - 1,
            now.day,
          );
          document.uploadedFileId = await _gcpClient.uploadDocument(
              path: document.path.toString(),
              fileName: "${oneMonthAgo.year}-${oneMonthAgo.month}.pdf",
              folderId: folderId,
              context: context);
          setState(() {
            if (document.uploadedFileId == null) {
              document.uploadStatus = UploadStatus.FAILURE;
            } else {
              document.uploadStatus = UploadStatus.SUCCESS;
            }
          });
        }
      }
    } catch (e) {
      Utils.snackbar(context, 'Error: ${e.toString()}');
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
        Utils.snackbar(context, 'Invalid file type');
        return;
      }
      setState(() {
        _csvFilePath = filePath;
      });
    } else {
      Utils.snackbar(context, 'No file selected');
    }
  }

  Future<void> _pickDocument(UploadDocument document) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) {
      if (mounted) {
        Utils.snackbar(context, 'No file selected for ${document.title}');
      }
      return;
    }
    setState(() {
      document.path = result.files.single.path;
      document.uploadStatus = UploadStatus.SELECTED;
    });
  }

  Future<void> _launchSheet() async {
    Uri url = Uri.parse(_spreadSheetUrlController.text);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Utils.snackbar(context, 'Could not open the sheet');
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
              Utils.resolveDriveFileUrl(uploadDocument.uploadedFileId);
          await Clipboard.setData(ClipboardData(text: fileIdUrl));
          Utils.snackbar(context, 'Drive file URL copied: $fileIdUrl');
        case UploadStatus.NOT_INITIATED || UploadStatus.FAILURE:
          _pickDocument(uploadDocument);
          return;
        case UploadStatus.SELECTED:
          setState(() {
            uploadDocument.path = null;
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
    return (Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI.isEmpty ||
            _isLoading ||
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
                    onPressed: Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI.isEmpty
                        ? null
                        : _pickCSVFile,
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
                    "Sheets ID: ${Utils.extractSheetsId(_spreadSheetUrlController.text)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: LinearProgressIndicator(),
                    ),
                  if (_isUploadingCSVToCreateSheet)
                    Text("Creating sheet by uploading CSV file..."),
                  if (_isRunningAppsScriptAutomation)
                    Text("Parsing data using EANW automation..."),
                  ...documentsToUpload
                      .where((doc) => doc.uploadStatus == UploadStatus.QUEUED)
                      .map((doc) => Text("Queued ${doc.title}...")),
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
                  Container(
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
                  Container(
                      height: 200, child: _getJsonWidget(_appsScriptResponse)),
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
