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
  final Map<String, String> _selectedOptions = {};
  final Set<String> _submittingPollIds = <String>{};
  static const Color gradientStart = Color(0xFF6C7CFF);
  static const Color gradientEnd = Color(0xFF4DD0E1);
  static const Color pageTop = Color(0xFF0B1020);
  static const Color pageMid = Color(0xFF121A3A);
  static const Color pageBottom = Color(0xFF1B255A);
  static const Color glassText = Color(0xFFF5F7FB);
  static const Color glassSubtext = Color(0xFFB9C6DD);
  static const Color glassSurface = Color(0xFFF5F7FB);

  Future<String?> _getUserVoteOnPoll(String pollId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final voteDoc = await _firestore
          .collection('poll_votes')
          .doc('${pollId}_${user.uid}')
          .get();

      if (!voteDoc.exists) return null;

      final data = voteDoc.data();
      final option = data?['option'];
      return option is String && option.isNotEmpty ? option : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> _submitVote({
    required BuildContext context,
    required String pollId,
    required String option,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to vote')));
      return false;
    }

    setState(() {
      _submittingPollIds.add(pollId);
    });

    try {
      final pollRef = _firestore.collection('public_polls').doc(pollId);
      final voteRef = _firestore
          .collection('poll_votes')
          .doc('${pollId}_${user.uid}');
      String? previousOption;

      await _firestore.runTransaction((transaction) async {
        final pollSnapshot = await transaction.get(pollRef);
        if (!pollSnapshot.exists) {
          throw StateError('This poll is no longer available.');
        }

        final pollData = pollSnapshot.data() ?? <String, dynamic>{};
        if (pollData['isOpen'] != true) {
          throw StateError('This poll is closed.');
        }

        final existingVote = await transaction.get(voteRef);
        final existingVoteData = existingVote.data();
        previousOption = existingVoteData?['option'] as String?;

        if (previousOption == option) {
          throw StateError('This option is already selected.');
        }

        final updatedVotes = Map<String, dynamic>.from(
          pollData['votes'] ?? <String, dynamic>{},
        );

        if (previousOption != null && previousOption!.isNotEmpty) {
          final previousCount =
              (updatedVotes[previousOption] as num?)?.toInt() ?? 0;
          if (previousCount > 0) {
            updatedVotes[previousOption!] = previousCount - 1;
          }
        }

        final currentVotes = (updatedVotes[option] as num?)?.toInt() ?? 0;

        updatedVotes[option] = currentVotes + 1;

        transaction.update(pollRef, {'votes': updatedVotes});
        transaction.set(voteRef, {
          'pollId': pollId,
          'userId': user.uid,
          'userEmail': user.email,
          'option': option,
          'votedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        setState(() {
          _selectedOptions[pollId] = option;
        });
      }

      final feedback = previousOption == null
          ? 'Vote recorded!'
          : 'Vote updated!';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(feedback)));
      }

      return true;
    } catch (e) {
      final message = e is StateError
          ? e.message.toString() ?? 'Unable to record vote.'
          : 'Error: $e';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _submittingPollIds.remove(pollId);
        });
      }
    }
  }

  Future<void> _selectOptionAndSubmit({
    required BuildContext context,
    required String pollId,
    required String option,
    required String? currentOption,
    required bool isSubmitting,
  }) async {
    if (isSubmitting || option == currentOption) {
      return;
    }

    final previousSelection = _selectedOptions[pollId];

    setState(() {
      _selectedOptions[pollId] = option;
    });

    final success = await _submitVote(
      context: context,
      pollId: pollId,
      option: option,
    );

    if (!success && mounted) {
      setState(() {
        if (previousSelection == null) {
          _selectedOptions.remove(pollId);
        } else {
          _selectedOptions[pollId] = previousSelection;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        title: const Text('Public Polls'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
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

          // Glow orbs
          Positioned(top: -60, left: -40, child: _glowOrb(180, gradientStart)),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowOrb(220, gradientEnd),
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
                        Icon(
                          Icons.poll_outlined,
                          size: 64,
                          color: Colors.white30,
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Column(
                    children: [
                      ...docs.asMap().entries.map((entry) {
                        final data = entry.value.data();
                        final pollId = entry.value.id;
                        final title = (data['title'] ?? 'Untitled Poll')
                            .toString();
                        final description = (data['description'] ?? '')
                            .toString();
                        final options = List<String>.from(
                          data['options'] ?? [],
                        );
                        final votes = Map<String, int>.from(
                          data['votes'] ?? {},
                        );
                        final isOpen = data['isOpen'] ?? true;

                        // Calculate total votes
                        int totalVotes = votes.values.fold(
                          0,
                          (sum, val) => sum + val,
                        );

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
    return FutureBuilder<String?>(
      future: _getUserVoteOnPoll(pollId),
      builder: (context, snapshot) {
        final votedOption = snapshot.data;
        final hasVoted = votedOption != null;
        final selectedOption = _selectedOptions[pollId] ?? votedOption;
        final isSubmitting = _submittingPollIds.contains(pollId);

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: glassSurface.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
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
                      color: glassText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (description.isNotEmpty)
                    Text(
                      description,
                      style: const TextStyle(color: glassSubtext, fontSize: 13),
                    ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      _statusChip(
                        label: isOpen ? 'OPEN' : 'CLOSED',
                        textColor: isOpen ? Colors.green : Colors.red,
                        backgroundColor: isOpen
                            ? Colors.green.withOpacity(0.12)
                            : Colors.red.withOpacity(0.12),
                      ),
                      const SizedBox(width: 8),
                      if (hasVoted)
                        _statusChip(
                          label: 'VOTED',
                          textColor: Colors.blue,
                          backgroundColor: Colors.blue.withOpacity(0.12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (isOpen) ...[
                    ...options.map(
                      (option) => _buildSelectableOption(
                        context: context,
                        pollId: pollId,
                        option: option,
                        selectedOption: selectedOption,
                        voteCount: votes[option] ?? 0,
                        totalVotes: totalVotes,
                        currentOption: votedOption,
                        isSubmitting: isSubmitting,
                      ),
                    ),
                    if (hasVoted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          isSubmitting
                              ? 'Updating your vote...'
                              : 'Tap any option to change your vote instantly.',
                          style: const TextStyle(
                            color: glassSubtext,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ] else ...[
                    ...options.map(
                      (option) => _buildResultOption(
                        option: option,
                        voteCount: votes[option] ?? 0,
                        totalVotes: totalVotes,
                        isSelected: option == votedOption,
                      ),
                    ),
                    if (hasVoted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          'You voted for $votedOption',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Total: $totalVotes votes',
                      style: const TextStyle(
                        color: glassSubtext,
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

  Widget _buildSelectableOption({
    required BuildContext context,
    required String pollId,
    required String option,
    required String? selectedOption,
    required int voteCount,
    required int totalVotes,
    required String? currentOption,
    required bool isSubmitting,
  }) {
    final isSelected = selectedOption == option;
    final percentage = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _selectOptionAndSubmit(
            context: context,
            pollId: pollId,
            option: option,
            currentOption: currentOption,
            isSubmitting: isSubmitting,
          ),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.14)
                  : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? gradientEnd.withOpacity(0.75)
                    : Colors.white.withOpacity(0.10),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Radio<String>(
                      value: option,
                      groupValue: selectedOption,
                      activeColor: gradientEnd,
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.selected)
                            ? gradientEnd
                            : Colors.white54,
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        _selectOptionAndSubmit(
                          context: context,
                          pollId: pollId,
                          option: value,
                          currentOption: currentOption,
                          isSubmitting: isSubmitting,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: glassText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: glassSubtext,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 56, right: 2, bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(
                          height: 8,
                          color: Colors.white.withOpacity(0.08),
                        ),
                        FractionallySizedBox(
                          widthFactor: percentage.clamp(0.0, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [gradientStart, gradientEnd],
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildResultOption({
    required String option,
    required int voteCount,
    required int totalVotes,
    required bool isSelected,
  }) {
    final percentage = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? gradientEnd.withOpacity(0.55)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      color: glassText,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$voteCount votes',
                  style: const TextStyle(color: glassSubtext, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(height: 28, color: Colors.white.withOpacity(0.08)),
                  FractionallySizedBox(
                    widthFactor: percentage.clamp(0.0, 1.0),
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [gradientStart, gradientEnd],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: glassText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _statusChip({
    required String label,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
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
