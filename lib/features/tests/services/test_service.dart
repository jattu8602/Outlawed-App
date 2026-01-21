import 'package:dio/dio.dart';
import '../models/test_models.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/api_constants.dart';

class TestService {
  final AuthService _authService;

  TestService(this._authService);

  // Fetch all free tests
  Future<List<TestModel>> getFreeTests() async {
    try {
      final response = await _authService.client.get(
        ApiConstants.freeTestsEndpoint,
        queryParameters: {'type': 'all'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> testsJson = response.data['tests'];
        return testsJson.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load free tests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching free tests: $e');
      rethrow;
    }
  }

  // Fetch all premium tests
  Future<List<TestModel>> getPremiumTests() async {
    try {
      final response = await _authService.client.get(
        ApiConstants.premiumTestsEndpoint,
        queryParameters: {'type': 'all'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> testsJson = response.data['tests'];
        return testsJson.map((json) => TestModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load premium tests: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching premium tests: $e');
      rethrow;
    }
  }

  // Fetch specific test details (passages + questions)
  Future<Map<String, dynamic>> getTestDetails(String id) async {
    try {
      final response = await _authService.client.get(
        ApiConstants.testDetailEndpoint(id),
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load test details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching test details: $e');
      rethrow;
    }
  }
}
