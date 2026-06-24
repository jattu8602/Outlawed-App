import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';

class GroupLeaderboardScreen extends StatefulWidget {
  final String groupId;
  final AuthService authService;
  final Map<String, dynamic>? userData;

  const GroupLeaderboardScreen({super.key, required this.groupId, required this.authService, this.userData});

  @override
  State<GroupLeaderboardScreen> createState() => _GroupLeaderboardScreenState();
}

class _GroupLeaderboardScreenState extends State<GroupLeaderboardScreen> {
  List<dynamic> _leaderboard = [];
  bool _isLoading = true;
  String _type = 'score';
  String? _myUserId;

  Dio get _dio => widget.authService.client;

  @override
  void initState() {
    super.initState();
    _myUserId = widget.userData?['id'];
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        ApiConstants.groupLeaderboardEndpoint(widget.groupId),
        queryParameters: {'type': _type},
      );
      setState(() {
        _leaderboard = response.data['leaderboard'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _switchType(String type) {
    if (_type == type) return;
    setState(() => _type = type);
    _loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Score/Hours toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildToggleButton('Score', 'score'),
              const SizedBox(width: 8),
              _buildToggleButton('Study Hours', 'hours'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : _leaderboard.isEmpty
                  ? Center(
                      child: Text(
                        'No activity this week',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _leaderboard.length,
                      itemBuilder: (ctx, i) => _buildRankCard(_leaderboard[i], i),
                    ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(String label, String type) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => _switchType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(dynamic entry, int index) {
    final isMe = entry['userId'] == _myUserId;
    final rank = entry['rank'] ?? index + 1;
    final tags = entry['tags'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? Colors.black : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: rank <= 3
                ? Text(
                    rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                    style: const TextStyle(fontSize: 20),
                  )
                : Text(
                    '#$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? Colors.grey.shade700 : Colors.grey.shade200,
            backgroundImage: entry['user']?['image'] != null
                ? NetworkImage(entry['user']['image'])
                : null,
            child: entry['user']?['image'] == null
                ? Text(
                    (entry['user']?['name'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry['user']?['name'] ?? 'Anonymous',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isMe ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      ...tags.take(2).map((t) => _buildMiniTag(t, isMe)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _type == 'hours'
                      ? '${(entry['studyHours'] ?? 0).toStringAsFixed(1)}h studied'
                      : '${entry['totalTests'] ?? 0} tests · avg ${(entry['avgScore'] ?? 0).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Score
          Text(
            _type == 'hours'
                ? '${(entry['studyHours'] ?? 0).toStringAsFixed(1)}h'
                : '${(entry['totalScore'] ?? 0).toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(dynamic tag, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: isMe ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tag['emoji'] ?? '🏷️',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}
