class ApiEndpoints {
  // Change the IP address to your laptop's IP for physical device builds
  // Run server using: python manage.py runserver 0.0.0.0:8000
  static const String baseUrl = 'http://192.168.1.80:8000/api';

  // Auth endpoints
  static const String login = '/login/';
  static const String logout = '/logout/';
  static const String signup = '/signup/';
  static const String verifyEmail = '/verify-email/';
  static const String forgotPassword = '/forgot-password/';
  static const String resetPassword = '/reset-password/';

  // Profile endpoints
  static const String profile = '/profile/';
  static const String updateProfile = '/update-profile/';
  static const String uploadImage = '/upload-image/';
  static const String getImage = '/get-image/';
  static const String deleteAccount = '/delete-account/';

  // Tutor endpoints
  static const String listTutors = '/list-tutors/';
  static const String searchTutors = '/search-tutors/';
  static const String departments = '/departments/';
  static const String subjects = '/subjects/';
  
  static String tutorProfile(int tutorId) => '/tutor/$tutorId/';
  static String tutorAvailability(int tutorId) => '/tutor/$tutorId/availability/';

  // Availability endpoints
  static const String availability = '/availability/';
  static const String addAvailability = '/tutor/availability/add/';
  
  static String updateAvailability(int availabilityId) => 
      '/tutor/availability/$availabilityId/update/';
  static String deleteAvailability(int availabilityId) => 
      '/tutor/availability/$availabilityId/delete/';

  // Tutee endpoints
  static const String demoSessions = '/demo-sessions/';
  static const String bookedClasses = '/booked-classes/';
  static const String bookDemoSession = '/book-demo-session/';
  
  static String cancelBooking(int bookingId) => '/cancel-booking/$bookingId/';
}