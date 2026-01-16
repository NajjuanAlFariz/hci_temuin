import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  bool _isStudentEmail(String email) {
    return email.endsWith('@students.paramadina.ac.id');
  }

  Future<void> _loginManual() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email dan password wajib diisi');
      return;
    }

    if (!_isStudentEmail(email)) {
      _showError(
        'Gunakan email mahasiswa (@students.paramadina.ac.id)',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) throw Exception('User tidak ditemukan');

      await _ensureUserFirestore(user);

      if (!mounted) return;
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login gagal');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Future<void> _loginWithGoogle() async {
  setState(() => _isLoading = true);

  try {
    /// ✅ AMAN: reset session TANPA disconnect
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final email = googleUser.email;

    if (!_isStudentEmail(email)) {
      await _googleSignIn.signOut();
      throw Exception(
        'Gunakan akun mahasiswa (@students.paramadina.ac.id)',
      );
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user == null) throw Exception('User tidak ditemukan');

    await _ensureUserFirestore(
      user,
      displayName: googleUser.displayName,
    );

    if (!mounted) return;
    context.go('/home');
  } catch (e) {
    if (!mounted) return;
    _showError(
      e.toString().replaceAll('Exception: ', ''),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  /* ============================================================
     FIRESTORE USER
  ============================================================ */
  Future<void> _ensureUserFirestore(
    User user, {
    String? displayName,
  }) async {
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await userDoc.get();

    if (!snapshot.exists) {
      await userDoc.set({
        'name': displayName ?? user.email!.split('@').first,
        'email': user.email,
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /* ============================================================
     UI
  ============================================================ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Image.asset(
                'assets/image/logo_temuin.png',
                height: 180,
              ),

              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Warna.blue,
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email mahasiswa',
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                      ),
                    ),

                    /// FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.go('/forgot-password'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _loginManual,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Login'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text('atau'),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: Image.asset(
                          'assets/image/icon/google.png',
                          height: 20,
                        ),
                        label: const Text('Login dengan Google'),
                        onPressed:
                            _isLoading ? null : _loginWithGoogle,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text(
                        'Belum punya akun? Daftar',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
