import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tutor_profile.dart';

class BrowseTutorsPage extends StatefulWidget {
  const BrowseTutorsPage({super.key});

  @override
  State<BrowseTutorsPage> createState() => _BrowseTutorsPageState();
}

class _BrowseTutorsPageState extends State<BrowseTutorsPage> {
  List<Map<String, dynamic>> _tutors = [];
  List<Map<String, dynamic>> _filteredTutors = [];
  bool _isLoadingTutors = true;
  
  // Filter controllers
  final TextEditingController _searchController = TextEditingController();
  String? _selectedDepartment;
  String? _selectedSubject;
  
  // API Base URL - match with backend
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
        
        // Search filter
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
        
        // Subject filter
        bool matchesSubject = _selectedSubject == null;
        if (!matchesSubject && _selectedSubject != null) {
          matchesSubject = subjectCode == _selectedSubject!.toLowerCase() ||
              subject.contains(_selectedSubject!.toLowerCase()) ||
              (_availableSubjects[_selectedSubject] != null && 
               subject.contains(_availableSubjects[_selectedSubject]!.toLowerCase()));
        }
        
        return matchesSearch && matchesDepartment && matchesSubject;
      }).toList();
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF305E9D),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Browse Tutors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tutors or subjects',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF2F5FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedDepartment,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF2F5FA),
                          hintText: 'Department',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          fillColor: const Color(0xFFF2F5FA),
                          hintText: 'Subject',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              child: Text(entry.key),
                            );
                          }),
                        ],
                        onChanged: _selectedDepartment == null
                            ? null
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
              ],
            ),
          ),
          
          // Results count
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '${_filteredTutors.length} Tutors Found',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Tutors List
          Expanded(
            child: _isLoadingTutors
                ? const Center(child: CircularProgressIndicator())
                : _filteredTutors.isEmpty
                    ? const Center(
                        child: Text(
                          'No tutors match your filters',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredTutors.length,
                        itemBuilder: (context, index) {
                          final tutor = _filteredTutors[index];
                          return TutorListCard(
                            tutor: tutor,
                            onTap: () => _viewTutorProfile(tutor),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class TutorListCard extends StatelessWidget {
  final Map<String, dynamic> tutor;
  final VoidCallback onTap;

  const TutorListCard({
    super.key,
    required this.tutor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userName = tutor['user']?['first_name'] ?? 'Unknown';
    final lastName = tutor['user']?['last_name'] ?? '';
    final fullName = '$userName $lastName'.trim();
    final subject = tutor['subject'] ?? 'Not Specified';
    final subjectCode = tutor['subject_code'] ?? '';
    final department = tutor['department'] ?? 'Not Specified';
    final rate = tutor['accountnumber'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 35,
                backgroundColor: const Color(0xFF305E9D),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              const SizedBox(width: 16),
              
              // Tutor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      department,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subjectCode.isNotEmpty ? '$subjectCode - $subject' : subject,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF305E9D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 18,
                          color: Color(0xFF305E9D),
                        ),
                        Text(
                          rate.toString().startsWith('Rs') ? rate : 'Rs. $rate/hr',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF305E9D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}