import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'home_page.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  // Fetch user data from Firestore
  Future<Map<String, String>> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = doc['username'] ?? 'User Name';
      final profileImage = doc['profileImage'] ?? '';
      final email = user.email ?? '';
      return {
        'username': username,
        'profileImage': profileImage,
        'email': email,
      };
    }
    return {'username': 'User Name', 'profileImage': '', 'email': ''};
  }

  // Log out the user
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer header with user profile
          SizedBox(
            height: 80,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.green.shade900),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FutureBuilder<Map<String, String>>(
                    future: _fetchUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }
                      if (snapshot.hasError) {
                        return const Icon(Icons.account_circle, size: 40, color: Colors.white);
                      }
                      final profileImage = snapshot.data?['profileImage'] ?? '';
                      return profileImage.isNotEmpty
                          ? CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(profileImage),
                            )
                          : const Icon(Icons.account_circle, size: 40, color: Colors.white);
                    },
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator(color: Colors.white);
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              "Error",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            );
                          }
                          return Text(
                            snapshot.data?['username'] ?? "User Name",
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          );
                        },
                      ),
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              "",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            );
                          }
                          return Text(
                            snapshot.data?['email'] ?? "",
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Menu options
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text("Account"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Home"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text("My orders"),
            onTap: () {
              // Navigate to orders page
            },
          ),
          ListTile(
            leading: const Icon(Icons.agriculture),
            title: const Text("Farm"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
          ),
          const SizedBox(height: 20),
          // Logout button
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Log out", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 245, 120, 11),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
