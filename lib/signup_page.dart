import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final enrollmentController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  bool showPassword = false;

  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _bgTop = Color(0xFF0B1020);
  static const Color _bgMid = Color(0xFF121A3A);
  static const Color _bgBottom = Color(0xFF1B255A);
  static const Color _accentPrimary = Color(0xFF6C7CFF);
  static const Color _accentSecondary = Color(0xFF4DD0E1);

  @override
  void dispose() {
    enrollmentController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> registerUser() async {
    if (enrollmentController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() => loading = true);

    try {
      // 🔒 Check enrollment uniqueness
      final query = await _firestore
          .collection('users')
          .where(
            'enrollmentNumber',
            isEqualTo: enrollmentController.text.trim(),
          )
          .get();

      if (query.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment number already registered')),
        );
        setState(() => loading = false);
        return;
      }

      // 🔑 Create Firebase Auth user
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User user = credential.user!;

      // 🗂 Store extra data in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid) // ✅ FIX
          .set({
            'enrollmentNumber': enrollmentController.text.trim(),
            'email': emailController.text.trim(),
            'role': 'voter',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 📧 Email verification
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registration successful. Verify your email and login.',
          ),
        ),
      );

      Navigator.pop(context); // back to login
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgBottom],
              ),
            ),
          ),

          Positioned(
            top: 90,
            left: -30,
            child: _accentOrb(110, _accentPrimary),
          ),
          Positioned(
            bottom: 90,
            right: -35,
            child: _accentOrb(130, _accentSecondary),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'New Voter Registration',
                          style: TextStyle(
                            color: _panelText,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: enrollmentController,
                          style: const TextStyle(color: _panelText),
                          decoration: _input('Enrollment Number'),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: emailController,
                          style: const TextStyle(color: _panelText),
                          decoration: _input('Email Address'),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: passwordController,
                          style: const TextStyle(color: _panelText),
                          obscureText: !showPassword,
                          decoration: _input(
                            'Password',
                            suffix: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: _mutedText,
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'Register',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedText),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0F162B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _accentSecondary),
      ),
    );
  }

  Widget _accentOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.14),
              blurRadius: 52,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
