import 'dart:io';
import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';
import 'package:flutter_application_kutuors/core/storage/token_storage.dart';

class ProfileService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  ProfileService(this._apiClient, this._tokenStorage);

  Future<Map<String, dynamic>> getUserProfile() async {
    return await _apiClient.get(ApiEndpoints.profile);
  }

  Future<Map<String, dynamic>> getProfileData() async {
    return await _apiClient.get(ApiEndpoints.updateProfile);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String contact,
  }) async {
    return await _apiClient.patch(
      ApiEndpoints.profile,
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'contact': contact,
      },
    );
  }

  Future<Map<String, dynamic>> updateProfileData({
    String? name,
    String? phoneNumber,
    String? subject,
    String? semester,
    String? rate,
    String? year,
    String? department,
    String? accountNumber,
  }) async {
    final Map<String, dynamic> body = {};
    
    if (name != null) body['name'] = name;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (subject != null) body['subject'] = subject;
    if (semester != null) body['semester'] = semester;
    if (rate != null) body['rate'] = rate;
    if (year != null) body['year'] = year;
    if (department != null) body['department'] = department;
    if (accountNumber != null) body['account_number'] = accountNumber;

    return await _apiClient.patch(
      ApiEndpoints.updateProfile,
      body: body,
    );
  }

  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    return await _apiClient.uploadFile(
      ApiEndpoints.uploadImage,
      imageFile.path,
      'image',
    );
  }

  Future<String?> getProfileImage() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.getImage);
      return response['image_url'] ?? response['image'];
    } catch (e) {
      // Return null if no image found
      return null;
    }
  }

  Future<void> deleteAccount() async {
    await _apiClient.delete(ApiEndpoints.deleteAccount);
    await _tokenStorage.deleteToken();
  }
}