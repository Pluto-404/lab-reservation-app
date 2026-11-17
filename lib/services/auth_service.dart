import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> registerStudent({
    required String email,
    required String password,
    required String name,
    required String nim,
    required String className,
    required String cohort,
  }) async {
    try {
      // Buat user di Firebase Authentication
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user == null) return null;

      final newUser = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        nim: nim,
        className: className,
        cohort: cohort,
        role: 'student', // default role is 'student'
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      late final UserCredential userCredential;

      if (kIsWeb) {
        // Flutter Web menggunakan popup Firebase Authentication.
        final provider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        // Android tetap menggunakan plugin Google Sign-In.
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user != null) {
        final userRef = _firestore.collection('users').doc(user.uid);
        final doc = await userRef.get();
        if (!doc.exists) {
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? '',
            nim: '',
            className: '',
            cohort: '',
            role: 'student',
            photoUrl: user.photoURL,
            createdAt: DateTime.now(),
          );
          await userRef.set(newUser.toMap());
        }
      }
      return userCredential;
    } catch (error, stackTrace) {
      debugPrint('Google Sign-In gagal: $error');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  Future<void> updateAcademicProfile({
    required String nim,
    required String className,
    required String cohort,
    String? name,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> data = {
      'nim': nim,
      'class_name': className,
      'cohort': cohort,
    };
    if (name != null && name.trim().isNotEmpty) {
      data['name'] = name.trim();
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  /// Stream profil pengguna secara real-time
  Stream<UserModel?> userProfileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
