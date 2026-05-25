import 'package:expense_and_net_worth_automation/src/features/journey/step_registry.dart';
import 'package:expense_and_net_worth_automation/src/features/summary/summary_view.dart';
import 'package:expense_and_net_worth_automation/src/providers/journey_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Action tab: renders the current in-progress step's view,
/// or the journey summary when complete.
///
/// Per user requirement:
/// - When journey is complete: shows "Journey Complete" immediately
///   while summary data loads in the background.
/// - When a step is in progress: renders that step's view (embedded).
class ActionTab extends StatelessWidget {
  const ActionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final journeyProvider = context.watch<JourneyProvider>();

    // Loading state — no data yet
    if (journeyProvider.isLoading && journeyProvider.journey == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error with no data
    if (journeyProvider.error != null && journeyProvider.journey == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Failed to load journey',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: journeyProvider.fetchJourney,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Journey complete → show summary
    if (journeyProvider.isJourneyComplete) {
      return const SummaryView();
    }

    // Render the in-progress step
    final inProgressStep = journeyProvider.inProgressStep;
    if (inProgressStep != null) {
      final view = StepRegistry.getViewForStep(inProgressStep);
      if (view != null) return view;
    }

    // Fallback: no step found (shouldn't happen with valid API data)
    return const Center(
      child: Text('No view matched for current step! Error in StepRegistry?'),
    );
  }
}
