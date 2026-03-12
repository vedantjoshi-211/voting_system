import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _firestore = FirebaseFirestore.instance;

  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _glassSurface = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top actions arranged in two rows to keep labels fully visible.
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _showCreateElectionDialog,
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Create Election',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _glassSurface.withOpacity(0.14),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.22),
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _showAddAnnouncementDialog,
                            icon: const Icon(
                              Icons.announcement,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Announcement',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _glassSurface.withOpacity(0.14),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.22),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: _showCreatePollDialog,
                            icon: const Icon(
                              Icons.poll,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: const Text(
                              'Create Poll',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _glassSurface.withOpacity(0.14),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.22),
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Elections list header
                  const Text(
                    'Active Elections',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Elections ListView
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('elections')
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
                          child: Text(
                            'No elections yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final electionId = docs[index].id;
                          final title = (data['title'] ?? 'Untitled')
                              .toString();
                          final status = (data['status'] ?? 'upcoming')
                              .toString();
                          final candidates =
                              (data['candidates'] as List?)?.length ?? 0;
                          final resultsVisible =
                              data['resultsVisible'] ?? false;

                          return _electionCard(
                            electionId: electionId,
                            title: title,
                            status: status,
                            candidateCount: candidates,
                            resultsVisible: resultsVisible,
                            onEdit: () {
                              _showEditElectionDialog(electionId, data);
                            },
                            onDelete: () {
                              _showDeleteConfirmation(electionId);
                            },
                            onToggleResults: () {
                              _toggleResultsVisibility(
                                electionId,
                                resultsVisible,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Announcements header
                  const Text(
                    'Announcements',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Announcements ListView
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('announcements')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Error: \${snap.error}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        );
                      }
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No announcements yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final announcementId = docs[index].id;
                          final title = (data['title'] ?? 'Untitled').toString();
                          final message = (data['message'] ?? '').toString();

                          return _announcementManagementCard(
                            announcementId: announcementId,
                            title: title,
                            message: message,
                            onEdit: () {
                              _showEditAnnouncementDialog(announcementId, data);
                            },
                            onDelete: () {
                              _showDeleteAnnouncementConfirmation(announcementId);
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  // Public Polls header
                  const Text(
                    'Public Polls',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Public Polls ListView
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                          child: Text(
                            'No polls yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          final pollId = docs[index].id;
                          final title = (data['title'] ?? 'Untitled')
                              .toString();
                          final description = (data['description'] ?? '')
                              .toString();
                          final options = List<String>.from(
                            data['options'] ?? [],
                          );
                          final isOpen = data['isOpen'] ?? true;
                          final votes = Map<String, int>.from(
                            data['votes'] ?? {},
                          );
                          final totalVotes = votes.values.fold(
                            0,
                            (sum, val) => sum + val,
                          );

                          return _pollManagementCard(
                            pollId: pollId,
                            title: title,
                            description: description,
                            optionCount: options.length,
                            totalVotes: totalVotes,
                            isOpen: isOpen,
                            onDelete: () {
                              _showDeletePollConfirmation(pollId);
                            },
                            onToggleStatus: () {
                              _togglePollStatus(pollId, isOpen);
                            },
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleResultsVisibility(String electionId, bool current) async {
    try {
      await _firestore.collection('elections').doc(electionId).update({
        'resultsVisible': !current,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !current
                ? 'Results published to voters'
                : 'Results hidden from voters',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _togglePollStatus(String pollId, bool current) async {
    try {
      await _firestore.collection('public_polls').doc(pollId).update({
        'isOpen': !current,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(!current ? 'Poll opened' : 'Poll closed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _electionCard({
    required String electionId,
    required String title,
    required String status,
    required int candidateCount,
    required bool resultsVisible,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onToggleResults,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _glassSurface.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _panelText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? Colors.green.withOpacity(0.12)
                          : Colors.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: status == 'active'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Candidates: $candidateCount',
                style: const TextStyle(color: _mutedText, fontSize: 13),
              ),
              const SizedBox(height: 12),

              // Primary actions row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Edit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C7CFF),
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Result visibility gets a full-width row so text is never clipped.
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onToggleResults,
                  icon: Icon(
                    resultsVisible ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    resultsVisible ? 'Hide Results' : 'Show Results',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resultsVisible
                        ? Colors.orange
                        : const Color(0xFF6C7CFF),
                    elevation: 0,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.22),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pollManagementCard({
    required String pollId,
    required String title,
    required String description,
    required int optionCount,
    required int totalVotes,
    required bool isOpen,
    required VoidCallback onDelete,
    required VoidCallback onToggleStatus,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _glassSurface.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _panelText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12),
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
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Options: $optionCount | Votes: $totalVotes',
                style: const TextStyle(color: _mutedText, fontSize: 13),
              ),
              const SizedBox(height: 12),

              if (description.isNotEmpty)
                Text(
                  description,
                  style: const TextStyle(color: _mutedText, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onToggleStatus,
                        icon: Icon(
                          isOpen ? Icons.lock : Icons.lock_open,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: Text(
                          isOpen ? 'Close Poll' : 'Open Poll',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOpen
                              ? Colors.orange
                              : Colors.green,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateElectionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final candidatesController = TextEditingController();
    String selectedStatus = 'upcoming';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Create Election',
          style: TextStyle(color: _panelText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Election Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: candidatesController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration(
                  'Candidates (comma-separated, e.g. John, Jane, Mike)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['upcoming', 'active', 'completed']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(color: _panelText),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value ?? 'upcoming';
                },
                style: const TextStyle(color: _panelText),
                dropdownColor: const Color(0xFF1B255A),
                iconEnabledColor: _mutedText,
                decoration: _inputDecoration('Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  candidatesController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all required fields')),
                );
                return;
              }

              List<String> candidateNames = candidatesController.text
                  .split(',')
                  .map((name) => name.trim())
                  .toList();
              List<Map<String, dynamic>>
              candidates = candidateNames.asMap().entries.map((entry) {
                return {
                  'candidateId':
                      '${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
                  'name': entry.value,
                  'votes': 0,
                };
              }).toList();

              try {
                await _firestore.collection('elections').add({
                  'title': titleController.text,
                  'description': descController.text,
                  'status': selectedStatus,
                  'resultsVisible': false,
                  'candidates': candidates,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Election created successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create', style: TextStyle(color: _panelText)),
          ),
        ],
      ),
    );
  }

  void _showEditElectionDialog(String electionId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final descController = TextEditingController(text: data['description']);
    String selectedStatus = data['status'] ?? 'upcoming';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text('Edit Election', style: TextStyle(color: _panelText)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Election Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                items: ['upcoming', 'active', 'completed']
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(color: _panelText),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  selectedStatus = value ?? 'upcoming';
                },
                style: const TextStyle(color: _panelText),
                dropdownColor: const Color(0xFF1B255A),
                iconEnabledColor: _mutedText,
                decoration: _inputDecoration('Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('elections')
                    .doc(electionId)
                    .update({
                      'title': titleController.text,
                      'description': descController.text,
                      'status': selectedStatus,
                    });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Election updated successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Update', style: TextStyle(color: _panelText)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String electionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Delete Election',
          style: TextStyle(color: _panelText),
        ),
        content: const Text(
          'Are you sure you want to delete this election?',
          style: TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('elections')
                    .doc(electionId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Election deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAnnouncementDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Add Announcement',
          style: TextStyle(color: _panelText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Message'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty || bodyController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all fields')),
                );
                return;
              }
              try {
                await _firestore.collection('announcements').add({
                  'title': titleController.text,
                  'message': bodyController.text,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement added')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Add', style: TextStyle(color: _panelText)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _mutedText),
      hintStyle: const TextStyle(color: _mutedText),
      filled: true,
      fillColor: _glassSurface.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF4DD0E1), width: 1.3),
      ),
    );
  }

  Widget _announcementManagementCard({
    required String announcementId,
    required String title,
    required String message,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _glassSurface.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _panelText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (message.isNotEmpty) ...
                [
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(color: _mutedText, fontSize: 13),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        label: const Text(
                          'Edit',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C7CFF),
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          elevation: 0,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.22),
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditAnnouncementDialog(String announcementId, Map<String, dynamic> data) {
    final titleController = TextEditingController(text: data['title']);
    final messageController = TextEditingController(text: data['message']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Edit Announcement',
          style: TextStyle(color: _panelText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Message'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty || messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all fields')),
                );
                return;
              }
              try {
                await _firestore
                    .collection('announcements')
                    .doc(announcementId)
                    .update({
                      'title': titleController.text,
                      'message': messageController.text,
                    });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement updated')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: \$e')));
              }
            },
            child: const Text('Update', style: TextStyle(color: _panelText)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAnnouncementConfirmation(String announcementId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Delete Announcement',
          style: TextStyle(color: _panelText),
        ),
        content: const Text(
          'Are you sure you want to delete this announcement?',
          style: TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('announcements')
                    .doc(announcementId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement deleted')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: \$e')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePollDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final optionsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text(
          'Create Public Poll',
          style: TextStyle(color: _panelText),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Poll Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Description (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: optionsController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration(
                  'Poll Options (comma-separated, e.g. Option A, Option B, Option C)',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  optionsController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fill all required fields')),
                );
                return;
              }

              List<String> options = optionsController.text
                  .split(',')
                  .map((opt) => opt.trim())
                  .toList();
              Map<String, int> votes = {};
              for (var option in options) {
                votes[option] = 0;
              }

              try {
                await _firestore.collection('public_polls').add({
                  'title': titleController.text,
                  'description': descController.text,
                  'options': options,
                  'votes': votes,
                  'isOpen': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Poll created successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create', style: TextStyle(color: _panelText)),
          ),
        ],
      ),
    );
  }

  void _showDeletePollConfirmation(String pollId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121A3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
        ),
        title: const Text('Delete Poll', style: TextStyle(color: _panelText)),
        content: const Text(
          'Are you sure you want to delete this poll?',
          style: TextStyle(color: _mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _mutedText)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('public_polls')
                    .doc(pollId)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Poll deleted')));
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
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
