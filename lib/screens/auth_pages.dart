import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_theme.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

String authMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use': return 'Email sudah terdaftar.';
      case 'invalid-email': return 'Format email tidak valid.';
      case 'weak-password': return 'Password terlalu lemah.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found': return 'Email atau password salah.';
      case 'network-request-failed': return 'Periksa koneksi internet.';
      default: return error.message ?? 'Autentikasi gagal.';
    }
  }
  return 'Permintaan gagal. Silakan coba lagi.';
}

void showAuthError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authMessage(error))));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  bool busy = false;
  bool hidden = true;

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  Future<void> login({bool google = false}) async {
    if (busy || (!google && !form.currentState!.validate())) return;
    setState(() => busy = true);
    try {
      if (google) {
        await auth.signInWithGoogle();
      } else {
        await auth.loginWithEmail(email: email.text.trim(), password: password.text);
      }
    } catch (error) {
      if (mounted) showAuthError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final input = email.text.trim();
    if (!input.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi email terlebih dahulu untuk mengatur ulang password.')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: input);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tautan reset password telah dikirim jika email terdaftar.')));
    } catch (error) {
      if (mounted) showAuthError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 750;
            final veryCompact = constraints.maxHeight < 610;
            final needsScroll = keyboardVisible || constraints.maxHeight < 590;
            final logoHeight = veryCompact ? 94.0 : (compact ? 116.0 : 155.0);
            final gap = compact ? 8.0 : 16.0;

            final content = Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/labbook-logo.svg',
                      width: compact ? 170 : 208,
                      height: logoHeight,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 20),
                  const Text(
                    'Selamat datang kembali',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.ink),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Masuk untuk melihat dan memesan laboratorium kampus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppTheme.muted),
                  ),
                  SizedBox(height: compact ? 16 : 28),
                  const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      hintText: 'nama@student.uns.ac.id',
                      prefixIcon: Icon(Icons.mail_outline),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                    validator: (v) => v == null || !v.trim().contains('@')
                        ? 'Masukkan email yang valid'
                        : null,
                  ),
                  SizedBox(height: gap),
                  const Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: password,
                    obscureText: hidden,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => login(),
                    decoration: InputDecoration(
                      hintText: 'Password akun',
                      prefixIcon: const Icon(Icons.lock_outline),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : resetPassword,
                      child: const Text('Lupa password?', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: busy ? null : () => login(),
                      child: busy
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Masuk'),
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 22),
                  const Center(child: Text('atau', style: TextStyle(fontSize: 12, color: AppTheme.muted))),
                  SizedBox(height: compact ? 9 : 16),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => login(google: true),
                      icon: Image.asset('assets/images/google_logo.png', width: 20, height: 20),
                      label: const Text('Lanjutkan dengan Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.ink,
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                ],
              ),
            );

            final body = needsScroll
                ? SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: content,
                  )
                : Center(child: content);

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: body,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final keyForm = GlobalKey<FormState>();
  final name = TextEditingController();
  final nim = TextEditingController();
  final className = TextEditingController();
  final cohort = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final auth = AuthService();
  bool busy = false;
  bool hidden = true;

  @override
  void dispose() {
    for (final c in [name, nim, className, cohort, email, password]) { c.dispose(); }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !keyForm.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await auth.registerStudent(email: email.text.trim(), password: password.text, name: name.text.trim(), nim: nim.text.trim(), className: className.text.trim(), cohort: cohort.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showAuthError(context, error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String label, TextEditingController controller, String hint, {TextInputType? keyboard, String? Function(String?)? validator, bool secure = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(controller: controller, keyboardType: keyboard, obscureText: secure && hidden,
        decoration: InputDecoration(hintText: hint, suffixIcon: secure ? IconButton(onPressed: () => setState(() => hidden = !hidden), icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined)) : null),
        validator: validator ?? (v) => v == null || v.trim().isEmpty ? '$label wajib diisi' : null),
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Daftar Mahasiswa')),
    body: SafeArea(child: PageWidth(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32), child: Form(key: keyForm, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Buat akun LabBook', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      const Text('Lengkapi identitas akademik sesuai data kampus.', style: TextStyle(color: AppTheme.muted)),
      const SizedBox(height: 26),
      field('Nama lengkap', name, 'Nama sesuai identitas kampus'),
      field('NIM', nim, 'Nomor induk mahasiswa'),
      field('Kelas', className, 'Contoh: PTIK A'),
      field('Angkatan', cohort, 'Contoh: 2023', keyboard: TextInputType.number, validator: (v) => v == null || !RegExp(r'^\d{4}$').hasMatch(v.trim()) ? 'Masukkan tahun angkatan (4 digit)' : null),
      field('Email', email, 'nama@student.uns.ac.id', keyboard: TextInputType.emailAddress, validator: (v) => v == null || !v.trim().contains('@') ? 'Email tidak valid' : null),
      field('Password', password, 'Minimal 8 karakter', secure: true, validator: (v) => v == null || v.length < 8 ? 'Password minimal 8 karakter' : null),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: busy ? null : submit, child: busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Buat akun')),
    ]))))),
  );
}
