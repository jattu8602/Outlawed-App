import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../auth/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      animation: 'assets/animations/welcome.json',
      title: 'Welcome to Outlawed',
      description: 'Your premium destination for CLAT preparation.',
    ),
    OnboardingData(
      animation: 'assets/animations/thinking.json',
      title: 'Smart Learning',
      description: 'Innovative tools to sharpen your legal mind.',
    ),
    OnboardingData(
      animation: 'assets/animations/community.json', // Using community.json
      title: 'Join the Community',
      description: 'Connect with fellow aspirants and grow together.',
    ),
    OnboardingData(
      animation: 'assets/animations/wellbeing.json',
      title: 'Stay Updated',
      description: 'Enable notifications to never miss a test or update.',
      isPermissionPage: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildUnconstrainedIndicator(),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildBottomButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Lottie.asset(
              data.animation,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (data.isPermissionPage) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestNotificationPermission,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Enable Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF), // Example premium color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildUnconstrainedIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: _currentIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentIndex == index ? const Color(0xFF6C63FF) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButtons() {
    bool isLastPage = _currentIndex == _pages.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!isLastPage)
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          )
        else
          const SizedBox.shrink(),
        ElevatedButton(
          onPressed: () {
            if (isLastPage) {
              _completeOnboarding();
            } else {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(isLastPage ? 'Get Started' : 'Next'),
        ),
      ],
    );
  }

  Future<void> _requestNotificationPermission() async {
    // Check current status first
    PermissionStatus status = await Permission.notification.status;

    if (status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification is already on'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      return;
    }

    // Request permission if not granted
    status = await Permission.notification.request();

    if (status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notifications disabled. Enable in settings?'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied.'),
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}

class OnboardingData {
  final String animation;
  final String title;
  final String description;
  final bool isPermissionPage;

  OnboardingData({
    required this.animation,
    required this.title,
    required this.description,
    this.isPermissionPage = false,
  });
}
