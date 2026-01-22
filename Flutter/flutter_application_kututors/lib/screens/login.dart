import 'package:flutter/material.dart';
import 'package:flutter_application_kututors/services/service_locator.dart';
import 'signup.dart';
import 'forgot_password.dart';
import 'tutor_home_page.dart';
import 'tutee_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Validate input
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Validate email format
    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await services.authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate based on user role
      final userRole = response['user']['role'];

      if (userRole == 'Tutor') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TutorHomePage()),
        );
      } else if (userRole == 'Tutee') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TuteeHomePage()),
        );
      }

      debugPrint('Login successful! Token: ${response['token']}');
      debugPrint('User: ${response['user']}');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: screenHeight * 0.03,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF8BA3C7),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/ku_logo.png',
                  height: screenHeight * 0.32,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.012),

                // Email field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.012),

                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),

                // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                   },
                  child: const Text(
                   'Forgot Password?',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

                // Login button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7AB8),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      disabledBackgroundColor: const Color(
                        0xFF4A7AB8,
                      ).withValues(alpha: 0.6),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: screenWidth * 0.05,
                            width: screenWidth * 0.05,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'LOG IN',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),

                // Don't have an account text
                const Text(
                  "Don't have an account?",
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                SizedBox(height: screenHeight * 0.008),

                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupPage(),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7AB8),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.022,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      disabledBackgroundColor: const Color(
                        0xFF4A7AB8,
                      ).withValues(alpha: 0.6),
                    ),
                    child: Text(
                      'SIGN UP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
