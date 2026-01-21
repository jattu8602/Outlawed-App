import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/widgets/app_logo.dart';
import '../widgets/refer_earn_capsule.dart';
import '../screens/streak_history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/data/lexia_quotes.dart';

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeTab({super.key, required this.userData});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isStreakActive = false; // Toggle this to test both states

  void _showStreakInfo() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Streak Rules 🔥',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRuleItem('Complete at least 1 Mock Test daily.'),
                _buildRuleItem('Solve 10+ practice questions.'),
                _buildRuleItem('Spend 30+ minutes on study material.'),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData['user'] ?? {};
    final String name = user['name'] ?? 'User';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: const AppLogo(),
        actions: [
          Row(
            children: [
              // Refer & Earn Capsule
              const ReferEarnCapsule(),
              const SizedBox(width: 8),
              // Group Button
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Navigate to Groups (placeholder)
                  },
                  icon: const Icon(
                    Icons.groups_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Groups',
                  splashRadius: 18,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $name! 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to ace your CLAT preparation?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // First Component: Streak (50%)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isStreakActive = !_isStreakActive;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          gradient: _isStreakActive
                              ? LinearGradient(
                                  colors: [Colors.orange.shade300, Colors.orange.shade500],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade900],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _isStreakActive
                              ? [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          children: [
                            // Corner Streak Count: Top Left, Huge & Bold
                            Positioned(
                              top: 12,
                              left: 20,
                              child: Text(
                                '4/10',
                                style: TextStyle(
                                  color: _isStreakActive
                                      ? Colors.white
                                      : Colors.blueGrey.shade400,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -3,
                                ),
                              ),
                            ),
                            // Fire Logo: Expanded and Shifted Bottom
                            Align(
                              alignment: const Alignment(0, 1.0),
                              child: _isStreakActive
                                  ? Lottie.asset(
                                      'assets/animations/fire.json',
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.contain,
                                      animate: true,
                                    )
                                  : SizedBox(
                                      height: 180,
                                      child: Icon(
                                        Icons.whatshot,
                                        size: 130,
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                            ),
                            // Learn! Link
                            Positioned(
                              bottom: 0,
                              left: 16,
                              child: GestureDetector(
                                onTap: _showStreakInfo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade700.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'learn!',
                                    style: TextStyle(
                                      color: Colors.yellow.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Second Component: Tests & Score (50%)
                  Expanded(
                    child: Column(
                      children: [
                        // Top Row: Free & Paid Tests (50/50)
                        Expanded(
                          child: Row(
                            children: [
                              _buildStatCard(
                                title: 'Free',
                                value: '12/20',
                                color: Colors.blue.shade50,
                                textColor: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                title: 'Paid',
                                value: '05/10',
                                color: Colors.purple.shade50,
                                textColor: Colors.purple.shade700,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Bottom: Score
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT SCORE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '142.5',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Icon(Icons.trending_up, color: Colors.green, size: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 7-Day Streak Marker
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A), // Dark bluish
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const StreakHistoryScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: const Text(
                                'more',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                             _isStreakActive ? 'On Fire! 🔥' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: _isStreakActive ? Colors.orange : Colors.white38,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStreakDay('M', isCompleted: true),
                      _buildStreakDay('T', isCompleted: true),
                      _buildStreakDay('W', isMissed: true),
                      _buildStreakDay('T', isCompleted: true),
                      _buildStreakDay('F', isCompleted: false),
                      _buildStreakDay('S', isCompleted: false),
                      _buildStreakDay('S', isCompleted: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const LexiaAIComponent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDay(String label, {bool isCompleted = false, bool isMissed = false}) {
    Color bgColor = Colors.white.withOpacity(0.05);
    Color borderColor = Colors.white.withOpacity(0.1);
    Widget content = Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.2),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
    Color labelColor = Colors.white38;

    if (isCompleted) {
      bgColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green.shade400;
      content = const Icon(Icons.check, color: Colors.green, size: 20);
      labelColor = Colors.green.shade400;
    } else if (isMissed) {
      bgColor = Colors.red.withOpacity(0.15);
      borderColor = Colors.red.shade400;
      content = const Icon(Icons.close, color: Colors.red, size: 20);
      labelColor = Colors.red.shade400;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Center(child: content),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: (isCompleted || isMissed) ? FontWeight.bold : FontWeight.normal,
            color: labelColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LexiaAIComponent extends StatefulWidget {
  const LexiaAIComponent({super.key});

  @override
  State<LexiaAIComponent> createState() => _LexiaAIComponentState();
}

class _LexiaAIComponentState extends State<LexiaAIComponent> {
  String _currentQuote = "";
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _pickNewQuote();
    _timer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _pickNewQuote();
    });
  }

  void _pickNewQuote() {
    final newQuote = LexiaQuotes.all[_random.nextInt(LexiaQuotes.all.length)];
    if (mounted) {
      setState(() {
        _currentQuote = newQuote;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBF2), // Creamy whitish background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/images/Lexia.webp',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Lexia Ai',
                style: TextStyle(
                  color: Colors.black, // Sharp black heading
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: SizedBox(
              height: 44, // Fixed height for 2 lines of text
              child: TypewriterText(
                text: _currentQuote,
                maxLines: 2,
                style: TextStyle(
                  color: Colors.black87, // Black text for readability
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final int? maxLines;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 30),
    this.maxLines,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = "";
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _displayedText = "";
    _currentIndex = 0;
    _timer = Timer.periodic(widget.duration, (timer) {
      if (_currentIndex < widget.text.length) {
        if (mounted) {
          setState(() {
            // Handle UTF-16 surrogate pairs (emojis) to prevent crashes
            int charCode = widget.text.codeUnitAt(_currentIndex);
            if (charCode >= 0xD800 && charCode <= 0xDBFF && _currentIndex + 1 < widget.text.length) {
              // High surrogate found, take next code unit as well
              _displayedText += widget.text.substring(_currentIndex, _currentIndex + 2);
              _currentIndex += 2;
            } else {
              _displayedText += widget.text[_currentIndex];
              _currentIndex++;
            }
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
