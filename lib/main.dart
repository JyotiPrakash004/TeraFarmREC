import 'package:flutter/material.dart';
import 'landing_page.dart';

void main() {
  runApp(const TeraFarmApp());
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Optionally add navigation logic if you want a splash delay
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => LandingPage()));
    });

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
      ),
    );
  }
}

class TeraFarmApp extends StatelessWidget {
  const TeraFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
