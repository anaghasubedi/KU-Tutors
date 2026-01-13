import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tutee_profile.dart';
import 'tutor_profile.dart';
import 'browse_tutors.dart';
import 'login.dart';

class TuteeHomePage extends StatefulWidget {
  const TuteeHomePage({super.key});

  @override
  State<TuteeHomePage> createState() => _TuteeHomePageState();
}

class _TuteeHomePageState extends State<TuteeHomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _tutors = [];
  List<Map<String, dynamic>> _filteredTutors = [];
  bool _isLoadingTutors = true;
  final bool _showAllTutors = false;
  
  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSubject;
  
  // API Base URL -match with backend
  static const String baseUrl = 'http://192.168.16.1:8000';

  // Subject data for Computer Science
  final Map<String, String> _computerScienceSubjects = {
    'MATH 101': 'Calculus and Linear Algebra',
    'PHYS 101': 'General Physics I',
    'COMP 102': 'Computer Programming',
    'ENGG 111': 'Elements of Engineering I',
    'CHEM 101': 'General Chemistry',
    'EDRG 101': 'Engineering Drawing I',
    'MATH 104': 'Advanced Calculus',
    'PHYS 102': 'General Physics II',
    'COMP 116': 'Object-Oriented Programming',
    'ENGG 112': 'Elements Of Engineering II',
    'ENGT 105': 'Technical Communication',
    'ENVE 101': 'Introduction to Environmental Engineering',
    'EDRG 102': 'Engineering Drawing II',
    'MATH 208': 'Statistics and Probability',
    'MCSC 201': 'Discrete Mathematics/Structure',
    'EEEG 202': 'Digital Logic',
    'EEEG 211': 'Electronics Engineering I',
    'COMP 202': 'Data Structures and Algorithms',
    'MATH 207': 'Differential Equations and Complex Variables',
    'MCSC 202': 'Numerical Methods',
    'COMP 204': 'Communication and Networking',
    'COMP 231': 'Microprocessor and Assembly Language',
    'COMP 232': 'Database Management Systems',
    'COMP 317': 'Computational Operations Research',
    'MGTS 301': 'Engineering Economics',
    'COMP 307': 'Operating Systems',
    'COMP 315': 'Computer Architecture and Organization',
    'COMP 316': 'Theory of Computation',
    'COMP 342': 'Computer Graphics',
    'COMP 343': 'Information System Ethics',
    'COMP 302': 'System Analysis and Design',
    'COMP 409': 'Compiler Design',
    'COMP 314': 'Algorithms and Complexity',
    'COMP 323': 'Graph Theory',
    'COMP 341': 'Human Computer Interaction',
    'MGTS 403': 'Engineering Management',
    'COMP 401': 'Software Engineering',
    'COMP 472': 'Artificial Intelligence',
    'MGTS 402': 'Engineering Entrepreneurship',
    'COMP 486': 'Software Dependability',
  };
  
  // Subject data for Computer Engineering
  final Map<String, String> _computerEngineeringSubjects = {
    'MATH 101': 'Calculus and Linear Algebra',
    'PHYS 101': 'General Physics I',
    'COMP 102': 'Computer Programming',
    'ENGG 111': 'Elements of Engineering I',
    'CHEM 101': 'General Chemistry',
    'EDRG 101': 'Engineering Drawing I',
    'MATH 104': 'Advanced Calculus',
    'PHYS 102': 'General Physics II',
    'COMP 116': 'Object-Oriented Programming',
    'ENGG 112': 'Elements Of Engineering II',
    'ENGT 105': 'Technical Communication',
    'ENVE 101': 'Introduction to Environmental Engineering',
    'EDRG 102': 'Engineering Drawing II',
    'MATH 208': 'Statistics and Probability',
    'MCSC 201': 'Discrete Mathematics/Structure',
    'EEEG 202': 'Digital Logic',
    'EEEG 211': 'Electronics Engineering I',
    'COMP 202': 'Data Structures and Algorithms',
    'MATH 207': 'Differential Equations and Complex Variables',
    'MCSC 202': 'Numerical Methods',
    'COMP 204': 'Communication and Networking',
    'COMP 231': 'Microprocessor and Assembly Language',
    'COMP 232': 'Database Management Systems',
    'MGTS 301': 'Engineering Economics',
    'COMP 307': 'Operating Systems',
    'COMP 315': 'Computer Architecture and Organization',
    'COEG 304': 'Instrumentation and Control',
    'COMP 310': 'Laboratory Work',
    'COMP 301': 'Principles of Programming Languages',
    'COMP 304': 'Operations Research',
    'COMP 302': 'System Analysis and Design',
    'COMP 342': 'Computer Graphics',
    'COMP 314': 'Algorithms and Complexity',
    'COMP 306': 'Embedded Systems',
    'COMP 343': 'Information System Ethics',
    'MGTS 403': 'Engineering Management',
    'COMP 401': 'Software Engineering',
    'COMP 472': 'Artificial Intelligence',
    'COMP 409': 'Compiler Design',
    'COMP 407': 'Digital Signal Processing',
    'MGTS 402': 'Engineering Entrepreneurship',
  };
  
  // Get available subjects based on selected department
  Map<String, String> get _availableSubjects {
    if (_selectedDepartment == 'Computer Science') {
      return _computerScienceSubjects;
    } else if (_selectedDepartment == 'Computer Engineering') {
      return _computerEngineeringSubjects;
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _loadTutors();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          _filteredTutors = _tutors;
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

  void _applyFilters() {
    setState(() {
      _filteredTutors = _tutors.where((tutor) {
        final searchQuery = _searchController.text.toLowerCase();
        final userName = tutor['user']?['first_name']?.toLowerCase() ?? '';
        final lastName = tutor['user']?['last_name']?.toLowerCase() ?? '';
        final fullName = '$userName $lastName'.toLowerCase();
        final subject = tutor['subject']?.toLowerCase() ?? '';
        final department = tutor['department']?.toLowerCase() ?? '';
        final subjectCode = tutor['subject_code']?.toLowerCase() ?? '';
        
        // Search filter - search in name, subject, department, and subject code
        final matchesSearch = searchQuery.isEmpty ||
            fullName.contains(searchQuery) ||
            userName.contains(searchQuery) ||
            lastName.contains(searchQuery) ||
            subject.contains(searchQuery) ||
            department.contains(searchQuery) ||
            subjectCode.contains(searchQuery);
        
        // Department filter
        final matchesDepartment = _selectedDepartment == null ||
            department == _selectedDepartment!.toLowerCase();
        
        // Subject filter - matches either subject code or subject name
        bool matchesSubject = _selectedSubject == null;
        if (!matchesSubject && _selectedSubject != null) {
          // Check if selected subject matches the tutor's subject code or subject name
          matchesSubject = subjectCode == _selectedSubject!.toLowerCase() ||
              subject.contains(_selectedSubject!.toLowerCase()) ||
              (_availableSubjects[_selectedSubject] != null && 
               subject.contains(_availableSubjects[_selectedSubject]!.toLowerCase()));
        }
        
        return matchesSearch && matchesDepartment && matchesSubject;
      }).toList();
    });
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
  final tutorId = tutor['id']; // Get tutor profile ID
  
  if (tutorId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TutorProfilePage(
          isOwner: false,
          tutorId: tutorId, // Pass the tutor ID
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to load tutor profile')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // Determine how many tutors to show
    final tutorsToShow = _showAllTutors 
        ? _filteredTutors 
        : (_filteredTutors.length > 5 ? _filteredTutors.sublist(0, 5) : _filteredTutors);

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
                        controller: _searchController,
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
                              initialValue: _selectedDepartment,
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
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Departments'),
                                ),
                                DropdownMenuItem(
                                  value: 'Computer Engineering',
                                  child: Text('Computer Engineering'),
                                ),
                                DropdownMenuItem(
                                  value: 'Computer Science',
                                  child: Text('Computer Science'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubject = null; // Reset subject when department changes
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedSubject,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Subject',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              menuMaxHeight: 300,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Subjects'),
                                ),
                                ..._availableSubjects.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text('${entry.key} - ${entry.value}'),
                                  );
                                }),
                              ],
                              onChanged: _selectedDepartment == null
                                  ? null // Disable if no department selected
                                  : (value) {
                                      setState(() {
                                        _selectedSubject = value;
                                        _applyFilters();
                                      });
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Browse Tutors ----------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Browse Tutors (${_filteredTutors.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                      if (_filteredTutors.length > 5)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BrowseTutorsPage(),
                                ),
                              );
                            },
                            child: const Text(
                             'Show More',
                                style: TextStyle(
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
                      else if (_filteredTutors.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No tutors match your filters'),
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