import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Product_page.dart';
import 'login_page.dart';
import 'dashboard_page.dart'; // Import the dashboard page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> categories = [
    {"name": "Onion", "image": "assets/onion.png"},
    {"name": "Tomato", "image": "assets/tomato.png"},
    {"name": "Beans", "image": "assets/beans.png"},
    {"name": "Greens", "image": "assets/greens.png"},
  ];

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _onCategorySelected(String category) {
    print("Filtering farms by: $category");
  }

  void _onFarmSelected(DocumentSnapshot farmDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductPage(farmId: farmDoc.id),
      ),
    );
  }

  int _selectedIndex = 0;

  void _onNavItemTapped(int index) {
    if (index == 1) {
      // Navigate to the dashboard when "Farm" is pressed
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SellerDashboard()),
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
        leading: IconButton(
          icon: Icon(Icons.logout, color: Colors.white),
          onPressed: _logout,
        ),
        title: Row(
          children: [
            Image.asset("assets/terafarm_logo.png", height: 40),
            SizedBox(width: 10),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
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
                children: categories.map((category) {
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
              stream: FirebaseFirestore.instance
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
                    final description = farm["farmDescription"] ?? "No description";
                    final imageUrl = farm["imageUrl"] ?? "assets/sample_farm.png";
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                              child: imageUrl.startsWith("assets/")
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
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(description, style: TextStyle(color: Colors.grey.shade700)),
                                  SizedBox(height: 5),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Scale: $scale"),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.orange, size: 16),
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
        selectedItemColor: Colors.purple, // Selected (Farm) icon is purple
        unselectedItemColor: Colors.grey,
        onTap: _onNavItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
    );
  }
}
