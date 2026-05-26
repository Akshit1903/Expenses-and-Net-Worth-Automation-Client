import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/eanw_section_card.dart';
import 'package:expense_and_net_worth_automation/src/features/summary/finance_log_card.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:expense_and_net_worth_automation/src/models/finance_log.dart';
import 'package:flutter/material.dart';

/// Summary view shown when the entire journey is complete.
///
/// Fetches main EANW details and latest finance log in parallel.
/// Shows "Journey Complete" while loading, then displays the
/// financial summary with all sections.
class SummaryView extends StatefulWidget {
  const SummaryView({super.key});

  @override
  State<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends State<SummaryView> {
  final EanwAppsScriptsClient _eanwAppsScriptClient =
      getIt<EanwAppsScriptsClient>();

  bool _isLoading = true;
  EanwDetails? _mainEANWDetails;
  FinanceLog? _financeLog;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  /// Fetches EANW details and finance log in parallel.
  Future<void> _fetchSummaryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _eanwAppsScriptClient.getMainEANWDetails(),
        _eanwAppsScriptClient.getLatestFinanceLog(),
      ]);

      final mainEANWResult = results[0];
      final financeLogResult = results[1];

      if (mainEANWResult.isSuccess && mainEANWResult.data != null) {
        _mainEANWDetails = EanwDetails.fromJson(mainEANWResult.data!);
      } else {
        throw mainEANWResult.errorMessage ?? 'Failed to fetch Main EANW Details';
      }

      if (financeLogResult.isSuccess && financeLogResult.data != null) {
        _financeLog = FinanceLog.fromJson(financeLogResult.data!);
      } else {
        throw financeLogResult.errorMessage ?? 'Failed to fetch latest Finance Log';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Journey Complete banner
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Journey Complete',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          // Loading state
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Error state (Premium MaterialBanner)
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MaterialBanner(
                  backgroundColor: theme.colorScheme.errorContainer,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  content: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                  actions: [
                    TextButton(
                      onPressed: _fetchSummaryData,
                      child: Text(
                        'Retry',
                        style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // EANW Details section
          if (_mainEANWDetails != null) ...[
            // Highlight cards
            Row(
              children: [
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    'Growth',
                    '₹${_mainEANWDetails!.growth}',
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildHighlightCard(
                    context,
                    'Total Expenses',
                    '₹${_mainEANWDetails!.totalExpenses}',
                    Icons.trending_down,
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Financial sections
            ..._mainEANWDetails!.allSections.map((entry) => EanwSectionCard(
                  title: entry.key,
                  section: entry.value,
                )),
          ],

          // Finance Log sections
          if (_financeLog != null && !_financeLog!.isEmpty) ...[
            const SizedBox(height: 24),
            Text('Finance Log',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Monthly
            if (_financeLog!.month.isNotEmpty) ...[
              Text('Monthly',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              ..._financeLog!.month
                  .map((g) => FinanceLogCard(financeLogGroup: g)),
            ],

            // Quarterly
            if (_financeLog!.quarter.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Quarterly',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              ..._financeLog!.quarter
                  .map((g) => FinanceLogCard(financeLogGroup: g)),
            ],

            // Yearly
            if (_financeLog!.year.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Yearly',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              ..._financeLog!.year
                  .map((g) => FinanceLogCard(financeLogGroup: g)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
