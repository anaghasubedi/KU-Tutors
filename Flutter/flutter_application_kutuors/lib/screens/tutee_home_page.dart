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
  bool _isLoadingTutors = true;
  bool _showAllTutors = false;
  
  // API Base URL -match with backend
  static const String baseUrl = 'http://192.168.16.1:8000';

  @override
  void initState() {
    super.initState();
    _loadTutors();
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
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
    // Only update _selectedIndex for Home (index 0)
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
    // Determine how many tutors to show
    final tutorsToShow = _showAllTutors 
        ? _tutors 
        : (_tutors.length > 5 ? _tutors.sublist(0, 5) : _tutors);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF305E9D),
        automaticallyImplyLeading: false, // Remove back arrow
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
                      // ---------------- Search ----------------
                      const Text(
                        'Search Tutors',
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
                      const SizedBox(height: 20),

                      // ---------------- Browse Tutors ----------------
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
                      
                      // Loading state
                      if (_isLoadingTutors)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      // No tutors found
                      else if (_tutors.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No tutors available at the moment'),
                          ),
                        )
                      // Display tutors
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...tutorsToShow.map((tutor) {
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
                              }),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // ---------------- Demo Sessions ----------------
                      const Text(
                        'Demo Sessions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(
                            tutor: 'Amit Sharma',
                            subject: 'Physics',
                            time: 'Mon 2 PM',
                            actionText: 'Book Class',
                          ),
                          SessionRow(
                            tutor: 'Sita Koirala',
                            subject: 'Math',
                            time: 'Wed 1 PM',
                            actionText: 'Book Class',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Classes Booked ----------------
                      const Text(
                        'Classes Booked',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(
                            tutor: 'Amit Sharma',
                            subject: 'Physics',
                            time: 'Tue 3 PM',
                            actionText: 'Booked ✅',
                          ),
                          SessionRow(
                            tutor: 'Sita Koirala',
                            subject: 'Math',
                            time: 'Thu 4 PM',
                            actionText: 'Booked ✅',
                          ),
                        ],
                      ),

                      const Spacer(), // fills remaining space to avoid overflow
                    ],
                  ),
                ),
              ),
            );
          },
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

// ---------------- Tutor Card ----------------
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

// ---------------- Session Row ----------------
class SessionRow extends StatelessWidget {
  final String tutor;
  final String subject;
  final String time;
  final String actionText;

  const SessionRow({
    super.key,
    required this.tutor,
    required this.subject,
    required this.time,
    required this.actionText,
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF305E9D),
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