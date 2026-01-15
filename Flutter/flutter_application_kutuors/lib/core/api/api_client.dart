import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_endpoints.dart';
import 'api_exceptions.dart';
import 'package:flutter_application_kutuors/core/storage/token_storage.dart';

class ApiClient {
  final TokenStorage _tokenStorage;

  ApiClient(this._tokenStorage);

  // GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint)
          .replace(queryParameters: queryParams);

      final headers = await _buildHeaders(requiresAuth);

      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      final headers = await _buildHeaders(requiresAuth);

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      final headers = await _buildHeaders(requiresAuth);

      final response = await http.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<void> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      final headers = await _buildHeaders(requiresAuth);

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw _handleResponse(response);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Multipart request for file uploads
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath,
    String fieldName,
  ) async {
    try {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw ApiException('Not authenticated');
      }

      final uri = Uri.parse(ApiEndpoints.baseUrl + endpoint);
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Token $token';
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, filePath),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Build headers with optional authentication
  Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = {'Content-Type': 'application/json'};

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token == null) {
        throw ApiException('Not authenticated');
      }
      headers['Authorization'] = 'Token $token';
    }

    return headers;
  }

  // Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body);
    }

    final error = jsonDecode(response.body);
    
    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(
          error['error'] ?? 'Invalid credentials',
        );
      case 403:
        throw ForbiddenException(
          error['error'] ?? 'Please verify your email first',
        );
      case 404:
        throw NotFoundException(
          error['error'] ?? 'Resource not found',
        );
      default:
        throw ApiException(
          _extractErrorMessage(error),
        );
    }
  }

  // Extract error message from response
  String _extractErrorMessage(dynamic error) {
    if (error is Map) {
      if (error.containsKey('email')) {
        return error['email'][0];
      } else if (error.containsKey('password')) {
        return error['password'][0];
      } else if (error.containsKey('error')) {
        return error['error'];
      }
    }
    return 'An error occurred';
  }

  // Handle errors
  Exception _handleError(dynamic e) {
    if (e is ApiException) {
      return e;
    }

    if (e.toString().contains('SocketException') ||
        e.toString().contains('Connection refused')) {
      return NetworkException(
        'Cannot connect to server. Make sure your Django server is running.',
      );
    }

    return ApiException(e.toString());
  }
}