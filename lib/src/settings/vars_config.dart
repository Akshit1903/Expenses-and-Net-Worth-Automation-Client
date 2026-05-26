import 'package:expense_and_net_worth_automation/src/config/apps_script_type.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/hosts_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/material.dart';

class VarsConfig extends StatefulWidget {
  const VarsConfig({super.key});

  @override
  State<VarsConfig> createState() => _VarsConfigState();
}

class _VarsConfigState extends State<VarsConfig> {
  final HostsService _hostsService = getIt<HostsService>();

  final TextEditingController _stateConfigAppsScriptController =
      TextEditingController();
  final TextEditingController _eanwAutomationAppsScriptController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _hostsService
        .getAppsScriptHost(AppsScriptType.eanw)
        .then((eanwAppsScriptURL) {
      _eanwAutomationAppsScriptController.text = eanwAppsScriptURL;
    });
    _hostsService
        .getAppsScriptHost(AppsScriptType.stateConfig)
        .then((stateConfigAppsScriptURL) {
      _stateConfigAppsScriptController.text = stateConfigAppsScriptURL;
    });
  }

  @override
  void dispose() {
    _stateConfigAppsScriptController.dispose();
    _eanwAutomationAppsScriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._buildURLFields(
            "State Config Script URL", _stateConfigAppsScriptController),
        ..._buildURLFields(
            "EANW Script URL", _eanwAutomationAppsScriptController),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _saveURLs();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _hostsService.refreshHosts();
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildURLFields(String title, TextEditingController controller) {
    return [
      Text(
        title,
        style: const TextStyle(fontSize: 18),
      ),
      const SizedBox(height: 16),
      CustomTextField(
        hintText: 'Enter $title',
        controller: controller,
      ),
      const SizedBox(height: 16),
    ];
  }

  Future<void> _saveURLs() async {
    await _hostsService.setAppsScriptHost(
      AppsScriptType.stateConfig,
      _stateConfigAppsScriptController.text,
    );
    await _hostsService.setAppsScriptHost(
      AppsScriptType.eanw,
      _eanwAutomationAppsScriptController.text,
    );
    SnackbarService.showSnackBar("URLs Updated", context);
  }
}
