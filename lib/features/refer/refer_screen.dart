import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/api_constants.dart';

class ReferScreen extends StatefulWidget {
  final AuthService authService;

  const ReferScreen({super.key, required this.authService});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  String? _referralCode;
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchReferralCode(), _fetchStats()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchReferralCode() async {
    try {
      final response = await widget.authService.client.post(
        ApiConstants.generateReferralEndpoint,
      );
      if (mounted && response.data['referralCode'] != null) {
        setState(() => _referralCode = response.data['referralCode']);
      }
    } catch (_) {}
  }

  Future<void> _fetchStats() async {
    try {
      final response = await widget.authService.client.get(
        ApiConstants.referralStatsEndpoint,
      );
      if (mounted) {
        setState(() => _stats = response.data);
      }
    } catch (_) {}
  }

  String get _playStoreReferrerLink =>
      'https://play.google.com/store/apps/details?id=com.outlawed.app&referrer=ref%3D$_referralCode';

  String get _deepLink =>
      'https://www.outlawed.in/download?ref=$_referralCode';

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _deepLink));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Referral link copied!')),
      );
    }
  }

  Future<void> _shareLink() async {
    await Share.share(
      'Download OUTLAWED and ace your CLAT preparation!\n\n'
      'Use my referral link to get started:\n$_playStoreReferrerLink\n\n'
      'If the link doesn\'t work, download from Play Store and enter my referral code: $_referralCode',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Refer & Earn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildReferralCodeCard(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildShareButtons(),
                  const SizedBox(height: 24),
                  _buildHowItWorks(),
                  const SizedBox(height: 24),
                  _buildRecentReferrals(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share Success, Multiply Rewards',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Invite your friends to OUTLAWED and earn coins for every successful referral!',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'YOUR REFERRAL CODE',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _referralCode ?? '------',
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconButton(Icons.copy, 'Copy', _copyLink),
              const SizedBox(width: 24),
              _buildIconButton(Icons.share, 'Share', _shareLink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final referStats = _stats;
    final totalReferrals = referStats?['totalReferrals'] ?? 0;
    final pointsEarned = referStats?['pointsEarned'] ?? 0;
    final currentCoins = referStats?['currentCoins'] ?? 0;

    return Row(
      children: [
        _buildStatCard('Total Joins', '$totalReferrals', Colors.blue),
        const SizedBox(width: 12),
        _buildStatCard('Coins Earned', '$pointsEarned', Colors.amber),
        const SizedBox(width: 12),
        _buildStatCard('Available', '$currentCoins', Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.shade100),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: color.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Share Your Link',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _copyLink,
            icon: const Icon(Icons.copy),
            label: const Text('Copy Referral Link'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareLink,
            icon: const Icon(Icons.share),
            label: const Text('Share via...'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How It Works',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildStep(
          '1',
          'Share Your Code',
          'Send your unique referral link to friends via WhatsApp, Telegram, or any app.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          '2',
          'They Join',
          'Your friend downloads OUTLAWED and signs up using your referral link.',
        ),
        const SizedBox(height: 12),
        _buildStep(
          '3',
          'You Both Earn',
          'You get 5 coins and your friend gets 3 coins as a welcome bonus!',
        ),
      ],
    );
  }

  Widget _buildStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReferrals() {
    final recent = _stats?['recentReferrals'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Referrals',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline,
                    size: 40, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No referrals yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Share your code to get started!',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...recent.map((r) => _buildReferralItem(r)),
      ],
    );
  }

  Widget _buildReferralItem(Map<String, dynamic> referral) {
    final name = referral['name'] ?? 'Friend';
    final date = referral['createdAt'] ?? '';
    final displayDate = date is String && date.length >= 10
        ? date.substring(0, 10)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.green.shade100,
            child: Text(
              name.toString()[0].toUpperCase(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (displayDate.isNotEmpty)
                  Text(
                    displayDate,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+5',
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
