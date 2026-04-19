import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Save persistent state
      await _setLoginState(true);

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
    required String fathersName,
    required String gender,
    required String email,
    required String phone,
    required String cnic,
    required String city,
    required String address,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'fathersName': fathersName,
        'gender': gender,
        'email': email,
        'phone': phone,
        'cnic': cnic,
        'city': city,
        'address': address,
        'role': 'personal',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save persistent state
      await _setLoginState(true);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    await _setLoginState(false);
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
