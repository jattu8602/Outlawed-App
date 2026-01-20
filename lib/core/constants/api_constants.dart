class ApiConstants {
  // Base URL for the hosted platform
  // static const String baseUrl = 'https://outlawed.in';
  static const String baseUrl = 'http://localhost:3000';

  // API Prefix
  static const String apiPrefix = '/api';

  // Auth Endpoints
  static const String mobileLoginEndpoint = '$apiPrefix/auth/mobile-login';

  // Helper to get full API URL
  static String get fullApiUrl => '$baseUrl$apiPrefix';

  // Tests Endpoint (Example)
  static const String testsEndpoint = '$apiPrefix/tests';
}
