import 'dart:async';
import 'dart:convert';

import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/clients/google_workspace_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transaction_repository.dart';
import 'package:expense_and_net_worth_automation/src/services/prefs_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// ViewModel for the Automation Trigger card.
///
/// Handles CSV file selection, spreadsheet creation, and Apps Script
class AutomationTriggerViewModel extends ChangeNotifier {
  final VoidCallback onComplete;

  final GoogleWorkspaceClient _workspaceClient = getIt<GoogleWorkspaceClient>();
  final EanwAppsScriptsClient _eanwClient = getIt<EanwAppsScriptsClient>();
  final ExternalTransactionRepository _externalTxnRepository =
      getIt<ExternalTransactionRepository>();
  final PrefsService _prefsService = getIt<PrefsService>();

  final TextEditingController spreadSheetUrlController =
      TextEditingController();

  String csvFilePath = '';
  bool isUploadingCSV = false;
  bool isRunningScript = false;
  String? appsScriptResponse;
  List<List<String>> unprocessedTransactions = [];

  StreamSubscription? _intentSub;

  AutomationTriggerViewModel({required this.onComplete}) {
    spreadSheetUrlController.addListener(notifyListeners);
    spreadSheetUrlController.addListener(_onWorkingEANWUrlChanged);

    final cachedId = _prefsService.getWorkingEANWSheetsId();
    if (cachedId != null && cachedId.isNotEmpty) {
      spreadSheetUrlController.text =
          TransformUtils.getGoogleSheetsUrl(cachedId);
    }

    // Listen for shared CSV files from other apps
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.length == 1 && value[0].path.split('.').last == 'csv') {
        csvFilePath = value[0].path;
        notifyListeners();
      }
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.length == 1 && value[0].path.split('.').last == 'csv') {
        csvFilePath = value[0].path;
        notifyListeners();
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _onWorkingEANWUrlChanged() {
    final text = spreadSheetUrlController.text;
    final sheetId = TransformUtils.extractSheetsId(text);
    if (sheetId.isNotEmpty) {
      _prefsService.setWorkingEANWSheetsId(sheetId);
    } else if (text.isEmpty) {
      _prefsService.removeWorkingEANWSheetsId();
    }
  }

  bool get isLoading => isUploadingCSV || isRunningScript;

  bool get canTrigger =>
      !isLoading &&
      (csvFilePath.isNotEmpty || spreadSheetUrlController.text.isNotEmpty);

  /// Opens file picker for CSV files.
  Future<void> pickCSVFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null) return;
    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.csv')) return;
    csvFilePath = path;
    notifyListeners();
  }

  /// Main automation flow: upload CSV → create sheet → run script.
  Future<void> triggerAutomation() async {
    try {
      // Step 1: If no URL but CSV exists, upload CSV to create sheet
      if (spreadSheetUrlController.text.isEmpty && csvFilePath.isNotEmpty) {
        isUploadingCSV = true;
        notifyListeners();
        final response = await _workspaceClient
            .createSpreadSheetByUploadingCSVFile(csvFilePath);
        final sheetId = jsonDecode(response)['id'] as String;
        spreadSheetUrlController.text =
            TransformUtils.getGoogleSheetsUrl(sheetId);
        isUploadingCSV = false;
        notifyListeners();
      }

      // Step 2: Trigger the automation script
      if (spreadSheetUrlController.text.isNotEmpty) {
        await Clipboard.setData(
            ClipboardData(text: spreadSheetUrlController.text));
        final sheetId =
            TransformUtils.extractSheetsId(spreadSheetUrlController.text);

        isRunningScript = true;
        notifyListeners();

        // Load external transactions from local storage
        final txs = _externalTxnRepository.loadFromPrefs();
        Map<String, dynamic> externalMeta = {
          'externalTransactions':
              txs.map((t) => t.toAppsScriptFormat()).toList(),
        };

        final result =
            await _eanwClient.triggerExpenseAndNetWorthAutomationAppsScript(
                sheetId, externalMeta);

        if (result.isSuccess && result.data != null) {
          appsScriptResponse = result.data;
          unprocessedTransactions = _parseUnprocessed(result.data!);
        } else {
          throw Exception(
              result.errorMessage ?? 'Unknown error from Apps Script');
        }

        isRunningScript = false;
        notifyListeners();
        onComplete();
      }
    } catch (e) {
      isUploadingCSV = false;
      isRunningScript = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Parses unprocessed transactions from the script response.
  List<List<String>> _parseUnprocessed(String responseData) {
    try {
      final json = jsonDecode(responseData);
      final rows = json['unprocessedTransactions'] as List?;
      if (rows == null) return [];
      return rows
          .map<List<String>>((r) => (r as List)
              .map<String>((i) => i == null ? '' : i.toString())
              .toList())
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    spreadSheetUrlController.removeListener(_onWorkingEANWUrlChanged);
    spreadSheetUrlController.removeListener(notifyListeners);
    spreadSheetUrlController.dispose();
    super.dispose();
  }
}
