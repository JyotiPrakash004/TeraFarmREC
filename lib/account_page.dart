import 'package:TeraFarm/order_list_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'login_page.dart';
import 'edit_profile_page.dart';
import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class AccountPage extends StatefulWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage>
    with TickerProviderStateMixin {
  bool _animate = false;

  Future<Map<String, dynamic>> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      return doc.data() ?? {};
    }
    return {};
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  int _getLevelUpThreshold(int level) => 20 + (level - 1) * 5;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(loc.accountPageTitle),
        backgroundColor: Colors.green.shade800,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.languageCode.toUpperCase()),
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
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserDetails(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(loc.errorLoadingProfile));
          }

          final userDetails = snap.data!;
          final level = userDetails['level'] as int? ?? 1;
          final xp = userDetails['xp'] as int? ?? 0;
          final threshold = _getLevelUpThreshold(level);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 28),
                ),
                Center(
                  child: _buildProfileHeader(
                    userDetails,
                    level,
                    xp,
                    threshold,
                    loc,
                  ),
                ),
                const SizedBox(height: 30),
                _buildAnimatedTile(
                  0,
                  _infoTile(
                    Icons.phone,
                    userDetails['phone'] as String? ?? loc.defaultPhone,
                  ),
                ),
                _buildAnimatedTile(
                  1,
                  _infoTile(
                    Icons.email_outlined,
                    userDetails['email'] as String? ?? loc.defaultEmail,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAnimatedTile(
                  2,
                  _menuTile(
                    Icons.list_alt,
                    loc.myOrders,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OrderListPage(),
                        ),
                      );
                    },
                  ),
                ),
                _buildAnimatedTile(3, _menuTile(Icons.badge, loc.badges)),
                _buildAnimatedTile(
                  4,
                  _menuTile(Icons.location_on, loc.myAddresses),
                ),
                _buildAnimatedTile(5, _menuTile(Icons.list, loc.myList)),
                _buildAnimatedTile(
                  6,
                  _menuTile(
                    Icons.logout,
                    loc.logout,
                    onTap: () => _logout(context),
                    isLogout: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    Map<String, dynamic> user,
    int lvl,
    int xp,
    int thresh,
    AppLocalizations loc,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  user['profileImage'] != null
                      ? NetworkImage(user['profileImage'])
                      : null,
              child:
                  user['profileImage'] == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.orange,
                child: InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          user['username'] as String? ?? loc.defaultUserName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(loc.buyerSellerLabel, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _showLevelRoadmap(context, loc),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  '${loc.levelLabel} $lvl',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: thresh > 0 ? xp / thresh : 0,
                    backgroundColor: Colors.grey,
                    color: Colors.blue,
                    minHeight: 5,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xp/$thresh ${loc.xpLabel}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedTile(int idx, Widget child) {
    return AnimatedSlide(
      offset: _animate ? Offset.zero : const Offset(0, 0.3),
      duration: Duration(milliseconds: 300 + idx * 100),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 300 + idx * 100),
        opacity: _animate ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: child,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.orange),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLevelRoadmap(BuildContext context, AppLocalizations loc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (_) => DraggableScrollableSheet(
            expand: false,
            builder:
                (_, ctrl) => SingleChildScrollView(
                  controller: ctrl,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          loc.levelRoadmapTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...List.generate(20, (i) {
                        final level = i + 1;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                level <= 20 ? Colors.green : Colors.grey,
                            child: Text('$level'),
                          ),
                          title: Text('${loc.levelLabel} $level'),
                          subtitle: Text(loc.rewardToBeAnnounced),
                          trailing:
                              level == 20
                                  ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  )
                                  : null,
                        );
                      }),
                    ],
                  ),
                ),
          ),
    );
  }
}
