import 'package:dio/dio.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/api_constants.dart';

class PaymentService {
  final Dio _dio;
  final Razorpay _razorpay = Razorpay();
  bool _initialized = false;

  void Function()? onPaymentSuccess;
  void Function(String? code, String? description)? onPaymentError;

  PaymentService(this._dio);

  void _ensureInitialized() {
    if (_initialized) return;
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initialized = true;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onPaymentSuccess?.call();
  }

  void _handleError(PaymentFailureResponse response) {
    onPaymentError?.call(response.code.toString(), response.message);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  Future<Map<String, dynamic>> fetchPlans() async {
    final res = await _dio.get(ApiConstants.paymentPlansEndpoint);
    return {'plans': res.data is List ? res.data : []};
  }

  Future<Map<String, dynamic>> fetchUserStatus() async {
    final res = await _dio.get(ApiConstants.userStatusEndpoint);
    return res.data;
  }

  Future<Map<String, dynamic>> createOrder(String planId, int amount, {int coinsUsed = 0}) async {
    final res = await _dio.post(
      ApiConstants.createOrderEndpoint,
      data: {'planId': planId, 'amount': amount, 'coinsUsed': coinsUsed},
    );
    return res.data;
  }

  Future<String> fetchRazorpayKey() async {
    final res = await _dio.get(ApiConstants.razorpayKeyEndpoint);
    return res.data['key'] as String;
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    required String planId,
  }) async {
    final res = await _dio.post(
      ApiConstants.verifyPaymentEndpoint,
      data: {
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
        'planId': planId,
      },
    );
    return res.data;
  }

  Future<List<dynamic>> fetchPaymentHistory() async {
    final res = await _dio.get(ApiConstants.userPaymentsEndpoint);
    return res.data is List ? res.data : [];
  }

  Future<void> openCheckout({
    required String key,
    required String orderId,
    required int amount,
    required String planName,
    required String? email,
    required String? contact,
  }) async {
    _ensureInitialized();
    var options = {
      'key': key,
      'amount': amount * 100,
      'currency': 'INR',
      'name': 'OUTLAWED',
      'description': 'Payment for $planName',
      'order_id': orderId,
      'prefill': {
        'contact': contact ?? '',
        'email': email ?? '',
      },
      'theme': {'color': '#2563eb'},
    };
    _razorpay.open(options);
  }

  void dispose() {
    _razorpay.clear();
  }
}
