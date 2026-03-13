import 'dart:ui';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CreateElectionPage extends StatefulWidget {
  const CreateElectionPage({super.key});

  @override
  State<CreateElectionPage> createState() => _CreateElectionPageState();
}

class _CandidateDraft {
  const _CandidateDraft({
    required this.candidateId,
    required this.name,
    required this.bio,
    required this.department,
    required this.semester,
    required this.manifesto,
    required this.photoBytes,
  });

  final String candidateId;
  final String name;
  final String bio;
  final String department;
  final String semester;
  final String manifesto;
  final Uint8List? photoBytes;
}

class _AddCandidateDialog extends StatefulWidget {
  const _AddCandidateDialog({
    required this.picker,
    required this.nextCandidateIndex,
  });

  final ImagePicker picker;
  final int nextCandidateIndex;

  @override
  State<_AddCandidateDialog> createState() => _AddCandidateDialogState();
}

class _AddCandidateDialogState extends State<_AddCandidateDialog> {
  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _glassSurface = Color(0xFFF5F7FB);

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _semesterController = TextEditingController();
  final _manifestoController = TextEditingController();

  Uint8List? _selectedPhotoBytes;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _semesterController.dispose();
    _manifestoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xFile = await widget.picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1000,
    );

    if (!mounted || xFile == null) return;

    final bytes = await xFile.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedPhotoBytes = bytes;
    });
  }

  void _addCandidate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Candidate name is required';
      });
      return;
    }

    Navigator.of(context).pop(
      _CandidateDraft(
        candidateId:
            '${DateTime.now().millisecondsSinceEpoch}_${widget.nextCandidateIndex}',
        name: name,
        bio: _bioController.text.trim(),
        department: _departmentController.text.trim(),
        semester: _semesterController.text.trim(),
        manifesto: _manifestoController.text.trim(),
        photoBytes: _selectedPhotoBytes,
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
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
      errorText: label == 'Candidate Name *' ? _nameError : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF121A3A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.22), width: 1),
      ),
      title: const Text('Add Candidate', style: TextStyle(color: _panelText)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white.withOpacity(0.14),
                backgroundImage: _selectedPhotoBytes != null
                    ? MemoryImage(_selectedPhotoBytes!)
                    : null,
                child: _selectedPhotoBytes == null
                    ? const Icon(
                        Icons.add_a_photo_outlined,
                        color: _panelText,
                        size: 24,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to add photo',
              style: TextStyle(color: _mutedText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: _panelText),
              onChanged: (_) {
                if (_nameError == null) return;
                setState(() {
                  _nameError = null;
                });
              },
              decoration: _dialogInputDecoration('Candidate Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _departmentController,
              style: const TextStyle(color: _panelText),
              decoration: _dialogInputDecoration('Department'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _semesterController,
              style: const TextStyle(color: _panelText),
              decoration: _dialogInputDecoration('Semester / Year'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: _panelText),
              maxLines: 2,
              decoration: _dialogInputDecoration('Bio'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _manifestoController,
              style: const TextStyle(color: _panelText),
              maxLines: 3,
              decoration: _dialogInputDecoration('Manifesto / Agenda'),
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
          onPressed: _addCandidate,
          child: const Text('Add', style: TextStyle(color: _panelText)),
        ),
      ],
    );
  }
}

class _CreateElectionPageState extends State<CreateElectionPage> {
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<_CandidateDraft> _candidates = [];
  String _selectedStatus = 'upcoming';
  bool _isSubmitting = false;

  static const Color _panelText = Color(0xFFF5F7FB);
  static const Color _mutedText = Color(0xFFB9C6DD);
  static const Color _glassSurface = Color(0xFFF5F7FB);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        title: const Text('Create Election'),
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
                  _buildElectionForm(),
                  const SizedBox(height: 16),
                  _buildCandidatesSection(),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _createElection,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSubmitting ? 'Creating...' : 'Create Election',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C7CFF),
                        elevation: 0,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.22),
                          width: 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElectionForm() {
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Election Details',
                style: TextStyle(
                  color: _panelText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: _panelText),
                decoration: _inputDecoration('Election Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: _panelText),
                maxLines: 3,
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                items: const ['upcoming', 'active', 'completed']
                    .map(
                      (status) => DropdownMenuItem<String>(
                        value: status,
                        child: Text(
                          status,
                          style: const TextStyle(color: _panelText),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value ?? 'upcoming';
                  });
                },
                style: const TextStyle(color: _panelText),
                dropdownColor: const Color(0xFF1B255A),
                iconEnabledColor: _mutedText,
                decoration: _inputDecoration('Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidatesSection() {
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Candidates',
                    style: TextStyle(
                      color: _panelText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddCandidateDialog,
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Add Candidate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DD0E1),
                      foregroundColor: const Color(0xFF0B1020),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_candidates.isEmpty)
                const Text(
                  'No candidates added yet. Use Add Candidate to include profile details and photo.',
                  style: TextStyle(color: _mutedText, fontSize: 13),
                )
              else
                ..._candidates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final candidate = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: candidate.photoBytes != null
                              ? MemoryImage(candidate.photoBytes!)
                              : null,
                          child: candidate.photoBytes == null
                              ? const Icon(
                                  Icons.person_outline,
                                  color: _panelText,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                candidate.name,
                                style: const TextStyle(
                                  color: _panelText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Department: ${candidate.department.isEmpty ? 'N/A' : candidate.department}',
                                style: const TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Semester: ${candidate.semester.isEmpty ? 'N/A' : candidate.semester}',
                                style: const TextStyle(
                                  color: _mutedText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove candidate',
                          onPressed: () {
                            setState(() {
                              _candidates.removeAt(index);
                            });
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddCandidateDialog() async {
    final candidateToAdd = await showDialog<_CandidateDraft>(
      context: context,
      builder: (_) => _AddCandidateDialog(
        picker: _picker,
        nextCandidateIndex: _candidates.length,
      ),
    );

    if (!mounted || candidateToAdd == null) return;

    setState(() {
      _candidates.add(candidateToAdd);
    });
  }

  Future<void> _createElection() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Election title is required')),
      );
      return;
    }

    if (_candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one candidate')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final electionRef = _firestore.collection('elections').doc();
      final candidatesPayload = <Map<String, dynamic>>[];

      for (var index = 0; index < _candidates.length; index++) {
        final candidate = _candidates[index];
        final photoBase64 = candidate.photoBytes == null
            ? ''
            : base64Encode(candidate.photoBytes!);

        candidatesPayload.add({
          'candidateId': candidate.candidateId,
          'name': candidate.name,
          'bio': candidate.bio,
          'department': candidate.department,
          'semester': candidate.semester,
          'manifesto': candidate.manifesto,
          'photoUrl': '',
          'photoPath': '',
          'photoBucket': '',
          'photoBase64': photoBase64,
          'votes': 0,
        });
      }

      await electionRef.set({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _selectedStatus,
        'resultsVisible': false,
        'candidates': candidatesPayload,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Election created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
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
