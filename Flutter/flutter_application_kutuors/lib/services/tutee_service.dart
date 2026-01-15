import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';

class TuteeService {
  final ApiClient _apiClient;

  TuteeService(this._apiClient);

  Future<Map<String, dynamic>> getDemoSessions() async {
    return await _apiClient.get(ApiEndpoints.demoSessions);
  }

  Future<Map<String, dynamic>> getBookedClasses() async {
    return await _apiClient.get(ApiEndpoints.bookedClasses);
  }

  Future<Map<String, dynamic>> bookDemoSession(int sessionId) async {
    return await _apiClient.post(
      ApiEndpoints.bookDemoSession,
      body: {'session_id': sessionId},
    );
  }

  Future<void> cancelBooking(int bookingId) async {
    await _apiClient.delete(
      ApiEndpoints.cancelBooking(bookingId),
    );
  }
}