import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyVotesPage extends StatelessWidget {
  const MyVotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Votes')),
        body: const Center(child: Text('Please log in to see your votes')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('My Votes'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                colors: [Color(0xFF0B1020), Color(0xFF121A3A), Color(0xFF1B255A)],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                  .collection('votes')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.white70)));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = (snap.data?.docs ?? []).toList();

                  // sort client-side by timestamp desc to avoid needing an index
                  docs.sort((a, b) {
                    final ta = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                    final tb = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
                    return tb.compareTo(ta);
                  });
                  if (docs.isEmpty) {
                    return Center(child: Text('You have not voted yet', style: TextStyle(color: Colors.white70)));
                  }

                  return ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final vote = docs[index].data();
                      final electionId = vote['electionId'] as String?;
                      final candidateId = vote['candidateId'] as String?;
                      final ts = vote['timestamp'] as Timestamp?;

                      return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        future: (electionId != null)
                            ? FirebaseFirestore.instance.collection('elections').doc(electionId).get()
                            : Future.value(null),
                        builder: (context, eSnap) {
                          if (eSnap.connectionState == ConnectionState.waiting) {
                            return _voteCardPlaceholder();
                          }

                          final eDoc = eSnap.data;
                          final eData = eDoc?.data();
                          final title = (eData?['title'] ?? 'Unknown Election').toString();

                          String candidateName = 'Unknown Candidate';
                          if (eData != null && eData['candidates'] is List) {
                            final List<dynamic> cands = eData['candidates'];
                            final found = cands.cast<Map<String, dynamic>>().firstWhere(
                              (c) => (c['candidateId'] ?? '') == (candidateId ?? ''),
                              orElse: () => {},
                            );
                            if (found is Map && found.containsKey('name')) candidateName = (found['name'] ?? '').toString();
                          }

                          final votedAt = ts?.toDate();
                          final timeText = votedAt != null ? '${votedAt.day}/${votedAt.month}/${votedAt.year} ${votedAt.hour.toString().padLeft(2,'0')}:${votedAt.minute.toString().padLeft(2,'0')}' : 'Unknown time';

                          return _voteCard(title: title, candidate: candidateName, time: timeText);
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

  Widget _voteCard({required String title, required String candidate, required String time}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB).withOpacity(0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF0B1020), fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Voted for: $candidate', style: const TextStyle(color: Color(0xFF6B7A90))),
              const SizedBox(height: 8),
              Text(time, style: const TextStyle(color: Color(0xFF6B7A90), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voteCardPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB).withOpacity(0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 16, width: 180, color: Colors.white24),
              const SizedBox(height: 8),
              Container(height: 12, width: 120, color: Colors.white24),
              const SizedBox(height: 8),
              Container(height: 10, width: 80, color: Colors.white24),
            ],
          ),
        ),
      ),
    );
  }
}
