import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login
  Future<UserCredential?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during login.');
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
      // 1. Create the user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 2. Add extra user data to Firestore
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
        'role': 'personal', // personal account
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'An error occurred during registration.');
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
