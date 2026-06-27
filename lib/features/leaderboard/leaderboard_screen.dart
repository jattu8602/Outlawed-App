import 'dart:async';
import 'dart:math' as math;
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



  Gradient _getPodiumGradient(int rank) {
    if (rank == 1) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFF7E40),
          const Color(0xFFFF7E40).withOpacity(0.0),
        ],
      );
    } else if (rank == 2) {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF6390FF),
          const Color(0xFF6390FF).withOpacity(0.0),
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFFC72C),
          const Color(0xFFFFC72C).withOpacity(0.0),
        ],
      );
    }
  }

  Color _getPodiumTopColor(int rank) {
    if (rank == 1) return const Color(0xFFFF9E6E);
    if (rank == 2) return const Color(0xFF8EB0FF);
    return const Color(0xFFFFE17D);
  }

  Color _getPodiumBorderColor(int rank) {
    if (rank == 1) return const Color(0xFFFF7E40);
    if (rank == 2) return const Color(0xFF6390FF);
    return const Color(0xFFFFC72C);
  }

  Widget _buildPodiumAvatar(String? name, String? imageUrl, Color color, double radius) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: color.withOpacity(0.12),
        backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
        child: hasImage
            ? null
            : Text(
                _getInitials(name),
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background podium blocks (Rank 2 and Rank 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (second != null)
                  _buildPodiumItem(second, 2, 90, 110),
                const SizedBox(width: 48), // Gap where center Rank 1 block overlaps
                if (third != null)
                  _buildPodiumItem(third, 3, 90, 85)
                else
                  const SizedBox(width: 102), // matching second block width + offset
              ],
            ),
          ),
          // Foreground center podium block (Rank 1)
          _buildPodiumItem(first, 1, 105, 145),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(Map<String, dynamic> user, int rank, double blockWidth, double blockHeight) {
    final name = user['name'] ?? 'Anonymous';
    final score = (user['totalScore'] ?? 0).toString();
    final imageUrl = user['image'] as String?;
    final themeColor = _getPodiumBorderColor(rank);
    final topColor = _getPodiumTopColor(rank);
    final gradient = _getPodiumGradient(rank);

    return SizedBox(
      width: blockWidth + 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for Rank 1
          if (rank == 1)
            Transform.translate(
              offset: const Offset(0, 4),
              child: Transform.rotate(
                angle: -0.08,
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 22),
                ),
              ),
            )
          else
            const SizedBox(height: 22),

          // Avatar
          _buildPodiumAvatar(name, imageUrl, themeColor, rank == 1 ? 32.0 : 26.0),
          const SizedBox(height: 8),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Score Capsule & 3D Block
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // Block
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    CustomPaint(
                      size: Size(blockWidth + 12, blockHeight),
                      painter: PodiumBlockPainter(
                        frontGradient: gradient,
                        topColor: topColor,
                        skewX: 12,
                        topFaceHeight: 12,
                      ),
                    ),
                    Positioned(
                      top: 22,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(44, 44),
                              painter: LaurelWreathPainter(color: Colors.white.withOpacity(0.85)),
                            ),
                            Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Score Capsule
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$score coins',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildCustomAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.close, color: Colors.black, size: 20),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _weekInfo?['range'] ?? 'January 2026',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.more_vert, color: Colors.black, size: 20),
        ),
      ],
    );
  }

  Widget _buildCurrentUserCard() {
    if (_currentUser == null) return const SizedBox.shrink();
    final name = _currentUser!['name'] ?? 'You';
    final score = (_currentUser!['totalScore'] ?? 0).toString();
    final rank = _currentUser!['rank'] ?? 0;
    final imageUrl = _currentUser!['image'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFC72C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFC72C).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC72C).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Color(0xFFFFC72C),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    _getInitials(name),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name (You)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Keep pushing to climb up!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white60,
                    fontWeight: FontWeight.w500,
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
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFFFFC72C),
                ),
              ),
              const Text(
                'coins',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankChangeBadge(Map<String, dynamic> user) {
    final hash = user['id']?.toString().hashCode ?? 0;
    final change = (hash % 5) + 1;
    final isUp = hash % 3 != 0;
    
    final bgColor = isUp ? const Color(0xFFE6F7ED) : const Color(0xFFFFEBEA);
    final textColor = isUp ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F);
    final arrow = isUp ? '▲' : '▼';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$change',
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            arrow,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingCard(Map<String, dynamic> user, int index) {
    final name = user['name'] ?? 'Anonymous';
    final score = (user['totalScore'] ?? 0).toString();
    final imageUrl = user['image'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text(
                    _getInitials(name),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$score coins',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          _buildRankChangeBadge(user),
        ],
      ),
    );
  }

  List<Widget> _buildRankingsList() {
    final list = <Widget>[];
    final startIndex = _leaderboard.length >= 3 ? 3 : 0;
    for (int i = startIndex; i < _leaderboard.length; i++) {
      list.add(_buildRankingCard(_leaderboard[i], i));
    }
    return list;
  }

  Widget _buildStreakMastersSection() {
    if (_streakLeaderboard.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
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
                      color: Colors.white.withOpacity(0.3),
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
                          left: -4,
                          top: -4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: i == 0
                                  ? const Color(0xFFF59E0B)
                                  : i == 1
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFEA580C),
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
                            color: Colors.white.withOpacity(0.5),
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
                      color: Colors.white.withOpacity(0.3),
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
                                color: Colors.grey.shade400,
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
                              color: Colors.grey.shade300,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.local_fire_department, color: Colors.grey.shade700, size: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                        color: const Color(0xFFFAF6EE),
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 24),
                        child: SafeArea(
                          bottom: false,
                          child: Column(
                            children: [
                              _buildCustomAppBar(),
                              const SizedBox(height: 16),
                              if (_previousWeekTop3.isNotEmpty)
                                _buildLastWeekTopper(),
                              if (_leaderboard.length >= 3)
                                _buildPodium(_leaderboard.take(3).toList()),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Icon(
                                Icons.keyboard_arrow_up,
                                color: Colors.grey.shade300,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCurrentUserCard(),
                            ..._buildRankingsList(),
                            const SizedBox(height: 24),
                            if (_streakLeaderboard.isNotEmpty)
                              _buildStreakMastersSection(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
    );
  }
}

class LaurelWreathPainter extends CustomPainter {
  final Color color;
  LaurelWreathPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Left branch arc
    canvas.drawArc(rect, 1.8, 2.68, false, paint);
    
    // Right branch arc
    canvas.drawArc(rect, -1.2, 2.4, false, paint);

    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw leaves on left side
    for (double angle = 1.9; angle <= 4.4; angle += 0.5) {
      final leafCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.save();
      canvas.translate(leafCenter.dx, leafCenter.dy);
      canvas.rotate(angle + math.pi / 4);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 3.5), leafPaint);
      canvas.restore();
    }

    // Draw leaves on right side
    for (double angle = -1.0; angle <= 1.4; angle += 0.5) {
      final leafCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.save();
      canvas.translate(leafCenter.dx, leafCenter.dy);
      canvas.rotate(angle - math.pi / 4);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 3.5), leafPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PodiumBlockPainter extends CustomPainter {
  final Gradient frontGradient;
  final Color topColor;
  final double skewX;
  final double topFaceHeight;

  PodiumBlockPainter({
    required this.frontGradient,
    required this.topColor,
    this.skewX = 12.0,
    this.topFaceHeight = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final wFront = w - skewX;

    // 1. Draw top face (parallelogram)
    final topPath = Path()
      ..moveTo(0, topFaceHeight)
      ..lineTo(wFront, topFaceHeight)
      ..lineTo(w, 0)
      ..lineTo(skewX, 0)
      ..close();
    
    final topPaint = Paint()
      ..color = topColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(topPath, topPaint);

    // 2. Draw front face (gradient rectangle)
    final frontRect = Rect.fromLTRB(0, topFaceHeight, wFront, h);
    final frontPaint = Paint()
      ..shader = frontGradient.createShader(frontRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(frontRect, frontPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

