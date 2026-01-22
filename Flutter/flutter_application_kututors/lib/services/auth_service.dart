import 'package:flutter_application_kututors/core/api/api_client.dart';
import 'package:flutter_application_kututors/core/api/api_endpoints.dart';
import 'package:flutter_application_kututors/core/storage/token_storage.dart';

class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  AuthService(this._apiClient, this._tokenStorage);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {'email': email, 'password': password},
      requiresAuth: false,
    );

    await _tokenStorage.saveToken(response['token']);
    return response;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.signup,
      body: {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'password': password,
        'confirm_password': confirmPassword,
      },
      requiresAuth: false,
    );

    return response;
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyEmail,
      body: {'email': email, 'verification_code': code},
      requiresAuth: false,
    );

    await _tokenStorage.saveToken(response['token']);
    return response;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
      requiresAuth: false,
    );
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String verificationCode,
    required String newPassword,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'email': email,
        'verification_code': verificationCode,
        'new_password': newPassword,
      },
      requiresAuth: false,
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (e) {
      // Ignore logout errors from backend
    } finally {
      await _tokenStorage.deleteToken();
    }
  }

  Future<bool> isLoggedIn() async {
    return await _tokenStorage.hasToken();
  }
}