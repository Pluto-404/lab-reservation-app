import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'screens/auth_pages.dart';
import 'screens/student_pages.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LabBookApp());
}

class LabBookApp extends StatelessWidget {
  const LabBookApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'LabBook',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = authSnapshot.data;
        if (user == null) return const LoginPage();
        return StreamBuilder<UserModel?>(
          key: ValueKey(user.uid),
          stream: auth.userProfileStream(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting &&
                !profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Gagal memuat profil. Periksa koneksi atau izin Firestore.',
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () => auth.signOut(),
                          child: const Text('Keluar'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final profile = profileSnapshot.data;
            if (profile == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Menyiapkan profil akun LabBook...'),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => auth.signOut(),
                          child: const Text('Batal & Keluar'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (profile.role == 'admin') {
              return Scaffold(
                appBar: AppBar(title: const Text('LabBook Admin')),
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Dashboard admin akan dikembangkan oleh tim admin.',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: auth.signOut,
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return StudentHome(key: ValueKey(profile.uid), profile: profile);
          },
        );
      },
    );
  }
}
