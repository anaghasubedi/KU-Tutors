// lib/core/service_locator.dart
import 'package:flutter_application_kutuors/services/auth_service.dart';
import 'package:flutter_application_kutuors/services/profile_service.dart';
import 'package:flutter_application_kutuors/services/tutor_service.dart';
import 'package:flutter_application_kutuors/services/availability_service.dart';
import 'package:flutter_application_kutuors/services/tutee_service.dart';
import 'package:flutter_application_kutuors/core/api/api_client.dart';
import 'package:flutter_application_kutuors/core/storage/token_storage.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  late final TokenStorage tokenStorage;
  late final ApiClient apiClient;
  late final AuthService authService;
  late final ProfileService profileService;
  late final TutorService tutorService;
  late final AvailabilityService availabilityService;
  late final TuteeService tuteeService;

  void initialize() {
    tokenStorage = TokenStorage();
    apiClient = ApiClient(tokenStorage);
    authService = AuthService(apiClient, tokenStorage);
    profileService = ProfileService(apiClient, tokenStorage);
    tutorService = TutorService(apiClient);
    availabilityService = AvailabilityService(apiClient);
    tuteeService = TuteeService(apiClient);
  }
}

// Global getter for easy access
final services = ServiceLocator();