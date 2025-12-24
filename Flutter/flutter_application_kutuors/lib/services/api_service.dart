import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IMPORTANT: Replace with your computer's local IP address
  // Find it by running 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux)
  // Example: if your IP is 192.168.1.5, use 'http://192.168.1.5:8000'
  static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
  
  // Login method
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save token to local storage
        await _saveToken(data['token']);
        
        return data;
      } else if (response.statusCode == 403) {
        // Email not verified
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Please verify your email first');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Make sure your Django server is running.');
      }
      rethrow;
    }
  }

  // Save token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        );
      }
    } catch (e) {
      // Ignore logout errors
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Signup method
  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phoneNumber,
    required String role,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'role': role,
          'password': password,
          'confirm_password': confirmPassword,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        // Handle different error formats
        if (error is Map) {
          // Get first error message
          String errorMsg = 'Signup failed';
          if (error.containsKey('email')) {
            errorMsg = error['email'][0];
          } else if (error.containsKey('password')) {
            errorMsg = error['password'][0];
          } else if (error.containsKey('error')) {
            errorMsg = error['error'];
          }
          throw Exception(errorMsg);
        }
        throw Exception('Signup failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server. Make sure your Django server is running.');
      }
      rethrow;
    }
  }

  // Verify email method
  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-email/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'verification_code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save token after verification
        await _saveToken(data['token']);
        
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Verification failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
        throw Exception('Cannot connect to server.');
      }
      rethrow;
    }
  }
}