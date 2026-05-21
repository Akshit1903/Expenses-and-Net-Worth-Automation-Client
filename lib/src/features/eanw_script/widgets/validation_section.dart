import 'package:expense_and_net_worth_automation/src/features/eanw_script/widgets/validation_card.dart';
import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:flutter/material.dart';

/// A collapsible section that shows a list of validation cards.
///
/// Hides itself entirely if the validations list is empty.
/// Shows count in the header (e.g., "Failed Validations (2)").
class ValidationSection extends StatelessWidget {
  final String title;
  final List<Validation> validations;
  final bool initiallyExpanded;

  const ValidationSection({
    super.key,
    required this.title,
    required this.validations,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (validations.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(
          '$title (${validations.length})',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: validations
            .map((v) => ValidationCard(validation: v))
            .toList(),
      ),
    );
  }
}
