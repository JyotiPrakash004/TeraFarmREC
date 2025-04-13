import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({Key? key}) : super(key: key);

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  // Assume each tile has an approximate fixed height
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

  // Checks if the current user's tile is visible in the list
  void _scrollListener() {
    if (_currentUserIndex == -1) return;
    final viewportStart = _scrollController.offset;
    final viewportEnd =
        _scrollController.offset + MediaQuery.of(context).size.height;
    final itemOffset = _currentUserIndex * _tileHeight;

    // If the current user's tile is not in the viewport, show the floating tile
    final isVisible = itemOffset >= viewportStart && itemOffset < viewportEnd;
    if (isVisible && _showFloatingYou) {
      setState(() {
        _showFloatingYou = false;
      });
    } else if (!isVisible && !_showFloatingYou) {
      setState(() {
        _showFloatingYou = true;
      });
    }
  }

  // Fetch users sorted by xp descending.
  // For "Local", we filter by a provided location string.
  Future<QuerySnapshot> _fetchUsers(
    bool isGlobal,
    String? currentUserLocation,
  ) {
    CollectionReference usersRef = FirebaseFirestore.instance.collection(
      'users',
    );
    Query query = usersRef.orderBy('xp', descending: true);
    if (!isGlobal && currentUserLocation != null) {
      query = query.where('location', isEqualTo: currentUserLocation);
    }
    return query.get();
  }

  @override
  Widget build(BuildContext context) {
    // Get current user and, if applicable, their location.
    final currentUser = FirebaseAuth.instance.currentUser;
    // For demonstration, you might fetch location from the current user's document.
    String? currentUserLocation =
        null; // Replace with actual location if available

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: "Global"), Tab(text: "Local")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboard(
            isGlobal: true,
            currentUserLocation: currentUserLocation,
          ),
          _buildLeaderboard(
            isGlobal: false,
            currentUserLocation: currentUserLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard({
    required bool isGlobal,
    String? currentUserLocation,
  }) {
    return FutureBuilder<QuerySnapshot>(
      future: _fetchUsers(isGlobal, currentUserLocation),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("Error loading leaderboard"));
        }
        List<DocumentSnapshot> docs = snapshot.data!.docs;

        // Determine the index (rank) of the current user
        _currentUserIndex = docs.indexWhere(
          (doc) => doc.id == FirebaseAuth.instance.currentUser?.uid,
        );

        return Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final userData = docs[index].data() as Map<String, dynamic>;
                final int rank = index + 1;
                final bool isCurrentUser =
                    docs[index].id == FirebaseAuth.instance.currentUser?.uid;
                return _buildAnimatedTile(
                  index,
                  _leaderboardTile(rank, userData, isCurrentUser),
                );
              },
            ),
            // Floating "You" row if current user's tile is scrolled out of view
            if (_showFloatingYou && _currentUserIndex != -1)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _floatingCurrentUser(docs[_currentUserIndex]),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedTile(int index, Widget child) {
    // Animation delay increases for later tiles
    final animationDuration = Duration(milliseconds: 300 + (index * 100));
    return AnimatedSlide(
      offset: const Offset(0, 0.3),
      duration: animationDuration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: animationDuration,
        opacity: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: SizedBox(height: _tileHeight, child: child),
        ),
      ),
    );
  }

  Widget _leaderboardTile(
    int rank,
    Map<String, dynamic> userData,
    bool isCurrentUser,
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
      title: Text(userData['username'] ?? 'Unknown'),
      subtitle: Text("${userData['xp'] ?? 0} XP"),
      trailing: Text(
        "#$rank",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tileColor: isCurrentUser ? Colors.blue.shade100 : null,
    );
  }

  Widget _floatingCurrentUser(DocumentSnapshot doc) {
    Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
    int rank = _currentUserIndex + 1;
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
        title: Text(userData['username'] ?? 'You'),
        subtitle: Text("${userData['xp'] ?? 0} XP"),
        trailing: Text(
          "#$rank",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
