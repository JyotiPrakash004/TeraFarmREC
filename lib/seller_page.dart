import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_page.dart';
import 'community_page.dart';
import 'ai_page.dart';
import 'order_list_page.dart';
import 'list_farm_page.dart';
import 'home_page.dart';
import 'grow_plant_page.dart';
import 'plant_growth_analysis_page.dart';
import 'shop_page.dart';
import 'menu_page.dart';
import 'crop_suggestion_page.dart';
import 'market_price_page.dart';
import 'sustainable.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class SellerPage extends StatelessWidget {
  const SellerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      drawer: const MenuPage(),
      body: SafeArea(
        child: Stack(
          children: [
            // Top bar with language picker, menu, notifications, cart
            Transform.translate(
              offset: const Offset(0, -9),
              child: Stack(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(
                                builder:
                                    (ctx) => IconButton(
                                      icon: const Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ),
                                      onPressed:
                                          () => Scaffold.of(ctx).openDrawer(),
                                    ),
                              ),
                              Row(
                                children: [
                                  // Language Dropdown
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<Locale>(
                                      icon: const Icon(
                                        Icons.language,
                                        color: Colors.white,
                                      ),
                                      value: localeProv.locale,
                                      items:
                                          AppLocalizations.supportedLocales
                                              .map(
                                                (l) => DropdownMenuItem(
                                                  value: l,
                                                  child: Text(
                                                    l.languageCode
                                                        .toUpperCase(),
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
                                          builder: (_) => const HomePage(),
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

            // Body — scrollable list of navigation buttons
            Padding(
              padding: const EdgeInsets.only(top: 120.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    _buildNavigationButton(
                      context,
                      label: loc.dashboard,
                      page: const DashboardPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.dailyTasks,
                      page: const PlantGrowthAnalysisPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.orders,
                      page: const OrderListPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.sustainableFarming,
                      page: const SustainablePage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.community,
                      page: const CommunityPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.shop,
                      page: const ShopPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.cropSuggestion,
                      page: CropSuggestionPage(),
                    ),
                    const SizedBox(height: 10),
                    _buildNavigationButton(
                      context,
                      label: loc.marketPriceAnalysis,
                      page: MarketPricePage(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Bottom action buttons + bottom nav bar
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary actions
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 10.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildBottomButton(
                          context,
                          label: loc.listFarm,
                          page: const ListFarmPage(),
                        ),
                        _buildBottomButton(
                          context,
                          label: loc.growPlant,
                          page: const GrowPlantPage(),
                        ),
                      ],
                    ),
                  ),

                  // Role switcher + AI nav
                  Container(
                    height: 60,
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
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                              ),
                          child: Text(loc.buyer),
                        ),
                        const SizedBox(width: 10),
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
                          onPressed: () {}, // already on SellerPage
                          child: Text(
                            loc.farmer,
                            style: const TextStyle(color: Colors.black),
                          ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
    BuildContext context, {
    required String label,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context, {
    required String label,
    required Widget page,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF407944),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed:
          () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }
}
