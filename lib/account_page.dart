import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'edit_profile_page.dart'; // Import the EditProfilePage

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final farmQuery = await FirebaseFirestore.instance
          .collection('farms')
          .where('sellerId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final farmName = farmQuery.docs.isNotEmpty ? farmQuery.docs.first['farmName'] : null;

      return {
        ...userDoc.data() ?? {},
        'farmName': farmName ?? 'No farm registered',
      };
    }
    return {};
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 51, 99, 31),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 51, 99, 31),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading account details."));
          }
          final userDetails = snapshot.data ?? {};
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: userDetails['profileImage'] != null
                        ? NetworkImage(userDetails['profileImage'])
                        : null,
                    child: userDetails['profileImage'] == null
                        ? Icon(Icons.account_circle, size: 80, color: Colors.red.shade300)
                        : null,
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfilePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text("Edit profile"),
                  ),
                  SizedBox(height: 20),
                  _buildTextField("Username", userDetails['username'] ?? "N/A"),
                  _buildTextField("My email Address", userDetails['email'] ?? "N/A"),
                  _buildTextField("Phone number", userDetails['phone'] ?? "N/A"),
                  _buildTextField("Locality", userDetails['locality'] ?? "N/A"),
                  _buildTextField("My Farm's name", userDetails['farmName'] ?? "No farm registered"),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: Icon(Icons.power_settings_new, color: Colors.white),
                    label: Text("Log out", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 226, 90, 90),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 5),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: value,
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}
