import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/eanw_section_card.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:flutter/material.dart';

/// Full-page view showing EANW financial details beautifully.
///
/// Used for both Working EANW and Main EANW display.
/// Shows growth + total expenses as highlight cards at the top,
/// followed by each financial section.
class EanwDetailsView extends StatelessWidget {
  final String title;
  final EanwDetails details;

  const EanwDetailsView({
    super.key,
    required this.title,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Highlight cards: Growth and Total Expenses
            Row(
              children: [
                Expanded(
                  child: _HighlightCard(
                    label: 'Growth',
                    value: '₹${details.growth}',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HighlightCard(
                    label: 'Total Expenses',
                    value: '₹${details.totalExpenses}',
                    icon: Icons.trending_down,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // All financial sections
            ...details.allSections.map((entry) => EanwSectionCard(
                  title: entry.key,
                  section: entry.value,
                )),
          ],
        ),
      ),
    );
  }
}

/// A compact highlight card for key metrics.
class _HighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HighlightCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(label,
                style: Theme.of(context).textTheme.bodySmall),
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
