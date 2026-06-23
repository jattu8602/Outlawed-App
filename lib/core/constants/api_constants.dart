class ApiConstants {
  // Base URL for the hosted platform
  static const String baseUrl = 'https://www.outlawed.in';
  // static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://10.234.59.180:3000';

  // API Prefix
  static const String apiPrefix = '/api';

  // Auth Endpoints
  static const String mobileLoginEndpoint = '$apiPrefix/auth/mobile-login';

  // User Endpoints
  static const String userStreakEndpoint = '$apiPrefix/user/streak';
  static const String generateReferralEndpoint = '$apiPrefix/user/generate-referral';
  static const String referralStatsEndpoint = '$apiPrefix/user/referrals';

  // Helper to get full API URL
  static String get fullApiUrl => '$baseUrl$apiPrefix';

  // Tests Endpoints
  static const String freeTestsEndpoint = '$apiPrefix/tests/free';
  static const String premiumTestsEndpoint = '$apiPrefix/tests/premium';
  static String testDetailEndpoint(String id) => '$apiPrefix/tests/$id';
  static String testSubmitEndpoint(String id) => '$apiPrefix/tests/$id/submit';
}
