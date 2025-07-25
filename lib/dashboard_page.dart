import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import 'cart_page.dart';
import 'grow_plant_page.dart';
import 'order_list_page.dart';
import 'list_farm_page.dart';
import 'edit_farm_page.dart';
import 'menu_page.dart';
import 'plant_growth_analysis_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  double earnings = 5000.0;

  DateTime parseOrderDate(dynamic rawDate) {
    if (rawDate is Timestamp) return rawDate.toDate();
    if (rawDate is String) return DateTime.parse(rawDate);
    throw Exception('Invalid orderDate format');
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);
    final sellerId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset("assets/top_bar.png", fit: BoxFit.cover),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: Builder(
                builder: (ctx) {
                  return IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  );
                },
              ),
              title: const SizedBox(),
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
                      MaterialPageRoute(
                        builder: (_) => CartPage(cartItems: []),
                      ),
                    );
                  },
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    icon: const Icon(Icons.language, color: Colors.white),
                    value: localeProv.locale,
                    items:
                        AppLocalizations.supportedLocales
                            .map(
                              (l) => DropdownMenuItem(
                                value: l,
                                child: Text(
                                  l.languageCode.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (locale) {
                      if (locale != null) {
                        localeProv.setLocale(locale);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(child: MenuPage()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  loc.farmDashboardTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildBarChart(sellerId, loc),
              const SizedBox(height: 30),
              Text(
                "${loc.totalEarnings}: ₹${earnings.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildDashboardButtons(loc),
              _buildFarmSection(sellerId, loc),
              _buildProductListingsTable(sellerId, loc),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlantGrowthAnalysisPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  loc.viewPlantAnalysis,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(String sellerId, AppLocalizations loc) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('orders')
              .where('sellerId', isEqualTo: sellerId)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(height: 200, child: Center(child: Text(loc.loading)));
        }
        if (snap.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text("${loc.error}: ${snap.error}")),
          );
        }
        if (!snap.hasData) {
          return SizedBox(height: 200, child: Center(child: Text(loc.noData)));
        }

        final orders =
            snap.data!.docs.where((doc) {
              try {
                final d = parseOrderDate(doc['orderDate']);
                return !d.isBefore(start) && !d.isAfter(end);
              } catch (_) {
                return false;
              }
            }).toList();

        final counts = {for (var i = 1; i <= end.day; i++) i: 0};
        for (var o in orders) {
          final day = parseOrderDate(o['orderDate']).day;
          counts[day] = (counts[day] ?? 0) + 1;
        }

        final bars =
            counts.entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.toDouble(),
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
          child: BarChart(
            BarChartData(
              barGroups: bars,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      return v.toInt().isEven
                          ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              v.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          )
                          : const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardButtons(AppLocalizations loc) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                _dashButton(loc.listFarm, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ListFarmPage()),
                  );
                }),
                const SizedBox(height: 10),
                _dashButton(loc.growPlant, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GrowPlantPage()),
                  );
                }),
                const SizedBox(height: 10),
                _dashButton(loc.ordersPageTitle, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderListPage()),
                  );
                }),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _dashButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildFarmSection(String sellerId, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          loc.yourFarm,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Center(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore
                    .collection('farms')
                    .where('sellerId', isEqualTo: sellerId)
                    .snapshots(),
            builder: (ctx, snap) {
              if (!snap.hasData) return const SizedBox();
              final farms = snap.data!.docs;
              if (farms.isEmpty) return Text(loc.noFarmRegistered);
              final farm = farms.first;
              return ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditFarmPage(farmId: farm.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, color: Colors.white),
                label: Text(
                  farm['farmName'] as String? ?? loc.yourFarm,
                  style: const TextStyle(color: Colors.white),
                ),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductListingsTable(String sellerId, AppLocalizations loc) {
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
              Text(
                loc.productListings,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream:
                    _firestore
                        .collection('farms')
                        .where('sellerId', isEqualTo: sellerId)
                        .snapshots(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final docs = snap.data!.docs;
                  final rows = <DataRow>[];
                  var idx = 1;
                  for (var d in docs) {
                    final prods =
                        (d.data() as Map<String, dynamic>)['products']
                            as List? ??
                        [];
                    for (var p in prods) {
                      rows.add(
                        DataRow(
                          cells: [
                            DataCell(Text((idx++).toString())),
                            DataCell(Text(p['cropName'] ?? '')),
                            DataCell(Text("${p['stock in kgs'] ?? ''} Kg")),
                            DataCell(Text("₹${p['pricePerKg'] ?? ''}")),
                          ],
                        ),
                      );
                    }
                  }
                  if (rows.isEmpty) return Text(loc.noProductsFound);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(loc.tableIndex)),
                        DataColumn(label: Text(loc.tableCrop)),
                        DataColumn(label: Text(loc.tableStock)),
                        DataColumn(label: Text(loc.tablePricePerKg)),
                      ],
                      rows: rows,
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
}
