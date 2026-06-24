import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';

class GroupMembersScreen extends StatefulWidget {
  final String groupId;
  final AuthService authService;

  const GroupMembersScreen({super.key, required this.groupId, required this.authService});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  List<dynamic> _members = [];
  bool _isLoading = true;
  bool _showTestHistory = true;
  String? _inviteCode;

  Dio get _dio => widget.authService.client;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(ApiConstants.groupDetailEndpoint(widget.groupId));
      final group = response.data['group'];
      final mySettings = response.data['myMembership'];
      setState(() {
        _members = group['members'] ?? [];
        _inviteCode = group['inviteCode'];
        _showTestHistory = mySettings?['showTestHistory'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleHistory() async {
    try {
      final response = await _dio.patch(
        ApiConstants.groupSettingsEndpoint(widget.groupId),
        data: {'showTestHistory': !_showTestHistory},
      );
      setState(() => _showTestHistory = response.data['showTestHistory']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _copyInviteCode() {
    if (_inviteCode == null) return;
    Clipboard.setData(ClipboardData(text: _inviteCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite code copied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.black))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Invite code card
              if (_inviteCode != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Invite Code',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _inviteCode!,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _copyInviteCode,
                        icon: const Icon(Icons.copy, size: 20),
                        tooltip: 'Copy invite code',
                      ),
                    ],
                  ),
                ),

              // Share history toggle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Share my test history',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _showTestHistory ? 'Visible to group members' : 'Hidden from group',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showTestHistory,
                      onChanged: (_) => _toggleHistory(),
                      activeThumbColor: Colors.white,
                      activeTrackColor: Colors.black,
                    ),
                  ],
                ),
              ),

              // Members list
              Text(
                'Members (${_members.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._members.map((m) => _buildMemberCard(m)),
            ],
          );
  }

  Widget _buildMemberCard(dynamic member) {
    final user = member['user'];
    final tags = member['tags'] as List<dynamic>? ?? [];
    final history = member['testHistory'];
    final role = member['role'] ?? 'MEMBER';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user?['image'] != null
                    ? NetworkImage(user['image'])
                    : null,
                child: user?['image'] == null
                    ? Text(
                        (user?['name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user?['name'] ?? 'Anonymous',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (role == 'OWNER') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'OWNER',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: tags.map((t) => _buildAnimatedTag(t)).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (history != null && _showTestHistory) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatMini('Tests', '${history['totalTests'] ?? 0}'),
                  _buildStatMini('Avg', '${(history['avgScore'] ?? 0).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ],
          if (history == null && member['showTestHistory'] == false)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'History is hidden',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTag(dynamic tag) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${tag['emoji'] ?? '🏷️'} ${tag['tag']}',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _buildStatMini(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}
