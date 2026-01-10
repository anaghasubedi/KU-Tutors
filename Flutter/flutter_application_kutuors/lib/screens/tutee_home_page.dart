import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tutee_profile.dart';
import 'tutor_profile.dart';
import 'login.dart';

class TuteeHomePage extends StatefulWidget {
  const TuteeHomePage({super.key});

  @override
  State<TuteeHomePage> createState() => _TuteeHomePageState();
}

class _TuteeHomePageState extends State<TuteeHomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _tutors = [];
  List<Map<String, dynamic>> _demoSessions = [];
  List<Map<String, dynamic>> _bookedClasses = [];
  bool _isLoadingTutors = true;
  bool _isLoadingDemos = true;
  bool _isLoadingBooked = true;
  bool _showAllTutors = false;
  
  // API Base URL -match with backend
  static const String baseUrl = 'http://192.168.16.1:8000';

  @override
  void initState() {
    super.initState();
    _loadTutors();
    _loadDemoSessions();
    _loadBookedClasses();
  }

  Future<void> _loadTutors() async {
    setState(() => _isLoadingTutors = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/list-tutors/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tutors = List<Map<String, dynamic>>.from(data['tutors']);
          _isLoadingTutors = false;
        });
      } else {
        throw Exception('Failed to load tutors');
      }
    } catch (e) {
      debugPrint('Error loading tutors: $e');
      setState(() => _isLoadingTutors = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tutors: $e')),
        );
      }
    }
  }

  Future<void> _loadDemoSessions() async {
    setState(() => _isLoadingDemos = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/demo-sessions/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _demoSessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          _isLoadingDemos = false;
        });
      } else {
        throw Exception('Failed to load demo sessions');
      }
    } catch (e) {
      debugPrint('Error loading demo sessions: $e');
      setState(() {
        _isLoadingDemos = false;
        // Fallback to empty list instead of showing error for demos
        _demoSessions = [];
      });
    }
  }

  Future<void> _loadBookedClasses() async {
    setState(() => _isLoadingBooked = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/booked-classes/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _bookedClasses = List<Map<String, dynamic>>.from(data['classes'] ?? []);
          _isLoadingBooked = false;
        });
      } else {
        throw Exception('Failed to load booked classes');
      }
    } catch (e) {
      debugPrint('Error loading booked classes: $e');
      setState(() {
        _isLoadingBooked = false;
        _bookedClasses = [];
      });
    }
  }

  Future<void> _bookDemoSession(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$baseUrl/api/book-demo/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'session_id': session['id'],
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully booked demo with ${session['tutor_name']}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Reload both demo sessions and booked classes
        await _loadDemoSessions();
        await _loadBookedClasses();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Failed to book demo');
      }
    } catch (e) {
      debugPrint('Error booking demo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book demo: $e'),
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
    if(index == 1){
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => const TuteeProfilePage(isPrivateView: true)
        ),
      );
    }
    else if (index == 2) {
      _handlelogout();
    }
    else {
      setState(() => _selectedIndex = index);
    }
  }

  void _viewTutorProfile(Map<String, dynamic> tutor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TutorProfilePage(isOwner: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutorsToShow = _showAllTutors 
        ? _tutors 
        : (_tutors.length > 5 ? _tutors.sublist(0, 5) : _tutors);

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
            _loadTutors(),
            _loadDemoSessions(),
            _loadBookedClasses(),
          ]);
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ---------------- Search & Filters ----------------
                        const Text(
                          'Search & Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search tutors or subjects',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Department',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'CS',
                                    child: Text('CS'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Math',
                                    child: Text('Math'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Physics',
                                    child: Text('Physics'),
                                  ),
                                ],
                                onChanged: (_) {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Subject Code',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: '101',
                                    child: Text('101'),
                                  ),
                                  DropdownMenuItem(
                                    value: '102',
                                    child: Text('102'),
                                  ),
                                ],
                                onChanged: (_) {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ---------------- Browse Tutors (KEPT SAME) ----------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Browse Tutors',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (_tutors.length > 5)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showAllTutors = !_showAllTutors;
                                  });
                                },
                                child: Text(
                                  _showAllTutors ? 'Show Less' : 'Show More',
                                  style: const TextStyle(
                                    color: Color(0xFF305E9D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        if (_isLoadingTutors)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_tutors.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No tutors available at the moment'),
                            ),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: tutorsToShow.map((tutor) {
                                final userName = tutor['user']?['first_name'] ?? 'Unknown';
                                final lastName = tutor['user']?['last_name'] ?? '';
                                final fullName = '$userName $lastName'.trim();
                                final subject = tutor['subject'] ?? 'Not Specified';
                                final rate = tutor['accountnumber'] ?? 'N/A';
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TutorCard(
                                    tutorName: fullName,
                                    subject: subject,
                                    rate: rate.toString().startsWith('Rs') 
                                        ? rate 
                                        : 'Rs. $rate/hr',
                                    onTap: () => _viewTutorProfile(tutor),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // ---------------- Demo Sessions (DYNAMIC) ----------------
                        const Text(
                          'Demo Sessions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        if (_isLoadingDemos)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_demoSessions.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No demo sessions available',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _demoSessions.map((session) {
                              return SessionRow(
                                tutor: session['tutor_name'] ?? 'Unknown',
                                subject: session['subject'] ?? 'N/A',
                                time: session['time'] ?? 'TBD',
                                actionText: 'Book Class',
                                onPressed: () => _bookDemoSession(session),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 20),

                        // ---------------- Classes Booked (DYNAMIC) ----------------
                        const Text(
                          'Classes Booked',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Center(
                                child: Text(
                                  'No booked classes yet',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: _bookedClasses.map((booking) {
                              return SessionRow(
                                tutor: booking['tutor_name'] ?? 'Unknown',
                                subject: booking['subject'] ?? 'N/A',
                                time: booking['time'] ?? 'TBD',
                                actionText: 'Booked ✅',
                                isBooked: true,
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

// ---------------- Tutor Card (KEPT SAME) ----------------
class TutorCard extends StatelessWidget {
  final String tutorName;
  final String subject;
  final String rate;
  final VoidCallback onTap;

  const TutorCard({
    super.key,
    required this.tutorName,
    required this.subject,
    required this.rate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF305E9D),
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              tutorName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subject,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              rate,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305E9D),
                minimumSize: const Size.fromHeight(30),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('View Profile', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Session Row (Updated) ----------------
class SessionRow extends StatelessWidget {
  final String tutor;
  final String subject;
  final String time;
  final String actionText;
  final bool isBooked;
  final VoidCallback? onPressed;

  const SessionRow({
    super.key,
    required this.tutor,
    required this.subject,
    required this.time,
    required this.actionText,
    this.isBooked = false,
    this.onPressed,
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
                    tutor,
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
                  onPressed: isBooked ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBooked ? Colors.green : const Color(0xFF305E9D),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(80, 25),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}