import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class _CandidateResult {
  const _CandidateResult({
    required this.candidateId,
    required this.name,
    required this.votes,
  });

  final String candidateId;
  final String name;
  final int votes;
}

class _ElectionReportData {
  const _ElectionReportData({
    required this.electionId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.candidates,
    required this.winners,
    required this.totalVotes,
    required this.topVotes,
    required this.runnerUpVotes,
  });

  final String electionId;
  final String title;
  final String description;
  final DateTime? createdAt;
  final List<_CandidateResult> candidates;
  final List<_CandidateResult> winners;
  final int totalVotes;
  final int topVotes;
  final int runnerUpVotes;

  bool get hasVotes => totalVotes > 0;
  bool get hasSingleWinner => winners.length == 1 && topVotes > 0;
  bool get hasTie => winners.length > 1 && topVotes > 0;
  int get winningMargin => hasSingleWinner ? topVotes - runnerUpVotes : 0;
  double get winningShare => hasVotes ? (topVotes / totalVotes) * 100 : 0;
}

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _reportChannel = MethodChannel(
    'com.example.voting_system/reports',
  );
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
                      final createdAt = (data['createdAt'] as Timestamp?)
                          ?.toDate();
                      final candidatesData = _extractCandidates(
                        data['candidates'],
                      );

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('votes')
                            .where('electionId', isEqualTo: electionId)
                            .snapshots(),
                        builder: (context, voteSnap) {
                          if (voteSnap.hasError) {
                            return _buildResultCard(
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
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Unable to load result details for this election.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (voteSnap.connectionState ==
                              ConnectionState.waiting) {
                            return _buildResultCard(
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
                                  const SizedBox(height: 18),
                                  const Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

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

                          final candidateList = <_CandidateResult>[];

                          for (var candidate in candidatesData) {
                            final candId = candidate['candidateId']?.toString();
                            final candName =
                                candidate['name']?.toString() ?? 'Unknown';

                            final votes =
                                (candId != null ? voteCount[candId] : 0) ?? 0;

                            candidateList.add(
                              _CandidateResult(
                                candidateId: candId ?? '',
                                name: candName,
                                votes: votes,
                              ),
                            );
                          }

                          candidateList.sort((a, b) {
                            final voteCompare = b.votes.compareTo(a.votes);
                            if (voteCompare != 0) return voteCompare;
                            return a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            );
                          });

                          int maxVotes = 0;
                          for (var cand in candidateList) {
                            final v = cand.votes;
                            if (v > maxVotes) maxVotes = v;
                          }

                          final List<_CandidateResult> winners = maxVotes > 0
                              ? candidateList
                                    .where(
                                      (candidate) =>
                                          candidate.votes == maxVotes,
                                    )
                                    .toList()
                              : <_CandidateResult>[];

                          final runnerUpVotes = candidateList
                              .where((candidate) => candidate.votes < maxVotes)
                              .fold<int>(
                                0,
                                (highest, candidate) =>
                                    candidate.votes > highest
                                    ? candidate.votes
                                    : highest,
                              );

                          final totalVotes = candidateList.fold<int>(
                            0,
                            (sum, candidate) => sum + candidate.votes,
                          );

                          final reportData = _ElectionReportData(
                            electionId: electionId,
                            title: title,
                            description: description,
                            createdAt: createdAt,
                            candidates: candidateList,
                            winners: winners,
                            totalVotes: totalVotes,
                            topVotes: maxVotes,
                            runnerUpVotes: runnerUpVotes,
                          );

                          return _buildResultCard(
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
                                _buildResultBanner(reportData),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildInfoChip(
                                      icon: Icons.groups_outlined,
                                      label:
                                          '${reportData.candidates.length} Candidates',
                                    ),
                                    _buildInfoChip(
                                      icon: Icons.how_to_vote_outlined,
                                      label:
                                          '${reportData.totalVotes} Total Votes',
                                    ),
                                    _buildInfoChip(
                                      icon: reportData.hasSingleWinner
                                          ? Icons.verified_outlined
                                          : reportData.hasTie
                                          ? Icons.balance_outlined
                                          : Icons.info_outline,
                                      label: reportData.hasSingleWinner
                                          ? 'Winner Declared'
                                          : reportData.hasTie
                                          ? 'Tie Result'
                                          : 'No Votes Yet',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        _showReportSheet(context, reportData),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: gradientStart,
                                      foregroundColor: glassText,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.description_outlined,
                                    ),
                                    label: const Text(
                                      'Generate Report',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

  List<Map<String, dynamic>> _extractCandidates(dynamic rawCandidates) {
    if (rawCandidates is! List) return const [];

    return rawCandidates
        .map((candidate) {
          if (candidate is Map<String, dynamic>) {
            return candidate;
          }
          if (candidate is Map) {
            return candidate.map(
              (key, value) => MapEntry(key.toString(), value),
            );
          }
          return <String, dynamic>{};
        })
        .where((candidate) => candidate.isNotEmpty)
        .toList();
  }

  Widget _buildResultCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: glassSurface.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildResultBanner(_ElectionReportData reportData) {
    if (!reportData.hasVotes) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text(
          'No votes cast yet. Generate the report to view election details.',
          style: TextStyle(color: glassSubtext, fontSize: 13),
        ),
      );
    }

    if (reportData.hasSingleWinner) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.65)),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Color(0xFF80FF9E), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'WINNER: ${reportData.winners.first.name.toUpperCase()}',
                style: const TextStyle(
                  color: Color(0xFF80FF9E),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.70)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: Color(0xFFFFA6A6), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TIE: ${reportData.winners.map((winner) => winner.name).join(', ').toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFFFFA6A6),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: glassSubtext),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: glassText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportSheet(
    BuildContext context,
    _ElectionReportData reportData,
  ) async {
    final generatedAt = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [pageTop, pageMid, pageBottom],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: gradientStart.withOpacity(0.20),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.assessment_outlined,
                                  color: glassText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Election Result Report',
                                      style: TextStyle(
                                        color: glassText,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Generated on ${_formatDateTime(generatedAt)}',
                                      style: const TextStyle(
                                        color: glassSubtext,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _buildReportSection(
                            title: reportData.title,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (reportData.description.isNotEmpty)
                                  Text(
                                    reportData.description,
                                    style: const TextStyle(
                                      color: glassSubtext,
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  )
                                else
                                  const Text(
                                    'No election description was provided.',
                                    style: TextStyle(
                                      color: glassSubtext,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    _buildReportMetric(
                                      'Status',
                                      reportData.hasSingleWinner
                                          ? 'Winner Declared'
                                          : reportData.hasTie
                                          ? 'Tie Result'
                                          : 'No Votes Cast',
                                    ),
                                    _buildReportMetric(
                                      'Candidates',
                                      '${reportData.candidates.length}',
                                    ),
                                    _buildReportMetric(
                                      'Total Votes',
                                      '${reportData.totalVotes}',
                                    ),
                                    _buildReportMetric(
                                      'Created',
                                      reportData.createdAt != null
                                          ? _formatDateTime(
                                              reportData.createdAt!,
                                            )
                                          : 'Not Available',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildReportSection(
                            title: 'Outcome Summary',
                            child: _buildOutcomeSummary(reportData),
                          ),
                          const SizedBox(height: 16),
                          _buildReportSection(
                            title: 'Candidate Ranking',
                            child: Column(
                              children: reportData.candidates.isEmpty
                                  ? [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          'No candidate records are available for this election.',
                                          style: TextStyle(
                                            color: glassSubtext,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ]
                                  : reportData.candidates
                                        .asMap()
                                        .entries
                                        .map(
                                          (entry) => _buildCandidateRow(
                                            rank: entry.key + 1,
                                            candidate: entry.value,
                                            isHighlighted: reportData.winners
                                                .any(
                                                  (winner) =>
                                                      winner.candidateId ==
                                                      entry.value.candidateId,
                                                ),
                                          ),
                                        )
                                        .toList(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildReportSection(
                            title: 'Report Notes',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNoteLine(
                                  'Report ID: ${reportData.electionId}',
                                ),
                                _buildNoteLine(
                                  'This report is auto-generated from the published election results currently stored in Firestore.',
                                ),
                                _buildNoteLine(
                                  reportData.hasTie
                                      ? 'A tie means more than one candidate finished with the same highest vote total.'
                                      : reportData.hasSingleWinner
                                      ? 'Winning margin is calculated against the next highest vote total.'
                                      : 'A winner cannot be declared until at least one vote is recorded.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);

                              try {
                                final savedLocation = await _downloadPdfReport(
                                  reportData,
                                  generatedAt,
                                );

                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      savedLocation == null ||
                                              savedLocation.isEmpty
                                          ? 'PDF report generated'
                                          : 'PDF saved to $savedLocation',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!mounted) return;
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Unable to generate PDF report: $error',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: gradientStart,
                              foregroundColor: glassText,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.download_outlined),
                            label: const Text('Download PDF'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: _buildPlainTextReport(
                                    reportData,
                                    generatedAt,
                                  ),
                                ),
                              );

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report copied to clipboard'),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: glassText,
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.25),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.copy_all_outlined),
                            label: const Text('Copy Report'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: gradientEnd,
                              foregroundColor: pageTop,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Close'),
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
      },
    );
  }

  Widget _buildReportSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildReportMetric(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: glassSubtext,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: glassText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutcomeSummary(_ElectionReportData reportData) {
    if (!reportData.hasVotes) {
      return const Text(
        'No votes have been cast for this election, so no winning candidate can be declared yet.',
        style: TextStyle(color: glassSubtext, fontSize: 14, height: 1.5),
      );
    }

    if (reportData.hasTie) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The election ended in a tie between ${reportData.winners.map((winner) => winner.name).join(', ')} with ${reportData.topVotes} votes each.',
            style: const TextStyle(color: glassText, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildReportMetric('Leading Votes', '${reportData.topVotes}'),
              _buildReportMetric(
                'Winning Share',
                '${reportData.winningShare.toStringAsFixed(1)}%',
              ),
            ],
          ),
        ],
      );
    }

    final winner = reportData.winners.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${winner.name} won this election with ${winner.votes} votes.',
          style: const TextStyle(
            color: glassText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The candidate secured ${reportData.winningShare.toStringAsFixed(1)}% of all recorded votes and finished ${reportData.winningMargin} votes ahead of the next candidate.',
          style: const TextStyle(
            color: glassSubtext,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildReportMetric('Winner', winner.name),
            _buildReportMetric('Winning Votes', '${winner.votes}'),
            _buildReportMetric(
              'Runner-up Votes',
              '${reportData.runnerUpVotes}',
            ),
            _buildReportMetric('Winning Margin', '${reportData.winningMargin}'),
          ],
        ),
      ],
    );
  }

  Widget _buildCandidateRow({
    required int rank,
    required _CandidateResult candidate,
    required bool isHighlighted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? Colors.green.withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? Colors.green.withOpacity(0.40)
              : Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: glassText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate.name,
                  style: TextStyle(
                    color: isHighlighted ? const Color(0xFF80FF9E) : glassText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isHighlighted ? 'Top performer' : 'Candidate',
                  style: const TextStyle(color: glassSubtext, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${candidate.votes} votes',
            style: TextStyle(
              color: isHighlighted ? const Color(0xFF80FF9E) : glassSubtext,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: glassSubtext),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: glassSubtext,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _buildPlainTextReport(
    _ElectionReportData reportData,
    DateTime generatedAt,
  ) {
    final buffer = StringBuffer()
      ..writeln('Election Result Report')
      ..writeln('Generated: ${_formatDateTime(generatedAt)}')
      ..writeln('Election: ${reportData.title}')
      ..writeln('Election ID: ${reportData.electionId}')
      ..writeln(
        'Created: ${reportData.createdAt != null ? _formatDateTime(reportData.createdAt!) : 'Not Available'}',
      )
      ..writeln(
        'Description: ${reportData.description.isEmpty ? 'No description provided.' : reportData.description}',
      )
      ..writeln('')
      ..writeln('Summary');

    if (!reportData.hasVotes) {
      buffer.writeln('No votes have been cast. No winner can be declared.');
    } else if (reportData.hasTie) {
      buffer.writeln(
        'Tie result: ${reportData.winners.map((winner) => winner.name).join(', ')} with ${reportData.topVotes} votes each.',
      );
    } else {
      buffer
        ..writeln('Winner: ${reportData.winners.first.name}')
        ..writeln('Winning votes: ${reportData.topVotes}')
        ..writeln('Runner-up votes: ${reportData.runnerUpVotes}')
        ..writeln('Winning margin: ${reportData.winningMargin}')
        ..writeln(
          'Winning share: ${reportData.winningShare.toStringAsFixed(1)}%',
        );
    }

    buffer
      ..writeln('Total candidates: ${reportData.candidates.length}')
      ..writeln('Total votes: ${reportData.totalVotes}')
      ..writeln('')
      ..writeln('Candidate Ranking');

    for (final entry in reportData.candidates.asMap().entries) {
      buffer.writeln(
        '${entry.key + 1}. ${entry.value.name} - ${entry.value.votes} votes',
      );
    }

    return buffer.toString().trimRight();
  }

  Future<String?> _downloadPdfReport(
    _ElectionReportData reportData,
    DateTime generatedAt,
  ) async {
    final pdfBytes = await _generateReportPdf(reportData, generatedAt);
    final fileName = _buildReportFileName(reportData);

    if (Platform.isAndroid) {
      try {
        return await _reportChannel.invokeMethod<String>('savePdfToDownloads', {
          'fileName': fileName,
          'bytes': pdfBytes,
        });
      } on MissingPluginException {
        throw Exception(
          'Android save channel unavailable. Please fully restart/reinstall the app once so native changes are applied.',
        );
      } on PlatformException {
        throw Exception('Failed to save report to Downloads on Android.');
      }
    }

    await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    return null;
  }

  Future<Uint8List> _generateReportPdf(
    _ElectionReportData reportData,
    DateTime generatedAt,
  ) async {
    final pdf = pw.Document();
    final baseColor = PdfColor.fromInt(pageTop.toARGB32());
    final accentColor = PdfColor.fromInt(gradientStart.toARGB32());
    final softColor = PdfColor.fromInt(glassSubtext.toARGB32());
    final highlightColor = PdfColor.fromInt(const Color(0xFF0F9D58).toARGB32());

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: pw.BorderRadius.circular(18),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Election Result Report',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  reportData.title,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Generated on ${_formatDateTime(generatedAt)}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildPdfSection(
            title: 'Election Details',
            titleColor: baseColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfMetaRow('Election ID', reportData.electionId),
                _buildPdfMetaRow(
                  'Created',
                  reportData.createdAt != null
                      ? _formatDateTime(reportData.createdAt!)
                      : 'Not Available',
                ),
                _buildPdfMetaRow(
                  'Status',
                  reportData.hasSingleWinner
                      ? 'Winner Declared'
                      : reportData.hasTie
                      ? 'Tie Result'
                      : 'No Votes Cast',
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  reportData.description.isEmpty
                      ? 'No election description was provided.'
                      : reportData.description,
                  style: pw.TextStyle(color: softColor, fontSize: 11),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildPdfSection(
            title: 'Outcome Summary',
            titleColor: baseColor,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _buildPdfSummaryText(reportData),
                  style: pw.TextStyle(color: baseColor, fontSize: 11),
                ),
                pw.SizedBox(height: 12),
                pw.Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildPdfMetric(
                      'Candidates',
                      '${reportData.candidates.length}',
                    ),
                    _buildPdfMetric('Total Votes', '${reportData.totalVotes}'),
                    _buildPdfMetric('Top Votes', '${reportData.topVotes}'),
                    if (reportData.hasSingleWinner)
                      _buildPdfMetric(
                        'Winning Margin',
                        '${reportData.winningMargin}',
                      ),
                    if (reportData.hasVotes)
                      _buildPdfMetric(
                        'Winning Share',
                        '${reportData.winningShare.toStringAsFixed(1)}%',
                      ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildPdfSection(
            title: 'Candidate Ranking',
            titleColor: baseColor,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
              columnWidths: {
                0: const pw.FixedColumnWidth(45),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildPdfTableCell('Rank', isHeader: true),
                    _buildPdfTableCell('Candidate', isHeader: true),
                    _buildPdfTableCell('Votes', isHeader: true),
                    _buildPdfTableCell('Status', isHeader: true),
                  ],
                ),
                ...reportData.candidates.asMap().entries.map((entry) {
                  final isWinner = reportData.winners.any(
                    (winner) => winner.candidateId == entry.value.candidateId,
                  );

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isWinner ? PdfColors.green50 : PdfColors.white,
                    ),
                    children: [
                      _buildPdfTableCell('${entry.key + 1}'),
                      _buildPdfTableCell(entry.value.name),
                      _buildPdfTableCell('${entry.value.votes}'),
                      _buildPdfTableCell(isWinner ? 'Leader' : 'Candidate'),
                    ],
                  );
                }),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          _buildPdfSection(
            title: 'Certification',
            titleColor: baseColor,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: highlightColor, width: 1),
                borderRadius: pw.BorderRadius.circular(12),
                color: PdfColors.green50,
              ),
              child: pw.Text(
                'This report was generated from the published election results stored in the system at the time shown above.',
                style: pw.TextStyle(color: baseColor, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSection({
    required String title,
    required PdfColor titleColor,
    required pw.Widget child,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(16),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: titleColor,
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  pw.Widget _buildPdfMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfMetric(String label, String value) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: PdfColors.black,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTableCell(String value, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          color: PdfColors.black,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _buildPdfSummaryText(_ElectionReportData reportData) {
    if (!reportData.hasVotes) {
      return 'No votes have been cast for this election, so no winning candidate can be declared yet.';
    }

    if (reportData.hasTie) {
      return 'The election ended in a tie between ${reportData.winners.map((winner) => winner.name).join(', ')} with ${reportData.topVotes} votes each.';
    }

    final winner = reportData.winners.first;
    return '${winner.name} won this election with ${winner.votes} votes, securing ${reportData.winningShare.toStringAsFixed(1)}% of all recorded votes and finishing ${reportData.winningMargin} votes ahead of the next candidate.';
  }

  String _buildReportFileName(_ElectionReportData reportData) {
    final normalized = reportData.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    final safeName = normalized.isEmpty ? 'election_report' : normalized;
    return '${safeName}_report.pdf';
  }
}
