import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter/services.dart';

import 'package:expense_and_net_worth_automation/src/clients/gcp_client.dart';
import 'package:json_view/json_view.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class AutomationTrigger extends StatefulWidget {
  const AutomationTrigger({super.key});

  @override
  State<AutomationTrigger> createState() => _AutomationTriggerState();
}

List<List<String>> _getUnprocessedTransactions(String unprocessedTransactions) {
  return unprocessedTransactions
      .split('#?@#')
      .map((e) => e.split('@-@'))
      .toList();
}

class _AutomationTriggerState extends State<AutomationTrigger> {
  bool _isLoading = false;
  String _csvFilePath = '';
  String _createSpreadSheetByUploadingCSVFileResponse = '{}';
  String _appsScriptResponse = '{}';
  List<List<String>> _unprocessedTransactions = [];

  Widget _getJsonWidget(String jsonString) => Flexible(
        flex: 1,
        child: JsonConfig(
            data: JsonConfigData(
                animation: true,
                animationDuration: Duration(milliseconds: 300),
                animationCurve: Curves.ease,
                itemPadding: const EdgeInsets.only(left: 8),
                color: const JsonColorScheme(
                  stringColor: Colors.grey,
                ),
                style: const JsonStyleScheme(
                  arrow: const Icon(Icons.arrow_right),
                )),
            child: JsonView(json: jsonDecode(jsonString))),
      );

  TextEditingController _spreadSheetUrlController = TextEditingController();

  late GcpClient _gcpClient;

  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();

    void _setFilePath(List<SharedMediaFile> value) {
      if (value.length == 1 && value[0].path.split('.').last == 'csv') {
        setState(() {
          _csvFilePath = value[0].path;
        });
      }
    }

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      _setFilePath(value);
      Future.delayed(Duration(milliseconds: 0)).then((value) {
        Navigator.of(context).pop();
      });
    }, onError: (err) {
      Utils.snackbar(context, "getIntentDataStream error: $err");
    });
    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      _setFilePath(value);
      ReceiveSharingIntent.instance.reset();
    });

    _spreadSheetUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    _gcpClient = GcpClient(context.read<AuthProvider>());
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  Future<void> _triggerAutomationButtonHandler(String filePath) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_spreadSheetUrlController.text.isEmpty) {
        String response =
            await _gcpClient.createSpreadSheetByUploadingCSVFile(filePath);
        setState(() {
          _createSpreadSheetByUploadingCSVFileResponse = response;
          String spreadSheetId =
              jsonDecode(_createSpreadSheetByUploadingCSVFileResponse)['id'];
          _spreadSheetUrlController.text =
              Utils.getGoogleSheetsUrl(spreadSheetId);
        });
      }
      await Clipboard.setData(
          ClipboardData(text: _spreadSheetUrlController.text));

      String spreadSheetId =
          Utils.extractSheetsId(_spreadSheetUrlController.text);
      String response = await _gcpClient
          .triggerExpenseAndNetWorthAutomationAppsScript(spreadSheetId);
      setState(() {
        _appsScriptResponse = response;
        _unprocessedTransactions = _getUnprocessedTransactions(
            jsonDecode(_appsScriptResponse)['response']['result']);
      });
    } catch (e) {
      Utils.snackbar(context, 'Error: ${e.toString()}');
    }
    setState(() {
      _isLoading = false;
    });
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

  Future<void> _launchSheet() async {
    Uri url = Uri.parse(_spreadSheetUrlController.text);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Utils.snackbar(context, 'Could not open the sheet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI.isEmpty
                  ? null
                  : _pickCSVFile,
              child: const Text('Select CSV File'),
            ),
            Text(_csvFilePath),
            SizedBox(height: 16),
            CustomTextField(
                hintText: 'Enter Sheets URL',
                controller: _spreadSheetUrlController),
            Text(
                "Sheets ID: ${Utils.extractSheetsId(_spreadSheetUrlController.text)}"),
            SizedBox(height: 16),
            if (_isLoading) LinearProgressIndicator(),
            ElevatedButton(
              onPressed: (Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI.isEmpty ||
                      _isLoading ||
                      (_csvFilePath == '' &&
                          _spreadSheetUrlController.text.isEmpty))
                  ? null
                  : () => _triggerAutomationButtonHandler(_csvFilePath),
              child: Text((_createSpreadSheetByUploadingCSVFileResponse == '{}')
                  ? 'Trigger Automation'
                  : 'ReRun Script'),
            ),
            _getJsonWidget(_createSpreadSheetByUploadingCSVFileResponse),
            if (_createSpreadSheetByUploadingCSVFileResponse != '{}')
              ElevatedButton(
                onPressed: () => _launchSheet(),
                child: const Text('Open Sheet'),
              ),
            _getJsonWidget(_appsScriptResponse),
            if (_unprocessedTransactions.length > 0)
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                      UnprocessedTransactionsPage.routeName,
                      arguments: _unprocessedTransactions.sublist(1)),
                  child: Text(
                      "Unprocessed Transactions(${_unprocessedTransactions.length})")),
          ]),
    );
  }
}
