import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:flutter/material.dart';

/// Renders a single validation comparison with pass/fail styling.
///
/// Shows the name, both values with their sources, and a colored
/// left border indicating pass (green) or fail (red).
class ValidationCard extends StatelessWidget {
  final Validation validation;

  const ValidationCard({super.key, required this.validation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passed = validation.passed;
    final diff = (validation.valueA - validation.valueB).abs();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: passed
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        // Colored left border indicator
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: passed ? Colors.green : Colors.red,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Pass/fail icon
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed ? Colors.green : Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      validation.name,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    _buildValueRow(
                      theme,
                      validation.sourceA,
                      _formatNumber(validation.valueA),
                    ),
                    _buildValueRow(
                      theme,
                      validation.sourceB,
                      _formatNumber(validation.valueB),
                    ),
                    if (!passed) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Difference: ₹${_formatNumber(diff)} '
                        '(tolerance: ${validation.tolerance})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueRow(ThemeData theme, String source, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(source, style: theme.textTheme.bodySmall),
          Text('₹$value',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatNumber(double value) {
    // Remove trailing zeros for cleaner display
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}
