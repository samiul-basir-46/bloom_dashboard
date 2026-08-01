import 'package:firebase_auth/firebase_auth.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    // We validate email suffix for administration checks.
    final allowedDomains = ['@bae-window.com', '@admin.com'];
    final allowedEmails = ['admin@gmail.com', 'admin.window@gmail.com'];
    
    bool isAllowed = allowedEmails.contains(email.toLowerCase());
    if (!isAllowed) {
      for (final domain in allowedDomains) {
        if (email.toLowerCase().endsWith(domain)) {
          isAllowed = true;
          break;
        }
      }
    }

    if (!isAllowed) {
      throw FirebaseAuthException(
        code: 'not-authorized',
        message: 'Access Denied: Only authorized administrators can log in.',
      );
    }

    // Configure Web Persistence safely for Incognito / Strict Privacy mode
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (_) {
      try {
        await _auth.setPersistence(Persistence.SESSION);
      } catch (_) {}
    }

    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
