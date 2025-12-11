import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:expense_and_net_worth_automation/src/utils/utils.dart';

class VarsConfig extends StatefulWidget {
  const VarsConfig({super.key});

  @override
  State<VarsConfig> createState() => _VarsConfigState();
}

class _VarsConfigState extends State<VarsConfig> {
  final TextEditingController _googleAppsScriptUrlController =
      TextEditingController(text: Utils.STATE_CONFIG_APPS_SCRIPT_URI);

  @override
  void initState() {
    super.initState();

    _googleAppsScriptUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _googleAppsScriptUrlController.dispose();
    super.dispose();
  }

  bool _isSaveButtonEnabled() {
    return Utils.STATE_CONFIG_APPS_SCRIPT_URI !=
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
            "State Config Script URL",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hintText: 'Enter State Config Script URL',
            controller: _googleAppsScriptUrlController,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSaveButtonEnabled()
                ? () async {
                    await Utils.prefs.setString(
                        Utils.STATE_CONFIG_APPS_SCRIPT_URI_PREFS_KEY,
                        _googleAppsScriptUrlController.text);
                    setState(() {
                      Utils.STATE_CONFIG_APPS_SCRIPT_URI =
                          _googleAppsScriptUrlController.text;
                      Utils.snackbar(
                          context, "State Config Script URL Updated");
                    });
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
