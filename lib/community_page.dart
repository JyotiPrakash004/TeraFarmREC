import 'package:flutter/material.dart';
import 'package:terafarm/buyers_page.dart';
import 'package:terafarm/home_page.dart';
import 'account_page.dart';
import 'shop_page.dart'; // Import ShopPage

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 1;

    void _onNavItemTapped(int index) {
      if (index == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else if (index == 1) {
        // Already on CommunityPage, do nothing
      } else if (index == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BuyersPage()),
        );
      } else if (index == 3) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShopPage()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Center(
        child: Text(
          'Welcome to the Community Page!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onNavItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Community',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Buy'),
          BottomNavigationBarItem(
            icon: Icon(Icons.store), // Changed to shop icon
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}
