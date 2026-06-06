import 'dart:async';

import 'package:expense_and_net_worth_automation/src/clients/home_server_client.dart';
import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/models/journey.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:flutter/material.dart';

/// Central state management for the finance journey.
///
/// Fetched at:
/// - App startup (after auth)
/// - After user completes an action
/// - Manual refresh from journey tab
class JourneyProvider extends ChangeNotifier {
  final HomeServerClient _homeServerClient = getIt<HomeServerClient>();
  final AuthService _authService = getIt<AuthService>();

  Journey? _journey;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _authSub;

  JourneyProvider() {
    _authSub = _authService.onUserChanged.listen((account) {
      if (account != null) {
        fetchJourney();
      } else {
        _journey = null;
        _error = null;
        notifyListeners();
      }
    });

    _authService.isSignedIn().then((signedIn) {
      if (signedIn) {
        fetchJourney();
      }
    });
  }

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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
