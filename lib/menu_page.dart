import 'package:TeraFarm/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'account_page.dart';
import 'home_page.dart';
import 'l10n/app_localizations.dart'; // Import localization

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

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        return const CircularProgressIndicator(
                          color: Colors.white,
                        );
                      }
                      if (snapshot.hasError) {
                        return const Icon(
                          Icons.account_circle,
                          size: 40,
                          color: Colors.white,
                        );
                      }
                      final profileImage = snapshot.data?['profileImage'] ?? '';
                      return profileImage.isNotEmpty
                          ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(profileImage),
                          )
                          : const Icon(
                            Icons.account_circle,
                            size: 40,
                            color: Colors.white,
                          );
                    },
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator(
                              color: Colors.white,
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              loc.error,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            );
                          }
                          return Text(
                            snapshot.data?['username'] ?? loc.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          );
                        },
                      ),
                      FutureBuilder<Map<String, String>>(
                        future: _fetchUserData(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snapshot.hasError) {
                            return const Text(
                              "",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            );
                          }
                          return Text(
                            snapshot.data?['email'] ?? "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
            leading: const Icon(Icons.account_circle),
            title: Text(loc.account),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(loc.home),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: Text(loc.myOrders),
            onTap: () {
              // TODO: Implement My Orders page navigation
            },
          ),
          ListTile(
            leading: const Icon(Icons.agriculture),
            title: Text(loc.farm),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: Text(
                loc.logout,
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 245, 120, 11),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
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
