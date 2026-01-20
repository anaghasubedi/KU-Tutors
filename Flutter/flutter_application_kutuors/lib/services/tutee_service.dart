import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';

class TuteeService {
  final ApiClient _apiClient;

  TuteeService(this._apiClient);

  /// Get available demo sessions
  Future<Map<String, dynamic>> getDemoSessions() async {
    return await _apiClient.get(ApiEndpoints.demoSessions);
  }

  /// Get booked classes for the logged-in user
  Future<Map<String, dynamic>> getBookedClasses() async {
    return await _apiClient.get(ApiEndpoints.bookedClasses);
  }

  /// Book a demo session using availability ID
  Future<Map<String, dynamic>> bookDemoSession(int availabilityId) async {
    return await _apiClient.post(
      ApiEndpoints.bookDemoSession,
      body: {'availability_id': availabilityId},
    );
  }

  /// Cancel a booking
  Future<void> cancelBooking(int bookingId) async {
    await _apiClient.delete(
      ApiEndpoints.cancelBooking(bookingId),
    );
  }

  /// Add subjects for tutee (optional method for future use)
  Future<Map<String, dynamic>> addSubjects({
    String? subjectRequired,
    String? semester,
  }) async {
    final body = <String, dynamic>{};
    
    if (subjectRequired != null) body['subject_required'] = subjectRequired;
    if (semester != null) body['semester'] = semester;
    
    return await _apiClient.post(
      '/tutee/subjects/add/',
      body: body,
    );
  }
}