import 'package:flutter/material.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';

class VarsConfig extends StatefulWidget {
  const VarsConfig({super.key});

  @override
  State<VarsConfig> createState() => _VarsConfigState();
}

class _VarsConfigState extends State<VarsConfig> {
  final TextEditingController _googleAppsScriptUrlController =
      TextEditingController(text: Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI);

  @override
  void dispose() {
    _googleAppsScriptUrlController.dispose();
    super.dispose();
  }

  bool _isSaveButtonEnabled() {
    return Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI !=
        _googleAppsScriptUrlController.text;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool shouldPop = (!_isSaveButtonEnabled()) ||
            (await Utils.showBackDialog(context) ?? false);
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Google Apps Script URL",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Enter Google Apps Script URL',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
            ),
            controller: _googleAppsScriptUrlController,
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaveButtonEnabled()
                ? () async {
                    await Utils.prefs.setString(
                        Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI_PREFS_KEY,
                        _googleAppsScriptUrlController.text);
                    setState(() {
                      Utils.EANW_AUTOMATION_APPS_SCRIPTS_URI =
                          _googleAppsScriptUrlController.text;

                      Utils.snackbar(context, "Script URL Updated");
                    });
                  }
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
