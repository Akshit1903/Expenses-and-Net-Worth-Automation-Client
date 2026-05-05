import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthConfig {
  static const List<String> _scopes = [
    "https://www.googleapis.com/auth/script.projects",
    "https://www.googleapis.com/auth/spreadsheets",
    'https://www.googleapis.com/auth/drive.file',
  ];

  static GoogleSignIn getSignInClient() {
    final String serverClientId = dotenv.get('SERVER_CLIENT_ID');

    return GoogleSignIn(scopes: _scopes, serverClientId: serverClientId);
  }
}
