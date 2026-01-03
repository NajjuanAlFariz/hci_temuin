import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;

  /* ============================================================
     REGISTER MANUAL (EMAIL + PASSWORD)
  ============================================================ */
  Future<void> _registerManual() async {
    final name = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Semua field wajib diisi');
      return;
    }

    if (password != confirm) {
      _showError('Password tidak sama');
      return;
    }

    if (!email.endsWith('@students.paramadina.ac.id')) {
      _showError('Gunakan email mahasiswa @students.paramadina.ac.id');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('User tidak ditemukan');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': name,
        'email': email,
        'provider': 'email',
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      context.go('/home');
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Register gagal');
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /* ============================================================
     REGISTER DENGAN GOOGLE
  ============================================================ */
  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _showError('Login Google dibatalkan');
        return;
      }

      /// 🔒 VALIDASI DOMAIN EMAIL
      if (!googleUser.email.endsWith('@students.paramadina.ac.id')) {
        await GoogleSignIn().signOut();
        _showError('Gunakan akun mahasiswa Paramadina');
        return;
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCred.user;
      if (user == null) throw Exception('User tidak ditemukan');

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final snapshot = await userRef.get();

      /// SIMPAN KE FIRESTORE JIKA BELUM ADA
      if (!snapshot.exists) {
        await userRef.set({
          'name': user.displayName ??
              user.email!.split('@').first,
          'email': user.email,
          'provider': 'google',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      _showError('Login Google gagal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
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
                    BoxShadow(color: Colors.black12, blurRadius: 12),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Warna.blue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: _usernameController,
                      decoration:
                          const InputDecoration(hintText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email Mahasiswa',
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration:
                          const InputDecoration(hintText: 'Password'),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      decoration: const InputDecoration(
                          hintText: 'Confirm Password'),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _registerManual,
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Sign Up'),
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Text('atau', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed:
                          _isLoading ? null : _registerWithGoogle,
                      icon: Image.asset(
                        'assets/image/icon/google.png',
                        height: 20,
                      ),
                      label:
                          const Text('Daftar dengan Google'),
                    ),

                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Have an account? Login now',
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
