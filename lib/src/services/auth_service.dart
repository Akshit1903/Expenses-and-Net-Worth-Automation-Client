import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn;

  AuthService(this._googleSignIn);

  Stream<GoogleSignInAccount?> get onUserChanged =>
      _googleSignIn.onCurrentUserChanged;

  Future<void> signIn() => _googleSignIn.signIn();
  Future<void> signOut() => _googleSignIn.signOut();
  Future<void> silentSignIn() => _googleSignIn.signInSilently();
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  Future<String> getAccessToken() async {
    final GoogleSignInAuthentication auth =
        await _getGoogleSignInAuthentication();
    final String? accessToken = auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception("Failed to retrieve access token");
    }
    return accessToken;
  }

  Future<String> getIDToken() async {
    final GoogleSignInAuthentication auth =
        await _getGoogleSignInAuthentication();
    final String? idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception("Failed to retrieve ID token");
    }
    return idToken;
  }

  Future<GoogleSignInAuthentication> _getGoogleSignInAuthentication() async {
    final GoogleSignInAccount? user = _googleSignIn.currentUser;
    if (user == null) {
      throw Exception("User not signed in");
    }
    return await user.authentication;
  }
}
