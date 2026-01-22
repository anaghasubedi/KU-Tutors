import 'package:flutter/material.dart';
import 'reset_password_new.dart';

class ResetPasswordConfirmationPage extends StatefulWidget {
  final String email;
  
  const ResetPasswordConfirmationPage({super.key, required this.email});

  @override
  State<ResetPasswordConfirmationPage> createState() => _ResetPasswordConfirmationPageState();
}

class _ResetPasswordConfirmationPageState extends State<ResetPasswordConfirmationPage> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerifyCode() {
    // Validate code
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
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

    // Navigate to new password page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResetPasswordNewPage(
          email: widget.email,
          verificationCode: _codeController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF4A7AB8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.05,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF8BA3C7),
                  borderRadius: BorderRadius.circular(24),
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
                  children: [
                    const Text(
                      'VERIFICATION\nCODE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    
                    Text(
                      "We've sent a verification code to\n${widget.email}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Verification Code field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _codeController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: InputDecoration(
                          hintText: 'Enter verification code',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7AB8),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.02,
                          ),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        onPressed: _handleVerifyCode,
                        child: Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}