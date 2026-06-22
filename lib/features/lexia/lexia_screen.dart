import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import 'lexia_chats_screen.dart';

final _TOOLS = [
  {'id': 'DOUBT_SOLVER', 'label': 'Doubt Solver', 'desc': 'Get instant answers to CLAT questions', 'icon': Icons.psychology},
  {'id': 'TEST_GENERATION', 'label': 'Generate Test', 'desc': 'Create custom CLAT practice tests', 'icon': Icons.quiz},
  {'id': 'PASSAGE_SUMMARIZER', 'label': 'Passage Summarizer', 'desc': 'Summarize legal & RC passages', 'icon': Icons.article},
  {'id': 'ESSAY_REVIEW', 'label': 'Essay Review', 'desc': 'Get feedback on your answers', 'icon': Icons.rate_review},
  {'id': 'COUNSELOR', 'label': 'CLAT Counselor', 'desc': 'Study advice & career guidance', 'icon': Icons.support_agent},
  {'id': 'SECTION_BOOSTER', 'label': 'Section Booster', 'desc': 'Focused practice by section', 'icon': Icons.trending_up},
  {'id': 'VOCAB_BUILDER', 'label': 'Vocab Builder', 'desc': 'Learn legal & English vocabulary', 'icon': Icons.menu_book},
  {'id': 'CURRENT_NEWS', 'label': 'Current News', 'desc': 'GK & current affairs updates', 'icon': Icons.newspaper},
  {'id': 'TEST_ANALYSIS', 'label': 'Test Analysis', 'desc': 'Analyze your test performance', 'icon': Icons.analytics},
];

final _DEFAULT_TOOL = _TOOLS[0];

const _FEATURES = [
  {'name': 'AI Doubt Solver', 'free': '1 query/day', 'paid': 'Unlimited', 'toolId': 'DOUBT_SOLVER'},
  {'name': 'AI Test Generation', 'free': '3 tests/month', 'paid': 'Unlimited', 'toolId': 'TEST_GENERATION'},
  {'name': 'Passage Summarizer', 'free': 'Not available', 'paid': 'Unlimited', 'toolId': 'PASSAGE_SUMMARIZER'},
  {'name': 'Essay & Answer Review', 'free': 'Not available', 'paid': '50 reviews/month', 'toolId': 'ESSAY_REVIEW'},
  {'name': 'CLAT Counselor', 'free': '1 query/day', 'paid': 'Unlimited', 'toolId': 'COUNSELOR'},
  {'name': 'Section Booster', 'free': '1 query/week', 'paid': 'Unlimited', 'toolId': 'SECTION_BOOSTER'},
  {'name': 'Vocab Builder', 'free': 'Not available', 'paid': 'Unlimited', 'toolId': 'VOCAB_BUILDER'},
  {'name': 'Current News', 'free': '5 queries/month', 'paid': 'Unlimited', 'toolId': 'CURRENT_NEWS'},
  {'name': 'Test Analysis', 'free': 'Not available', 'paid': 'Unlimited', 'toolId': 'TEST_ANALYSIS'},
  {'name': 'Chat History', 'free': 'Last 7 days', 'paid': 'Unlimited', 'toolId': null},
];

class LexiaScreen extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> userData;

  const LexiaScreen({super.key, required this.authService, required this.userData});

  @override
  State<LexiaScreen> createState() => _LexiaScreenState();
}

class _LexiaScreenState extends State<LexiaScreen> {
  String? _activeChatId;
  List<Map<String, dynamic>> _messages = [];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingMessages = false;
  bool _isSending = false;
  Map<String, dynamic> _selectedTool = _DEFAULT_TOOL;
  Map<String, dynamic> _usages = {};
  String get _role {
    final user = widget.userData['user'] as Map<String, dynamic>?;
    return (user?['role'] as String?) ?? 'FREE';
  }

  bool get _isFree => _role == 'FREE';

  @override
  void initState() {
    super.initState();
    _loadUsages();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadUsages() async {
    try {
      final res = await widget.authService.client.get(
        '${ApiConstants.apiPrefix}/lexia/usage',
      );
      if (res.statusCode == 200 && res.data is Map) {
        setState(() => _usages = Map<String, dynamic>.from(res.data));
      }
    } catch (_) {}
  }

  Future<void> _loadMessages(String chatId) async {
    setState(() => _isLoadingMessages = true);
    try {
      final res = await widget.authService.client.get(
        '${ApiConstants.apiPrefix}/lexia/chat/$chatId/messages',
      );
      if (res.statusCode == 200 && res.data is List) {
        setState(() => _messages = List<Map<String, dynamic>>.from(res.data));
      }
    } catch (_) {}
    setState(() => _isLoadingMessages = false);
    _scrollToBottom();
  }

  Future<String?> _createChat(String firstMessage) async {
    try {
      final res = await widget.authService.client.post(
        '${ApiConstants.apiPrefix}/lexia/chat',
        data: {'firstMessage': firstMessage},
      );
      if (res.statusCode == 201 && res.data is Map) {
        return res.data['id'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _handleSend() async {
    final text = _inputController.text.trim();
    final isDefaultTool = _selectedTool['id'] == _DEFAULT_TOOL['id'];
    if (text.isEmpty && isDefaultTool) return;
    if (_isSending) return;

    if (_isExhausted(_selectedTool['id'] as String)) {
      _showFeaturesComparison();
      return;
    }

    _inputController.clear();

    if (_activeChatId == null) {
      final chatId = await _createChat(text.isNotEmpty ? text : 'Using ${_selectedTool['label']}');
      if (!mounted) return;
      if (chatId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create chat. Please try again.'), duration: Duration(seconds: 2)),
        );
        return;
      }
      setState(() => _activeChatId = chatId);
      if (text.isEmpty) return;
    }

    final msg = {
      'id': 'user-${DateTime.now().millisecondsSinceEpoch}',
      'role': 'USER',
      'content': text,
      'toolType': null,
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(msg));
    _scrollToBottom();
    await _sendMessage(text);
  }

  Future<void> _sendMessage(String content) async {
    setState(() => _isSending = true);

    final aiMsgId = 'ai-${DateTime.now().millisecondsSinceEpoch}';
    final aiMsg = {
      'id': aiMsgId,
      'role': 'ASSISTANT',
      'content': '',
      'toolType': _selectedTool['id'],
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() => _messages.add(aiMsg));
    _scrollToBottom();

    try {
      final response = await widget.authService.client.post(
        '${ApiConstants.apiPrefix}/lexia/chat/${_activeChatId!}/messages',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: {'content': content, 'toolType': _selectedTool['id']},
      );

      if (response.statusCode == 429) {
        setState(() => _messages.removeWhere((m) => m['id'] == aiMsgId || m['id'].startsWith('user-')));
        _isSending = false;
        _scrollToBottom();
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == aiMsgId);
          _messages.add({
            'id': 'err-${DateTime.now().millisecondsSinceEpoch}',
            'role': 'ASSISTANT',
            'content': 'Sorry, something went wrong. Please try again.',
          });
        });
        _isSending = false;
        _scrollToBottom();
        return;
      }

      final contentType = response.headers.value('content-type') ?? '';
      String fullContent = '';

      if (contentType.contains('text/event-stream')) {
        final rawBody = response.data as String? ?? '';
        for (final line in rawBody.split('\n')) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['content'] != null) {
                fullContent += data['content'] as String;
                setState(() {
                  final idx = _messages.indexWhere((m) => m['id'] == aiMsgId);
                  if (idx >= 0) _messages[idx] = {..._messages[idx], 'content': fullContent};
                });
                _scrollToBottom();
              }
            } catch (_) {}
          }
        }
      } else {
        final resData = response.data;
        if (resData is Map && resData['content'] != null) {
          fullContent = resData['content'] as String;
          setState(() {
            final idx = _messages.indexWhere((m) => m['id'] == aiMsgId);
            if (idx >= 0) _messages[idx] = {
              ..._messages[idx],
              'content': fullContent,
              'id': resData['id'] ?? aiMsgId,
            };
          });
          _scrollToBottom();
        }
      }

      _loadUsages();
      if (_isFree && _selectedTool['id'] != _DEFAULT_TOOL['id']) {
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _showFeaturesComparison();
        });
      }
    } catch (e) {
      setState(() {
        _messages.removeWhere((m) => m['id'] == aiMsgId);
        _messages.add({
          'id': 'err-${DateTime.now().millisecondsSinceEpoch}',
          'role': 'ASSISTANT',
          'content': 'Network error. Please check your connection.',
        });
      });
    }

    setState(() => _isSending = false);
    _scrollToBottom();
  }

  bool _isExhausted(String toolId) {
    final usage = _usages[toolId];
    if (usage is! Map) return false;
    final used = (usage['used'] ?? 0) as int;
    final limit = (usage['limit'] ?? -1) as int;
    return _isFree && limit != -1 && used >= limit;
  }

  bool get _isCurrentToolExhausted => _isExhausted(_selectedTool['id'] as String);

  void _openChat(String chatId) {
    setState(() {
      _activeChatId = chatId;
      _messages = [];
    });
    _loadMessages(chatId);
  }

  void _newChat() {
    setState(() {
      _activeChatId = null;
      _messages = [];
    });
  }

  void _openChatsList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LexiaChatsScreen(
          authService: widget.authService,
          onChatSelected: _openChat,
        ),
      ),
    );
  }

  // ── Tool Selector (matches web ToolSelector.jsx) ──

  void _showToolSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        Map<String, dynamic>? toolUsage(String toolId) {
          final u = _usages[toolId];
          if (u is! Map) return null;
          return {'used': u['used'] ?? 0, 'limit': u['limit'] ?? -1};
        }

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  _lexiaLogo(size: 20),
                  const SizedBox(width: 8),
                  const Text('Lexia Tools', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              if (_isFree) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Free plan — some tools are limited. ',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      GestureDetector(
                        onTap: () { Navigator.pop(ctx); _showFeaturesComparison(); },
                        child: Text('See plans', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: List.generate(_TOOLS.length, (i) {
                    final tool = _TOOLS[i];
                    final isSelected = tool['id'] == _selectedTool['id'];
                    final exhausted = _isFree && _isExhausted(tool['id'] as String);
                    final usage = toolUsage(tool['id'] as String);
                    final used = (usage?['used'] as int?) ?? 0;
                    final limit = (usage?['limit'] as int?) ?? -1;

                    return GestureDetector(
                      onTap: () {
                        if (exhausted) {
                          Navigator.pop(ctx);
                          _showFeaturesComparison();
                          return;
                        }
                        setState(() => _selectedTool = Map<String, dynamic>.from(tool));
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.black
                                : exhausted
                                    ? Colors.grey.shade200
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                exhausted ? Icons.lock_outline : tool['icon'] as IconData,
                                color: isSelected ? Colors.white : exhausted ? Colors.grey.shade400 : Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        tool['label'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: isSelected ? Colors.white : exhausted ? Colors.grey.shade400 : Colors.black,
                                        ),
                                      ),
                                      if (exhausted) ...[
                                        const SizedBox(width: 6),
                                        Text('Used', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    exhausted ? 'Limit reached for this period' : tool['desc'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected ? Colors.white70 : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (usage != null && !isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  limit == -1 ? '∞' : '$used/$limit',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: exhausted ? Colors.grey.shade400 : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); _showFeaturesComparison(); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                  child: const Text(
                    'Upgrade to Pro to unlock all features',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Features Comparison (matches web FeaturesComparison.jsx) ──

  void _showFeaturesComparison() {
    _loadUsages();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String freeLabel(Map<String, dynamic> feature) {
          if (feature['free'] == 'Not available') return 'Not available';
          final toolId = feature['toolId'] as String?;
          if (toolId == null) return feature['free'] as String;
          final usage = _usages[toolId];
          if (usage is! Map) return feature['free'] as String;
          final limit = (usage['limit'] ?? -1) as int;
          if (limit == -1) return feature['free'] as String;
          final used = (usage['used'] ?? 0) as int;
          final period = (usage['period'] ?? '') as String;
          final periodLabel = period == 'daily' ? 'today' : period == 'weekly' ? 'this week' : 'this month';
          return '$used/$limit $periodLabel';
        }

        bool isExhausted(Map<String, dynamic> feature) {
          if (feature['free'] == 'Not available') return true;
          final toolId = feature['toolId'] as String?;
          if (toolId == null) return false;
          return _isExhausted(toolId);
        }

        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    const Text('Lexia Features', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.close, size: 20, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        const Expanded(flex: 3, child: SizedBox()),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text('FREE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 1)),
                              const Text('₹0', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              Text('PRO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade700, letterSpacing: 1)),
                              const Text('Paid', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(_FEATURES.length, (i) {
                      final feature = _FEATURES[i];
                      final exhausted = isExhausted(feature);
                      final label = freeLabel(feature);
                      final isNotAvail = feature['free'] == 'Not available';

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: i < _FEATURES.length - 1
                              ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(feature['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isNotAvail
                                      ? Colors.grey.shade100
                                      : exhausted
                                          ? Colors.grey.shade200
                                          : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isNotAvail || exhausted ? Colors.grey.shade500 : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  feature['paid'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () { /* Navigate to payments */ },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(14)),
                        child: const Text(
                          'Upgrade to Pro',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lexiaLogo({double size = 18}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.asset('assets/images/Lexia.webp', width: size, height: size, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: _lexiaLogo(size: 18),
          ),
          const SizedBox(width: 10),
          const Text('Lexia AI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(4)),
            child: Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.amber.shade800, letterSpacing: 1)),
          ),
          const Spacer(),
          _headerBtn(Icons.history, 'History', _openChatsList),
          const SizedBox(width: 4),
          _headerBtn(Icons.add, 'New Chat', _newChat),
        ],
      ),
    );
  }

  Widget _headerBtn(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_activeChatId == null) {
      return _buildWelcome();
    }
    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return _buildEmptyChat();
    }
    return _buildMessagesList();
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
            child: _lexiaLogo(size: 28),
          ),
          const SizedBox(height: 20),
          const Text('Lexia AI Tutor', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            'Your personal CLAT preparation assistant. Ask doubts, generate tests, review essays, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ...List.generate(6, (i) {
            final items = [
              {'label': 'Doubt Solver', 'icon': Icons.psychology},
              {'label': 'Generate Test', 'icon': Icons.quiz},
              {'label': 'Summarizer', 'icon': Icons.article},
              {'label': 'Essay Review', 'icon': Icons.rate_review},
              {'label': 'Counselor', 'icon': Icons.support_agent},
              {'label': 'Section Booster', 'icon': Icons.trending_up},
            ][i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(items['icon'] as IconData, size: 18, color: Colors.grey.shade700),
                    const SizedBox(width: 10),
                    Text(items['label'] as String, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _lexiaLogo(size: 40),
          const SizedBox(height: 16),
          const Text('Ask me anything about CLAT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Type a question below or tap + to use a specific tool.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final msg = _messages[i];
        final isUser = msg['role'] == 'USER';
        final content = msg['content'] as String? ?? '';
        final toolType = msg['toolType'] as String?;

        if (content.isEmpty && isUser) return const SizedBox.shrink();

        return Padding(
          padding: EdgeInsets.only(bottom: i < _messages.length - 1 ? 12 : 0),
          child: isUser ? _buildUserBubble(content) : _buildAiBubble(content, toolType),
        );
      },
    );
  }

  Widget _buildUserBubble(String content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              content,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiBubble(String content, String? toolType) {
    final tool = _TOOLS.firstWhere((t) => t['id'] == toolType, orElse: () => _DEFAULT_TOOL);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: Icon(tool['icon'] as IconData, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (toolType != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    toolType.replaceAll('_', ' '),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey.shade500, letterSpacing: 0.5),
                  ),
                ),
              if (content.isEmpty && _isSending)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                    SizedBox(width: 8),
                    Text('Thinking...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                )
              else if (content.isNotEmpty)
                MarkdownBody(
                  data: content,
                  styleSheet: MarkdownStyleSheet(
                    p: const TextStyle(fontSize: 14, color: Color(0xFF1F2937), height: 1.5),
                    strong: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    em: const TextStyle(fontStyle: FontStyle.italic),
                    listBullet: TextStyle(color: Colors.grey.shade600),
                    code: TextStyle(backgroundColor: Colors.grey.shade100, fontSize: 13, fontFamily: 'monospace'),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    codeblockPadding: const EdgeInsets.all(12),
                    h1: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    h2: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    h3: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(left: BorderSide(color: Colors.black, width: 3)),
                      color: Colors.grey.shade50,
                    ),
                    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    final exhausted = _isCurrentToolExhausted;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedTool['id'] != _DEFAULT_TOOL['id'])
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: exhausted ? Colors.red.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: exhausted ? Colors.red.shade200 : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  _lexiaLogo(size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      exhausted
                          ? '${_selectedTool['label']} — Limit exhausted. Tap to upgrade.'
                          : 'Using: ${_selectedTool['label']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: exhausted ? Colors.red.shade600 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  if (exhausted)
                    GestureDetector(
                      onTap: () => _showFeaturesComparison(),
                      child: Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.red.shade700, decoration: TextDecoration.underline)),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _selectedTool = Map<String, dynamic>.from(_DEFAULT_TOOL)),
                      child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showToolSelector,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.add, color: Colors.grey.shade700, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _inputController,
                  enabled: !exhausted,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: exhausted ? 'Limit exhausted — upgrade to continue' : 'Ask Lexia...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _isSending ? null : _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: _isSending
                        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade600))
                        : Icon(Icons.arrow_upward, color: Colors.black, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
