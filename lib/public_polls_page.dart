import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicPollsPage extends StatefulWidget {
  const PublicPollsPage({super.key});

  @override
  State<PublicPollsPage> createState() => _PublicPollsPageState();
}

class _PublicPollsPageState extends State<PublicPollsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<bool> _hasUserVotedOnPoll(String pollId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final voteDoc = await _firestore
          .collection('poll_votes')
          .doc('${pollId}_${user.uid}')
          .get();

      return voteDoc.exists;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Public Polls'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle:
            const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      body: Stack(
        children: [
          // Background gradient
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

          // Glow orbs
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
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestore
                  .collection('public_polls')
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
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.poll_outlined, size: 64, color: Colors.white30),
                        const SizedBox(height: 16),
                        const Text(
                          'No polls yet',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    children: [
                      ...docs.asMap().entries.map((entry) {
                        final data = entry.value.data();
                        final pollId = entry.value.id;
                        final title = (data['title'] ?? 'Untitled Poll').toString();
                        final description = (data['description'] ?? '').toString();
                        final options = List<String>.from(data['options'] ?? []);
                        final votes = Map<String, int>.from(data['votes'] ?? {});
                        final isOpen = data['isOpen'] ?? true;

                        // Calculate total votes
                        int totalVotes = votes.values.fold(0, (sum, val) => sum + val);

                        return _pollCard(
                          pollId: pollId,
                          title: title,
                          description: description,
                          options: options,
                          votes: votes,
                          totalVotes: totalVotes,
                          isOpen: isOpen,
                        );
                      }).toList(),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pollCard({
    required String pollId,
    required String title,
    required String description,
    required List<String> options,
    required Map<String, int> votes,
    required int totalVotes,
    required bool isOpen,
  }) {
    return FutureBuilder<bool>(
      future: _hasUserVotedOnPoll(pollId),
      builder: (context, snapshot) {
        final hasVoted = snapshot.data ?? false;
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB).withOpacity(0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0B1020),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF6B7A90),
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Status badge with vote status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOpen ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            color: isOpen ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasVoted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'VOTED',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Poll options with vote bars
                  ...options.asMap().entries.map((entry) {
                    String option = entry.value;
                    int voteCount = votes[option] ?? 0;
                    double percentage = totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  option,
                                  style: const TextStyle(
                                    color: Color(0xFF0B1020),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$voteCount votes',
                                style: const TextStyle(
                                  color: Color(0xFF6B7A90),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Stack(
                            children: [
                              // Background bar
                              Container(
                                width: double.infinity,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Vote bar
                              Container(
                                width: (MediaQuery.of(context).size.width - 56) * (percentage / 100),
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6C7CFF), Color(0xFF4DD0E1)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              // Percentage text
                              Center(
                                child: Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Color(0xFF0B1020),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Vote button
                          if (isOpen && !hasVoted)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: SizedBox(
                                width: double.infinity,
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      final user = _auth.currentUser;
                                      if (user == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Please login to vote')),
                                        );
                                        return;
                                      }

                                      // Record vote
                                      final currentVotes = votes[option] ?? 0;
                                      votes[option] = currentVotes + 1;

                                      await _firestore.collection('public_polls').doc(pollId).update({
                                        'votes': votes,
                                      });

                                      // Track that user voted on this poll
                                      await _firestore
                                          .collection('poll_votes')
                                          .doc('${pollId}_${user.uid}')
                                          .set({
                                        'pollId': pollId,
                                        'userId': user.uid,
                                        'userEmail': user.email,
                                        'option': option,
                                        'votedAt': FieldValue.serverTimestamp(),
                                      });

                                      if (mounted) {
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vote recorded!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C7CFF),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Vote',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (hasVoted)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: double.infinity,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.5),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'You already voted',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Total: $totalVotes votes',
                      style: const TextStyle(
                        color: Color(0xFF6B7A90),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

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
