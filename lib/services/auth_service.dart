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
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

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
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

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

          await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        }
      }
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAcademicProfile({
    required String nim,
    required String className,
    required String cohort,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'nim': nim,
      'class_name': className,
      'cohort': cohort,
    });
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final User? user = _auth.currentUser;
    if (user == null) return null;

    final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
