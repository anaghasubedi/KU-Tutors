import 'package:flutter/material.dart';

class TuteeHomePage extends StatelessWidget {
  const TuteeHomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------------- Search & Filters ----------------
                      const Text('Search & Filters',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
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
                                DropdownMenuItem(value: 'CS', child: Text('CS')),
                                DropdownMenuItem(
                                    value: 'Math', child: Text('Math')),
                                DropdownMenuItem(
                                    value: 'Physics', child: Text('Physics')),
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
                                DropdownMenuItem(value: '101', child: Text('101')),
                                DropdownMenuItem(value: '102', child: Text('102')),
                              ],
                              onChanged: (_) {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Browse Tutors ----------------
                      const Text('Browse Tutors',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: const [
                            TutorCard(
                                tutorName: 'Ram Sharma',
                                subject: 'Math',
                                rate: 'Rs. 800/hr'),
                            SizedBox(width: 8),
                            TutorCard(
                                tutorName: 'Sita Karki',
                                subject: 'Physics',
                                rate: 'Rs. 900/hr'),
                            SizedBox(width: 8),
                            TutorCard(
                                tutorName: 'Hari Adhikari',
                                subject: 'CS',
                                rate: 'Rs. 1000/hr'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Demo Sessions ----------------
                      const Text('Demo Sessions',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(
                              tutor: 'Amit Sharma',
                              subject: 'Physics',
                              time: 'Mon 2 PM',
                              actionText: 'Book Class'),
                          SessionRow(
                              tutor: 'Sita Koirala',
                              subject: 'Math',
                              time: 'Wed 1 PM',
                              actionText: 'Book Class'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ---------------- Classes Booked ----------------
                      const Text('Classes Booked',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Column(
                        children: const [
                          SessionRow(
                              tutor: 'Amit Sharma',
                              subject: 'Physics',
                              time: 'Tue 3 PM',
                              actionText: 'Booked ✅'),
                          SessionRow(
                              tutor: 'Sita Koirala',
                              subject: 'Math',
                              time: 'Thu 4 PM',
                              actionText: 'Booked ✅'),
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
        selectedItemColor: const Color(0xFF305E9D),
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

  const TutorCard(
      {super.key,
      required this.tutorName,
      required this.subject,
      required this.rate});

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
                child: Icon(Icons.person, color: Colors.white)),
            const SizedBox(height: 8),
            Text(tutorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(subject),
            Text(rate, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305E9D),
                minimumSize: const Size.fromHeight(30),
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              child: const Text('View Profile', style: TextStyle(fontSize: 12)),
            )
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

  const SessionRow(
      {super.key,
      required this.tutor,
      required this.subject,
      required this.time,
      required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(tutor),
        subtitle: Text(subject),
        trailing: Column(
          mainAxisSize: MainAxisSize.min, // prevents extra vertical space
          children: [
            Text(time),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305E9D),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(80, 25),
              ),
              child: Text(actionText, style: const TextStyle(fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }
}