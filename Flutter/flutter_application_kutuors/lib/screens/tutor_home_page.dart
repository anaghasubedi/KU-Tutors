import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'tutor_profile.dart';
import 'login.dart';

class TutorHomePage extends StatefulWidget {
    const TutorHomePage({super.key});

  @override
  State<TutorHomePage> createState() => _TutorHomePageState();
}

class _TutorHomePageState extends State <TutorHomePage>{
  int _selectedIndex = 0;
  Future<void> _handlelogout() async{
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
        try{
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
    setState(() => _selectedIndex = index);
    if (index == 1) {
     Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => const TutorProfilePage(isOwner: true)
          ),
      ); 
    }
    else if (index == 2) {
      _handlelogout();
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
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Ongoing Sessions ----------------
            const Text('Ongoing Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: h * 0.015),
            Column(
              children: const [
                SessionCard(
                  tutee: 'Ram Sharma',
                  subject: 'Math',
                  time: 'Mon 4 PM',
                  buttonText: 'Mark Complete',
                ),
                SessionCard(
                  tutee: 'Sita Karki',
                  subject: 'Physics',
                  time: 'Wed 6 PM',
                  buttonText: 'Mark Complete',
                ),
              ],
            ),
            SizedBox(height: h * 0.03),

            // ---------------- Demo Bookings ----------------
            const Text('Demo Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: h * 0.015),
            Column(
              children: const [
                SessionCard(
                  tutee: 'Hari Adhikari',
                  subject: 'CS',
                  time: 'Fri 2 PM',
                  buttonText: 'Mark Complete',
                ),
              ],
            ),
            SizedBox(height: h * 0.03),

            // ---------------- Completed Sessions ----------------
            const Text('Completed Sessions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: h * 0.015),
            Column(
              children: const [
                SessionCard(
                  tutee: 'Ram Sharma',
                  subject: 'Math',
                  time: 'Last Mon 4 PM',
                  buttonText: 'Completed ✅',
                  isCompleted: true,
                ),
                SessionCard(
                  tutee: 'Sita Karki',
                  subject: 'Physics',
                  time: 'Last Wed 6 PM',
                  buttonText: 'Completed ✅',
                  isCompleted: true,
                ),
              ],
            ),
          ],
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

// ---------------- Session Card ----------------
class SessionCard extends StatelessWidget {
  final String tutee;
  final String subject;
  final String time;
  final String buttonText;
  final bool isCompleted;

  const SessionCard({
    super.key,
    required this.tutee,
    required this.subject,
    required this.time,
    required this.buttonText,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final double h = MediaQuery.of(context).size.height;
    final double w = MediaQuery.of(context).size.width;

    return Card(
      margin: EdgeInsets.symmetric(vertical: h * 0.008),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(w * 0.04),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Tutee Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tutee, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subject),
                Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            // Action Button
            ElevatedButton(
              onPressed: isCompleted ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305E9D),
                padding: EdgeInsets.symmetric(vertical: h * 0.015, horizontal: w * 0.04),
                minimumSize: Size(w * 0.28, h * 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}