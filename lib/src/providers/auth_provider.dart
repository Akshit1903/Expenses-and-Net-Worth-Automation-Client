import 'package:expense_and_net_worth_automation/src/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  GoogleSignIn _googleSignIn = Utils.googleSignIn;
  final SharedPreferencesWithCache _prefs = Utils.prefs;

  Future<bool> isAuthenticated() {
    return _googleSignIn.isSignedIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _prefs.remove(Utils.EMAIL);
    notifyListeners();
  }

  Future<void> signIn() async {
    if (_prefs.containsKey(Utils.EMAIL)) {
      await _googleSignIn.signInSilently();
    } else {
      await _googleSignIn.signIn();
      await _prefs.setString(Utils.EMAIL, _googleSignIn.currentUser!.email);
    }
    notifyListeners();
  }

  Future<String?> get getAccessToken async {
    GoogleSignInAccount? googleSignInAccount = await _googleSignIn.currentUser;
    if (googleSignInAccount == null) {
      await signIn();
      googleSignInAccount = await _googleSignIn.currentUser;
    }
    final googleSignInAuthentication =
        await googleSignInAccount!.authentication;
    return googleSignInAuthentication.accessToken;
  }
}
