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

  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _bgTop = Color(0xFF0B1020);
  static const Color _bgMid = Color(0xFF121A3A);
  static const Color _bgBottom = Color(0xFF1B255A);
  static const Color _accentPrimary = Color(0xFF6C7CFF);
  static const Color _accentSecondary = Color(0xFF4DD0E1);

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
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
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Login to continue to your voting dashboard',
                    style: TextStyle(color: _mutedText, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Card
                  Container(
                    width: 340,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                        width: 1,
                      ),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
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
                                showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
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
                                if (email.text.isEmpty ||
                                    password.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Enter email and password'),
                                    ),
                                  );
                                  return;
                                }
                                try {
                                  final cred = await _auth
                                      .signInWithEmailAndPassword(
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
                                  email.clear();
                                  password.clear();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginSuccessPage(),
                                    ),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.message ?? 'Login failed',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  color: _panelText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
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
                                color: _mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                                color: Colors.white.withOpacity(0.24),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: _accentSecondary.withOpacity(
                                0.15,
                              ),
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
      hintStyle: const TextStyle(color: Color(0xFFB9C6DD), fontSize: 14),
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.only(bottom: 8),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0x99F5F7FB), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF4DD0E1), width: 1.7),
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

  void _showAdminLoginDialog() {
    final adminEmail = TextEditingController();
    final adminPassword = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF17203A),
        title: const Text('Admin Login', style: TextStyle(color: _panelText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adminEmail,
              decoration: InputDecoration(
                labelText: 'Admin Email',
                filled: true,
                fillColor: const Color(0xFF0F162B),
                labelStyle: const TextStyle(color: _mutedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: _panelText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adminPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Admin Password',
                filled: true,
                fillColor: const Color(0xFF0F162B),
                labelStyle: const TextStyle(color: _mutedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: _panelText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
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
            child: const Text(
              'Login',
              style: TextStyle(color: _accentSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
