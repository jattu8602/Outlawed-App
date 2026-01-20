
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/api_constants.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
    clientId: '637048765769-7qeqitad98ci79fmlf4q3afko4aksfs9.apps.googleusercontent.com', // Android Client ID
    serverClientId: '637048765769-dj2k2m6ah1c4d4j0fi76fsnvun5fs2ke.apps.googleusercontent.com', // Web Client ID
  );

  late Dio _dio;
  late PersistCookieJar _cookieJar;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    _cookieJar = PersistCookieJar(
      storage: FileStorage("$appDocPath/.cookies/"),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // Sign in with Google and exchange token
  Future<Map<String, dynamic>?> signIn() async {
    try {
      // 1. Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to retrieve ID Token from Google');
      }

      // 2. Exchange Token with Backend
      final Response response = await _dio.post(
        ApiConstants.mobileLoginEndpoint,
        data: {'idToken': idToken},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Success! Cookie is automatically saved by CookieManager
        return response.data;
      } else {
        throw Exception('Backend authentication failed: ${response.data}');
      }
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _cookieJar.deleteAll();
  }

  // Get Dio instance (authenticated)
  Dio get client => _dio;
}
