import 'package:flutter/material.dart';
import 'package:flutter_application_kututors/services/service_locator.dart';
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
  List<Map<String, dynamic>> _bookedClasses = [];
  List<Map<String, dynamic>> _completedSessions = [];
  bool _isLoadingOngoing = true;
  bool _isLoadingBooked = true;
  bool _isLoadingCompleted = true;

  @override
  void initState() {
    super.initState();
    _loadAllSessions();
  }

  Future<void> _loadAllSessions() async {
    _loadOngoingSessions();
    _loadBookedClasses();
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

  Future<void> _loadBookedClasses() async {
    setState(() => _isLoadingBooked = true);
    
    try {
      final data = await services.tuteeService.getBookedClasses();
      
      setState(() {
        _bookedClasses = List<Map<String, dynamic>>.from(data['booked_classes'] ?? []);
        _isLoadingBooked = false;
      });
    } catch (e) {
      debugPrint('Error loading booked classes: $e');
      setState(() => _isLoadingBooked = false);
    }
  }

  Future<void> _loadCompletedSessions() async {
    setState(() => _isLoadingCompleted = true);
    
    try {
      final data = await services.tuteeService.getCompletedClasses();
      
      setState(() {
        _completedSessions = List<Map<String, dynamic>>.from(data['completed_classes'] ?? []);
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

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await services.tuteeService.cancelBooking(booking['id']);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled successfully')),
        );
        _loadAllSessions();
      }
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel booking: $e')),
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

                      // ---------------- My Classes (Booked Classes) ----------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Classes (${_bookedClasses.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoadingBooked)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_bookedClasses.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No booked classes'),
                          ),
                        )
                      else
                        ..._bookedClasses.take(3).map((booking) {
                          final tuteeName = booking['tutee_name'] ?? 
                                          booking['student_name'] ?? 
                                          'Unknown';
                          final subject = booking['subject'] ?? 'Not Specified';
                          final time = booking['time'] ?? 
                                      booking['scheduled_at'] ?? 
                                      'N/A';
                          
                          return SessionRow(
                            tutee: tuteeName,
                            subject: subject,
                            time: time,
                            actionText: 'Cancel',
                            onAction: () => _cancelBooking(booking),
                            isBooked: true,
                          );
                        }),
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
                            child: Text('No completed sessions yet'),
                          ),
                        )
                      else
                        ..._completedSessions.take(3).map((session) {
                          final tuteeName = session['tutee_name'] ?? 
                                          session['student_name'] ?? 
                                          'Unknown';
                          final subject = session['subject'] ?? 'Not Specified';
                          final time = session['time'] ?? 
                                      session['scheduled_at'] ?? 
                                      'N/A';
                          
                          return CompletedSessionRow(
                            tutee: tuteeName,
                            subject: subject,
                            time: time,
                          );
                        }),

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

// ---------------- Session Card (for Ongoing Sessions) ----------------
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

// ---------------- Session Row (for My Classes) ----------------
class SessionRow extends StatelessWidget {
  final String tutee;
  final String subject;
  final String time;
  final String actionText;
  final VoidCallback onAction;
  final bool isBooked;

  const SessionRow({
    super.key,
    required this.tutee,
    required this.subject,
    required this.time,
    required this.actionText,
    required this.onAction,
    this.isBooked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
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
                      fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBooked ? Colors.red : const Color(0xFF305E9D),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(80, 25),
                  ),
                  child: Text(actionText, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Completed Session Row ----------------
class CompletedSessionRow extends StatelessWidget {
  final String tutee;
  final String subject;
  final String time;

  const CompletedSessionRow({
    super.key,
    required this.tutee,
    required this.subject,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutee,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
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
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}