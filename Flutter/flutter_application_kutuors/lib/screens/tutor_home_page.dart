import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/service_locator.dart';
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
  bool _isLoadingDemo = true;
  bool _isLoadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _loadAllSessions();
  }

  Future<void> _loadAllSessions() async {
    _loadOngoingSessions();
    _loadDemoBookings();
    _loadCompletedSessions();
  }

  Future<void> _loadOngoingSessions() async {
    setState(() => _isLoadingOngoing = true);
    
    try {
      final data = await services.tuteeService.getBookedClasses();
      
      setState(() {
        final allSessions = List<Map<String, dynamic>>.from(data['booked_classes'] ?? []);
        _ongoingSessions = allSessions.where((session) {
          final status = session['status']?.toString().toLowerCase() ?? '';
          final isDemo = session['is_demo'] == true || session['is_demo'] == 1;
          return status == 'ongoing' && !isDemo;
        }).toList();
        _isLoadingOngoing = false;
      });
    } catch (e) {
      debugPrint('Error loading ongoing sessions: $e');
      setState(() => _isLoadingOngoing = false);
    }
  }

  Future<void> _loadDemoBookings() async {
    setState(() => _isLoadingDemo = true);
    
    try {
      final data = await services.tuteeService.getDemoSessions();
      
      setState(() {
        _demoBookings = List<Map<String, dynamic>>.from(data['demo_sessions'] ?? []);
        _isLoadingDemo = false;
      });
    } catch (e) {
      debugPrint('Error loading demo bookings: $e');
      setState(() => _isLoadingDemo = false);
    }
  }

  Future<void> _loadCompletedSessions() async {
    setState(() => _isLoadingCompleted = true);
    
    try {
      final data = await services.tuteeService.getBookedClasses();
      
      setState(() {
        final allSessions = List<Map<String, dynamic>>.from(data['booked_classes'] ?? []);
        _completedSessions = allSessions.where((session) {
          final status = session['status']?.toString().toLowerCase() ?? '';
          return status == 'completed';
        }).toList();
        _isLoadingCompleted = false;
      });
    } catch (e) {
      debugPrint('Error loading completed sessions: $e');
      setState(() => _isLoadingCompleted = false);
    }
  }

  Future<void> _handleMarkComplete(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Session Complete'),
        content: Text('Mark session with ${session['tutee_name'] ?? 'student'} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await services.availabilityService.updateAvailabilityStatus(
        availabilityId: session['id'],
        status: 'completed',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session marked as completed')),
        );
        _loadAllSessions();
      }
    } catch (e) {
      debugPrint('Error marking session complete: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark complete: $e')),
        );
      }
    }
  }

  Future<void> _handleCancelBooking(Map<String, dynamic> session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text('Cancel demo session with ${session['tutee_name'] ?? 'student'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await services.tuteeService.cancelBooking(session['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
        _loadAllSessions();
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
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
        await services.authService.logout();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadAllSessions,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- Ongoing Sessions ----------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ongoing Sessions (${_ongoingSessions.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingOngoing)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_ongoingSessions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No ongoing sessions'),
                          ),
                        )
                      else
                        Column(
                          children: _ongoingSessions.map((session) {
                            final tuteeName = session['tutee_name'] ?? 
                                            session['student_name'] ?? 
                                            'Unknown';
                            final subject = session['subject'] ?? 'Not Specified';
                            final time = session['time'] ?? 
                                        session['scheduled_at'] ?? 
                                        'TBD';
                            
                            return SessionCard(
                              tutee: tuteeName,
                              subject: subject,
                              time: time,
                              buttonText: 'Mark Complete',
                              onPressed: () => _handleMarkComplete(session),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // ---------------- Demo Bookings ----------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Demo Bookings (${_demoBookings.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingDemo)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_demoBookings.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No demo bookings'),
                          ),
                        )
                      else
                        Column(
                          children: _demoBookings.map((session) {
                            final tuteeName = session['tutee_name'] ?? 
                                            session['student_name'] ?? 
                                            'Unknown';
                            final subject = session['subject'] ?? 'Not Specified';
                            final time = session['time'] ?? 
                                        session['scheduled_at'] ?? 
                                        'TBD';
                            
                            return SessionCard(
                              tutee: tuteeName,
                              subject: subject,
                              time: time,
                              buttonText: 'Cancel',
                              buttonColor: Colors.red,
                              onPressed: () => _handleCancelBooking(session),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // ---------------- Completed Sessions ----------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completed Sessions (${_completedSessions.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingCompleted)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_completedSessions.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No completed sessions'),
                          ),
                        )
                      else
                        Column(
                          children: _completedSessions.map((session) {
                            final tuteeName = session['tutee_name'] ?? 
                                            session['student_name'] ?? 
                                            'Unknown';
                            final subject = session['subject'] ?? 'Not Specified';
                            final time = session['time'] ?? 
                                        session['scheduled_at'] ?? 
                                        'Last session';
                            
                            return SessionCard(
                              tutee: tuteeName,
                              subject: subject,
                              time: time,
                              buttonText: 'Completed ✅',
                              isCompleted: true,
                            );
                          }).toList(),
                        ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
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

// ---------------- Session Card ----------------
class SessionCard extends StatelessWidget {
  final String tutee;
  final String subject;
  final String time;
  final String buttonText;
  final bool isCompleted;
  final VoidCallback? onPressed;
  final Color? buttonColor;

  const SessionCard({
    super.key,
    required this.tutee,
    required this.subject,
    required this.time,
    required this.buttonText,
    this.isCompleted = false,
    this.onPressed,
    this.buttonColor,
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
                backgroundColor: buttonColor ?? const Color(0xFF305E9D),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                minimumSize: const Size(100, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}