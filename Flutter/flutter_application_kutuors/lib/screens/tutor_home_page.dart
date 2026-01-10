import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tutor_profile.dart';
import 'login.dart';

class TutorHomePage extends StatefulWidget {
  const TutorHomePage({super.key});

  @override
  State<TutorHomePage> createState() => _TutorHomePageState();
}

class _TutorHomePageState extends State<TutorHomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _ongoingSessions = [];
  List<Map<String, dynamic>> _demoBookings = [];
  List<Map<String, dynamic>> _completedSessions = [];
  bool _isLoadingOngoing = true;
  bool _isLoadingDemos = true;
  bool _isLoadingCompleted = true;

  // API Base URL - match with backend
  static const String baseUrl = 'http://192.168.16.1:8000';

  @override
  void initState() {
    super.initState();
    _loadOngoingSessions();
    _loadDemoBookings();
    _loadCompletedSessions();
  }

  Future<void> _loadOngoingSessions() async {
    setState(() => _isLoadingOngoing = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/tutor/ongoing-sessions/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _ongoingSessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          _isLoadingOngoing = false;
        });
      } else {
        throw Exception('Failed to load ongoing sessions');
      }
    } catch (e) {
      debugPrint('Error loading ongoing sessions: $e');
      setState(() {
        _isLoadingOngoing = false;
        _ongoingSessions = [];
      });
    }
  }

  Future<void> _loadDemoBookings() async {
    setState(() => _isLoadingDemos = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/tutor/demo-bookings/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _demoBookings = List<Map<String, dynamic>>.from(data['bookings'] ?? []);
          _isLoadingDemos = false;
        });
      } else {
        throw Exception('Failed to load demo bookings');
      }
    } catch (e) {
      debugPrint('Error loading demo bookings: $e');
      setState(() {
        _isLoadingDemos = false;
        _demoBookings = [];
      });
    }
  }

  Future<void> _loadCompletedSessions() async {
    setState(() => _isLoadingCompleted = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/tutor/completed-sessions/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _completedSessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          _isLoadingCompleted = false;
        });
      } else {
        throw Exception('Failed to load completed sessions');
      }
    } catch (e) {
      debugPrint('Error loading completed sessions: $e');
      setState(() {
        _isLoadingCompleted = false;
        _completedSessions = [];
      });
    }
  }

  Future<void> _markAsComplete(Map<String, dynamic> session) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: Text(
          'Mark session with ${session['tutee_name']} as complete?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/tutor/mark-complete/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'session_id': session['id'],
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session with ${session['tutee_name']} marked as complete!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload data
        await _loadOngoingSessions();
        await _loadDemoBookings();
        await _loadCompletedSessions();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to mark as complete');
      }
    } catch (e) {
      debugPrint('Error marking session complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as complete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlelogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ApiService.logout();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TutorProfilePage(isOwner: true),
        ),
      );
    } else if (index == 2) {
      _handlelogout();
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF305E9D),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('assets/images/ku_logo.png', height: 50),
            const SizedBox(width: 12),
            const Text(
              'KU Tutors',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadOngoingSessions(),
            _loadDemoBookings(),
            _loadCompletedSessions(),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- Ongoing Sessions (DYNAMIC) ----------------
              const Text(
                'Ongoing Sessions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: h * 0.015),
              
              if (_isLoadingOngoing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_ongoingSessions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No ongoing sessions',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _ongoingSessions.map((session) {
                    return SessionCard(
                      tutee: session['tutee_name'] ?? 'Unknown',
                      subject: session['subject'] ?? 'N/A',
                      time: session['time'] ?? 'TBD',
                      buttonText: 'Mark Complete',
                      onPressed: () => _markAsComplete(session),
                    );
                  }).toList(),
                ),
              SizedBox(height: h * 0.03),

              // ---------------- Demo Bookings (DYNAMIC) ----------------
              const Text(
                'Demo Bookings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: h * 0.015),
              
              if (_isLoadingDemos)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_demoBookings.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No demo bookings',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _demoBookings.map((booking) {
                    return SessionCard(
                      tutee: booking['tutee_name'] ?? 'Unknown',
                      subject: booking['subject'] ?? 'N/A',
                      time: booking['time'] ?? 'TBD',
                      buttonText: 'Mark Complete',
                      onPressed: () => _markAsComplete(booking),
                    );
                  }).toList(),
                ),
              SizedBox(height: h * 0.03),

              // ---------------- Completed Sessions (DYNAMIC) ----------------
              const Text(
                'Completed Sessions',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: h * 0.015),
              
              if (_isLoadingCompleted)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_completedSessions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        'No completed sessions yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: _completedSessions.map((session) {
                    return SessionCard(
                      tutee: session['tutee_name'] ?? 'Unknown',
                      subject: session['subject'] ?? 'N/A',
                      time: session['time'] ?? 'TBD',
                      buttonText: 'Completed ✅',
                      isCompleted: true,
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      
      // ---------------- Bottom Navigation ----------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF305E9D),
        onTap: _onBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Log Out'),
        ],
      ),
    );
  }
}

// ---------------- Session Card (KEPT SIMPLE) ----------------
class SessionCard extends StatelessWidget {
  final String tutee;
  final String subject;
  final String time;
  final String buttonText;
  final bool isCompleted;
  final VoidCallback? onPressed;

  const SessionCard({
    super.key,
    required this.tutee,
    required this.subject,
    required this.time,
    required this.buttonText,
    this.isCompleted = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutee,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: isCompleted ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305E9D),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}