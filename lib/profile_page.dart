import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_votes_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  User? user;
  Future<String?>? _enrollmentFuture;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _enrollmentFuture = _fetchEnrollment();
  }

  Future<String?> _fetchEnrollment() async {
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user!.uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;

      // Primary key used in signup: 'enrollmentNumber'
      if (data.containsKey('enrollmentNumber')) {
        return (data['enrollmentNumber'] ?? '').toString();
      }

      // Backwards compatibility: support older 'enrollment' key
      if (data.containsKey('enrollment')) {
        return (data['enrollment'] ?? '').toString();
      }
    } catch (e) {
      debugPrint('fetchEnrollment error: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const pageTop = Color(0xFF0B1020);
    const pageMid = Color(0xFF121A3A);
    const pageBottom = Color(0xFF1B255A);
    const gradientStart = Color(0xFF6C7CFF);
    const gradientEnd = Color(0xFF4DD0E1);

    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile'),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pageTop, pageMid, pageBottom],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile card (off-white, matching home style)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [gradientStart, gradientEnd]),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _initialsFromEmail(user?.email),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user?.displayName ?? 'Voter',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0B1020)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              user?.email ?? 'No email',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7A90)),
                            ),
                            const SizedBox(height: 18),

                            // Enrollment row (from Firestore if available)
                            FutureBuilder<String?>(
                              future: _enrollmentFuture,
                              builder: (context, snap) {
                                Widget valueWidget;
                                if (snap.connectionState == ConnectionState.waiting) {
                                  valueWidget = const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  );
                                } else {
                                  final val = snap.data;
                                  valueWidget = Text(
                                    (val != null && val.isNotEmpty) ? val : 'Not set',
                                    style: const TextStyle(color: Color(0xFF0B1020), fontWeight: FontWeight.w700),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.badge, color: Color(0xFF6B7A90)),
                                        const SizedBox(width: 10),
                                        const Text('Enrollment', style: TextStyle(color: Color(0xFF6B7A90))),
                                        const Spacer(),
                                        valueWidget,
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    // Single action: Sign out
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _auth.signOut();
                                          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: gradientEnd,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Sign out', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Quick links (only My Votes)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.history, color: Colors.white70),
                              title: const Text('My Votes', style: TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MyVotesPage()),
                                );
                              },
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

  String _initialsFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'V';
    final part = email.split('@').first;
    if (part.isEmpty) return 'V';
    return part.length >= 2 ? part.substring(0, 2).toUpperCase() : part.substring(0, 1).toUpperCase();
  }
}