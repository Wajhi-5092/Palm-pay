import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paypalm/services/connectivity_service.dart';
import 'package:paypalm/services/local_app_state_service.dart';
import 'package:paypalm/services/auth_session_service.dart';
import 'package:paypalm/services/mpin_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAppStateService _localState = LocalAppStateService();

  /// Lowercase trimmed email for consistent storage and lookups.
  static String normalizeEmail(String email) => email.trim().toLowerCase();

  /// Ensures the email is not already registered in Firebase Auth (so it can be used for a new account).
  /// Call before [register]. Returns the normalized email.
  Future<String> validateEmailForNewAccount(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) {
      throw Exception('Please enter your email address.');
    }
    try {
      // Firebase Auth canonical check for whether this email already has an account.
      // ignore: deprecated_member_use
      final methods = await _auth.fetchSignInMethodsForEmail(normalized);
      if (methods.isNotEmpty) {
        throw Exception(
          'This email is already registered. Sign in or use a different email.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception('Please enter a valid email address.');
      }
      throw Exception(e.message ?? 'Could not verify email availability.');
    }
    return normalized;
  }

  /// Validates the signed-in user against Firebase servers (e.g. account deleted in Console).
  /// When offline, leaves the session unchanged. On invalid/revoked user, signs out locally.
  Future<User?> syncSignedInUserWithServer(User? user) async {
    if (user == null) return null;
    final connectivity = ConnectivityService();
    if (!await connectivity.isInternetAvailable()) {
      return user;
    }
    try {
      await user.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        return user;
      }
      if (e.code == 'user-not-found' ||
          e.code == 'user-disabled' ||
          e.code == 'invalid-user-token') {
        await logout(clearMpin: false);
        return _auth.currentUser;
      }
      return user;
    } catch (_) {
      return user;
    }
  }

  /// Consumer accounts expect `users/{uid}` in Firestore. If only Auth remains (profile bulk-deleted),
  /// sign out so the user must register again.
  Future<void> requirePersonalUserProfileAfterLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await _firestore.collection('users').doc(user.uid).get();
    if (snap.exists) return;
    await logout(clearMpin: false);
    throw Exception(
      'No profile found for this account. It may have been removed — please register again.',
    );
  }

  Future<void> _setLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', isLoggedIn);
  }

  // Login
  Future<UserCredential?> login(String identifier, String password) async {
    try {
      String emailToUse = identifier;

      if (!identifier.contains('@')) {
        final querySnapshot = await _firestore
            .collection('users')
            .where('phone', isEqualTo: identifier)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          throw Exception('No user found with this phone number.');
        }
        
        emailToUse = querySnapshot.docs.first.data()['email'];
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      await requirePersonalUserProfileAfterLogin();

      // Save persistent state
      await _setLoginState(true);
      await _localState.ensureDefaults();
      final user = userCredential.user;
      if (user != null) {
        // Persist encrypted session metadata for instant login.
        await AuthSessionService().persistSessionFromUser(user, pendingRefresh: false);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect email or password, please try again.');
      }
      throw Exception(e.message ?? 'An error occurred during login.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Register
  Future<UserCredential?> register({
    required String name,
    required String gender,
    required String email,
    required String phone,
    required String cnic,
    required String city,
    required String address,
    required String password,
  }) async {
    try {
      final normalizedEmail = await validateEmailForNewAccount(email);

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'gender': gender,
        'email': normalizedEmail,
        'phone': phone,
        'cnic': cnic,
        'city': city,
        'address': address,
        'role': 'personal',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save persistent state
      await _setLoginState(true);
      await _localState.ensureDefaults();
      final user = userCredential.user;
      if (user != null) {
        await AuthSessionService().persistSessionFromUser(user, pendingRefresh: false);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception(
          'This email is already registered. Sign in or use a different email.',
        );
      }
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
  }

  /// Deletes the signed-in user from Auth and removes their Firestore profile and palm lookup row.
  /// Requires the account password for reauthentication.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in.');
    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('This account cannot be deleted from the app.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect password.');
      }
      if (e.code == 'too-many-requests') {
        throw Exception('Too many attempts. Try again later.');
      }
      throw Exception(e.message ?? 'Could not verify password.');
    }

    final uid = user.uid;
    try {
      await _firestore.collection('palmLookup').doc(uid).delete();
    } catch (e, st) {
      debugPrint('palmLookup delete: $e\n$st');
    }
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e, st) {
      debugPrint('users delete: $e\n$st');
    }

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Already removed (e.g. Cloud Function deleted Auth after Firestore profile removal).
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please sign out and sign in again, then retry.');
      } else {
        rethrow;
      }
    }

    await logout(clearMpin: true);
  }

  // Logout
  Future<void> logout({bool clearMpin = true}) async {
    if (clearMpin) {
      // Best-effort removal of MPIN metadata while user is still signed-in.
      await MpinService().removeMpin();
    }

    await _auth.signOut();
    await AuthSessionService().clearSession();
    await _setLoginState(false);
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
