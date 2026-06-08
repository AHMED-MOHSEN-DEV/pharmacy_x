import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String adminEmail = 'admin@gmail.com';

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String job,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('User was not created');
    }

    final cleanEmail = email.trim().toLowerCase();
    final role = cleanEmail == adminEmail ? 'admin' : 'employee';

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': cleanEmail,
      'gender': gender,
      'job': job,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> loginAndGetRole({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('Login failed');
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) {
      throw Exception('User data not found in Firestore');
    }

    final data = doc.data()!;
    return data['role'] ?? 'employee';
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}