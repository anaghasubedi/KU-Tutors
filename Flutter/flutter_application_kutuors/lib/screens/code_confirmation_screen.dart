import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CodeConfirmationScreen extends StatefulWidget {
  final String email;
  final String userType; // 'tutor' or 'tutee'
  final String? newPassword; // Optional: for password reset flow

  const CodeConfirmationScreen({
    Key? key,
    required this.email,
    required this.userType,
    this.newPassword,
  }) : super(key: key);

  @override
  State<CodeConfirmationScreen> createState() => _CodeConfirmationScreenState();
}

class _CodeConfirmationScreenState extends State<CodeConfirmationScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  int _remainingTime = 900; // 15 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().length != 6) {
      _showError('Please enter a 6-digit code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check if this is a password reset or email verification
      if (widget.newPassword != null) {
        // Password reset flow
        await _resetPassword();
      } else {
        // Email verification flow
        await _verifyEmail();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Network error. Please try again.');
    }
  }

  Future<void> _verifyEmail() async {
    final url = widget.userType == 'tutor'
        ? 'http://10.0.2.2:8000/api/tutor-verify-email/'
        : 'http://10.0.2.2:8000/api/tutee-verify-email/';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': widget.email,
        'code': _codeController.text.trim(),
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      _showSuccess('Email verified successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      final data = json.decode(response.body);
      _showError(data['error'] ?? 'Invalid verification code');
    }
  }

  Future<void> _resetPassword() async {
    final url = widget.userType == 'tutor'
        ? 'http://10.0.2.2:8000/api/tutor-reset-password/'
        : 'http://10.0.2.2:8000/api/tutee-reset-password/';

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': widget.email,
        'code': _codeController.text.trim(),
        'new_password': widget.newPassword,
        'confirm_password': widget.newPassword,
      }),
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      _showSuccess('Password reset successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      final data = json.decode(response.body);
      _showError(data['error'] ?? 'Invalid reset code');
    }
  }

  Future<void> _resendCode() async {
    setState(() => _isLoading = true);

    try {
      final url = widget.userType == 'tutor'
          ? 'http://10.0.2.2:8000/api/tutor-forgot-password/'
          : 'http://10.0.2.2:8000/api/tutee-forgot-password/';

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        setState(() {
          _remainingTime = 900;
          _timer?.cancel();
          _startTimer();
        });
        _showSuccess('New code sent to your email');
      } else {
        _showError('Failed to resend code');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Network error. Please try again.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A), // Deep blue background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card Container
                Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B5998), // Medium blue
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Title
                      const Text(
                        'CONFIRMATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Description
                      const Text(
                        "We've sent a confirmation code to your\nemail",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Email display
                      Text(
                        widget.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Timer
                      Text(
                        'Time remaining: ${_formatTime(_remainingTime)}',
                        style: TextStyle(
                          color: _remainingTime < 60 ? Colors.red : Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Code Input Field
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B7DC5), // Lighter blue
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Enter the verification code',
                            hintStyle: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              letterSpacing: 0,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C5282),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'VERIFY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Resend Code
                      TextButton(
                        onPressed: _isLoading ? null : _resendCode,
                        child: const Text(
                          'Resend Code',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
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
}