import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const Color gradientStart = Color(0xFF6C7CFF);
  static const Color gradientEnd = Color(0xFF4DD0E1);
  static const Color pageTop = Color(0xFF0B1020);
  static const Color pageMid = Color(0xFF121A3A);
  static const Color pageBottom = Color(0xFF1B255A);
  static const Color glassText = Color(0xFFF5F7FB);
  static const Color glassSubtext = Color(0xFFB9C6DD);
  static const Color glassSurface = Color(0xFFF5F7FB);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        title: const Text('Results & Reports'),
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
          /// Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pageTop, pageMid, pageBottom],
              ),
            ),
          ),

          Positioned(top: -60, left: -40, child: _glowOrb(160, gradientStart)),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowOrb(200, gradientEnd),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('elections')
                    .where('resultsVisible', isEqualTo: true)
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snap.data?.docs ?? []).toList();

                  docs.sort((a, b) {
                    final ta =
                        (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final tb =
                        (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return tb.compareTo(ta);
                  });

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No published results yet',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final electionId = docs[index].id;
                      final title = (data['title'] ?? 'Untitled').toString();
                      final description = (data['description'] ?? '')
                          .toString();
                      final candidatesData =
                          (data['candidates'] as List?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('votes')
                            .where('electionId', isEqualTo: electionId)
                            .snapshots(),
                        builder: (context, voteSnap) {
                          /// 🔥 FIXED VOTE COUNT LOGIC
                          final voteCount = <String, int>{};

                          if (voteSnap.hasData) {
                            for (var vote in voteSnap.data!.docs) {
                              final candidateId = vote
                                  .data()['candidateId']
                                  ?.toString();

                              if (candidateId != null &&
                                  candidateId.isNotEmpty) {
                                voteCount[candidateId] =
                                    (voteCount[candidateId] ?? 0) + 1;
                              }
                            }
                          }

                          /// Build candidate list
                          final candidateList = <Map<String, dynamic>>[];

                          for (var candidate in candidatesData) {
                            final candId = candidate['candidateId']?.toString();
                            final candName =
                                candidate['name']?.toString() ?? 'Unknown';

                            final votes =
                                (candId != null ? voteCount[candId] : 0) ?? 0;

                            candidateList.add({
                              'candidateId': candId ?? '',
                              'name': candName,
                              'votes': votes,
                            });
                          }

                          /// Determine winner
                          int maxVotes = 0;
                          for (var cand in candidateList) {
                            final v = (cand['votes'] ?? 0) as int;
                            if (v > maxVotes) maxVotes = v;
                          }

                          final winners = maxVotes > 0
                              ? candidateList
                                    .where(
                                      (c) =>
                                          (c['votes'] ?? 0) as int == maxVotes,
                                    )
                                    .toList()
                              : [];

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: glassSurface.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: glassText,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      description,
                                      style: const TextStyle(
                                        color: glassSubtext,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    /// RESULT BANNER
                                    if (maxVotes == 0) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 6,
                                        ),
                                        child: Text(
                                          'No votes cast',
                                          style: TextStyle(
                                            color: glassSubtext,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ] else if (winners.length == 1) ...[
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(
                                              0.65,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.emoji_events,
                                              color: Color(0xFF80FF9E),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'WINNER: ${winners[0]['name']?.toString().toUpperCase() ?? "UNKNOWN"}',
                                                style: const TextStyle(
                                                  color: Color(0xFF80FF9E),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else if (winners.length > 1) ...[
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.withOpacity(0.70),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.warning_amber,
                                              color: Color(0xFFFFA6A6),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'TIE: ${winners.map((w) => w['name']).join(', ').toUpperCase()}',
                                                style: const TextStyle(
                                                  color: Color(0xFFFFA6A6),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 8),
                                    const Text(
                                      'Vote Count:',
                                      style: TextStyle(
                                        color: glassText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    ...candidateList.map((c) {
                                      final candVotes =
                                          (c['votes'] ?? 0) as int;
                                      final isWinner = winners.any(
                                        (w) =>
                                            w['candidateId'] ==
                                            c['candidateId'],
                                      );

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                c['name'] ?? 'Unknown',
                                                style: TextStyle(
                                                  color: isWinner
                                                      ? const Color(0xFF80FF9E)
                                                      : glassText,
                                                  fontWeight: isWinner
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '$candVotes',
                                              style: TextStyle(
                                                color: isWinner
                                                    ? const Color(0xFF80FF9E)
                                                    : glassSubtext,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
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
