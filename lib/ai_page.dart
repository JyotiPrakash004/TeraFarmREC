import 'package:TeraFarm/menu_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'plantcare_page.dart';
import 'teradoc_page.dart';
import 'recommendation_ai_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      drawer: const Drawer(child: MenuPage()),

      appBar: AppBar(
        title: Text(
          loc.aiPageTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Language picker
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(l.languageCode.toUpperCase()),
                    );
                  }).toList(),
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

      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlantCareApp()),
                    );
                  },
                  icon: const Icon(
                    Icons.local_florist,
                    size: 24,
                    color: Colors.white,
                  ),
                  label: Text(
                    loc.teraCareAI,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeradocApp()),
                    );
                  },
                  icon: const Icon(
                    Icons.medical_services,
                    size: 24,
                    color: Colors.white,
                  ),
                  label: Text(
                    loc.teraDocAI,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecommendationForm(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.recommend,
                    size: 24,
                    color: Colors.white,
                  ),
                  label: Text(
                    loc.teraRecommendAI,
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 60),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          // Bottom navigation bar
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
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      },
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
                        side: BorderSide(color: Colors.grey.shade400, width: 2),
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
                          MaterialPageRoute(builder: (_) => const SellerPage()),
                        );
                      },
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
                      onPressed: () {
                        // already on AI page
                      },
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
    );
  }
}
