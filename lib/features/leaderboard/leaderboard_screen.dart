import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';

class LeaderboardScreen extends StatefulWidget {
  final AuthService authService;

  const LeaderboardScreen({super.key, required this.authService});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _streakLeaderboard = [];
  List<Map<String, dynamic>> _historicalStreak = [];
  List<Map<String, dynamic>> _previousWeekTop3 = [];
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _weekInfo;
  bool _loading = true;
  String? _error;
  int _showTopperIndex = 0;
  Timer? _topperTimer;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _topperTimer?.cancel();
    super.dispose();
  }

  void _startTopperTimer() {
    _topperTimer?.cancel();
    if (_previousWeekTop3.length < 2) return;
    _topperTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _showTopperIndex = (_showTopperIndex + 1) % _previousWeekTop3.length;
      });
    });
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final response = await widget.authService.client.get(
        '${ApiConstants.apiPrefix}/leaderboard',
      );
      setState(() {
        _loading = false;
        if (response.statusCode == 200) {
          _leaderboard = List<Map<String, dynamic>>.from(response.data['leaderboard'] ?? []);
          _streakLeaderboard = List<Map<String, dynamic>>.from(response.data['streakLeaderboard'] ?? []);
          _historicalStreak = List<Map<String, dynamic>>.from(response.data['historicalStreak'] ?? []);
          _previousWeekTop3 = List<Map<String, dynamic>>.from(response.data['previousWeekTop3'] ?? []);
          _currentUser = response.data['currentUser'];
          _weekInfo = response.data['weekInfo'];
          _showTopperIndex = 0;
          _startTopperTimer();
        } else {
          _error = 'Failed (${response.statusCode})';
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildAvatar({
    required String? name,
    required String? imageUrl,
    required double radius,
    Color? bgColor,
    Color? textColor,
    double? fontSize,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor ?? Colors.grey.shade200,
      backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
      child: hasImage
          ? null
          : Text(
              _getInitials(name),
              style: TextStyle(
                fontSize: fontSize ?? radius * 0.65,
                fontWeight: FontWeight.w800,
                color: textColor ?? Colors.grey.shade700,
              ),
            ),
    );
  }

  Color _rankColor(int rank) {
    switch (rank) {
      case 1: return const Color(0xFFF59E0B);
      case 2: return const Color(0xFF94A3B8);
      case 3: return const Color(0xFFEA580C);
      default: return Colors.grey.shade300;
    }
  }

  IconData _rankIcon(int rank) {
    switch (rank) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.workspace_premium;
      case 3: return Icons.military_tech;
      default: return Icons.emoji_events;
    }
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    if (top3.length < 3) return const SizedBox.shrink();

    final second = top3.length > 1 ? top3[1] : null;
    final first = top3[0];
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null)
            Expanded(child: _buildPodiumItem(second, 2, 100)),
          Expanded(child: _buildPodiumItem(first, 1, 130)),
          if (third != null)
            Expanded(child: _buildPodiumItem(third, 3, 100)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double avatarSize) {
    final name = user['name'] ?? 'Anonymous';
    final score = (user['totalScore'] ?? 0).toString();
    final imageUrl = user['image'] as String?;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAvatar(
          name: name,
          imageUrl: imageUrl,
          radius: avatarSize / 2,
          bgColor: _rankColor(rank).withOpacity(0.15),
          textColor: _rankColor(rank),
          fontSize: avatarSize / 3,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: _rankColor(rank),
          ),
        ),
        if (rank == 1)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.auto_awesome, color: _rankColor(rank), size: 18),
          ),
      ],
    );
  }

  Widget _buildLastWeekTopper() {
    const double height = 56;
    final len = _previousWeekTop3.length;
    final active = _showTopperIndex;
    final prev = (active - 1 + len) % len;

    double offset(int i) {
      if (i == active) return 0;
      if (i == prev) return -height;
      return height;
    }

    double opacity(int i) => i == active ? 1 : 0;

    final rankIcons = [Icons.emoji_events, Icons.workspace_premium, Icons.military_tech];
    final rankColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFFEA580C),
    ];
    final rankLabels = ['#1', '#2', '#3'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        height: height,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200.withValues(alpha: 0.6)),
        ),
        child: Stack(
          children: List.generate(len, (i) {
            final u = _previousWeekTop3[i];
            final name = u['name'] ?? 'Anonymous';
            final score = (u['totalScore'] ?? 0).toString();
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              left: 0, right: 0,
              top: offset(i),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                opacity: opacity(i),
                child: SizedBox(
                  height: height,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(rankIcons[i], color: rankColors[i], size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Last Week ${rankLabels[i]}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: rankColors[i].withValues(alpha: 0.7),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          score,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: rankColors[i],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 8),
            Text(
              'Leaderboard',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('Failed to load', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: _fetchLeaderboard, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLeaderboard,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      if (_weekInfo != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _weekInfo!['range'] ?? '',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                              ),
                              if (_weekInfo!['daysRemaining'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_weekInfo!['daysRemaining']}d left',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.indigo.shade600),
                                  ),
                                ),
                            ],
                          ),
                        ),

                      if (_previousWeekTop3.isNotEmpty)
                        _buildLastWeekTopper(),

                      if (_leaderboard.length >= 3)
                        _buildPodium(_leaderboard.take(3).toList()),

                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: Text(
                          'RANKINGS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      if (_currentUser != null) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  '#${_currentUser!['rank']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              _currentUser!['name'] ?? 'You',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${_currentUser!['totalScore']} pts · ${_currentUser!['totalTests']} tests',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_currentUser!['totalScore']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'PTS',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                       ...List.generate(_leaderboard.length, (i) {
                        final user = _leaderboard[i];
                        final rank = i + 1;
                        final name = user['name'] ?? 'Anonymous';
                        final score = (user['totalScore'] ?? 0).toString();
                        final tests = user['totalTests'] ?? 0;
                        final imageUrl = user['image'] as String?;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: i < _leaderboard.length - 1
                                ? Border(bottom: BorderSide(color: Colors.grey.shade200))
                                : null,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: Center(
                                  child: rank <= 3
                                      ? Icon(_rankIcon(rank), color: _rankColor(rank), size: 24)
                                      : Text(
                                          '$rank',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildAvatar(
                                name: name,
                                imageUrl: imageUrl,
                                radius: 18,
                                bgColor: Colors.grey.shade100,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '$tests tests',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    score,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: rank <= 3 ? _rankColor(rank) : Colors.grey.shade800,
                                    ),
                                  ),
                                  Text(
                                    'PTS',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // --- Streak Masters ---
                      if (_streakLeaderboard.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Streak Masters',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        'Top 30 Consistency',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ...List.generate(_streakLeaderboard.length, (i) {
                                final user = _streakLeaderboard[i];
                                final name = user['name'] ?? 'Anonymous';
                                final streak = user['currentStreak'] ?? 0;
                                final peak = user['peakStreak'] ?? 0;
                                final imageUrl = user['image'] as String?;
                                return Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    border: i < _streakLeaderboard.length - 1
                                        ? Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06)))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          _buildAvatar(
                                            name: name,
                                            imageUrl: imageUrl,
                                            radius: 18,
                                            bgColor: Colors.grey.shade900,
                                            textColor: Colors.grey,
                                            fontSize: 11,
                                          ),
                                          if (i < 3)
                                            Positioned(
                                              left: -4, top: -4,
                                              child: Container(
                                                width: 18, height: 18,
                                                decoration: BoxDecoration(
                                                  color: i == 0 ? const Color(0xFFF59E0B) : i == 1 ? const Color(0xFF94A3B8) : const Color(0xFFEA580C),
                                                  borderRadius: BorderRadius.circular(9),
                                                  border: Border.all(color: const Color(0xFF0F172A), width: 2),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${i + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                color: Color(0xFFE2E8F0),
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              'Peak: ${peak}d',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$streak',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              if (_historicalStreak.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Divider(color: Colors.white.withOpacity(0.08)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'PAST STREAKS',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ...List.generate(_historicalStreak.length, (i) {
                                        final user = _historicalStreak[i];
                                        final name = user['name'] ?? 'Anonymous';
                                        final peak = user['peakStreak'] ?? 0;
                                        final imageUrl = user['image'] as String?;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Row(
                                            children: [
                                              _buildAvatar(
                                                name: name,
                                                imageUrl: imageUrl,
                                                radius: 14,
                                                bgColor: Colors.grey.shade900,
                                                textColor: Colors.grey.shade700,
                                                fontSize: 9,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Text(
                                                '$peak',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(Icons.local_fire_department, color: Colors.grey.shade800, size: 14),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}
