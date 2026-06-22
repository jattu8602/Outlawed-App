import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';

class LexiaChatsScreen extends StatefulWidget {
  final AuthService authService;
  final void Function(String chatId) onChatSelected;

  const LexiaChatsScreen({
    super.key,
    required this.authService,
    required this.onChatSelected,
  });

  @override
  State<LexiaChatsScreen> createState() => _LexiaChatsScreenState();
}

class _LexiaChatsScreenState extends State<LexiaChatsScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String? _deleteTarget;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      final res = await widget.authService.client.get(
        '${ApiConstants.apiPrefix}/lexia/chat',
      );
      if (res.statusCode == 200 && res.data is List) {
        setState(() => _chats = List<Map<String, dynamic>>.from(res.data));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deleteChat(String chatId) async {
    try {
      await widget.authService.client.delete(
        '${ApiConstants.apiPrefix}/lexia/chat/$chatId',
      );
      setState(() => _chats.removeWhere((c) => c['id'] == chatId));
    } catch (_) {}
    setState(() => _deleteTarget = null);
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chat History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No chats yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Start a conversation with Lexia AI', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _chats.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                    itemBuilder: (ctx, i) {
                      final chat = _chats[i];
                      final title = chat['title'] as String? ?? 'Chat';
                      final count = chat['_count'] is Map ? (chat['_count']['messages'] ?? 0) : 0;
                      final date = _formatDate(chat['createdAt'] as String?);

                      return Dismissible(
                        key: ValueKey(chat['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade400),
                        ),
                        confirmDismiss: (_) async {
                          setState(() => _deleteTarget = chat['id'] as String?);
                          return false;
                        },
                        child: ListTile(
                          onTap: () {
                            widget.onChatSelected(chat['id'] as String);
                            Navigator.pop(context);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.chat, color: Colors.grey.shade700, size: 20),
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '$count messages · $date',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                          ),
                          trailing: _deleteTarget == chat['id']
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => setState(() => _deleteTarget = null),
                                      child: Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                                    ),
                                    TextButton(
                                      onPressed: () => _deleteChat(chat['id'] as String),
                                      child: Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.red.shade600)),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
