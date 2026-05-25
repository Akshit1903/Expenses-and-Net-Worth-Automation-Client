import 'dart:io';

import 'package:expense_and_net_worth_automation/src/features/eanw_script/automation_trigger_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/home/unprocessed_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/utils/custom_text_field.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:expense_and_net_worth_automation/src/utils/transform_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Automation trigger card extracted from the old expenses page.
///
/// Shows CSV picker, Sheets URL field, and trigger button.
/// When [highlight] is true (workingEANW not uploaded),
/// an animated border draws attention to this card.
class AutomationTriggerCard extends StatefulWidget {
  final AutomationTriggerViewModel viewModel;
  final bool highlight;

  const AutomationTriggerCard({
    super.key,
    required this.viewModel,
    this.highlight = false,
  });

  @override
  State<AutomationTriggerCard> createState() => _AutomationTriggerCardState();
}

class _AutomationTriggerCardState extends State<AutomationTriggerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Pulsing glow animation for highlight mode
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (widget.highlight) _glowController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AutomationTriggerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlight && !_glowController.isAnimating) {
      _glowController.repeat(reverse: true);
    } else if (!widget.highlight && _glowController.isAnimating) {
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Card(
          elevation: widget.highlight ? 2 + (_glowAnimation.value * 4) : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: widget.highlight
                ? BorderSide(
                    color: theme.colorScheme.primary
                        .withValues(alpha: 0.3 + _glowAnimation.value * 0.5),
                    width: 2,
                  )
                : BorderSide.none,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Automation Trigger', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            // CSV file picker
            ElevatedButton.icon(
              onPressed: vm.isLoading ? null : vm.pickCSVFile,
              icon: const Icon(Icons.table_view),
              label: const Text('Select CSV File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (vm.csvFilePath.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Selected: ${vm.csvFilePath.split(Platform.pathSeparator).last}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),

            // Sheets URL field
            CustomTextField(
              hintText: 'Enter Sheets URL',
              controller: vm.spreadSheetUrlController,
            ),
            const SizedBox(height: 8),
            Text(
              'Sheets ID: ${TransformUtils.extractSheetsId(vm.spreadSheetUrlController.text)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Loading indicators
            if (vm.isLoading) const LinearProgressIndicator(),
            if (vm.isUploadingCSV)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Creating sheet from CSV...'),
              ),
            if (vm.isRunningScript)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Running EANW automation...'),
              ),

            const SizedBox(height: 16),

            // Trigger button
            FilledButton(
              onPressed: vm.canTrigger
                  ? () async {
                      try {
                        await vm.triggerAutomation();
                        if (mounted) {
                          SnackbarService.showSnackBar(
                              'Automation triggered successfully!', context);
                        }
                      } catch (e) {
                        if (mounted) {
                          SnackbarService.showSnackBar('Error: $e', context);
                        }
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Trigger Automation'),
            ),

            // Open sheet button
            if (vm.spreadSheetUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _launchSheet(vm.spreadSheetUrlController.text),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open Sheet'),
              ),
            ],

            // Unprocessed transactions button
            if (vm.unprocessedTransactions.isNotEmpty) ...[
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pushNamed(
                  UnprocessedTransactionsPage.routeName,
                  arguments: vm.unprocessedTransactions.length > 1
                      ? vm.unprocessedTransactions.sublist(1)
                      : vm.unprocessedTransactions,
                ),
                child: Text(
                  'View Unprocessed Transactions '
                  '(${vm.unprocessedTransactions.length})',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _launchSheet(String urlText) async {
    if (!TransformUtils.isValidGoogleSheetsUrl(urlText)) {
      SnackbarService.showSnackBar(
          'Invalid URL. Only HTTPS Google URLs are allowed.', context);
      return;
    }
    final url = Uri.parse(urlText);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        SnackbarService.showSnackBar('Could not open the sheet', context);
      }
    }
  }
}
