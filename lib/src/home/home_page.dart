import 'package:expense_and_net_worth_automation/src/home/automation_trigger.dart';
import 'package:expense_and_net_worth_automation/src/home/vars_config/vars_config_page.dart';
import 'package:expense_and_net_worth_automation/src/providers/auth_provider.dart';
import 'package:expense_and_net_worth_automation/src/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('EANW Automation'),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.pushNamed(context, VarsConfigPage.routeName);
                setState(() {});
              },
              icon: const Icon(Icons.edit),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, SettingsView.routeName);
              },
              icon: const Icon(Icons.settings),
            ),
            IconButton(
              onPressed: () async {
                await context.read<AuthProvider>().signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: AutomationTrigger());
  }
}
