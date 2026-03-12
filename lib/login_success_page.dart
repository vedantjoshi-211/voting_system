import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginSuccessPage extends StatelessWidget {
  const LoginSuccessPage({super.key});

  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _bgTop = Color(0xFF0B1020);
  static const Color _bgMid = Color(0xFF121A3A);
  static const Color _bgBottom = Color(0xFF1B255A);
  static const Color _accentPrimary = Color(0xFF6C7CFF);
  static const Color _accentSecondary = Color(0xFF4DD0E1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: Stack(
        children: [
          // 🔥 Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgBottom],
              ),
            ),
          ),

          // 🔵 Glow orbs
          Positioned(top: 90, left: -30, child: _glowOrb(110, _accentPrimary)),
          Positioned(
            bottom: 90,
            right: -35,
            child: _glowOrb(130, _accentSecondary),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.22),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Success icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [_accentPrimary, _accentSecondary],
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Login Successful',
                          style: TextStyle(
                            color: _panelText,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 10),

                        const Text(
                          'You have successfully logged in.\nYou can now explore the app.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _mutedText, height: 1.4),
                        ),

                        const SizedBox(height: 30),

                        // Explore App Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            },
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
                            child: const Center(
                              child: Text(
                                'Explore App',
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

  // 🔹 Glow orb
  Widget _glowOrb(double size, Color color) {
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
