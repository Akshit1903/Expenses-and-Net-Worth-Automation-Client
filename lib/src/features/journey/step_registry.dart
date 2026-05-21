import 'package:expense_and_net_worth_automation/src/features/document_upload/document_upload_view.dart';
import 'package:expense_and_net_worth_automation/src/features/eanw_script/eanw_script_view.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:flutter/material.dart';

/// Configurable mapping from journey step IDs to their view builders.
///
/// To add a new step:
/// 1. Create the step's view widget
/// 2. Add an entry to [_registry] and [_icons]
class StepRegistry {
  /// Maps step ID → widget builder function.
  static final Map<String, Widget Function(JourneyStep)> _registry = {
    'document_upload': (step) => DocumentUploadView(step: step),
    'eanw_script': (step) => EanwScriptView(step: step),
  };

  /// Maps step ID → icon for display in the journey stepper.
  static final Map<String, IconData> _icons = {
    'document_upload': Icons.upload_file,
    'eanw_script': Icons.analytics,
  };

  /// Returns the view widget for a given step, or null if unregistered.
  static Widget? getViewForStep(JourneyStep step) {
    return _registry[step.id]?.call(step);
  }

  /// Returns an appropriate icon for the step.
  static IconData getIconForStep(String id) {
    return _icons[id] ?? Icons.circle_outlined;
  }
}
