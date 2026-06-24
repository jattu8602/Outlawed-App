import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/constants/api_constants.dart';

class TestAttemptScreen extends StatefulWidget {
  final AuthService authService;
  final String testId;

  const TestAttemptScreen({
    super.key,
    required this.authService,
    required this.testId,
  });

  @override
  State<TestAttemptScreen> createState() => _TestAttemptScreenState();
}

class _TestAttemptScreenState extends State<TestAttemptScreen> {
  final Dio _dio = Dio();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _test;
  List<dynamic> _questions = [];
  List<dynamic> _passages = [];

  int _currentIndex = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isStarted = false;
  bool _isCompleted = false;
  bool _isSubmitting = false;

  final Map<String, dynamic> _answers = {};
  final Set<String> _markedForLater = {};
  final Set<String> _visitedQuestions = {};

  // Results
  Map<String, dynamic>? _results;

  @override
  void initState() {
    super.initState();
    _dio.options = widget.authService.client.options;
    _dio.interceptors.addAll(widget.authService.client.interceptors);
    _fetchTest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTest() async {
    try {
      final res = await _dio.get(ApiConstants.testDetailEndpoint(widget.testId));
      if (mounted) {
        setState(() {
          _test = res.data['test'];
          _questions = res.data['questions'] ?? [];
          _passages = res.data['passages'] ?? [];
          _timeRemaining = (_test?['durationInMinutes'] as int? ?? 0) * 60;
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 && mounted) {
        Navigator.pop(context);
      }
      if (mounted) setState(() { _error = 'Failed to load test'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load test'; _loading = false; });
    }
  }

  void _startTest() {
    setState(() { _isStarted = true; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeRemaining <= 1) {
        t.cancel();
        _autoSubmit();
      }
      setState(() => _timeRemaining--);
    });
  }

  Future<void> _autoSubmit() async {
    if (_isCompleted || _isSubmitting) return;
    setState(() => _isCompleted = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time is up! Submitting test...'), backgroundColor: Colors.red),
      );
    }
    await _submitTest();
  }

  Future<void> _submitTest() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final payload = {
        'answers': _answers,
        'markedForLater': _markedForLater.toList(),
        'timeSpent': (_test?['durationInMinutes'] as int? ?? 0) * 60 - _timeRemaining,
      };
      final res = await _dio.post(ApiConstants.testSubmitEndpoint(widget.testId), data: payload);
      if (mounted) {
        setState(() {
          _results = res.data;
          _isSubmitting = false;
          _isCompleted = true;
        });
        _showResults();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit test'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showResults() {
    if (_results == null) return;
    final correct = _results!['correctAnswers'] ?? _results!['score'] ?? 0;
    final total = _questions.length;
    final score = _results!['percentage'] ?? _results!['percentageScore'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: score >= 50 ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  score >= 50 ? Icons.emoji_events : Icons.replay,
                  color: score >= 50 ? Colors.green.shade600 : Colors.red.shade600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text('Test Complete!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _resultItem('Score', '$score%', Colors.blue),
                  _resultItem('Correct', '$correct', Colors.green),
                  _resultItem('Total', '$total', Colors.grey),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Tests', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getStatus(int index) {
    final q = _questions[index] as Map<String, dynamic>;
    final id = q['id'] as String;
    final ans = _answers[id];
    final hasAnswer = ans != null && (ans is! String || ans.isNotEmpty) && (ans is! List || ans.isNotEmpty);
    if (hasAnswer) return 'attempted';
    if (_markedForLater.contains(id)) return 'marked';
    if (_visitedQuestions.contains(id)) return 'seen';
    return 'unattempted';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'attempted': return Colors.green;
      case 'marked': return Colors.orange;
      case 'seen': return Colors.red;
      default: return Colors.grey.shade300;
      }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'attempted': return Colors.white;
      case 'marked': return Colors.white;
      case 'seen': return Colors.white;
      default: return Colors.grey.shade700;
    }
  }

  Map<String, dynamic>? _getPassageForQuestion(Map<String, dynamic> q) {
    final passageId = q['passageId'] as String?;
    if (passageId == null || _passages.isEmpty) return null;
    for (final p in _passages) {
      if ((p as Map)['id'] == passageId) return p as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 16),
              Text('Loading test...', style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      );
    }

    if (_error != null || _test == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error ?? 'Test not found', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isStarted) {
      return _buildStartScreen();
    }

    if (_isCompleted && _results != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Test submitted!')),
      );
    }

    return _buildTestScreen();
  }

  Widget _buildStartScreen() {
    final totalQ = _questions.length;
    final duration = _test?['durationInMinutes'] ?? 0;
    final positive = _test?['positiveMarks'] ?? 0;
    final negative = _test?['negativeMarks'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.assignment, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                _test?['title'] ?? 'Test',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    _infoRow(Icons.help_outline, 'Total Questions', '$totalQ'),
                    const Divider(height: 24),
                    _infoRow(Icons.timer_outlined, 'Duration', '$duration min'),
                    const Divider(height: 24),
                    _infoRow(Icons.add_circle_outline, 'Positive Marks', '+$positive'),
                    const Divider(height: 24),
                    _infoRow(Icons.remove_circle_outline, 'Negative Marks', '-$negative'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Start Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 15))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildTestScreen() {
    final q = _currentIndex < _questions.length ? _questions[_currentIndex] as Map<String, dynamic> : null;
    final passage = q != null ? _getPassageForQuestion(q) : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildQuestionPalette(),
            Expanded(
              child: q != null ? _buildQuestionContent(q, passage) : const SizedBox(),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final timeLow = _timeRemaining <= 300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showExitConfirm(),
            child: Icon(Icons.close, color: Colors.grey.shade600, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _test?['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: timeLow ? Colors.red.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: timeLow ? Colors.red : Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatTime(_timeRemaining),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: timeLow ? Colors.red.shade700 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showExitConfirm(),
            style: TextButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Submit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPalette() {
    final total = _questions.length;
    final itemSize = 36.0;
    final gap = 6.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: itemSize + 4,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: total,
              separatorBuilder: (_, __) => SizedBox(width: gap),
              itemBuilder: (ctx, i) {
                final status = _getStatus(i);
                final isCurrent = i == _currentIndex;
                final id = (_questions[i] as Map)['id'] as String;
                final isMarkedAndAnswered = _markedForLater.contains(id) && _answers[id] != null;

                return GestureDetector(
                  onTap: () {
                    _updateQuestionVisit();
                    setState(() => _currentIndex = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: itemSize,
                    height: itemSize,
                    decoration: BoxDecoration(
                      color: _statusColor(status),
                      borderRadius: BorderRadius.circular(isCurrent ? 12 : 8),
                      border: Border.all(
                        color: isCurrent ? Colors.blue.shade500 : Colors.transparent,
                        width: isCurrent ? 2.5 : 0,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _statusTextColor(status),
                            ),
                          ),
                        ),
                        if (isMarkedAndAnswered)
                          Positioned(
                            top: -3, right: -3,
                            child: Container(
                              width: 10, height: 10,
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(Colors.green, 'Attempted'),
              const SizedBox(width: 12),
              _legendDot(Colors.orange, 'Marked'),
              const SizedBox(width: 12),
              _legendDot(Colors.red, 'Visited'),
              const SizedBox(width: 12),
              _legendDot(Colors.grey.shade300, 'Unseen'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildQuestionContent(Map<String, dynamic> q, Map<String, dynamic>? passage) {
    final options = q['options'] as List<dynamic>?;
    final questionType = q['questionType'] as String? ?? 'OPTIONS';
    final qId = q['id'] as String;
    final section = (q['section'] as String? ?? '').replaceAll('_', ' ');
    final qNumber = _currentIndex + 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q$qNumber', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(section, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (passage != null) _buildPassageCard(passage),
          if (passage != null) const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildHtmlText(q['questionText'] as String? ?? ''),
          ),
          const SizedBox(height: 16),

          if (q['optionType'] == 'SINGLE' && options != null) ...[
            ...options.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _answers[qId] = entry.value;
                      _visitedQuestions.add(qId);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _answers[qId] == entry.value ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _answers[qId] == entry.value ? Colors.blue.shade400 : Colors.grey.shade200,
                        width: _answers[qId] == entry.value ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _answers[qId] == entry.value ? Colors.blue : Colors.transparent,
                            border: Border.all(
                              color: _answers[qId] == entry.value ? Colors.blue : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: _answers[qId] == entry.value
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value as String, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          if (q['optionType'] == 'MULTIPLE' && options != null) ...[
            ...options.asMap().entries.map((entry) {
              final selected = (_answers[qId] as List?)?.contains(entry.value) ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      final list = List<String>.from(_answers[qId] as List? ?? []);
                      if (list.contains(entry.value)) {
                        list.remove(entry.value);
                      } else {
                        list.add(entry.value as String);
                      }
                      _answers[qId] = list;
                      _visitedQuestions.add(qId);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.blue.shade400 : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: selected ? Colors.blue : Colors.transparent,
                            border: Border.all(
                              color: selected ? Colors.blue : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(entry.value as String, style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          if (questionType == 'INPUT') ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter your answer...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) {
                setState(() {
                  _answers[qId] = v;
                  _visitedQuestions.add(qId);
                });
              },
            ),
          ],

          if (_answers[qId] != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _answers.remove(qId)),
              icon: Icon(Icons.refresh, size: 16, color: Colors.grey.shade600),
              label: Text('Clear response', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassageCard(Map<String, dynamic> passage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article_outlined, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text('Passage ${passage['passageNumber'] ?? ''}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700)),
            ],
          ),
          if (passage['title'] != null) ...[
            const SizedBox(height: 6),
            Text(passage['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
          const SizedBox(height: 8),
          Text(_stripHtml(passage['content'] as String? ?? ''),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final qId = _currentIndex < _questions.length ? (_questions[_currentIndex] as Map)['id'] as String : '';
    final isMarked = _markedForLater.contains(qId);
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Q${_currentIndex + 1} of ${_questions.length}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _bottomBtn(
                icon: Icons.arrow_back_ios_new,
                label: 'Previous',
                onTap: _currentIndex > 0 ? () { _updateQuestionVisit(); setState(() => _currentIndex--); } : null,
              ),
              const SizedBox(width: 8),
              _bottomBtn(
                icon: Icons.bookmark_border,
                label: isMarked ? 'Marked' : 'Mark',
                color: isMarked ? Colors.orange : null,
                onTap: () {
                  setState(() {
                    if (isMarked) { _markedForLater.remove(qId); } else { _markedForLater.add(qId); }
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLast ? _showExitConfirm : () { _updateQuestionVisit(); setState(() => _currentIndex++); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? Colors.green : Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(isLast ? 'Submit' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomBtn({
    required IconData icon, required String label, Color? color, VoidCallback? onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? Colors.black,
        side: BorderSide(color: color ?? Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  void _updateQuestionVisit() {
    if (_currentIndex < _questions.length) {
      final id = (_questions[_currentIndex] as Map)['id'] as String;
      _visitedQuestions.add(id);
    }
  }

  void _showExitConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Submit Test?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Are you sure you want to submit? Unanswered questions will be counted as incorrect.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(ctx); _submitTest(); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit & Exit', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Continue Test', style: TextStyle(color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHtmlText(String html) {
    final text = _stripHtml(html);
    return Text(text, style: const TextStyle(fontSize: 15, height: 1.5));
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }
}
