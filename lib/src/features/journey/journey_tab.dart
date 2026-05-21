import 'package:expense_and_net_worth_automation/src/features/journey/step_registry.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Journey tab: stepper-like overview of all journey steps.
///
/// Shows each step's status (completed/in-progress/not started).
/// Pull-to-refresh triggers a journey API refetch.
/// Tapping a step pushes its view via StepRegistry.
class JourneyTab extends StatelessWidget {
  const JourneyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();

    // Loading state (no data yet)
    if (journeyProvider.isLoading && journeyProvider.journey == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (no data)
    if (journeyProvider.error != null && journeyProvider.journey == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load journey',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(journeyProvider.error!,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: journeyProvider.fetchJourney,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final steps = journeyProvider.steps;

    return RefreshIndicator(
      onRefresh: journeyProvider.fetchJourney,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Journey Complete banner
          if (journeyProvider.isJourneyComplete)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Journey Complete',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                ],
              ),
            ),

          // Loading indicator during refresh
          if (journeyProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(),
            ),

          // Step cards
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _StepCard(
              step: step,
              stepNumber: index + 1,
              isLast: index == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

/// A single step card in the journey stepper.
class _StepCard extends StatelessWidget {
  final JourneyStep step;
  final int stepNumber;
  final bool isLast;

  const _StepCard({
    required this.step,
    required this.stepNumber,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNotStarted = step.stepStatus == StepStatus.notStarted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stepper rail: icon + connecting line
          Column(
            children: [
              _buildStatusIcon(theme),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: step.stepStatus == StepStatus.completed
                      ? Colors.green
                      : theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Step content card
          Expanded(
            child: Card(
              elevation: 0,
              color: isNotStarted
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.15)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: step.stepStatus == StepStatus.inProgress
                    ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                    : BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: ListTile(
                enabled: !isNotStarted,
                title: Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isNotStarted ? theme.colorScheme.outline : null,
                  ),
                ),
                subtitle: Text(
                  _statusText,
                  style: TextStyle(
                    color: isNotStarted
                        ? theme.colorScheme.outline
                        : _statusColor,
                    fontSize: 12,
                  ),
                ),
                trailing: isNotStarted
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: isNotStarted ? null : () => _navigateToStep(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (step.stepStatus) {
      case StepStatus.completed:
        return const Icon(Icons.check_circle, color: Colors.green, size: 28);
      case StepStatus.inProgress:
        return Icon(Icons.play_circle_filled,
            color: theme.colorScheme.primary, size: 28);
      case StepStatus.notStarted:
        return Icon(Icons.circle_outlined,
            color: theme.colorScheme.outline, size: 28);
    }
  }

  String get _statusText {
    switch (step.stepStatus) {
      case StepStatus.completed:
        return 'Completed';
      case StepStatus.inProgress:
        return 'In Progress';
      case StepStatus.notStarted:
        return 'Not Started';
    }
  }

  Color get _statusColor {
    switch (step.stepStatus) {
      case StepStatus.completed:
        return Colors.green;
      case StepStatus.inProgress:
        return Colors.amber.shade700;
      case StepStatus.notStarted:
        return Colors.grey;
    }
  }

  void _navigateToStep(BuildContext context) {
    final view = StepRegistry.getViewForStep(step);
    if (view == null) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => view,
    ));
  }
}
