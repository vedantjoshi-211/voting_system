import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ElectionsPage extends StatefulWidget {
  final String? electionId;
  const ElectionsPage({super.key, this.electionId});

  @override
  State<ElectionsPage> createState() => _ElectionsPageState();
}

class _ElectionsPageState extends State<ElectionsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Elections'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B1020),
                  Color(0xFF121A3A),
                  Color(0xFF1B255A),
                ],
              ),
            ),
          ),

          /// Glow Orbs
          Positioned(
            top: -60,
            left: -40,
            child: _glowOrb(180, const Color(0xFF6C7CFF)),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowOrb(220, const Color(0xFF4DD0E1)),
          ),

          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: widget.electionId != null
                  ? _singleElectionView()
                  : _activeElectionsView(),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SINGLE ELECTION VIEW =================
  Widget _singleElectionView() {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future:
          _firestore.collection('elections').doc(widget.electionId).get(),
      builder: (context, docSnap) {
        if (docSnap.hasError) {
          return Center(
              child: Text('Error: ${docSnap.error}',
                  style: const TextStyle(color: Colors.white70)));
        }

        if (docSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = docSnap.data;
        if (doc == null || !doc.exists) {
          return const Center(
              child: Text('Election not found',
                  style: TextStyle(color: Colors.white70)));
        }

        final data = doc.data() ?? {};
        final title = (data['title'] ?? 'Untitled').toString();
        final description = (data['description'] ?? '').toString();
        final candidates =
            (data['candidates'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return ListView(
          children: [
            _electionCard(
              electionId: doc.id,
              title: title,
              description: description,
              candidates: candidates,
            ),
          ],
        );
      },
    );
  }

  /// ================= ACTIVE ELECTIONS STREAM =================
  Widget _activeElectionsView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('elections')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.white70)));
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
              child: Text('No active elections',
                  style: TextStyle(color: Colors.white70)));
        }

        return ListView.separated(
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final electionId = docs[index].id;
            final title = (data['title'] ?? 'Untitled').toString();
            final description = (data['description'] ?? '').toString();
            final candidates =
                (data['candidates'] as List?)?.cast<Map<String, dynamic>>() ??
                    [];

            return _electionCard(
              electionId: electionId,
              title: title,
              description: description,
              candidates: candidates,
            );
          },
        );
      },
    );
  }

  /// ================= ELECTION CARD =================
  Widget _electionCard({
    required String electionId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> candidates,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB).withOpacity(0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Color(0xFF0B1020),
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(description,
                  style: const TextStyle(
                      color: Color(0xFF6B7A90), fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Select Candidate:',
                  style: TextStyle(
                      color: Color(0xFF0B1020),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              ...candidates.map((candidate) {
                return GestureDetector(
                  onTap: () {
                    _handleVote(
                        electionId,
                        candidate['candidateId'].toString(),
                        candidate['name'].toString());
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6C7CFF).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(candidate['name'] ?? 'Unknown',
                              style: const TextStyle(
                                  color: Color(0xFF0B1020),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Color(0xFF6B7A90)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= VOTING LOGIC =================
  Future<void> _handleVote(
      String electionId, String candidateId, String candidateName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final userVotesSnapshot = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: userId)
          .get();

      final existingVoteDocs = userVotesSnapshot.docs
          .where((d) => (d.data()['electionId'] ?? '') == electionId);

      if (existingVoteDocs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('You have already voted in this election')),
        );
        return;
      }

      await _firestore.collection('votes').add({
        'electionId': electionId,
        'userId': userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final electionDoc =
          await _firestore.collection('elections').doc(electionId).get();

      final List candidates =
          (electionDoc.data()?['candidates'] as List?) ?? [];

      for (var candidate in candidates) {
        if (candidate['candidateId'] == candidateId) {
          candidate['votes'] = (candidate['votes'] ?? 0) + 1;
        }
      }

      await _firestore
          .collection('elections')
          .doc(electionId)
          .update({'candidates': candidates});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Vote cast for $candidateName successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// ================= GLOW ORB =================
  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 120,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
