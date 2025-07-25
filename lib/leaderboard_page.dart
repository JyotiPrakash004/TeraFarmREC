import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final double _tileHeight = 80.0;
  int _currentUserIndex = -1;
  bool _showFloatingYou = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_currentUserIndex == -1) return;
    final viewportStart = _scrollController.offset;
    final viewportEnd =
        _scrollController.offset + MediaQuery.of(context).size.height;
    final itemOffset = _currentUserIndex * _tileHeight;

    final isVisible = itemOffset >= viewportStart && itemOffset < viewportEnd;
    if (isVisible && _showFloatingYou) {
      setState(() => _showFloatingYou = false);
    } else if (!isVisible && !_showFloatingYou) {
      setState(() => _showFloatingYou = true);
    }
  }

  Future<QuerySnapshot> _fetchUsers(
    bool isGlobal,
    String? currentUserLocation,
  ) {
    final usersRef = FirebaseFirestore.instance.collection('users');
    Query query = usersRef.orderBy('xp', descending: true);
    if (!isGlobal && currentUserLocation != null) {
      query = query.where('location', isEqualTo: currentUserLocation);
    }
    return query.get();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    final currentUserLocation = null; // fetch if you have it

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.leaderboardTitle),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(
                Icons.language,
                color: Color.fromARGB(255, 9, 0, 0),
              ),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(
                        l.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) localeProv.setLocale(newLocale);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: loc.tabGlobal), Tab(text: loc.tabLocal)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboard(
            isGlobal: true,
            loc: loc,
            currentUserLocation: currentUserLocation,
          ),
          _buildLeaderboard(
            isGlobal: false,
            loc: loc,
            currentUserLocation: currentUserLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard({
    required bool isGlobal,
    required AppLocalizations loc,
    String? currentUserLocation,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: _fetchUsers(isGlobal, currentUserLocation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: Text(loc.loading));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text(loc.errorLoadingLeaderboard));
        }
        final docs = snapshot.data!.docs;
        _currentUserIndex = docs.indexWhere(
          (doc) => doc.id == FirebaseAuth.instance.currentUser?.uid,
        );

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final userData = docs[index].data()! as Map<String, dynamic>;
                final rank = index + 1;
                final isCurrent =
                    docs[index].id == FirebaseAuth.instance.currentUser?.uid;
                return _buildAnimatedTile(
                  index,
                  _leaderboardTile(loc, rank, userData, isCurrent),
                );
              },
            ),
            if (_showFloatingYou && _currentUserIndex != -1)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _floatingCurrentUser(loc, docs[_currentUserIndex]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedTile(int index, Widget child) {
    final delay = Duration(milliseconds: 300 + index * 100);
    return AnimatedSlide(
      offset: const Offset(0, 0.3),
      duration: delay,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: delay,
        opacity: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: SizedBox(height: _tileHeight, child: child),
        ),
      ),
    );
  }

  Widget _leaderboardTile(
    AppLocalizations loc,
    int rank,
    Map<String, dynamic> userData,
    bool isCurrent,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            userData['profileImage'] != null
                ? NetworkImage(userData['profileImage'])
                : null,
        child:
            userData['profileImage'] == null ? const Icon(Icons.person) : null,
      ),
      title: Text(userData['username'] ?? loc.unknownUser),
      subtitle: Text('${userData['xp'] ?? 0} XP'),
      trailing: Text(
        '#$rank',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tileColor: isCurrent ? Colors.blue.shade100 : null,
    );
  }

  Widget _floatingCurrentUser(AppLocalizations loc, DocumentSnapshot doc) {
    final userData = doc.data()! as Map<String, dynamic>;
    final rank = _currentUserIndex + 1;
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.yellow.shade100,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              userData['profileImage'] != null
                  ? NetworkImage(userData['profileImage'])
                  : null,
          child:
              userData['profileImage'] == null
                  ? const Icon(Icons.person)
                  : null,
        ),
        title: Text(userData['username'] ?? loc.youLabel),
        subtitle: Text('${userData['xp'] ?? 0} XP'),
        trailing: Text(
          '#$rank',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
