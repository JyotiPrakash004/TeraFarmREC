import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_page.dart';
import 'order_list_page.dart';
import 'list_farm_page.dart';
import 'login_page.dart';
import 'home_page.dart'; 
import 'edit_farm_page.dart';
import 'chatbot_page.dart'; // <-- Added import for ChatbotPage

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  _SellerDashboardState createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double earnings = 5000.0;

  // Set default selected index to 1 (Farm)
  int _selectedIndex = 1;

  // Logout function that signs out and navigates to the login page
  void logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Bottom navigation tap handler
  void _onNavItemTapped(int index) {
    if (index == 0) {
      // Navigate to HomePage when home button is tapped
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 1) {
      // Already on SellerDashboard (Farm), so do nothing.
    } else if (index == 2) {
      // Change nothing else; regardless of tapped icon, keep Farm (index 1) selected.
    }
    // Always reset selected index to 1 so that only the Farm icon is colored.
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    String sellerId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removed the default back button
        backgroundColor: Colors.green.shade900, // Updated to match HomePage AppBar color
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start, // Left align the title content
          children: [
            Icon(Icons.menu, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "Dashboard",
              style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple, // Selected (Farm) icon is purple
        unselectedItemColor: Colors.grey, // Others remain grey
        onTap: _onNavItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Account'),
        ],
      ),
      // Updated FloatingActionButton with custom icon for plant care
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade800,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PlantCareApp()),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.eco, color: Colors.white, size: 28), // Leaf icon
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10),
              Text(
                "Total Earnings: Rs.${earnings.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text("Bar Chart Placeholder")),
              ),
              SizedBox(height: 20),
              // Centered dashboard buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      _buildDashboardButton("List a Farm", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ListFarmPage()),
                        );
                      }),
                      SizedBox(height: 10),
                      _buildDashboardButton("List a Produce", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddProductPage()),
                        );
                      }),
                      SizedBox(height: 10),
                      _buildDashboardButton("Orders", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderListPage()),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              // "Your Farm" heading
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Your Farm",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 10),
              // Display the farm created by this seller
              Center(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('farms')
                      .where('sellerId', isEqualTo: sellerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return SizedBox();
                    final farms = snapshot.data!.docs;
                    if (farms.isEmpty) return Text("No farm registered by you.");

                    final farm = farms.first;
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditFarmPage(farmId: farm.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 45, 126, 48),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            farm['farmName'] ?? "Your Farm",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.edit, color: Colors.white),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              // Product Listings Table
              Container(
                width: 300,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green.shade800),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Product Listings",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('farms')
                          .where('sellerId', isEqualTo: sellerId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();
                        final farmDocs = snapshot.data!.docs;
                        if (farmDocs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("No products found."),
                          );
                        }

                        final List<DataRow> allRows = [];
                        int rowIndex = 1;
                        for (var doc in farmDocs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final products = data['products'] as List? ?? [];
                          for (int i = 0; i < products.length; i++) {
                            final product = products[i] as Map<String, dynamic>;
                            final cropName = product['cropName'] ?? 'N/A';
                            final stock = product['stock in kgs'] ?? '0';
                            final price = product['pricePerKg'] ?? 'N/A';

                            allRows.add(
                              DataRow(cells: [
                                DataCell(Text(rowIndex.toString())),
                                DataCell(Text(cropName)),
                                DataCell(Text("$stock Kg")),
                                DataCell(Text("Rs. $price")),
                              ]),
                            );
                            rowIndex++;
                          }
                        }

                        if (allRows.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text("No products found."),
                          );
                        }

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text("#")),
                              DataColumn(label: Text("Crop")),
                              DataColumn(label: Text("Stock")),
                              DataColumn(label: Text("Price per Kg")),
                            ],
                            rows: allRows,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // BUY SEEDS BUTTON
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => BuySeedsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Buy Seeds",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade800,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}

class BuySeedsPage extends StatefulWidget {
  const BuySeedsPage({super.key});

  @override
  _BuySeedsPageState createState() => _BuySeedsPageState();
}

class _BuySeedsPageState extends State<BuySeedsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _seedNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  void _orderSeeds() {
    if (_formKey.currentState!.validate()) {
      final seedName = _seedNameController.text;
      final quantity = int.parse(_quantityController.text);

      // Simulate order placement (replace with actual logic as needed)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order placed for $quantity Kg of $seedName")),
      );

      // Clear the form
      _seedNameController.clear();
      _quantityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Buy Seeds"),
        backgroundColor: Colors.green.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order Seeds",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _seedNameController,
                decoration: InputDecoration(
                  labelText: "Seed Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the seed name";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: "Quantity (in Kg)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter the quantity";
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return "Please enter a valid quantity";
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _orderSeeds,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Place Order",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
