import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'login_page.dart';
import 'account_page.dart'; // Import the AccountPage
import 'home_page.dart'; // Import the DashboardPage

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  Future<Map<String, String>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final username = doc['username'] ?? 'User Name';
      final profileImage = doc['profileImage'] ?? ''; // Fetch profile image URL
      final email = user.email ?? ''; // Fetch user email
      return {
        'username': username,
        'profileImage': profileImage,
        'email': email,
      };
    }
    return {'username': 'User Name', 'profileImage': '', 'email': ''};
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
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80, // Set height explicitly
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.green.shade900),
              margin: EdgeInsets.zero, // Remove default margin
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FutureBuilder<Map<String, String>>(
                    future: _fetchUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(color: Colors.white);
                      }
                      if (snapshot.hasError) {
                        return Icon(
                          Icons.account_circle,
                          size: 40,
                          color: Colors.white,
                        );
                      }
                      final profileImage = snapshot.data?['profileImage'] ?? '';
                      return profileImage.isNotEmpty
                          ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              profileImage,
                            ), // Display profile image
                          )
                          : Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.white,
                          ); // Default icon
                    },
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(
                              color: Colors.white,
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "Error",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            );
                          }
                          return Text(
                            snapshot.data?['username'] ?? "User Name",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ), // Adjust font size
                          );
                        },
                      ),
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox.shrink(); // Avoid showing multiple progress indicators
                          }
                          if (snapshot.hasError) {
                            return Text(
                              "",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            snapshot.data?['email'] ?? "",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ), // Display email below username
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text("Account"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AccountPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text("Home"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.shopping_bag),
            title: Text("My orders"),
            onTap: () {
              // Navigate to orders page
            },
          ),
          ListTile(
            leading: Icon(Icons.agriculture),
            title: Text("Farm"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
            },
          ),
          SizedBox(height: 20), // Add spacing before the logout button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text("Log out", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(
                  255,
                  245,
                  120,
                  11,
                ), // Set button color to red
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
