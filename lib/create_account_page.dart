import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Firestore import
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // ✅ Firestore instance

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController =
      TextEditingController(); // ✅ Username field
  final TextEditingController phoneController =
      TextEditingController(); // ✅ Phone field

  void _registerUser() async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      // Store additional user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': usernameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'uid': userCredential.user!.uid,
      });

      // Redirect to Login Page after successful signup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
            image: AssetImage("assets/create_account_bg.png"),
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
              "Create an Account",
              style: TextStyle(fontSize: 22, color: Colors.orangeAccent),
            ),
            SizedBox(height: 20),

            _buildTextField("Username", usernameController), // ✅ Username field
            _buildTextField("Email Address", emailController),
            _buildTextField(
              "Phone Number",
              phoneController,
            ), // ✅ Phone number field
            _buildTextField("Password", passwordController, isPassword: true),

            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _registerUser,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Create an account",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
