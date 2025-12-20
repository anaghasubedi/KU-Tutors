import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'screens/signup.dart';
import 'screens/login.dart';
import 'screens/forgot_password.dart';
import 'screens/confirmation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KU Tutors',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0072BB),
          primary: Color(0xFF0072BB),
          secondary: Color(0xFF4CB5F5),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0072BB),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF0072BB),
          foregroundColor: Colors.white,
        ),
        textTheme: TextTheme(
          headlineMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0072BB),
          ),
        ),
      ),
      home: const ForgotPasswordPage(), // Change this line to switch pages
    );
  }
}

