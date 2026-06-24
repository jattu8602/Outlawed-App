import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/services/auth_service.dart';
import '../home/home_screen.dart';

class LoginPage extends StatefulWidget {
  final AuthService? authService;

  const LoginPage({super.key, this.authService});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthService _authService;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showReferralInput = false;
  final _referralControllers = List.generate(8, (_) => TextEditingController());
  final _referralFocusNodes = List.generate(8, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    for (final c in _referralControllers) { c.dispose(); }
    for (final f in _referralFocusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _referralCode => _referralControllers.map((c) => c.text).join();

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final code = _referralCode;
      if (code.length == 8) {
        _authService.setReferralCode(code);
      }

      final userData = await _authService.signIn();

      if (userData != null && mounted) {
        // Navigate to Home Screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomeScreen(userData: userData, authService: _authService),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Welcome Lottie Animation (Reuse welcome.json or use a logo animation if available)
                   Lottie.asset(
                    'assets/animations/welcome.json',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue your journey.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(flex: 1),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Referral code toggle + input
                  if (!_showReferralInput)
                    GestureDetector(
                      onTap: () {
                        setState(() => _showReferralInput = true);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _referralFocusNodes[0].requestFocus();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'Have a referral code?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  if (_showReferralInput)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.card_giftcard, color: Colors.grey.shade400, size: 18),
                              const SizedBox(width: 8),
                              const Text('Referral code', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showReferralInput = false;
                                    for (final c in _referralControllers) { c.clear(); }
                                  });
                                },
                                child: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(8, (i) {
                              return SizedBox(
                                width: 28,
                                child: TextField(
                                  controller: _referralControllers[i],
                                  focusNode: _referralFocusNodes[i],
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  textCapitalization: TextCapitalization.characters,
                                  keyboardType: TextInputType.text,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    contentPadding: const EdgeInsets.only(bottom: 4),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black, width: 2),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    hintText: '—',
                                    hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                                  ),
                                  onChanged: (val) {
                                    if (val.isNotEmpty && i < 7) {
                                      _referralFocusNodes[i + 1].requestFocus();
                                    } else if (val.isEmpty && i > 0) {
                                      _referralFocusNodes[i - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                  // Google Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google.png',
                            height: 24,
                            width: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 150,
                  height: 150,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
