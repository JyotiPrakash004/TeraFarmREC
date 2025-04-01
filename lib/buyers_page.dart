import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Product_page.dart';
import 'home_page.dart'; // Import the dashboard page
import 'menu_page.dart'; // Import the MenuPage
import 'cart_page.dart'; // Import the CartPage
import 'community_page.dart'; // Import the CommunityPage
import 'shop_page.dart'; // Import ShopPage

class BuyersPage extends StatefulWidget {
  // Changed class name
  const BuyersPage({super.key});

  @override
  _BuyersPageState createState() => _BuyersPageState(); // Updated state class name
}

class _BuyersPageState extends State<BuyersPage> {
  // Changed state class name
  final List<Map<String, String>> categories = [
    {"name": "Onion", "image": "assets/onion.png"},
    {"name": "Tomato", "image": "assets/tomato.png"},
    {"name": "Beans", "image": "assets/beans.png"},
    {"name": "Greens", "image": "assets/greens.png"},
  ];

  void _onCategorySelected(String category) {
    print("Filtering farms by: $category");
  }

  void _onFarmSelected(DocumentSnapshot farmDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductPage(farmId: farmDoc.id)),
    );
  }

  int _selectedIndex = 2;

  void _onNavItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CommunityPage()),
      );
    } else if (index == 2) {
      // Already on BuyersPage, do nothing
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ShopPage()),
      );
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              ),
        ),
        title: Row(
          children: [
            Transform.translate(
              offset: Offset(
                -40,
                5,
              ), // Move the logo 40 pixels left and 5 pixels down
              child: Image.asset("assets/terafarm_logo.png", height: 40),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartPage(cartItems: []),
                ), // Navigate to CartPage
              );
            },
          ),
        ],
      ),
      drawer: MenuPage(), // Add the MenuPage as the drawer
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Search",
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Eat what makes you healthy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    categories.map((category) {
                      return GestureDetector(
                        onTap: () => _onCategorySelected(category["name"]!),
                        child: Column(
                          children: [
                            Image.asset(category["image"]!, width: 50),
                            SizedBox(height: 5),
                            Text(category["name"]!),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Farms around you",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.grey.shade700),
                  onPressed: () {},
                ),
              ],
            ),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('farms')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final farmDocs = snapshot.data!.docs;

                if (farmDocs.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text("No farms found."),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: farmDocs.length,
                  itemBuilder: (context, index) {
                    final farm = farmDocs[index].data() as Map<String, dynamic>;
                    final farmName = farm["farmName"] ?? "Unnamed Farm";
                    final description =
                        farm["farmDescription"] ?? "No description";
                    final imageUrl =
                        farm["imageUrl"] ?? "assets/sample_farm.png";
                    final scale = farm["scale"] ?? "N/A";
                    final rating = farm["rating"] ?? 4.0;

                    return GestureDetector(
                      onTap: () => _onFarmSelected(farmDocs[index]),
                      child: Card(
                        margin: EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              child:
                                  imageUrl.startsWith("assets/")
                                      ? Image.asset(
                                        imageUrl,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                      : Image.network(
                                        imageUrl,
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Scale: $scale"),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 16,
                                          ),
                                          Text(rating.toString()),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple, // Selected icon color
        unselectedItemColor: Colors.grey, // Unselected icon color
        onTap: _onNavItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment), // Community icon
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag), // Buy icon
            label: 'Buy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store), // Changed to shop icon
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}
