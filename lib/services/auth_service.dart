import 'package:firebase_auth/firebase_auth.dart';

/// Admin Auth Service
/// Sirf ek admin account ke liye — email + password se login
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String adminEmail = 'cricket.mania78362@gmail.com';

  /// Current user (null if not logged in)
  User? get currentUser => _auth.currentUser;

  /// Auth state stream (login/logout sunne ke liye)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email + password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleError(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Error handling — friendly messages
  String _handleError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Admin account not found';
      case 'wrong-password':
        return 'Ghalat password';
      case 'invalid-email':
        return 'Email sahi nahi hai';
      case 'user-disabled':
        return 'Account disable hai';
      case 'too-many-requests':
        return 'Bohat zyada attempts — thori der baad try karein';
      case 'network-request-failed':
        return 'Internet connection check karein';
      case 'invalid-credential':
        return 'Email ya password ghalat hai';
      default:
        return e.message ?? 'Login failed';
    }
  }
}