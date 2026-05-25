import 'package:expense_and_net_worth_automation/src/clients/eanw_apps_scripts_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/eanw_details.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/models/validation.dart';
import 'package:flutter/material.dart';

/// ViewModel for the EANW Script journey step.
///
/// Extracts validation response, working/main EANW upload status
/// from the step context. Manages working EANW details fetching.
class EanwScriptViewModel extends ChangeNotifier {
  final EanwAppsScriptsClient _eanwClient = getIt<EanwAppsScriptsClient>();

  /// Parsed from step context.
  final ValidationResponse? validationResponse;
  final bool workingEANWUploaded;
  final bool mainEANWUploaded;

  /// Fetched on demand when user taps "View Working EANW".
  EanwDetails? workingEanwDetails;
  bool isLoadingWorkingDetails = false;
  String? workingDetailsError;

  EanwScriptViewModel({required JourneyStep step})
      : validationResponse = _parseValidationResponse(step.context),
        workingEANWUploaded =
            step.context['workingEANWUploaded'] as bool? ?? false,
        mainEANWUploaded = step.context['mainEANWUploaded'] as bool? ?? false;

  /// Parses the validationResponse from the step context map.
  static ValidationResponse? _parseValidationResponse(
      Map<String, dynamic> context) {
    final vrJson = context['validationResponse'] as Map<String, dynamic>?;
    if (vrJson == null) return null;
    return ValidationResponse.fromJson(vrJson);
  }

  /// Whether all validations passed (submit button enablement).
  bool get allValidationsPassed => validationResponse?.isSuccess ?? false;

  /// Fetches the working EANW financial details.
  Future<void> fetchWorkingEANWDetails() async {
    isLoadingWorkingDetails = true;
    workingDetailsError = null;
    notifyListeners();

    try {
      final result = await _eanwClient.getWorkingEANWDetails();
      if (result.isSuccess && result.data != null) {
        workingEanwDetails = EanwDetails.fromJson(result.data!);
      } else {
        workingDetailsError = result.errorMessage ?? 'Failed to load details';
      }
    } catch (e) {
      workingDetailsError = e.toString();
    } finally {
      isLoadingWorkingDetails = false;
      notifyListeners();
    }
  }
}
