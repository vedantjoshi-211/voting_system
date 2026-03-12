import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  static const Color gradientStart = Color(0xFF6C7CFF);
  static const Color gradientEnd = Color(0xFF4DD0E1);
  static const Color pageTop = Color(0xFF0B1020);
  static const Color pageMid = Color(0xFF121A3A);
  static const Color pageBottom = Color(0xFF1B255A);
  static const Color glassText = Color(0xFFF5F7FB);
  static const Color glassSubtext = Color(0xFFB9C6DD);
  static const Color glassSurface = Color(0xFFF5F7FB);

  static const List<String> _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formatDate(DateTime dt) =>
      '${_months[dt.month]} ${dt.day}, ${dt.year}';

  String _formatFull(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${_months[dt.month]} ${dt.day}, ${dt.year}  •  $h:$m $ampm';
  }

  void _showDetail(BuildContext context, String title, String body, DateTime time) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A2250), Color(0xFF0D1530)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Sheet header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [gradientStart, gradientEnd],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Announcement',
                      style: TextStyle(
                        color: glassSubtext,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: glassSubtext),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Colors.white12, height: 20),
              ),
              // Scrollable body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        color: glassText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Date badge
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: gradientEnd,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatFull(time),
                          style: const TextStyle(
                            color: gradientEnd,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Divider
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            gradientStart.withOpacity(0.6),
                            gradientEnd.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Body content
                    Text(
                      body.isEmpty ? 'No additional details provided.' : body,
                      style: const TextStyle(
                        color: glassSubtext,
                        fontSize: 15,
                        height: 1.7,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pageTop, pageMid, pageBottom],
              ),
            ),
          ),
          Positioned(top: -60, left: -40, child: _glowOrb(180, gradientStart)),
          Positioned(bottom: -80, right: -60, child: _glowOrb(220, gradientEnd)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // ── Header banner ──────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: glassSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(11),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [gradientStart, gradientEnd],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Official Announcements',
                                    style: TextStyle(
                                      color: glassText,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Latest updates and notices from the college',
                                    style: TextStyle(
                                      color: glassSubtext,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Announcement list ──────────────────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('announcements')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snap.error}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                gradientEnd,
                              ),
                            ),
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inbox_rounded,
                                  color: Colors.white24,
                                  size: 52,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No announcements yet',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final title =
                                (data['title'] ?? 'Untitled').toString();
                            final body = (data['message'] ?? data['body'] ?? '').toString();
                            final ts = data['createdAt'];
                            final time = ts is Timestamp
                                ? ts.toDate()
                                : DateTime.now();

                            return _announcementCard(
                              context: context,
                              index: index + 1,
                              title: title,
                              body: body,
                              time: time,
                            );
                          },
                        );
                      },
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
    required BuildContext context,
    required int index,
    required String title,
    required String body,
    required DateTime time,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: glassSurface.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Index badge
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [gradientStart, gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Title + date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: glassText,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: glassSubtext,
                            size: 11,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(time),
                            style: const TextStyle(
                              color: glassSubtext,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // More Info button
                GestureDetector(
                  onTap: () => _showDetail(context, title, body, time),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [gradientStart, gradientEnd],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'More Info',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
