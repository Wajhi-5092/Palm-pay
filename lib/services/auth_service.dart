import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Optional early check — prefer relying on [createUserWithEmailAndPassword]
  /// (`email-already-in-use`) so results match Auth after deletions/propagation.
  ///
  /// [fetchSignInMethodsForEmail] can lag behind Auth deletions; do not use this
  /// as the only gate for registration.
  Future<String> validateEmailForNewAccount(String email) async {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) {
      throw Exception('Please enter your email address.');
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

  /// Ensures `users/{uid}` exists after sign-in. If you deleted only the Firestore
  /// document (not the Firebase Auth user), we recreate a minimal profile so the
  /// user can sign in again instead of being stuck.
  Future<void> requirePersonalUserProfileAfterLogin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final ref = _firestore.collection('users').doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final email = normalizeEmail(user.email ?? '');
    final displayName = user.displayName?.trim();
    await ref.set({
      'uid': user.uid,
      'name': (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'PayPalm User',
      'email': email,
      'gender': '',
      'phone': '',
      'cnic': '',
      'city': '',
      'address': '',
      'role': 'personal',
      'walletBalance': LocalAppStateService.defaultBalance,
      'createdAt': FieldValue.serverTimestamp(),
      'profileRepaired': true,
    }, SetOptions(merge: true));
  }

  /// Shown when sign-up hits [email-already-in-use]. Often the Firestore profile was
  /// deleted but the **Firebase Auth** user still exists (registration queries cannot
  /// read Firestore while signed out). User should sign in (profile is auto-repaired)
  /// or delete the Auth user in Console.
  static const String emailAlreadyInUseGuidance =
      'This email is still registered for login in Firebase. '
      'If you only deleted the database profile, use Sign in with this email and password — '
      'your profile will be restored automatically. '
      'To create a completely new account with this email, delete the user in '
      'Firebase Console → Authentication → Users, then try again. '
      'Otherwise sign in, or choose a different email.';

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
    final normalizedEmail = normalizeEmail(email);
    if (normalizedEmail.isEmpty) {
      throw Exception('Please enter your email address.');
    }

    try {
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
        'walletBalance': LocalAppStateService.defaultBalance,
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
        throw Exception(emailAlreadyInUseGuidance);
      }
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
  }

  /// Deletes the Firebase **Auth** user first (so the email is released for sign-up),
  /// then [logout]. Firestore `users/{uid}` and `palmLookup/{uid}` are removed by
  /// Cloud Function `deleteUserDataWhenAuthRemoved` — deploy `functions` for that path.
  ///
  /// We avoid deleting Firestore before Auth here: doing so triggers
  /// `deleteAuthWhenUserProfileDeleted` and can invalidate the client session before
  /// `user.delete()` runs, leaving Auth cleanup inconsistent.
  Future<void> deleteAccount({required String password}) async {
    User? user = _auth.currentUser;
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

    user = _auth.currentUser;
    if (user == null) throw Exception('Session expired. Sign in again and retry.');

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Auth user already removed (e.g. admin or another client).
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
