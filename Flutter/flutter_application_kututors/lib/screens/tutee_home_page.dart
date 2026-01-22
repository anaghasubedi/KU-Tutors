import 'package:flutter/material.dart';
import 'package:flutter_application_kututors/services/service_locator.dart';
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
  List<Map<String, dynamic>> _bookedClasses = [];
  List<Map<String, dynamic>> _completedClasses = [];
  bool _isLoadingTutors = true;
  bool _isLoadingBookedClasses = true;
  bool _isLoadingCompletedClasses = true;
  final bool _showAllTutors = false;
  
  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSubject;

  // Subject data for Computer Science
  final Map<String, String> _csSubjects = {
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
  final Map<String, String> _ceSubjects = {
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
    if (_selectedDepartment == 'CS') {
      return _csSubjects;
    } else if (_selectedDepartment == 'CE') {
      return _ceSubjects;
    }
    // When "All Departments" is selected, combine both subject lists
    return {..._csSubjects, ..._ceSubjects};
  }

  @override
  void initState() {
    super.initState();
    _loadTutors();
    _loadBookedClasses();
    _loadCompletedClasses();
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
      final data = await services.tutorService.listTutors(
        search: null,
        department: null,
        subject: null,
      );
      
      debugPrint('API Response: $data');
      debugPrint('Tutors count: ${data['tutors']?.length ?? 0}');
      
      setState(() {
        _tutors = List<Map<String, dynamic>>.from(data['tutors'] ?? []);
        _filteredTutors = _tutors;
        _isLoadingTutors = false;
      });
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

  Future<void> _loadBookedClasses() async {
    setState(() => _isLoadingBookedClasses = true);
    
    try {
      final data = await services.tuteeService.getBookedClasses();
      
      setState(() {
        _bookedClasses = List<Map<String, dynamic>>.from(data['booked_classes'] ?? []);
        _isLoadingBookedClasses = false;
      });
    } catch (e) {
      debugPrint('Error loading booked classes: $e');
      setState(() => _isLoadingBookedClasses = false);
    }
  }

  Future<void> _loadCompletedClasses() async {
    setState(() => _isLoadingCompletedClasses = true);
    
    try {
      final data = await services.tuteeService.getCompletedClasses();
      
      setState(() {
        _completedClasses = List<Map<String, dynamic>>.from(data['completed_classes'] ?? []);
        _isLoadingCompletedClasses = false;
      });
    } catch (e) {
      debugPrint('Error loading completed classes: $e');
      setState(() => _isLoadingCompletedClasses = false);
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
        _loadBookedClasses();
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

  void _applyFilters() {
    setState(() {
      _filteredTutors = _tutors.where((tutor) {
        final searchQuery = _searchController.text.toLowerCase();
        final userName = tutor['user']?['first_name']?.toLowerCase() ?? '';
        final lastName = tutor['user']?['last_name']?.toLowerCase() ?? '';
        final fullName = '$userName $lastName'.toLowerCase();
        final subject = tutor['subject']?.toLowerCase() ?? '';
        final department = tutor['department']?.toLowerCase() ?? '';
        
        // Search filter
        final matchesSearch = searchQuery.isEmpty ||
            fullName.contains(searchQuery) ||
            userName.contains(searchQuery) ||
            lastName.contains(searchQuery) ||
            subject.contains(searchQuery) ||
            department.contains(searchQuery);
        
        // Department filter
        bool matchesDepartment = true;
        if (_selectedDepartment != null) {
          if (_selectedDepartment == 'CS') {
            matchesDepartment = department.contains('computer science') || 
                               department == 'cs';
          } else if (_selectedDepartment == 'CE') {
            matchesDepartment = department.contains('computer engineering') || 
                               department == 'ce';
          }
        }
        
        // Subject filter
        bool matchesSubject = _selectedSubject == null;
        if (!matchesSubject && _selectedSubject != null) {
          matchesSubject = subject.contains(_selectedSubject!.toLowerCase()) ||
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
          SnackBar(content: Text('Logout failed: $e'))
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
    final tutorId = tutor['id'];
    
    if (tutorId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TutorProfilePage(
            isOwner: false,
            tutorId: tutorId,
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
    final tutorsToShow = _showAllTutors 
        ? _filteredTutors 
        : (_filteredTutors.length > 5 ? _filteredTutors.sublist(0, 5) : _filteredTutors);

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
                      // Search & Filters
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Departments', overflow: TextOverflow.ellipsis),
                                ),
                                DropdownMenuItem(
                                  value: 'CE',
                                  child: Text('Computer Engineering', overflow: TextOverflow.ellipsis),
                                ),
                                DropdownMenuItem(
                                  value: 'CS',
                                  child: Text('Computer Science', overflow: TextOverflow.ellipsis),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value;
                                  _selectedSubject = null;
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              isExpanded: true,
                              menuMaxHeight: 300,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Subjects', overflow: TextOverflow.ellipsis),
                                ),
                                ..._availableSubjects.entries.map((entry) {
                                  return DropdownMenuItem(
                                    value: entry.key,
                                    child: Text('${entry.key} - ${entry.value}', overflow: TextOverflow.ellipsis),
                                  );
                                }),
                              ],
                              onChanged: (value) {
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

                      // Browse Tutors
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
                      
                      if (_isLoadingTutors)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_filteredTutors.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No tutors match your filters'),
                          ),
                        )
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
                                final isOnline = tutor['is_online'] ?? false;
                                
                                String rateText = 'N/A';
                                final rateValue = tutor['rate'];
                                if (rateValue != null && rateValue.toString().isNotEmpty && rateValue.toString() != 'null' && rateValue.toString() != 'Not Provided') {
                                  rateText = rateValue.toString().startsWith('Rs') 
                                      ? rateValue.toString()
                                      : 'Rs. $rateValue/hr';
                                }
                                
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TutorCard(
                                    tutorName: fullName,
                                    subject: subject,
                                    rate: rateText,
                                    isOnline: isOnline,
                                    onTap: () => _viewTutorProfile(tutor),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Booked Classes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Booked Classes (${_bookedClasses.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_isLoadingBookedClasses)
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
                          final tutorName = booking['tutor_name'] ?? 'Unknown';
                          final subject = booking['subject'] ?? 'Not Specified';
                          final time = booking['time'] ?? 'N/A';
                          
                          return SessionRow(
                            tutor: tutorName,
                            subject: subject,
                            time: time,
                            actionText: 'Cancel',
                            onAction: () => _cancelBooking(booking),
                            isBooked: true,
                          );
                        }),
                      const SizedBox(height: 20),

                      // Completed Sessions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completed Sessions (${_completedClasses.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      if (_isLoadingCompletedClasses)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_completedClasses.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text('No completed sessions yet'),
                          ),
                        )
                      else
                        ..._completedClasses.take(3).map((session) {
                          final tutorName = session['tutor_name'] ?? 'Unknown';
                          final subject = session['subject'] ?? 'Not Specified';
                          final time = session['time'] ?? 'N/A';
                          
                          return CompletedSessionRow(
                            tutor: tutorName,
                            subject: subject,
                            time: time,
                          );
                        }),
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

// Tutor Card Widget with Online Status
class TutorCard extends StatelessWidget {
  final String tutorName;
  final String subject;
  final String rate;
  final bool isOnline;
  final VoidCallback onTap;

  const TutorCard({
    super.key,
    required this.tutorName,
    required this.subject,
    required this.rate,
    required this.isOnline,
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
            Stack(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF305E9D),
                  child: Icon(Icons.person, color: Colors.white, size: 32),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? Colors.green : Colors.grey,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tutorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subject,
              style: const TextStyle(fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              rate,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isOnline ? Colors.green : Colors.grey,
                  width: 1,
                ),
              ),
              child: Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
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

// Session Row Widget
class SessionRow extends StatelessWidget {
  final String tutor;
  final String subject;
  final String time;
  final String actionText;
  final VoidCallback onAction;
  final bool isBooked;

  const SessionRow({
    super.key,
    required this.tutor,
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

// Completed Session Row Widget
class CompletedSessionRow extends StatelessWidget {
  final String tutor;
  final String subject;
  final String time;

  const CompletedSessionRow({
    super.key,
    required this.tutor,
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