import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'tutee_profile.dart';
import 'tutor_profile.dart';

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

  // Department & Subject selection
  String? selectedDepartment;
  String? selectedSubject;

  // Subject lists by department
  final Map<String, List<String>> subjectsByDept = {
    'CS': [
      'MATH 101','PHYS 101','COMP 102','ENGG 111','CHEM 101','EDRG 101','ENGG 101',
      'MATH 104','PHYS 102','COMP 116','ENGG 112','ENGT 105','ENVE 101','EDRG 102','ENGG 102',
      'MATH 208','MCSC 201','EEEG 202','EEEG 211','COMP 202','COMP 206','EEEG 217',
      'MATH 207','MCSC 202','COMP 204','COMP 231','COMP 232','COMP 207',
      'COMP 317','MGTS 301','COMP 307','COMP 315','COMP 316','COMP 342','COMP 311',
      'COMP 343','COMP 302','COMP 409','COMP 314','COMP 323','COMP 341','COMP 313',
      'MGTS 403','COMP 401','COMP 472','MGTS 402','COMP 486','COMP 408'
    ],
    'CE': [
      'MATH 101','PHYS 101','COMP 102','ENGG 111','CHEM 101','EDRG 101','ENGG 101',
      'MATH 104','PHYS 102','COMP 116','ENGG 112','ENGT 105','ENVE 101','EDRG 102','ENGG 102',
      'MATH 208','MCSC 201','EEEG 202','EEEG 211','COMP 202','COMP 206','EEEG 217',
      'MATH 207','MCSC 202','COMP 204','COMP 231','COMP 232','COMP 207',
      'MGTS 301','COMP 307','COMP 315','COEG 304','COMP 310','COMP 303','COMP 301',
      'COMP 304','COMP 302','COMP 342','COMP 314','COMP 306','COMP 343','COMP 308',
      'MGTS 403','COMP 401','COMP 472','COMP 409','COMP 407','MGTS 402','COMP 408'
    ],
  };

  List<String> get currentSubjects =>
      selectedDepartment != null ? subjectsByDept[selectedDepartment!] ?? [] : [];

  // API Base URL
  static const String baseUrl = 'http://192.168.16.245:8000';

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

  // ---------------- Filtered tutors ----------------
  List<Map<String, dynamic>> get filteredTutors {
    List<Map<String, dynamic>> list = _tutors;

    if (selectedDepartment != null && selectedDepartment!.isNotEmpty) {
      list = list.where((tutor) {
        final dept = tutor['department'] ?? '';
        return dept == selectedDepartment;
      }).toList();
    }

    if (selectedSubject != null && selectedSubject!.isNotEmpty) {
      list = list.where((tutor) {
        final subj = tutor['subject'] ?? '';
        return subj == selectedSubject;
      }).toList();
    }

    return list;
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TuteeProfilePage(isPrivateView: true)),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _viewTutorProfile(Map<String, dynamic> tutor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TutorProfilePage(isOwner: false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutorsList = filteredTutors;
    final tutorsToShow = _showAllTutors
        ? tutorsList
        : (tutorsList.length > 5 ? tutorsList.sublist(0, 5) : tutorsList);

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
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
                      const Text('Search & Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search tutors or subjects',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              value: selectedDepartment,
                              items: subjectsByDept.keys.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment = value;
                                  selectedSubject = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Subject',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              value: (selectedSubject != null && currentSubjects.contains(selectedSubject)) ? selectedSubject : null,
                              items: currentSubjects.map((subj) => DropdownMenuItem(value: subj, child: Text(subj))).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSubject = value;
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
                          const Text('Browse Tutors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (tutorsList.length > 5)
                            TextButton(
                              onPressed: () => setState(() => _showAllTutors = !_showAllTutors),
                              child: Text(_showAllTutors ? 'Show Less' : 'Show More',
                                  style: const TextStyle(color: Color(0xFF305E9D), fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_isLoadingTutors)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      else if (tutorsList.isEmpty)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No tutors available')))
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
                                  rate: rate.toString().startsWith('Rs') ? rate : 'Rs. $rate/hr',
                                  onTap: () => _viewTutorProfile(tutor),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ---------------- Demo Sessions ----------------
                      const Text('Demo Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(tutor: 'Amit Sharma', subject: 'Physics', time: 'Mon 2 PM', actionText: 'Book Class'),
                          SessionRow(tutor: 'Sita Koirala', subject: 'Math', time: 'Wed 1 PM', actionText: 'Book Class'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Classes Booked ----------------
                      const Text('Classes Booked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(tutor: 'Amit Sharma', subject: 'Physics', time: 'Tue 3 PM', actionText: 'Booked ✅'),
                          SessionRow(tutor: 'Sita Koirala', subject: 'Math', time: 'Thu 4 PM', actionText: 'Booked ✅'),
                        ],
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
            const CircleAvatar(radius: 30, backgroundColor: Color(0xFF305E9D), child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(height: 8),
            Text(tutorName, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            Text(subject, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(rate, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF305E9D), minimumSize: const Size.fromHeight(30), padding: const EdgeInsets.symmetric(vertical: 4)),
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

  const SessionRow({super.key, required this.tutor, required this.subject, required this.time, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(tutor),
        subtitle: Text(subject),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(time),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF305E9D), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), minimumSize: const Size(80, 25)),
              child: Text(actionText, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Tutor Profile Page ----------------
class TutorProfilePage extends StatelessWidget {
  final bool isOwner;
  const TutorProfilePage({super.key, this.isOwner = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      appBar: AppBar(title: const Text("Tutor Profile")),
      body: const Center(
        child: Text("Tutor Profile Page", style: TextStyle(color: Colors.white, fontSize: 20)),
      ),
    );
  }
}
