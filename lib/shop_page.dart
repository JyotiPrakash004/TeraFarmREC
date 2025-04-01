import 'package:flutter/material.dart';
import 'home_page.dart'; // Import HomePage for navigation
import 'community_page.dart'; // Import CommunityPage
import 'buyers_page.dart'; // Import BuyersPage

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  int _selectedIndex = 3; // Set default selected index to Shop

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return; // Prevent reloading the same page

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CommunityPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BuyersPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        title: Text("Shop"),
        backgroundColor: Colors.green.shade800,
      ),
      body: Center(
        child: Text(
          "Welcome to the Shop!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Shop'),
        ],
      ),
    );
  }
}
