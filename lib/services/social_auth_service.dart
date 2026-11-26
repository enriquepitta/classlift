import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The Google SDK is initialized once for both sign-in and reauthentication.
class SocialAuthService {
  static Future<void>? _googleInitialization;

  static Future<AuthCredential> googleCredential() async {
    final initialization =
        _googleInitialization ??= GoogleSignIn.instance.initialize();
    try {
      await initialization;
    } catch (_) {
      if (identical(_googleInitialization, initialization)) {
        _googleInitialization = null;
      }
      rethrow;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }
}
