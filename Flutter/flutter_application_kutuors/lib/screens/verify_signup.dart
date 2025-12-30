import 'package:flutter/material.dart';
import 'package:flutter_application_kutuors/services/api_service.dart';
import 'tutor_home_page.dart';
import 'tutee_home_page.dart';

class VerifySignupPage extends StatefulWidget {
  final String email;
  
  const VerifySignupPage({super.key, required this.email});

  @override
  State<VerifySignupPage> createState() => _VerifySignupPageState();
}

class _VerifySignupPageState extends State<VerifySignupPage> {
  bool _isLoading = false;
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter verification code'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_codeController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code must be 6 digits'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.verifyEmail(
        widget.email,
        _codeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Email verified successfully!'),
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

      debugPrint('Verification successful! Token: ${response['token']}');
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
                horizontal: screenWidth * 0.05, vertical: screenHeight * 0.03),
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
                  height: screenHeight * 0.25,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.02),

                // Title
                const Text(
                  'VERIFY EMAIL',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Instructions
                Text(
                  'A verification code has been sent to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Verification code field
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !_isLoading,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.85),
                    hintText: '000000',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.018,
                        horizontal: screenWidth * 0.04),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7AB8),
                      foregroundColor: Colors.white,
                      elevation: 5,
                      padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.022),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      disabledBackgroundColor: const Color(0xFF4A7AB8).withValues(alpha: 0.6),
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
                            'VERIFY',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Back to login
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Back to Signup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}