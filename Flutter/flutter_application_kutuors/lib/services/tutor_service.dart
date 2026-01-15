import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/api/api_endpoints.dart';

class TutorService {
  final ApiClient _apiClient;

  TutorService(this._apiClient);

  Future<Map<String, dynamic>> listTutors({
    String? search,
    String? department,
    String? subject,
  }) async {
    final Map<String, String> queryParams = {};
    
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (department != null && department.isNotEmpty) {
      queryParams['department'] = department;
    }
    if (subject != null && subject.isNotEmpty) {
      queryParams['subject'] = subject;
    }

    return await _apiClient.get(
      ApiEndpoints.listTutors,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<Map<String, dynamic>> searchTutorsBySubject(String query) async {
    return await _apiClient.get(
      ApiEndpoints.searchTutors,
      queryParams: {'query': query},
    );
  }

  Future<Map<String, dynamic>> getTutorProfile(int tutorId) async {
    return await _apiClient.get(
      ApiEndpoints.tutorProfile(tutorId),
    );
  }

  Future<Map<String, dynamic>> listDepartments() async {
    return await _apiClient.get(ApiEndpoints.departments);
  }

  Future<Map<String, dynamic>> listSubjects({String? department}) async {
    final queryParams = department != null && department.isNotEmpty
        ? {'department': department}
        : null;

    return await _apiClient.get(
      ApiEndpoints.subjects,
      queryParams: queryParams,
    );
  }
}