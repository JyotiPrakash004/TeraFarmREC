import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collaboration Demo',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const CollaborationPage(),
    );
  }
}

class CollaborationPage extends StatefulWidget {
  const CollaborationPage({Key? key}) : super(key: key);

  @override
  _CollaborationPageState createState() => _CollaborationPageState();
}

class _CollaborationPageState extends State<CollaborationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isReadyToCollab = false;

  final String currentUserId = "User123";
  final Map<String, dynamic> currentUserDetails = {
    "ownerName": "User123",
    "farmName": "Paradise Farm",
    "location": "Padur",
    "imageUrl": "https://via.placeholder.com/100",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadToggleStateFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadToggleStateFromFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection('collabReady')
        .doc(currentUserId)
        .get();
    setState(() {
      _isReadyToCollab = doc.exists;
    });
  }

  Future<void> _publishCollabStatus() async {
    await FirebaseFirestore.instance
        .collection('collabReady')
        .doc(currentUserId)
        .set(currentUserDetails);
  }

  Future<void> _removeCollabStatus() async {
    await FirebaseFirestore.instance
        .collection('collabReady')
        .doc(currentUserId)
        .delete();
  }

  void _onRequestAccess(String targetUserId) async {
    await FirebaseFirestore.instance.collection('pendingRequests').add({
      'requestorId': currentUserId,
      'targetUserId': targetUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaboration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Apply Requests'),
            Tab(text: 'Pending Requests'),
            Tab(text: 'Received Requests'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Ready to Collab?'),
                const Spacer(),
                Switch(
                  value: _isReadyToCollab,
                  onChanged: (bool newValue) async {
                    setState(() {
                      _isReadyToCollab = newValue;
                    });
                    if (newValue) {
                      await _publishCollabStatus();
                    } else {
                      await _removeCollabStatus();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApplyRequestsTab(),
                _buildPendingRequestsTab(),
                _buildReceivedRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('collabReady').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No one is ready to collab yet."));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final targetUserId = docs[index].id;
            return Card(
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    child: data['imageUrl'] != null
                        ? Image.network(
                            data['imageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.agriculture, size: 60),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['ownerName'] ?? 'No Name',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          data['farmName'] ?? 'No Farm Name',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        Text("Location: ${data['location'] ?? 'Unknown'}"),
                      ],
                    ),
                  ),
                  ButtonBar(
                    alignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (targetUserId != currentUserId) {
                            _onRequestAccess(targetUserId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You cannot request collab with yourself!'),
                              ),
                            );
                          }
                        },
                        child: const Text("Request to Collab"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pendingRequests')
          .where('requestorId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final requestDocs = snapshot.data!.docs;
        if (requestDocs.isEmpty) {
          return const Center(child: Text("No pending requests."));
        }
        return ListView.builder(
          itemCount: requestDocs.length,
          itemBuilder: (context, index) {
            final data = requestDocs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text("Requested collab with: ${data['targetUserId'] ?? 'Unknown'}"),
              subtitle: Text(
                "Sent on: ${data['timestamp'] != null ? data['timestamp'].toDate().toString() : 'N/A'}",
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReceivedRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pendingRequests')
          .where('targetUserId', isEqualTo: currentUserId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No received requests."));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final requestId = docs[index].id;
            final requesterId = data['requestorId'];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text("Request from: $requesterId"),
                subtitle: Text(
                  "Received on: ${data['timestamp'] != null ? data['timestamp'].toDate().toString() : 'N/A'}",
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('approvedRequests').add({
                          'ownerId': currentUserId,
                          'requestorId': requesterId,
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        await FirebaseFirestore.instance
                            .collection('pendingRequests')
                            .doc(requestId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request approved')),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('pendingRequests')
                            .doc(requestId)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request denied')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
