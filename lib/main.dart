import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'plant_growth_analysis_page.dart'; // 👈 Import the plant growth page

void main() {
  runApp(const TeraFarmApp());
}

class TeraFarmApp extends StatelessWidget {
  const TeraFarmApp({super.key});

  Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TeraFarm',
      theme: ThemeData(primarySwatch: Colors.green),
      routes: {
        '/growth-analysis':
            (context) => const PlantGrowthAnalysisPage(), // 👈 Add this route
      },
      home: FutureBuilder(
        future: _initializeFirebase(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error initializing Firebase"));
          } else {
            return const AuthWrapper();
          }
        },
      ),
    );
  }
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
            colors: [
              Colors.green.shade800,
              const Color.fromARGB(255, 47, 75, 48),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 80, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'TeraFarm',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 👇 You can navigate to PlantGrowthAnalysisPage for testing like this
    return const LandingPage(); // Or add a button in LandingPage to push to '/growth-analysis'
  }
}
