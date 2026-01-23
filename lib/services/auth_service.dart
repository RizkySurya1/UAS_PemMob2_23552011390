import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;

  bool get isLoggedIn => user != null;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final userCredential =
        await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'email': email,
      'name': name,
      'phone': phone,
      'role': 'user', // default user
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  /// 🔑 ROLE CHECK (ADMIN / USER)
  Future<String> getUserRole() async {
    final uid = _auth.currentUser!.uid;

    final doc =
        await _firestore.collection('users').doc(uid).get();

    return doc.data()?['role'] ?? 'user';
  }
}
