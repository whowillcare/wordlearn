import 'package:firebase_auth/firebase_auth.dart';

import 'package:word_learn_app/core/logger.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final gsi.GoogleSignIn _googleSignIn;

  AuthRepository({FirebaseAuth? firebaseAuth, gsi.GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? gsi.GoogleSignIn(scopes: ['email']);

  Stream<User?> get user => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final gsi.GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      Log.i(
        "Google Auth Tokens - Access: ${googleAuth.accessToken != null}, ID: ${googleAuth.idToken != null}",
      );

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e, stack) {
      Log.e("Google Sign-In Error", e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
