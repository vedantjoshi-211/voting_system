import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  // Theme colors (match login/home)
  static const Color gradientStart = Color(0xFF6C7CFF);
  static const Color gradientEnd = Color(0xFF4DD0E1);
  static const Color pageTop = Color(0xFF0B1020);
  static const Color pageMid = Color(0xFF121A3A);
  static const Color pageBottom = Color(0xFF1B255A);

  static const Color cardSurface = Color(0xFFF5F7FB);
  static const Color cardText = Color(0xFF0B1020);
  static const Color cardSub = Color(0xFF6B7A90);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        title: const Text('Announcements'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pageTop, pageMid, pageBottom],
              ),
            ),
          ),

          // optional glow orbs for visual continuity
          Positioned(
            top: -60,
            left: -40,
            child: _glowOrb(180, gradientStart),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowOrb(220, gradientEnd),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardSurface.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.35)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [gradientStart, gradientEnd]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.campaign, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Official Announcements',
                                      style: TextStyle(
                                          color: cardText, fontWeight: FontWeight.w800, fontSize: 16)),
                                  SizedBox(height: 4),
                                  Text('Latest updates and notices from the college',
                                      style: TextStyle(color: cardSub, fontSize: 13)),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Announcements list (Firestore stream)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: Colors.transparent,
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('announcements')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) {
                                return Center(
                                  child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.white70)),
                                );
                              }
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final docs = snap.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Center(
                                  child: Text('No announcements yet', style: TextStyle(color: Colors.white70)),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data();
                                  final title = (data['title'] ?? 'Untitled').toString();
                                  final body = (data['body'] ?? '').toString();
                                  final ts = data['createdAt'];
                                  final time = ts is Timestamp
                                      ? ts.toDate()
                                      : DateTime.now();
                                  final subtitle = body.length > 120 ? '${body.substring(0, 120)}…' : body;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _announcementCard(
                                      title: title,
                                      subtitle: subtitle,
                                      time: time,
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: cardSurface.withOpacity(0.98),
                                            title: Text(title, style: const TextStyle(color: cardText)),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    body,
                                                    style: const TextStyle(color: cardText),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Posted: ${time.toLocal()}',
                                                    style: const TextStyle(color: cardSub, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Close'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
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

  Widget _announcementCard({
    required String title,
    required String subtitle,
    required DateTime time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardSurface.withOpacity(0.94),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.28)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [gradientStart, gradientEnd]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.announcement, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: cardText, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(subtitle, style: const TextStyle(color: cardSub, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${time.day}/${time.month}/${time.year}',
                  style: const TextStyle(color: cardSub, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.22),
        boxShadow: [BoxShadow(color: color.withOpacity(0.36), blurRadius: 120, spreadRadius: 36)],
      ),
    );
  }
}