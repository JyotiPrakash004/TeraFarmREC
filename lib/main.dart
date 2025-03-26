import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'landing_page.dart';
import 'home_page.dart';
import 'dashboard_page.dart'; // Seller dashboard

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(TeraFarmApp());
}

class TeraFarmApp extends StatelessWidget {
  const TeraFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: AuthWrapper());
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              String role = userSnapshot.data!['role'] ?? 'buyer';
              return role == 'buyer' ? HomePage() : SellerDashboard();
            },
          );
        } else {
          return LandingPage();
        }
      },
    );
  }
}
