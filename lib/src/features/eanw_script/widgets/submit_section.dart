import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:flutter/material.dart';

/// Submit section that runs two parallel operations with loading indicators.
///
/// Executes copyEANWToMainSheet and overwriteNetWorthAndUpdateEANWFinanceLog
/// in parallel, showing a loading/complete indicator for each.
class SubmitSection extends StatefulWidget {
  /// Whether the submit button should be enabled (all validations passed).
  final bool isEnabled;

  /// Called after both operations complete successfully.
  final VoidCallback onSubmitComplete;

  const SubmitSection({
    super.key,
    required this.isEnabled,
    required this.onSubmitComplete,
  });

  @override
  State<SubmitSection> createState() => _SubmitSectionState();
}

class _SubmitSectionState extends State<SubmitSection> {
  final EanwAppsScriptsClient _client = getIt<EanwAppsScriptsClient>();

  bool _isSubmitting = false;
  bool _copyComplete = false;
  bool _financeLogComplete = false;
  String? _error;

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _copyComplete = false;
      _financeLogComplete = false;
      _error = null;
    });

    try {
      // Run both operations in parallel
      await Future.wait([
        _client.copyEANWToMainSheet().then((result) {
          if (!result.isSuccess) throw result.errorMessage ?? 'Copy failed';
          setState(() => _copyComplete = true);
        }),
        _client.overwriteNetWorthAndUpdateEANWFinanceLog().then((result) {
          if (!result.isSuccess) throw result.errorMessage ?? 'Update failed';
          setState(() => _financeLogComplete = true);
        }),
      ]);

      // Both succeeded → notify parent
      widget.onSubmitComplete();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Commit Expenses and Net Worth ',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            // Operation status rows (shown during/after submission)
            if (_isSubmitting || _copyComplete || _financeLogComplete) ...[
              _OperationRow(
                title: 'Copying to Main Sheet',
                isComplete: _copyComplete,
                isInProgress: _isSubmitting && !_copyComplete,
              ),
              const SizedBox(height: 8),
              _OperationRow(
                title: 'Overwriting Net Worth and Updating Finance Log',
                isComplete: _financeLogComplete,
                isInProgress: _isSubmitting && !_financeLogComplete,
              ),
              const SizedBox(height: 16),
            ],

            // Error display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),

            // Submit button
            FilledButton.icon(
              onPressed:
                  (widget.isEnabled && !_isSubmitting) ? _handleSubmit : null,
              icon: const Icon(Icons.publish),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single row showing an operation's loading/complete state.
class _OperationRow extends StatelessWidget {
  final String title;
  final bool isComplete;
  final bool isInProgress;

  const _OperationRow({
    required this.title,
    required this.isComplete,
    required this.isInProgress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey('$title-$isComplete'),
        children: [
          if (isInProgress)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isComplete)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              title,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
