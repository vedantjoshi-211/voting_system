import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_success_page.dart';
import 'signup_page.dart';
import 'admin_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPassword = false;

  static const Color _panelText = Color(0xFFECE9FF);
  static const Color _mutedText = Color(0xFFB7B2D9);

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
                colors: [
                  Color(0xFF170D3A),
                  Color(0xFF1A1041),
                  Color(0xFF170D3A),
                ],
              ),
            ),
          ),

          // Glow orbs
          Positioned(top: 130, left: -55, child: _glowOrb(120, const Color(0xFF58B9FF))),
          Positioned(top: 200, left: 70, child: _glowOrb(88, const Color(0xFFE16DFF))),
          Positioned(top: 230, right: -24, child: _glowOrb(90, const Color(0xFFFF4B9A))),
          Positioned(bottom: 160, left: -36, child: _glowOrb(76, const Color(0xFF79C9FF))),
          Positioned(bottom: 68, right: -46, child: _glowOrb(190, const Color(0xFFFF3DA2))),

          // Main content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome text above card
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: _panelText,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Login to continue to your voting dashboard',
                    style: TextStyle(color: _mutedText, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Glass card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: 340,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB7A5FF).withOpacity(0.11),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.34),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.26),
                              blurRadius: 45,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Log In',
                                style: TextStyle(
                                  color: _panelText,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Email
                            TextField(
                              controller: email,
                              style: const TextStyle(color: _panelText),
                              decoration: _inputStyle(hint: 'Enter email'),
                            ),
                            const SizedBox(height: 18),

                            // Password
                            TextField(
                              controller: password,
                              obscureText: !showPassword,
                              style: const TextStyle(color: _panelText),
                              decoration: _inputStyle(
                                hint: 'Enter password',
                                suffix: IconButton(
                                  icon: Icon(
                                    showPassword ? Icons.visibility_off : Icons.visibility,
                                    color: _mutedText,
                                  ),
                                  onPressed: () =>
                                      setState(() => showPassword = !showPassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Log in button
                            Center(
                              child: SizedBox(
                                width: 170,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (email.text.isEmpty || password.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Enter email and password'),
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      final cred = await _auth.signInWithEmailAndPassword(
                                        email: email.text.trim(),
                                        password: password.text.trim(),
                                      );
                                      final user = cred.user!;
                                      if (!user.emailVerified) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please verify your email first',
                                            ),
                                          ),
                                        );
                                        await _auth.signOut();
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LoginSuccessPage(),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(e.message ?? 'Login failed'),
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF78709A).withOpacity(0.52),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.18),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    'Log in',
                                    style: TextStyle(
                                      color: _panelText,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Register link
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignupPage(),
                                  ),
                                ),
                                child: const Text(
                                  'New voter? Register now',
                                  style: TextStyle(
                                    color: Color(0xFFCFC8FA),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Admin login
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: OutlinedButton(
                                onPressed: _showAdminLoginDialog,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.32),
                                    width: 1.3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor:
                                      const Color(0xFF7A719E).withOpacity(0.2),
                                ),
                                child: const Text(
                                  'Admin Login',
                                  style: TextStyle(
                                    color: _panelText,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8F88B8), fontSize: 14),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.only(bottom: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xB8F2EFFF), width: 1.7),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFFFFFF), width: 2),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.55),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.65),
            blurRadius: 56,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  void _showAdminLoginDialog() {
    final adminEmail = TextEditingController();
    final adminPassword = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Admin Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adminEmail,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              const String correctEmail = 'admin@voting.com';
              const String correctPassword = 'Admin@123';
              if (adminEmail.text == correctEmail &&
                  adminPassword.text == correctPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboard()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid admin credentials')),
                );
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
