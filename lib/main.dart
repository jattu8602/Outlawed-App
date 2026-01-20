import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/auth_service.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _hasSeenOnboarding;
  Map<String, dynamic>? _userData;
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAppState();
  }

  Future<void> _checkAppState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;

    if (hasSeen) {
      // Check session
      // Wait slightly for AuthService CookieJar to init
      await Future.delayed(const Duration(milliseconds: 500));
      final user = await _authService.getCurrentUser();
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeen;
          _userData = user;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeen;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Outlawed',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
        fontFamily: GoogleFonts.inter().fontFamily, // Apply Inter globally
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: !_hasSeenOnboarding!
          ? const OnboardingScreen()
          : (_userData != null
              ? HomeScreen(userData: _userData!, authService: _authService)
              : const LoginPage()),
    );
  }
}
