import 'package:expense_and_net_worth_automation/src/models/finance_log.dart';
import 'package:flutter/material.dart';

/// Renders a single FinanceLogGroup as a card.
///
/// Shows group name as header, then metrics sorted by value descending.
/// Percentage values are displayed without ₹ prefix.
class FinanceLogCard extends StatelessWidget {
  final FinanceLogGroup group;

  const FinanceLogCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = group.sortedMetrics;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Divider(height: 20),
            ...sorted.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatValue(entry.key, entry.value),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: entry.value.startsWith('-')
                              ? theme.colorScheme.error
                              : null,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// Formats the value: percentages shown as-is, others with ₹ prefix.
  String _formatValue(String key, String value) {
    final isPercentage = key.contains('%') ||
        key.contains('Increase') ||
        key.contains('Growth');
    if (isPercentage) {
      // Try to format as percentage
      final numVal = double.tryParse(value);
      if (numVal != null) return '${(numVal * 100).toStringAsFixed(2)}%';
      return value;
    }
    return '₹$value';
  }
}
