import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart' as latLong;

import 'location.dart';
import 'Product_page.dart';
import 'menu_page.dart';
import 'cart_page.dart';
import 'seller_page.dart';
import 'address_map_picker.dart';
import 'ai_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userAddress = '';

  // Add this for static language options
  final List<Map<String, dynamic>> _languages = [
    {'name': 'English', 'locale': Locale('en')},
    {'name': 'हिन्दी', 'locale': Locale('hi')},
    {'name': 'தமிழ்', 'locale': Locale('ta')},
    {'name': 'తెలుగు', 'locale': Locale('te')},
  ];
  late Map<String, dynamic> _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = _languages[0]; // Default to English
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
      final addr = LocationService().currentAddress ?? '';
      setState(
        () =>
            _userAddress =
                addr.isNotEmpty
                    ? addr
                    : AppLocalizations.of(context)!.noDescription,
      );

      final pos = LocationService().currentPosition;
      if (pos != null) {
        await _storeUserLocation(addr, pos.latitude, pos.longitude);
      }
    } catch (_) {
      setState(
        () => _userAddress = AppLocalizations.of(context)!.noDescription,
      );
    }
  }

  Future<void> _storeUserLocation(
    String address,
    double lat,
    double lon,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'u_id': user.uid,
      'location': {'address': address, 'latitude': lat, 'longitude': lon},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _chooseMapLocation() async {
    final initial =
        LocationService().currentPosition != null
            ? latLong.LatLng(
              LocationService().currentPosition!.latitude,
              LocationService().currentPosition!.longitude,
            )
            : latLong.LatLng(37.7749, -122.4194);

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressMapPicker(initialLocation: initial),
      ),
    );

    if (result != null) {
      final newAddr = result['address'] as String;
      final lat = result['lat'] as double;
      final lng = result['lng'] as double;
      await _storeUserLocation(newAddr, lat, lng);
      setState(() => _userAddress = newAddr);
    }
  }

  void _onFarmSelected(DocumentSnapshot farmDoc) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductPage(farmId: farmDoc.id)),
    );
  }

  Widget _buildLocationWidget(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
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
              _userAddress.isNotEmpty ? _userAddress : loc.fetchingLocation,
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
    final loc = AppLocalizations.of(context)!;
    // Remove listen: false so the widget rebuilds on locale change!
    final localeProv = Provider.of<LocaleProvider>(context);

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
                  // Top bar with menu, language picker, notifications & cart
                  Stack(
                    children: [
                      Image.asset(
                        'assets/top_bar.png',
                        width: double.infinity,
                        height: 112,
                        fit: BoxFit.fill,
                      ),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18.0),
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
                                        (ctx) => IconButton(
                                          icon: const Icon(
                                            Icons.menu,
                                            color: Colors.white,
                                          ),
                                          onPressed:
                                              () =>
                                                  Scaffold.of(ctx).openDrawer(),
                                        ),
                                  ),
                                  Row(
                                    children: [
                                      // Language dropdown
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                            0,
                                            243,
                                            243,
                                            243,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: const Color.fromARGB(
                                              0,
                                              0,
                                              0,
                                              0,
                                            ),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<
                                            Map<String, dynamic>
                                          >(
                                            value: _languages.firstWhere(
                                              (lang) =>
                                                  lang['locale'].languageCode ==
                                                  localeProv
                                                      .locale
                                                      .languageCode,
                                              orElse: () => _languages[0],
                                            ),
                                            icon: const Icon(
                                              Icons.language,
                                              color: Color.fromARGB(
                                                255,
                                                255,
                                                255,
                                                255,
                                              ),
                                            ),
                                            items:
                                                _languages.map((lang) {
                                                  return DropdownMenuItem<
                                                    Map<String, dynamic>
                                                  >(
                                                    value: lang,
                                                    child: Text(lang['name']),
                                                  );
                                                }).toList(),
                                            onChanged: (
                                              Map<String, dynamic>? newLang,
                                            ) {
                                              if (newLang != null) {
                                                localeProv.setLocale(
                                                  newLang['locale'],
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
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
                                                  (_) => const CartPage(
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

                  // Body content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          _buildLocationWidget(loc),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: loc.searchHint,
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
                                child: Text(
                                  loc.priceLowToHigh,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.buyDirect,
                            style: const TextStyle(
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
                            builder: (ctx, snap) {
                              if (!snap.hasData) {
                                return const Padding(
                                  padding: EdgeInsets.only(top: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final docs = snap.data!.docs;
                              if (docs.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 20),
                                  child: Text(loc.noFarms),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                itemBuilder: (ctx, i) {
                                  return _buildFarmCard(docs[i], loc);
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

              // Bottom navigation
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
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
                          onPressed:
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              ),
                          child: Text(
                            loc.buyer,
                            style: const TextStyle(color: Colors.black),
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
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SellerPage(),
                                ),
                              ),
                          child: Text(loc.farmer),
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
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AIPage(),
                                ),
                              ),
                          child: Text(
                            loc.ai,
                            style: const TextStyle(color: Colors.white),
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

  Widget _buildFarmCard(DocumentSnapshot doc, AppLocalizations loc) {
    final farm = doc.data()! as Map<String, dynamic>;
    final name = farm['farmName'] ?? loc.unnamedFarm;
    final desc = farm['farmDescription'] ?? loc.noDescription;
    final imageUrl = farm['imageUrl'] ?? 'assets/sample_farm.png';
    final scale = farm['scale'] ?? 'N/A';
    final rating = farm['rating'] ?? 4.0;

    return GestureDetector(
      onTap: () => _onFarmSelected(doc),
      child: Card(
        margin: const EdgeInsets.only(bottom: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child:
                  imageUrl.startsWith('assets/')
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(desc, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${loc.scaleLabel}: $scale'),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
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
  }
}
