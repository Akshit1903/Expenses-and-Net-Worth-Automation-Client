import 'dart:async';

import 'package:expense_and_net_worth_automation/src/config/dependency_injection.dart';
import 'package:expense_and_net_worth_automation/src/services/auth_service.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  bool _isSigningIn = false;
  bool _isAuthenticated = false;

  /// ARCH-6 FIX: Store the stream subscription so it can be cancelled
  /// in [dispose] to prevent memory leaks if the provider is ever recreated.
  late final StreamSubscription _userChangedSubscription;

  AuthProvider() : _authService = getIt<AuthService>() {
    _userChangedSubscription = _authService.onUserChanged.listen((account) {
      _isAuthenticated = account != null;
      notifyListeners();
    });
  }

  bool get isAuthenticated => _isAuthenticated;
  bool get isSigningIn => _isSigningIn;

  Future<void> signIn() async {
    _setIsSigningIn(true);
    try {
      await _authService.signIn();
    } finally {
      _setIsSigningIn(false);
    }
  }

  Future<void> signOut() async {
    _setIsSigningIn(true);
    try {
      await _authService.signOut();
    } finally {
      _setIsSigningIn(false);
    }
  }

  Future<void> silentSignIn() async {
    _setIsSigningIn(true);
    try {
      await _authService.silentSignIn();
    } finally {
      _setIsSigningIn(false);
    }
  }

  void _setIsSigningIn(bool value) {
    _isSigningIn = value;
    notifyListeners();
  }

  /// ARCH-6 FIX: Cancel the stream subscription to prevent leaks.
  @override
  void dispose() {
    _userChangedSubscription.cancel();
    super.dispose();
  }
}
