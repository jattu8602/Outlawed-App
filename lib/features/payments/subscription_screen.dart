import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/payment_service.dart';
import 'payment_history_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final AuthService authService;

  const SubscriptionScreen({super.key, required this.authService});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late PaymentService _paymentService;
  List<dynamic> _plans = [];
  Map<String, dynamic>? _userStatus;
  bool _loading = true;
  String? _error;
  String? _loadingPlanId;

  // For each plan, track coin slider value
  final Map<String, double> _coinValues = {};

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(widget.authService.client);
    _paymentService.onPaymentSuccess = _onPaymentVerified;
    _paymentService.onPaymentError = (code, msg) {
      if (mounted) {
        setState(() => _loadingPlanId = null);
        _showError(msg ?? 'Payment was cancelled or failed');
      }
    };
    _loadData();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _paymentService.fetchPlans(),
        _paymentService.fetchUserStatus(),
      ]);
      final plans = results[0]['plans'] as List<dynamic>;
      final status = results[1];
      if (mounted) {
        setState(() {
          _plans = plans;
          _userStatus = status['user'] as Map<String, dynamic>?;
          _loading = false;
          for (final p in plans) {
            _coinValues.putIfAbsent(p['id'], () => 0);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load plans. Pull to retry.';
        });
      }
    }
  }

  Future<void> _handlePurchase(Map<String, dynamic> plan) async {
    setState(() => _loadingPlanId = plan['id']);
    _error = null;

    try {
      final price = plan['price'] as num;
      final discount = plan['discount'] as num? ?? 0;
      final baseDiscountPrice = discount > 0 ? price - (price * discount / 100) : price;
      final coinsUsed = (_coinValues[plan['id']] ?? 0).round();
      final maxCoins = (baseDiscountPrice / 2).floor();
      final sanitizedCoins = coinsUsed.clamp(0, maxCoins).toInt();
      final finalAmount = (baseDiscountPrice - sanitizedCoins).round();

      final order = await _paymentService.createOrder(
        plan['id'] as String,
        finalAmount,
        coinsUsed: sanitizedCoins,
      );

      final key = await _paymentService.fetchRazorpayKey();

      await _paymentService.openCheckout(
        key: key,
        orderId: order['orderId'] as String,
        amount: finalAmount,
        planName: plan['name'] as String,
        email: _userStatus?['email'] as String?,
        contact: _userStatus?['phone'] as String?,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['error'] ?? 'Failed to process payment';
      _showError(msg);
      setState(() => _loadingPlanId = null);
    } catch (e) {
      _showError('Something went wrong. Please try again.');
      setState(() => _loadingPlanId = null);
    }
  }

  void _onPaymentVerified() {
    _loadData();
    if (mounted) {
      setState(() => _loadingPlanId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Welcome to Pro.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    setState(() => _error = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = _userStatus?['isCurrentlyPaid'] == true;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentHistoryScreen(authService: widget.authService),
              ),
            ),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('History', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (isPaid) _buildActiveBanner(),
                  ..._plans.map((plan) => _buildPlanCard(plan)),
                  const SizedBox(height: 24),
                  _buildSecureBadge(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveBanner() {
    final paidUntil = _userStatus?['paidUntil'] as String?;
    final daysRemaining = _userStatus?['daysRemaining'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF065F46), Color(0xFF059669)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pro Member',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (paidUntil != null)
                  Text('Valid until ${_formatDate(paidUntil)} ($daysRemaining days left)',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] as String;
    final price = plan['price'] as num;
    final discount = plan['discount'] as num? ?? 0;
    final description = plan['description'] as String? ?? '';
    final duration = plan['duration'] as int?;
    final durationType = plan['durationType'] as String?;
    final planId = plan['id'] as String;
    final isLoading = _loadingPlanId == planId;

    final baseDiscountPrice = discount > 0 ? price - (price * discount / 100) : price;
    final maxCoins = (baseDiscountPrice / 2).floor();
    final coinsUsed = (_coinValues[planId] ?? 0).round();
    final finalAmount = (baseDiscountPrice - coinsUsed.clamp(0, maxCoins)).round();

    String durationText = '';
    if (duration != null && durationType != null) {
      if (durationType == 'months') {
        durationText = duration >= 12 ? '${duration ~/ 12} Year' : '$duration Months';
      } else if (durationType == 'days') {
        durationText = '$duration Days';
      } else if (durationType == 'years') {
        durationText = '$duration Year${duration > 1 ? 's' : ''}';
      } else if (durationType == 'until_date') {
        durationText = 'Until ${_formatDate(plan['untilDate'] as String? ?? '')}';
      }
    }

    final isPopular = name.toLowerCase().contains('quarterly') || name.toLowerCase().contains('recommended');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? Colors.blue.shade400 : Colors.grey.shade200,
          width: isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? Colors.blue.withOpacity(0.1) : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isPopular ? Colors.blue.shade50 : Colors.grey.shade50,
                      Colors.white,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          if (durationText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(durationText,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${discount.round()}% OFF',
                            style: TextStyle(
                                color: Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (isPopular)
                Positioned(
                  right: 20,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('POPULAR',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: Text('₹${price.round()}',
                        style: TextStyle(
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                            fontSize: 16)),
                  ),
                Text('₹$finalAmount',
                    style: TextStyle(
                        fontSize: discount > 0 ? 32 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text('/${durationText.isNotEmpty ? durationText.split(' ').first.toLowerCase() : 'total'}',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
            ),
          if (maxCoins > 0) _buildCoinSlider(planId, baseDiscountPrice.round(), maxCoins),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handlePurchase(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPopular ? Colors.blue : Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Unlock Now  →',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinSlider(String planId, int basePrice, int maxCoins) {
    final coins = _userStatus?['coins'] as int? ?? 0;
    if (coins <= 0 || maxCoins <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.monetization_on, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text('Use coins to save (You have $coins)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.amber.shade100,
                    thumbColor: Colors.amber.shade700,
                    overlayColor: Colors.amber.withOpacity(0.1),
                    valueIndicatorColor: Colors.amber.shade700,
                    valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                  ),
                  child: Slider(
                    value: _coinValues[planId] ?? 0,
                    min: 0,
                    max: maxCoins.toDouble(),
                    divisions: maxCoins,
                    label: '${_coinValues[planId]?.round() ?? 0} coins',
                    onChanged: (v) => setState(() => _coinValues[planId] = v),
                  ),
                ),
              ),
              Text('-₹${(_coinValues[planId] ?? 0).round()}',
                  style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecureBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Text('Secure payments powered by Razorpay',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}
