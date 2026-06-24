import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/auth_service.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final AuthService authService;
  final Map<String, dynamic>? userData;

  const GroupChatScreen({super.key, required this.groupId, required this.authService, this.userData});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<dynamic> _messages = [];
  bool _isLoading = true;
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  Dio get _dio => widget.authService.client;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(ApiConstants.groupChatEndpoint(widget.groupId));
      setState(() {
        _messages = response.data['messages'] ?? [];
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _msgController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final response = await _dio.post(
        ApiConstants.groupChatEndpoint(widget.groupId),
        data: {'content': content},
      );
      setState(() {
        _messages.add(response.data['message']);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _msgController.text = content;
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.black))
              : _messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)),
                          const SizedBox(height: 4),
                          Text('Say hello to your group!', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                    ),
        ),
        _buildInputBar(),
      ],
    );
  }

  Widget _buildMessage(dynamic msg) {
    final isSystem = msg['type'] == 'SYSTEM' || msg['type'] == 'TAG_UPDATE';
    final isMe = msg['user']?['id'] == widget.userData?['id'];
    final tags = msg['tags'] as List<dynamic>? ?? [];

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg['content'] ?? '',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: msg['user']?['image'] != null
                  ? NetworkImage(msg['user']['image'])
                  : null,
              child: msg['user']?['image'] == null
                  ? Text(
                      (msg['user']?['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg['user']?['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        ...tags.map((t) => _buildTag(t)),
                      ],
                    ],
                  ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.black : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: msg['user']?['image'] != null
                  ? NetworkImage(msg['user']['image'])
                  : null,
              child: msg['user']?['image'] == null
                  ? Text(
                      (msg['user']?['name'] ?? '?')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(dynamic tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${tag['emoji'] ?? '🏷️'} ${tag['tag']}',
        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: _isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
