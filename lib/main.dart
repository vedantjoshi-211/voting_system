import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:firebase_core/firebase_core.dart';

const Color _appBackground = Color(0xFF0B1020);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EVotingApp());
}

class EVotingApp extends StatelessWidget {
  const EVotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6C7CFF),
      brightness: Brightness.dark,
      surface: _appBackground,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Voting System',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _appBackground,
        canvasColor: _appBackground,
        cardColor: const Color(0xFF121A3A),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF121A3A),
        ),
      ),
      home: FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          // Show loading screen while Firebase initializes
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: _appBackground,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF4DD0E1)),
              ),
            );
          }

          // Show error if Firebase fails to initialize
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: _appBackground,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Error initializing app: ${snapshot.error}',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }

          // Firebase initialized successfully, show login page
          return const LoginPage();
        },
      ),
    );
  }
}
