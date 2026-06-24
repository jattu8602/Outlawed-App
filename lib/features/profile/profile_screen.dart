import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../auth/login_page.dart';
import '../payments/subscription_screen.dart';
import '../refer/refer_screen.dart';
import 'change_background_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final AuthService authService;

  const ProfileScreen({
    super.key,
    required this.userData,
    required this.authService,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _stats = const {'totalTests': 0, 'avgScore': 0, 'weekRank': 0};
  String _bgImagePath = 'assets/images/profile_bg.png';

  @override
  void initState() {
    super.initState();
    _loadCachedStats();
    _refreshStats();
  }

  Future<void> _loadCachedStats() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('profile_stats');
    final savedBg = prefs.getString('selected_profile_bg');
    if (mounted) {
      setState(() {
        if (cached != null) _stats = jsonDecode(cached);
        if (savedBg != null) _bgImagePath = savedBg;
      });
    }
  }

  Future<void> _refreshStats() async {
    try {
      final res = await widget.authService.client.get(
        '${ApiConstants.apiPrefix}/user/stats',
      );
      if (res.statusCode == 200 && mounted) {
        final data = res.data;
        // Silently update cache + state without loading spinner
        setState(() => _stats = data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_stats', jsonEncode(data));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData['user'] ?? {};
    final String name = user['name'] ?? 'User';
    final String email = user['email'] ?? '';
    final String? photoUrl = user['image'];
    final String role = user['role'] ?? 'Free';

    final totalTests = _stats['totalTests'] ?? 0;
    final avgScore = _stats['avgScore'] ?? 0;
    final weekRank = _stats['weekRank'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferScreen(authService: widget.authService),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'change_bg') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangeBackgroundScreen(),
                  ),
                );
                if (result != null && result is String) {
                  setState(() {
                    _bgImagePath = result;
                  });
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'change_bg',
                child: Row(
                  children: [
                    Icon(Icons.wallpaper, size: 20, color: Colors.black87),
                    SizedBox(width: 12),
                    Text('Change Background'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_bgImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black,
                          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          onBackgroundImageError: photoUrl != null && photoUrl.isNotEmpty
                              ? (_, __) {}
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? _buildFallbackAvatar(name)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (role == 'PAID' || role == 'ADMIN') ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified, color: Colors.blue, size: 20),
                ],
              ],
            ),
            Text(
              email,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),

            // Stats Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('Tests', '$totalTests'),
                  _buildVerticalDivider(),
                  _buildStatItem('Avg Score', '$avgScore%'),
                  _buildVerticalDivider(),
                  _buildStatItem('Rank', weekRank != null ? '#$weekRank' : '#--'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Edit Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Menu Options
            _buildMenuItem(Icons.workspace_premium_outlined, 'Subscription',
                role == 'PAID' ? 'You are Pro' : 'Upgrade to Premium', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionScreen(authService: widget.authService),
                ),
              );
            }),
            _buildMenuItem(Icons.history, 'Test History', '$totalTests tests taken',
                onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Test History coming soon'),
                    duration: Duration(seconds: 2)),
              );
            }),
            _buildMenuItem(Icons.share_outlined, 'Refer & Earn',
                'Earn coins by inviting friends', onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReferScreen(authService: widget.authService),
                ),
              );
            }),
            _buildMenuItem(Icons.settings_outlined, 'Settings', '', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Settings coming soon'),
                    duration: Duration(seconds: 2)),
              );
            }),
            _buildMenuItem(Icons.help_outline, 'Help & Support', '', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Help & Support coming soon'),
                    duration: Duration(seconds: 2)),
              );
            }),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                tileColor: Colors.red.shade50.withOpacity(0.5),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _buildFallbackAvatar(String name) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        tileColor: Colors.grey.shade50,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/logout_cat.json',
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oh no! You are leaving...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('No'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await widget.authService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Yes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
