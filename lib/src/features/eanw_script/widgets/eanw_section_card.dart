import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:flutter/material.dart';

/// Renders a single EanwSection (e.g., Income, Expenses) as a card.
///
/// Shows section title with total prominently, then lists all
/// split entries with name and ₹ formatted value.
class EanwSectionCard extends StatelessWidget {
  final String title;
  final EanwSection section;

  const EanwSectionCard({
    super.key,
    required this.title,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = section.split.entries.toList();

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
            // Section header with total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '₹${section.total}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const Divider(height: 24),
              // Split entries
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(e.key,
                              style: theme.textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(
                          '₹${e.value}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            // Negative values in red
                            color: e.value.startsWith('-')
                                ? theme.colorScheme.error
                                : null,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
