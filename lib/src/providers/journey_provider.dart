import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:flutter/material.dart';

/// Central state management for the finance journey.
///
/// Fetched at:
/// - App startup (after auth)
/// - After user completes an action
/// - Manual refresh from journey tab
class JourneyProvider extends ChangeNotifier {
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();

  Journey? _journey;
  bool _isLoading = false;
  String? _error;

  Journey? get journey => _journey;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// The single in-progress step (guaranteed at most one).
  JourneyStep? get inProgressStep => _journey?.inProgressStep;

  /// Whether the entire journey is complete.
  bool get isJourneyComplete => _journey?.complete ?? false;

  /// All steps in the journey.
  List<JourneyStep> get steps => _journey?.steps ?? [];

  /// Fetches the latest journey state from the backend.
  Future<void> fetchJourney() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _homeServerClient.getJourney();
      _journey = Journey.fromJson(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
