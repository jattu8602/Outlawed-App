import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';
import 'group_chat_screen.dart';
import 'group_leaderboard_screen.dart';
import 'group_members_screen.dart';
import 'join_group_screen.dart';
import 'create_group_screen.dart';

class GroupScreen extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> userData;

  const GroupScreen({super.key, required this.authService, required this.userData});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;
  String? _selectedGroupId;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Dio get _dio => widget.authService.client;

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(ApiConstants.groupsEndpoint);
      final data = response.data;
      setState(() {
        _groups = data['groups'] ?? [];
        if (_groups.isNotEmpty && _selectedGroupId == null) {
          _selectedGroupId = _groups[0]['id'];
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic>? get _selectedGroup {
    if (_selectedGroupId == null) return null;
    try {
      return _groups.firstWhere((g) => g['id'] == _selectedGroupId);
    } catch (_) {
      return null;
    }
  }

  void _openJoinScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JoinGroupScreen(authService: widget.authService)),
    );
    if (result == true) await _loadGroups();
  }

  void _openCreateScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateGroupScreen(authService: widget.authService)),
    );
    if (result == true) await _loadGroups();
  }

  Future<void> _joinRandom() async {
    try {
      final response = await _dio.post(
        '${ApiConstants.apiPrefix}/groups/random',
      );
      final data = response.data;
      if (data['group'] != null) {
        setState(() => _selectedGroupId = data['group']['id']);
      }
      await _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    try {
      await _dio.post(ApiConstants.groupLeaveEndpoint(groupId));
      setState(() => _selectedGroupId = null);
      await _loadGroups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.black)),
      );
    }

    if (_groups.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Groups', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('No groups yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Join or create a group to get started', style: TextStyle(color: Colors.grey.shade400), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _joinRandom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shuffle, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Join Random Group', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _openJoinScreen,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Join by Code', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _openCreateScreen,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create Group', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _selectedGroup?['name'] ?? 'Groups',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'random') _joinRandom();
              if (value == 'join') _openJoinScreen();
              if (value == 'create') _openCreateScreen();
              if (value == 'leave' && _selectedGroupId != null) _leaveGroup(_selectedGroupId!);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'random', child: Row(
                children: [
                  Icon(Icons.shuffle, size: 18),
                  SizedBox(width: 8),
                  Text('Join Random Group'),
                ],
              )),
              const PopupMenuItem(value: 'join', child: Text('Join by Code')),
              const PopupMenuItem(value: 'create', child: Text('Create Group')),
              if (_groups.length > 1)
                const PopupMenuItem(value: 'leave', child: Text('Leave Group')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_groups.length > 1)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _groups.length,
                itemBuilder: (ctx, i) {
                  final g = _groups[i];
                  final isSelected = g['id'] == _selectedGroupId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGroupId = g['id']),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        g['name'] ?? 'Group',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab('Chat', 0),
                _buildTab('Leaderboard', 1),
                _buildTab('Members', 2),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedGroupId == null
                ? const Center(child: Text('Select a group'))
                : IndexedStack(
                    index: _currentTab,
                    children: [
                      GroupChatScreen(groupId: _selectedGroupId!, authService: widget.authService, userData: widget.userData),
                      GroupLeaderboardScreen(groupId: _selectedGroupId!, authService: widget.authService, userData: widget.userData),
                      GroupMembersScreen(groupId: _selectedGroupId!, authService: widget.authService),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.black : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
