import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ElectionsPage extends StatefulWidget {
  final String? electionId;
  const ElectionsPage({super.key, this.electionId});

  @override
  State<ElectionsPage> createState() => _ElectionsPageState();
}

class _ElectionsPageState extends State<ElectionsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final Map<String, String> _photoUrlCache = {};
  final Map<String, Uint8List> _photoBytesCache = {};
  static const Color gradientStart = Color(0xFF6C7CFF);
  static const Color gradientEnd = Color(0xFF4DD0E1);
  static const Color pageTop = Color(0xFF0B1020);
  static const Color pageMid = Color(0xFF121A3A);
  static const Color pageBottom = Color(0xFF1B255A);
  static const Color glassText = Color(0xFFF5F7FB);
  static const Color glassSubtext = Color(0xFFB9C6DD);
  static const Color glassSurface = Color(0xFFF5F7FB);

  int _epochMillisFromDoc(Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    if (createdAt is Timestamp) {
      return createdAt.millisecondsSinceEpoch;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageTop,
      appBar: AppBar(
        title: const Text('Elections'),
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
          /// Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [pageTop, pageMid, pageBottom],
              ),
            ),
          ),

          /// Glow Orbs
          Positioned(top: -60, left: -40, child: _glowOrb(180, gradientStart)),
          Positioned(
            bottom: -80,
            right: -60,
            child: _glowOrb(220, gradientEnd),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      future: _firestore.collection('elections').doc(widget.electionId).get(),
      builder: (context, docSnap) {
        if (docSnap.hasError) {
          return Center(
            child: Text(
              'Error: ${docSnap.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (docSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final doc = docSnap.data;
        if (doc == null || !doc.exists) {
          return const Center(
            child: Text(
              'Election not found',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final data = doc.data() ?? {};
        final title = (data['title'] ?? 'Untitled').toString();
        final description = (data['description'] ?? '').toString();
        final candidates =
            (data['candidates'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final isVotingClosed = _isVotingClosed(data);

        return ListView(
          children: [
            _electionCard(
              electionId: doc.id,
              title: title,
              description: description,
              candidates: candidates,
              isVotingClosed: isVotingClosed,
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
            child: Text(
              'Error: ${snap.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = [...(snap.data?.docs ?? [])];
        docs.sort((a, b) {
          final aMillis = _epochMillisFromDoc(a.data());
          final bMillis = _epochMillisFromDoc(b.data());
          return bMillis.compareTo(aMillis);
        });

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No active elections',
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
            final description = (data['description'] ?? '').toString();
            final candidates =
                (data['candidates'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
            final isVotingClosed = _isVotingClosed(data);

            return _electionCard(
              electionId: electionId,
              title: title,
              description: description,
              candidates: candidates,
              isVotingClosed: isVotingClosed,
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
    required bool isVotingClosed,
  }) {
    final userId = _auth.currentUser?.uid;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
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
              Text(
                title,
                style: const TextStyle(
                  color: glassText,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: glassSubtext, fontSize: 13),
              ),
              const SizedBox(height: 16),

              if (isVotingClosed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.35),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.orangeAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Results declared. Voting is closed for this election.',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Candidates:',
                  style: TextStyle(
                    color: glassText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...candidates.asMap().entries.map((entry) {
                  final index = entry.key;
                  final candidateMap = Map<String, dynamic>.from(entry.value);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        _candidateAvatar(
                          candidateMap,
                          electionId: electionId,
                          candidateIndex: index,
                          radius: 19,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (candidateMap['name'] ?? 'Unknown').toString(),
                            style: const TextStyle(
                              color: glassSubtext,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCandidateDetails(
                            candidateMap,
                            electionId: electionId,
                            candidateIndex: index,
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: glassSubtext,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                          ),
                          icon: const Icon(Icons.info_outline, size: 15),
                          label: const Text('More Info'),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ] else
                FutureBuilder<bool>(
                  future: userId == null
                      ? Future.value(false)
                      : _firestore
                            .collection('votes')
                            .where('userId', isEqualTo: userId)
                            .where('electionId', isEqualTo: electionId)
                            .limit(1)
                            .get()
                            .then((snap) => snap.docs.isNotEmpty),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final hasVoted = snap.data ?? false;

                    if (hasVoted) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.greenAccent.withOpacity(0.35),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.greenAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You have already voted in this election',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Candidates:',
                            style: TextStyle(
                              color: glassText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...candidates.asMap().entries.map((entry) {
                            final index = entry.key;
                            final candidateMap = Map<String, dynamic>.from(
                              entry.value,
                            );
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  _candidateAvatar(
                                    candidateMap,
                                    electionId: electionId,
                                    candidateIndex: index,
                                    radius: 19,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      (candidateMap['name'] ?? 'Unknown')
                                          .toString(),
                                      style: const TextStyle(
                                        color: glassSubtext,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showCandidateDetails(
                                      candidateMap,
                                      electionId: electionId,
                                      candidateIndex: index,
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: glassSubtext,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.info_outline,
                                      size: 15,
                                    ),
                                    label: const Text('More Info'),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Candidate:',
                          style: TextStyle(
                            color: glassText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...candidates.asMap().entries.map((entry) {
                          final index = entry.key;
                          final candidateMap = Map<String, dynamic>.from(
                            entry.value,
                          );
                          final candidateName =
                              (candidateMap['name'] ?? 'Unknown').toString();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _candidateAvatar(
                                      candidateMap,
                                      electionId: electionId,
                                      candidateIndex: index,
                                      radius: 19,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        candidateName,
                                        style: const TextStyle(
                                          color: glassText,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _showCandidateDetails(
                                          candidateMap,
                                          electionId: electionId,
                                          candidateIndex: index,
                                        ),
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                        ),
                                        label: const Text('More Info'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: glassSubtext,
                                          side: BorderSide(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          final confirmed = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              backgroundColor: const Color(
                                                0xFF1B255A,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: const Text(
                                                'Confirm Vote',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              content: Text(
                                                'You are voting for $candidateName',
                                                style: const TextStyle(
                                                  color: Color(0xFFB9C6DD),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(false),
                                                  child: const Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                      color: Color(0xFFB9C6DD),
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF6C7CFF),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(true),
                                                  child: const Text(
                                                    'Yes, Vote',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirmed == true) {
                                            _handleVote(
                                              electionId,
                                              candidateMap['candidateId']
                                                  .toString(),
                                              candidateName,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.how_to_vote_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Vote'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: gradientStart,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _candidateCacheKey(Map<String, dynamic> candidate) {
    final id = (candidate['candidateId'] ?? '').toString();
    final path = (candidate['photoPath'] ?? '').toString();
    final bucket = (candidate['photoBucket'] ?? '').toString();
    if (id.isNotEmpty && bucket.isNotEmpty) return '$id@$bucket';
    if (id.isNotEmpty) return id;
    if (path.isNotEmpty) return path;
    return (candidate['name'] ?? '').toString();
  }

  Uint8List? _candidateBytesFromBase64(Map<String, dynamic> candidate) {
    final cacheKey = _candidateCacheKey(candidate);
    final cached = _photoBytesCache[cacheKey];
    if (cached != null) return cached;

    final photoBase64 = (candidate['photoBase64'] ?? '').toString();
    if (photoBase64.isEmpty) return null;

    try {
      final bytes = base64Decode(photoBase64);
      _photoBytesCache[cacheKey] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  String _normalizeBucket(String bucket) {
    if (bucket.startsWith('gs://')) {
      return bucket.replaceFirst('gs://', '');
    }
    return bucket;
  }

  List<String> _candidateBucketsForRead(Map<String, dynamic> candidate) {
    final fromDoc = _normalizeBucket(
      (candidate['photoBucket'] ?? '').toString(),
    );
    final configured = _normalizeBucket(
      _firestore.app.options.storageBucket ?? '',
    );
    final projectId = _firestore.app.options.projectId;
    final appspotBucket = projectId.isEmpty ? '' : '$projectId.appspot.com';

    final buckets = <String>[];
    if (fromDoc.isNotEmpty) buckets.add(fromDoc);
    if (configured.isNotEmpty && !buckets.contains(configured)) {
      buckets.add(configured);
    }
    if (appspotBucket.isNotEmpty && !buckets.contains(appspotBucket)) {
      buckets.add(appspotBucket);
    }

    return buckets;
  }

  Future<String> _resolveCandidatePhotoUrl({
    required Map<String, dynamic> candidate,
    required String electionId,
    required int candidateIndex,
  }) async {
    final directUrl = (candidate['photoUrl'] ?? '').toString();
    if (directUrl.isNotEmpty) return directUrl;

    final cacheKey = _candidateCacheKey(candidate);
    final cached = _photoUrlCache[cacheKey];
    if (cached != null && cached.isNotEmpty) return cached;

    var photoPath = (candidate['photoPath'] ?? '').toString();
    if (photoPath.isEmpty) {
      final candidateId = (candidate['candidateId'] ?? '').toString();
      if (candidateId.isNotEmpty) {
        photoPath =
            'elections/$electionId/candidates/${candidateId}_$candidateIndex.jpg';
      }
    }
    if (photoPath.isEmpty) return '';

    try {
      const retryDelays = [
        Duration(milliseconds: 250),
        Duration(milliseconds: 650),
        Duration(milliseconds: 1200),
      ];

      final buckets = _candidateBucketsForRead(candidate);

      for (final bucket in buckets) {
        final storage = FirebaseStorage.instanceFor(bucket: 'gs://$bucket');

        for (var attempt = 0; attempt < retryDelays.length; attempt++) {
          try {
            final resolved = await storage
                .ref()
                .child(photoPath)
                .getDownloadURL();
            _photoUrlCache[cacheKey] = resolved;
            return resolved;
          } on FirebaseException catch (e) {
            final isLastAttempt = attempt == retryDelays.length - 1;
            if (e.code != 'object-not-found' || isLastAttempt) {
              rethrow;
            }
            await Future.delayed(retryDelays[attempt]);
          }
        }
      }

      return '';
    } on FirebaseException catch (e) {
      debugPrint(
        'Candidate photo resolve failed for path "$photoPath": ${e.code} ${e.message ?? ''}',
      );
      return '';
    } catch (_) {
      return '';
    }
  }

  Widget _candidateAvatar(
    Map<String, dynamic> candidate, {
    required String electionId,
    required int candidateIndex,
    double radius = 20,
  }) {
    final directUrl = (candidate['photoUrl'] ?? '').toString();
    final fallbackName = (candidate['name'] ?? 'C').toString();
    final base64Bytes = _candidateBytesFromBase64(candidate);

    Widget initialsAvatar() {
      final initials = fallbackName.isEmpty
          ? 'C'
          : fallbackName.trim().split(RegExp(r'\s+')).take(2).map((part) {
              if (part.isEmpty) return '';
              return part[0].toUpperCase();
            }).join();

      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(0.14),
        child: Text(
          initials.isEmpty ? 'C' : initials,
          style: const TextStyle(
            color: glassText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
    }

    Widget networkAvatar(String url) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(0.14),
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }

    Widget memoryAvatar(Uint8List bytes) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white.withOpacity(0.14),
        backgroundImage: MemoryImage(bytes),
      );
    }

    if (base64Bytes != null) {
      return memoryAvatar(base64Bytes);
    }

    if (directUrl.isNotEmpty) {
      return networkAvatar(directUrl);
    }

    return FutureBuilder<String>(
      future: _resolveCandidatePhotoUrl(
        candidate: candidate,
        electionId: electionId,
        candidateIndex: candidateIndex,
      ),
      builder: (context, snap) {
        final resolvedUrl = snap.data ?? '';
        if (resolvedUrl.isNotEmpty) {
          return networkAvatar(resolvedUrl);
        }
        return initialsAvatar();
      },
    );
  }

  Future<void> _showCandidateDetails(
    Map<String, dynamic> candidate, {
    required String electionId,
    required int candidateIndex,
  }) async {
    final name = (candidate['name'] ?? 'Unknown').toString();
    final department = (candidate['department'] ?? 'N/A').toString();
    final semester = (candidate['semester'] ?? 'N/A').toString();
    final bio = (candidate['bio'] ?? '').toString();
    final manifesto = (candidate['manifesto'] ?? '').toString();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121A3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Candidate Details',
            style: TextStyle(color: glassText, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: _candidateAvatar(
                    candidate,
                    electionId: electionId,
                    candidateIndex: candidateIndex,
                    radius: 44,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  style: const TextStyle(
                    color: glassText,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Department: $department',
                  style: const TextStyle(color: glassSubtext, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semester: $semester',
                  style: const TextStyle(color: glassSubtext, fontSize: 14),
                ),
                if (bio.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Bio',
                    style: TextStyle(
                      color: glassText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bio,
                    style: const TextStyle(color: glassSubtext, fontSize: 14),
                  ),
                ],
                if (manifesto.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Manifesto',
                    style: TextStyle(
                      color: glassText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    manifesto,
                    style: const TextStyle(color: glassSubtext, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Color(0xFFB9C6DD)),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ================= VOTING LOGIC =================
  Future<void> _handleVote(
    String electionId,
    String candidateId,
    String candidateName,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final electionDoc = await _firestore
          .collection('elections')
          .doc(electionId)
          .get();

      final electionData = electionDoc.data() ?? <String, dynamic>{};
      if (_isVotingClosed(electionData)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Results have been declared. Voting is closed.'),
          ),
        );
        return;
      }

      final userVotesSnapshot = await _firestore
          .collection('votes')
          .where('userId', isEqualTo: userId)
          .get();

      final existingVoteDocs = userVotesSnapshot.docs.where(
        (d) => (d.data()['electionId'] ?? '') == electionId,
      );

      if (existingVoteDocs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already voted in this election'),
          ),
        );
        return;
      }

      await _firestore.collection('votes').add({
        'electionId': electionId,
        'userId': userId,
        'candidateId': candidateId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final List candidates =
          (electionDoc.data()?['candidates'] as List?) ?? [];

      for (var candidate in candidates) {
        if (candidate['candidateId'] == candidateId) {
          candidate['votes'] = (candidate['votes'] ?? 0) + 1;
        }
      }

      await _firestore.collection('elections').doc(electionId).update({
        'candidates': candidates,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vote cast for $candidateName successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// ================= GLOW ORB =================
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

  bool _isVotingClosed(Map<String, dynamic> electionData) {
    final status = (electionData['status'] ?? '').toString().toLowerCase();
    const closedStatuses = {'closed', 'completed', 'ended', 'result_declared'};
    return electionData['resultsVisible'] == true ||
        closedStatuses.contains(status);
  }
}
