import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final AuthService authService;

  const PaymentHistoryScreen({super.key, required this.authService});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late PaymentService _paymentService;
  List<dynamic> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(widget.authService.client);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final data = await _paymentService.fetchPaymentHistory();
      if (mounted) setState(() => _payments = data);
    } catch (_) {
      if (mounted) setState(() => _payments = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _payments.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text('No payment history yet',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey.shade500)),
                                const SizedBox(height: 8),
                                Text('Your purchases will appear here',
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _payments.length,
                      itemBuilder: (context, index) => _buildPaymentCard(_payments[index]),
                    ),
            ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    final p = payment as Map<String, dynamic>;
    final plan = p['plan'] as Map<String, dynamic>?;
    final status = p['status'] as String? ?? '';
    final amount = p['amount'] as num? ?? 0;
    final coinsUsed = p['coinsUsed'] as int? ?? 0;
    final planName = plan?['name'] as String? ?? 'Unknown Plan';
    final createdAt = p['createdAt'] as String? ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'SUCCESS':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Success';
      case 'FAILED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Failed';
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(planName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('₹$amount',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (coinsUsed > 0)
                        Text(' + $coinsUsed coins',
                            style: TextStyle(color: Colors.amber.shade700, fontSize: 12)),
                    ],
                  ),
                  if (createdAt.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_formatDate(createdAt),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statusText,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      ),
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
