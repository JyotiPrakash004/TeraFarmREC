import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'forum_page.dart';
import 'home_page.dart';
import 'shop_page.dart';
import 'leaderboard_page.dart';
import 'colab_page.dart';
import 'dashboard_page.dart';
import 'cart_page.dart';
import 'menu_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedIndex = 1;

  void _onNavItemTapped(int index) {
    if (index == _selectedIndex) return;
    Widget? dest;
    switch (index) {
      case 0:
        dest = const HomePage();
        break;
      case 2:
        dest = const DashboardPage();
        break;
      case 3:
        dest = const ShopPage();
        break;
    }
    if (dest != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dest!),
      );
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        leading: Builder(
          builder: (ctx) {
            return IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          },
        ),
        title: Image.asset("assets/terafarm_logo.png", height: 40),
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
                  builder: (_) => const CartPage(cartItems: []),
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
      drawer: const MenuPage(),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey.shade300,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(
              loc.myCommunity,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LeaderboardPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(120, 120),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.leaderboard,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.leaderboard,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _communityButton(
                        label: loc.collab,
                        icon: Icons.group,
                        page: const ColabPage(),
                      ),
                      const SizedBox(width: 20),
                      _communityButton(
                        label: loc.forum,
                        icon: Icons.forum,
                        page: const ForumPage(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: _onNavItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: loc.navHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.apartment),
            label: loc.navCommunity,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.leaderboard),
            label: loc.navDashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store),
            label: loc.navShop,
          ),
        ],
      ),
    );
  }

  Widget _communityButton({
    required String label,
    required IconData icon,
    required Widget page,
  }) {
    return ElevatedButton(
      onPressed:
          () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        minimumSize: const Size(120, 120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
