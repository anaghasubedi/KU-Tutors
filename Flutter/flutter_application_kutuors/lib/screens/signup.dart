import 'package:flutter/material.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  String? selectedRole;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8BA3C7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/ku_logo.png',
                        height: 150,
                        width: 150,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CREATE AN ACCOUNT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField('Full Name'),
                      const SizedBox(height: 12),
                      _buildTextField('Email'),
                      const SizedBox(height: 12),
                      _buildTextField('Phone no.'),
                      const SizedBox(height: 12),
                      _buildRoleDropdown(),
                      const SizedBox(height: 12),
                      _buildTextFieldWithIcon('Password', Icons.visibility_outlined),
                      const SizedBox(height: 12),
                      _buildTextFieldWithIcon('Confirm Password', Icons.visibility_outlined),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7AB8),
                          foregroundColor: Colors.white,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: () {
                          // Handle signup logic
                        },
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Already have an account?",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7AB8),
                          foregroundColor: Colors.white,
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "LOG IN",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                selectedRole ?? 'Role',
                style: TextStyle(
                  color: selectedRole == null ? Colors.grey[600] : Colors.grey[800],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return SizedBox(
                    height: 150,
                    child: Column(
                      children: [
                        ListTile(
                          title: const Center(child: Text('Tutor')),
                          onTap: () {
                            setState(() {
                              selectedRole = 'Tutor';
                            });
                            Navigator.pop(context);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          title: const Center(child: Text('Tutee')),
                          onTap: () {
                            setState(() {
                              selectedRole = 'Tutee';
                            });
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(Icons.arrow_circle_down_outlined, color: Colors.grey[600], size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String labelText) {
    return SizedBox(
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: labelText,
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldWithIcon(String labelText, IconData icon) {
    return SizedBox(
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          textAlign: TextAlign.center,
          obscureText: labelText.toLowerCase().contains('password'),
          decoration: InputDecoration(
            hintText: labelText,
            hintStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            suffixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ),
    );
  }
}