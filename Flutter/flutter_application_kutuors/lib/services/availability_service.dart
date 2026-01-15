import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';

class AvailabilityService {
  final ApiClient _apiClient;

  AvailabilityService(this._apiClient);

  Future<Map<String, dynamic>> getAvailability() async {
    return await _apiClient.get(ApiEndpoints.availability);
  }

  Future<Map<String, dynamic>> getTutorAvailability(int tutorId) async {
    return await _apiClient.get(
      ApiEndpoints.tutorAvailability(tutorId),
    );
  }

  Future<Map<String, dynamic>> addAvailability({
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.addAvailability,
      body: {
        'date': date,
        'start_time': startTime,
        'end_time': endTime,
      },
    );
  }

  Future<Map<String, dynamic>> updateAvailabilityStatus({
    required int availabilityId,
    required String status,
  }) async {
    return await _apiClient.patch(
      ApiEndpoints.updateAvailability(availabilityId),
      body: {'status': status},
    );
  }

  Future<void> deleteAvailability(int availabilityId) async {
    await _apiClient.delete(
      ApiEndpoints.deleteAvailability(availabilityId),
    );
  }
}