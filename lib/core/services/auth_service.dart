import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.sendEmailVerification();
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Complete profile and save to Firestore
  Future<void> completeUserProfile({
    required String phone,
    required int age,
    required String profession,
  }) async {
    User? user = _auth.currentUser;
    if (user != null) {
      final nom = user.displayName ?? '';
      final pseudo = nom.trim().split(' ').isNotEmpty ? nom.trim().split(' ')[0] : 'Citoyen';

      await _firestore.collection('citoyens').doc(user.uid).set({
        'nom': nom,
        'pseudo': pseudo,
        'email': user.email ?? '',
        'telephone': phone,
        'age': age,
        'profession': profession,
        'role': 'citoyen',
        'points': 0, // Gamification initialized
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();
}
