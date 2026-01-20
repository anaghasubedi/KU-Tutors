import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';

class AvailabilityService {
  final ApiClient _apiClient;

  AvailabilityService(this._apiClient);

  /// Get availability for the current tutor (owner)
  Future<Map<String, dynamic>> getAvailability({
    String? date,
    String? fromDate,
  }) async {
    final queryParams = <String, String>{};
    
    if (date != null) queryParams['date'] = date;
    if (fromDate != null) queryParams['from_date'] = fromDate;
    
    return await _apiClient.get(
      '/tutor/availability/',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Get availability for a specific tutor by ID
  Future<Map<String, dynamic>> getTutorAvailability(int tutorId, {
    String? date,
    String? fromDate,
  }) async {
    final queryParams = <String, String>{
      'tutor_id': tutorId.toString(),
    };
    
    if (date != null) queryParams['date'] = date;
    if (fromDate != null) queryParams['from_date'] = fromDate;
    
    return await _apiClient.get(
      '/tutor/availability/',
      queryParams: queryParams,
    );
  }

  /// Add new availability slot
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

  /// Update existing availability slot
  Future<Map<String, dynamic>> updateAvailability(
    int availabilityId, {
    String? date,
    String? startTime,
    String? endTime,
    String? status,
  }) async {
    final body = <String, dynamic>{};
    
    if (date != null) body['date'] = date;
    if (startTime != null) body['start_time'] = startTime;
    if (endTime != null) body['end_time'] = endTime;
    if (status != null) body['status'] = status;
    
    return await _apiClient.patch(
      ApiEndpoints.updateAvailability(availabilityId),
      body: body,
    );
  }

  /// Update availability status (for marking sessions complete, etc.)
  Future<void> updateAvailabilityStatus({
    required int availabilityId,
    required String status,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.updateAvailability(availabilityId),
      body: {'status': status},
    );
  }

  /// Delete availability slot
  Future<void> deleteAvailability(int availabilityId) async {
    await _apiClient.delete(
      ApiEndpoints.deleteAvailability(availabilityId),
    );
  }
}