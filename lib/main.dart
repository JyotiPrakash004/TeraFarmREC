import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'landing_page.dart';

void main() {
  runApp(const TeraFarmApp());
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade800, const Color.fromARGB(255, 47, 75, 48)],
          ),
        ),
      ),
    );
  }
}

class TeraFarmApp extends StatelessWidget {
  const TeraFarmApp({super.key});

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _initializeFirebase(), // Offload Firebase initialization
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen(); // Show SplashScreen while Firebase initializes
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error initializing Firebase"));
          } else {
            return const AuthWrapper(); // Proceed to the app
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Always return LandingPage, regardless of auth status.
    return LandingPage();
  }
}
