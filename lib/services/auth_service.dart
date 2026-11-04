import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    User? createdUser;

    try {
      final UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        return 'Unable to create account.';
      }
      try {
        await _firestore
            .collection('Users')
            .doc(createdUser.uid)
            .set({
          'UserId': createdUser.uid,
          'Name': name.trim(),
          'Email': email.trim(),
          'Phone': phone.trim(),
          'Role': role,
          'ProfileImage': '',
          'Status': role == 'Organizer' ? 'Pending' : 'Active',
          'CreatedAt': FieldValue.serverTimestamp(),
        }).timeout(
          const Duration(seconds: 15),
        );
      } on FirebaseException catch (e) {
        print('Firestore Error: ${e.code}');
        print('Firestore Message: ${e.message}');
        return null;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already registered.';

        case 'invalid-email':
          return 'Please enter a valid email address.';

        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';

        case 'operation-not-allowed':
          return 'Email/Password registration is not enabled in Firebase.';

        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';

        default:
          return e.message ?? 'Registration failed.';
      }
    } catch (e) {
      print('Registration Error: $e');
      if (createdUser != null) {
        return null;
      }

      return 'Registration failed. Please try again.';
    }
  }
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account found with this email.';

        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email or password.';

        case 'invalid-email':
          return 'Please enter a valid email address.';

        case 'user-disabled':
          return 'This account has been disabled.';

        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';

        default:
          return e.message ?? 'Login failed.';
      }
    } catch (e) {
      return 'Login failed. Please try again.';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return 'Google sign-in was canceled.';
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final docRef = _firestore.collection('Users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          await docRef.set({
            'UserId': user.uid,
            'Name': user.displayName ?? '',
            'Email': user.email ?? '',
            'Phone': '',
            'Role': 'attendee',
            'ProfileImage': user.photoURL ?? '',
            'Status': 'Active',
            'CreatedAt': FieldValue.serverTimestamp(),
          });
        }
        return null;
      }
      return 'Failed to sign in with Google.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Google Sign-In failed.';
    } catch (e) {
      return 'Google Sign-In failed. Please try again.';
    }
  }
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }
  Future<void> signOut() async {
    try {
      await _firestore.clearPersistence();
    } catch (_) {
    }
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove('last_session_uid');
    await preferences.remove('last_session_role');
    await _auth.signOut();
  }
  User? get currentUser {
    return _auth.currentUser;
  }
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
