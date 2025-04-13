import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'cart_page.dart';
import 'community_page.dart';
import 'grow_plant_page.dart'; // Now pointing to our new page.
import 'order_list_page.dart';
import 'list_farm_page.dart';
import 'edit_farm_page.dart';
import 'menu_page.dart';
import 'home_page.dart';
import 'shop_page.dart';
import 'ai_page.dart';
import 'plant_growth_analysis_page.dart'; // New: Plant growth analysis page.

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double earnings = 5000.0;

  @override
  Widget build(BuildContext context) {
    String sellerId = _auth.currentUser!.uid;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(sellerId),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green.shade900,
      leading: Builder(
        builder:
            (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
      ),
      title: Row(
        children: [
          Transform.translate(
            offset: const Offset(-40, 5),
            child: Image.asset("assets/terafarm_logo.png", height: 40),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CartPage(cartItems: [])),
            );
          },
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        child: MenuPage(),
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      backgroundColor: Colors.blue.shade900,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIPage()),
        );
      },
      child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
    );
  }

  Widget _buildBody(String sellerId) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildDashboardHeader(),
            const SizedBox(height: 20),
            _buildBarChart(sellerId),
            _buildEarningsSection(),
            _buildDailyTaskSection(),
            _buildDashboardButtons(),
            _buildFarmSection(sellerId),
            _buildProductListingsTable(sellerId),
            _buildActionButtons(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlantGrowthAnalysisPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Plant Growth Analysis",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        "Farm Dashboard",
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEarningsSection() {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(
          "Total Earnings: Rs.${earnings.toStringAsFixed(2)}",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildBarChart(String sellerId) {
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .where('sellerId', isEqualTo: sellerId)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (!snapshot.hasData) {
          return SizedBox(
            height: 200,
            child: const Center(child: Text("No Data")),
          );
        }
        final allOrders = snapshot.data!.docs;
        final filteredOrders =
            allOrders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderDateRaw = data['orderDate'];
              DateTime? date;
              if (orderDateRaw is Timestamp) {
                date = orderDateRaw.toDate();
              } else if (orderDateRaw is String) {
                try {
                  date = DateTime.parse(orderDateRaw);
                } catch (e) {
                  date = null;
                }
              }
              if (date == null) return false;
              return !date.isBefore(startOfMonth) && !date.isAfter(endOfMonth);
            }).toList();

        Map<int, int> ordersPerDay = {
          for (int day = 1; day <= endOfMonth.day; day++) day: 0,
        };

        for (var order in filteredOrders) {
          final data = order.data() as Map<String, dynamic>;
          final orderDateRaw = data['orderDate'];
          DateTime? date;
          if (orderDateRaw is Timestamp) {
            date = orderDateRaw.toDate();
          } else if (orderDateRaw is String) {
            try {
              date = DateTime.parse(orderDateRaw);
            } catch (e) {
              date = null;
            }
          }
          if (date != null) {
            ordersPerDay[date.day] = (ordersPerDay[date.day] ?? 0) + 1;
          }
        }

        List<BarChartGroupData> barGroups =
            ordersPerDay.entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: Colors.blue,
                    width: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList();

        return Container(
          height: 200,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.green.shade800, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                barTouchData: BarTouchData(enabled: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 != 0) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                groupsSpace: 8,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDailyTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Daily Task",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Watering",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Column(
                    children: [
                      const Text("At 8:30 AM"),
                      Checkbox(value: false, onChanged: (value) {}),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Column(
                    children: [
                      const Text("At 5:30 PM"),
                      Checkbox(value: false, onChanged: (value) {}),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardButtons() {
    return Column(
      children: [
        const SizedBox(height: 20),
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
                }, Colors.orange),
                const SizedBox(height: 10),
                _buildDashboardButton("Grow a Plant", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GrowPlantPage(),
                    ),
                  );
                }, Colors.orange),
                const SizedBox(height: 10),
                _buildDashboardButton("Orders", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => OrderListPage()),
                  );
                }, Colors.orange),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFarmSection(String sellerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Your Farm",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Center(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('farms')
                    .where('sellerId', isEqualTo: sellerId)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final farms = snapshot.data!.docs;
              if (farms.isEmpty) {
                return const Text("No farm registered by you.");
              }
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
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      farm['farmName'] ?? "Your Farm",
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.edit, color: Colors.white),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListingsTable(String sellerId) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 300,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green.shade800),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Product Listings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('farms')
                        .where('sellerId', isEqualTo: sellerId)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final farmDocs = snapshot.data!.docs;
                  if (farmDocs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
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
                        DataRow(
                          cells: [
                            DataCell(Text(rowIndex.toString())),
                            DataCell(Text(cropName)),
                            DataCell(Text("$stock Kg")),
                            DataCell(Text("Rs. $price")),
                          ],
                        ),
                      );
                      rowIndex++;
                    }
                  }
                  if (allRows.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("No products found."),
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
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
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(children: [const SizedBox(height: 20)]);
  }

  Widget _buildDashboardButton(
    String text,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }
}
