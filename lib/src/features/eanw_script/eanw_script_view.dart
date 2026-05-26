import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/automation_trigger_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/eanw_script_viewmodel.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/automation_trigger_card.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/eanw_details_view.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/submit_section.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/validation_section.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transaction_repository.dart';
import 'package:expense_and_net_worth_automation/src/features/external_transactions/external_transactions_page.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:expense_and_net_worth_automation/src/utils/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main view for the EANW Script journey step.
class EanwScriptView extends StatefulWidget {
  final JourneyStep step;
  final bool embedded;

  const EanwScriptView({
    super.key,
    required this.step,
    this.embedded = false,
  });

  @override
  State<EanwScriptView> createState() => _EanwScriptViewState();
}

class _EanwScriptViewState extends State<EanwScriptView> {
  final ExternalTransactionRepository _externalTxnRepository =
      getIt<ExternalTransactionRepository>();
  late final EanwScriptViewModel _viewModel;
  late final AutomationTriggerViewModel _triggerViewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = EanwScriptViewModel(step: widget.step);
    _triggerViewModel = AutomationTriggerViewModel(
      onComplete: () {
        context.read<JourneyProvider>().fetchJourney();
      },
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _triggerViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => ListenableBuilder(
        listenable: _triggerViewModel,
        builder: (context, _) => _buildBody(context),
      ),
    );

    if (widget.embedded) return body;

    return Scaffold(
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final vr = _viewModel.validationResponse;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error banner for fetching working details
          if (_viewModel.workingDetailsError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MaterialBanner(
                  backgroundColor: theme.colorScheme.errorContainer,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  content: Text(
                    _viewModel.workingDetailsError!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => _viewModel.fetchWorkingEANWDetails(),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 1. Validation status banner
          if (vr != null) _buildValidationBanner(theme, vr.isSuccess),

          // 2. Failed validations (open by default)
          if (vr != null && vr.failedValidations.isNotEmpty)
            ValidationSection(
              title: 'Failed Validations',
              validations: vr.failedValidations,
              initiallyExpanded: true,
            ),

          // 3. Passed validations (closed by default)
          if (vr != null && vr.passedValidations.isNotEmpty)
            ValidationSection(
              title: 'Passed Validations',
              validations: vr.passedValidations,
              initiallyExpanded: false,
            ),

          const SizedBox(height: 8),

          // 4. Manage External Transactions button
          _buildManageExternalTransactionsButton(context),

          const SizedBox(height: 8),

          // 5. Automation Trigger card (highlighted when working EANW not uploaded)
          AutomationTriggerCard(
            viewModel: _triggerViewModel,
            highlight: !_viewModel.workingEANWUploaded,
          ),

          const SizedBox(height: 8),

          // 6. View Working EANW button
          if (_viewModel.workingEANWUploaded) _buildWorkingEanwButton(context),

          const SizedBox(height: 4),

          // 7. Submit section
          SubmitSection(
            isEnabled: _viewModel.allValidationsPassed,
            onSubmitComplete: () {
              context.read<JourneyProvider>().fetchJourney();
              _externalTxnRepository.clear();
              if (mounted) {
                SnackbarService.showSnackBar(
                    'Successfully submitted!', context);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Green/red banner showing overall validation status.
  Widget _buildValidationBanner(ThemeData theme, bool isSuccess) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSuccess
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            isSuccess ? 'All validations passed' : 'Some validations failed',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Button to view working EANW details — fetches on tap.
  Widget _buildWorkingEanwButton(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: const Text('View Working EANW'),
        subtitle: const Text('Tap to see financial breakdown'),
        trailing: _viewModel.isLoadingWorkingDetails
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _viewModel.isLoadingWorkingDetails
            ? null
            : () async {
                await _viewModel.fetchWorkingEANWDetails();
                if (_viewModel.workingEanwDetails != null && mounted) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EanwDetailsView(
                      title: 'Working EANW',
                      details: _viewModel.workingEanwDetails!,
                    ),
                  ));
                } else if (_viewModel.workingDetailsError != null && mounted) {
                  SnackbarService.showSnackBar(
                      _viewModel.workingDetailsError!, context);
                }
              },
      ),
    );
  }

  /// Button to manage external transactions.
  Widget _buildManageExternalTransactionsButton(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
        title: const Text('Manage External Transactions'),
        subtitle: const Text('Non-axio transactions'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pushNamed(ExternalTransactionsPage.routeName);
        },
      ),
    );
  }
}
