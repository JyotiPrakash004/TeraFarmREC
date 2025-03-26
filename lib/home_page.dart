import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Product_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Categories remain the same
  final List<Map<String, String>> categories = [
    {"name": "Onion", "image": "assets/onion.png"},
    {"name": "Tomato", "image": "assets/tomato.png"},
    {"name": "Beans", "image": "assets/beans.png"},
    {"name": "Greens", "image": "assets/greens.png"},
  ];

  // Logout function
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Category filter (dummy for now)
  void _onCategorySelected(String category) {
    print("Filtering farms by: $category");
  }

  // Farm selection → navigate to product page or farm details
  void _onFarmSelected(DocumentSnapshot farmDoc) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductPage(farmId: farmDoc.id),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar with logout button on the left
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
            // Search Bar
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

            // Title
            Text(
              "Eat what makes you healthy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            // Category Row
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

            // Farms Header + Filter Icon
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

            // Farms List from Firestore
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
                    // Updated key: using 'farmDescription' instead of 'description'
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
                            // Farm Image
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
                            // Farm Details
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
    );
  }
}
