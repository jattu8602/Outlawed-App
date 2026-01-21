import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/widgets/app_logo.dart';
import '../widgets/refer_earn_capsule.dart';

class HomeTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeTab({super.key, required this.userData});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isStreakActive = true; // Toggle this to test both states

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
          ],
        ),
      ),
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
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
