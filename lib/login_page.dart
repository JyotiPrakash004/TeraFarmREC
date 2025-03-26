import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'dashboard_page.dart';
import 'create_account_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String selectedRole = 'buyer'; // Default role selection

  void _loginUser(BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Update Firestore with selected role
      await _firestore.collection('users').doc(userCredential.user!.uid).set(
        {'role': selectedRole},
        SetOptions(merge: true), // Merge keeps existing data intact
      );

      // Navigate based on selected role
      if (selectedRole == 'seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SellerDashboard()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/login_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Login",
              style: TextStyle(fontSize: 22, color: Colors.orangeAccent),
            ),
            SizedBox(height: 20),

            _buildTextField("Email Address", emailController),
            _buildTextField("Password", passwordController, isPassword: true),

            SizedBox(height: 20),

            // Buyer/Seller Role Selection
            Text(
              "Select Role",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Row(
              children: [
                Radio(
                  value: 'buyer',
                  groupValue: selectedRole,
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
                Text("Buyer", style: TextStyle(color: Colors.white)),
                Radio(
                  value: 'seller',
                  groupValue: selectedRole,
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
                Text("Seller", style: TextStyle(color: Colors.white)),
              ],
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () => _loginUser(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Signup Navigation
            Center(
              child: TextButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateAccountPage(),
                      ),
                    ),
                child: Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.white)),
        SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }
}
