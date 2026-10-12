import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  // 1. Request OTP
  Future<Map<String, dynamic>> requestOtp(String contact) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/otp/request',
        data: {'contact': contact},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('OTP request failed: ${e.type}');
      debugPrint('HTTP status: ${e.response?.statusCode}');
      debugPrint('Response body: ${e.response?.data}');

      final data = e.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Server is taking too long. Please try again.');
      }

      throw Exception('Failed to send OTP. Please try again.');
    }
  }

  // 2. Verify OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String contact,
    required String code,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/api/v1/auth/otp/verify',
        data: {'contact': contact, 'code': code},
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;

      // 1. Try simple "message" field
      if (data is Map && data['message'] != null) {
        throw Exception(data['message']);
      }

      // 2. Try Problem Details "detail" field
      if (data is Map && data['detail'] != null) {
        throw Exception(data['detail']);
      }

      // 3. Timeout
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Server is taking too long. Please try again.');
      }

      // 4. Fallback
      throw Exception('Invalid OTP. Please try again.');
    }
  }
}
