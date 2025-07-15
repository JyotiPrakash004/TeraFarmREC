import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location.dart';
import 'Product_page.dart';
import 'dashboard_page.dart';
import 'menu_page.dart';
import 'cart_page.dart';
import 'community_page.dart';
import 'shop_page.dart';
import 'seller_page.dart';
import 'address_map_picker.dart';
import 'package:latlong2/latlong.dart' as latLong;
import 'ai_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userAddress = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF475D27),
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      await LocationService().determinePosition();
      String address = LocationService().currentAddress ?? 'Unknown Location';
      setState(() {
        _userAddress = address;
      });

      if (LocationService().currentPosition != null) {
        await _storeUserLocation(
          address,
          LocationService().currentPosition!.latitude,
          LocationService().currentPosition!.longitude,
        );
      }
    } catch (e) {
      setState(() {
        _userAddress = 'Location unavailable';
      });
    }
  }

  Future<void> _storeUserLocation(
    String address,
    double lat,
    double lon,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final uid = currentUser.uid;
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'u_id': uid,
      'location': {'address': address, 'latitude': lat, 'longitude': lon},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Launches the map-based location picker using AddressMapPicker.
  Future<void> _chooseMapLocation() async {
    final latLong.LatLng initialLocation =
        LocationService().currentPosition != null
            ? latLong.LatLng(
              LocationService().currentPosition!.latitude,
              LocationService().currentPosition!.longitude,
            )
            : latLong.LatLng(37.7749, -122.4194); // Default: San Francisco

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddressMapPicker(initialLocation: initialLocation),
      ),
    );

    if (result != null && result is Map) {
      final newAddress = result["address"] as String;
      final lat = result["lat"] as double;
      final lng = result["lng"] as double;

      await _storeUserLocation(newAddress, lat, lng);
      setState(() {
        _userAddress = newAddress;
      });
    }
  }

  void _onFarmSelected(DocumentSnapshot farmDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductPage(farmId: farmDoc.id)),
    );
  }

  /// Builds the location widget.
  /// A map icon button is added to the right of the displayed location.
  Widget _buildLocationWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: Colors.green, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _userAddress.isNotEmpty ? _userAddress : 'Fetching location...',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          // New map icon button to open the AddressMapPicker.
          IconButton(
            icon: const Icon(Icons.map, color: Colors.green),
            onPressed: _chooseMapLocation,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF407944),
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const MenuPage(),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -9),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/top_bar.png',
                          width: MediaQuery.of(context).size.width,
                          height: 112,
                          fit: BoxFit.fill,
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 60),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Builder(
                                      builder:
                                          (context) => IconButton(
                                            icon: const Icon(
                                              Icons.menu,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                () =>
                                                    Scaffold.of(
                                                      context,
                                                    ).openDrawer(),
                                          ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.notifications,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.shopping_cart,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => const CartPage(
                                                      cartItems: [],
                                                    ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          _buildLocationWidget(),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "Search",
                                    prefixIcon: const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade200,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "Price : Low to High",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Buy directly from farms", // Changed from "Farms around you"
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('farms')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final farmDocs = snapshot.data!.docs;
                              if (farmDocs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Text("No farms found."),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: farmDocs.length,
                                itemBuilder: (context, index) {
                                  final farm =
                                      farmDocs[index].data()
                                          as Map<String, dynamic>;
                                  final farmName =
                                      farm["farmName"] ?? "Unnamed Farm";
                                  final description =
                                      farm["farmDescription"] ??
                                      "No description";
                                  final imageUrl =
                                      farm["imageUrl"] ??
                                      "assets/sample_farm.png";
                                  final scale = farm["scale"] ?? "N/A";
                                  final rating = farm["rating"] ?? 4.0;

                                  return GestureDetector(
                                    onTap:
                                        () => _onFarmSelected(farmDocs[index]),
                                    child: Card(
                                      margin: const EdgeInsets.only(bottom: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  farmName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  description,
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text("Scale: $scale"),
                                                    Row(
                                                      children: [
                                                        const Icon(
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
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: Container(
                    height: 73,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/bottom_bar.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Buyer',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF407944),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SellerPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'Farmer',
                          ), // Changed from 'Seller' to 'Farmer'
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AIPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'AI',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
