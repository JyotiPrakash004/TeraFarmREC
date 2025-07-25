import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'farm_collab_detail_page.dart';

class ColabPage extends StatefulWidget {
  const ColabPage({super.key});

  @override
  State<ColabPage> createState() => _ColabPageState();
}

class _ColabPageState extends State<ColabPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool isReadyToCollab = false;
  String? userFarmId;
  String searchQuery = '';
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Map<String, DocumentSnapshot> _sentRequests = {};

  Map<String, double>? userLocation;
  String distanceFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedFilter();
    _loadUserFarm();
    _loadSentRequests();
  }

  Future<void> _loadSavedFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('colab_distance_filter');
    if (saved != null && mounted) {
      setState(() => distanceFilter = saved);
    }
  }

  Future<void> _saveFilter(String newFilter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('colab_distance_filter', newFilter);
  }

  Future<void> _loadUserFarm() async {
    final query =
        await FirebaseFirestore.instance
            .collection('farms')
            .where('sellerId', isEqualTo: currentUserId)
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      userFarmId = doc.id;
      setState(() {
        isReadyToCollab = doc['isReadyToCollab'] ?? false;
      });
      if (doc['latitude'] != null && doc['longitude'] != null) {
        userLocation = {'lat': doc['latitude'], 'lng': doc['longitude']};
      }
    }
  }

  Future<void> _loadSentRequests() async {
    final query =
        await FirebaseFirestore.instance
            .collection('collabRequests')
            .where('requesterId', isEqualTo: currentUserId)
            .get();

    setState(() {
      _sentRequests = {for (var doc in query.docs) doc['farmId']: doc};
    });
  }

  Future<void> _updateReadiness(bool value) async {
    if (userFarmId != null) {
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(userFarmId)
          .update({'isReadyToCollab': value});
      setState(() => isReadyToCollab = value);
    }
  }

  Future<void> _sendCollabRequest(String farmId) async {
    final docRef = await FirebaseFirestore.instance
        .collection('collabRequests')
        .add({
          'farmId': farmId,
          'requesterId': currentUserId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
    final newDoc = await docRef.get();
    setState(() => _sentRequests[farmId] = newDoc);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration request sent!')),
    );
  }

  Future<void> _cancelRequest(String requestId, String farmId) async {
    await FirebaseFirestore.instance
        .collection('collabRequests')
        .doc(requestId)
        .delete();
    setState(() => _sentRequests.remove(farmId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request cancelled.')));
  }

  Future<void> _approveRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('collabRequests')
        .doc(requestId)
        .update({'status': 'approved'});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request approved.')));
  }

  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance
        .collection('collabRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Request rejected.')));
  }

  Future<void> _endCollaboration(String requestId) async {
    await FirebaseFirestore.instance
        .collection('collabRequests')
        .doc(requestId)
        .delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Collaboration ended.')));
  }

  Future<void> _approveOrderCollab(String docId, String orderId) async {
    final batch = FirebaseFirestore.instance.batch();
    final reqRef = FirebaseFirestore.instance
        .collection('orderCollabRequests')
        .doc(docId);
    batch.update(reqRef, {'status': 'approved'});

    final others =
        await FirebaseFirestore.instance
            .collection('orderCollabRequests')
            .where('orderId', isEqualTo: orderId)
            .where('status', isEqualTo: 'pending')
            .get();
    for (var d in others.docs) {
      if (d.id != docId) batch.update(d.reference, {'status': 'expired'});
    }

    final orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId);
    batch.update(orderRef, {
      'status': 'collaborating',
      'collaboratorId': currentUserId,
    });

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order collaboration accepted!')),
    );
  }

  Future<void> _rejectOrderCollab(String docId) async {
    await FirebaseFirestore.instance
        .collection('orderCollabRequests')
        .doc(docId)
        .update({'status': 'rejected'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order collaboration rejected.')),
    );
  }

  Widget _buildApplyRequestsTab() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Ready to Collab?'),
          value: isReadyToCollab,
          onChanged: (val) => _updateReadiness(val),
        ),
        if (isReadyToCollab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search farms...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged:
                  (val) => setState(() => searchQuery = val.toLowerCase()),
            ),
          ),
        if (isReadyToCollab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
            child: DropdownButtonFormField<String>(
              value: distanceFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by distance',
              ),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Farms')),
                DropdownMenuItem(value: '5km', child: Text('Within 5 km')),
                DropdownMenuItem(value: '1km', child: Text('Within 1 km')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => distanceFilter = val);
                  _saveFilter(val);
                }
              },
            ),
          ),
        if (isReadyToCollab)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('farms')
                      .where('isReadyToCollab', isEqualTo: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final farms =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name =
                          (data['farmName'] ?? '').toString().toLowerCase();

                      if (data['sellerId'] == currentUserId ||
                          !name.contains(searchQuery)) {
                        return false;
                      }

                      if (distanceFilter != 'All' && userLocation != null) {
                        if (data['latitude'] == null ||
                            data['longitude'] == null) {
                          return false;
                        }
                        final dist = Geolocator.distanceBetween(
                          userLocation!['lat']!,
                          userLocation!['lng']!,
                          data['latitude'],
                          data['longitude'],
                        );
                        if (distanceFilter == '5km' && dist > 5000)
                          return false;
                        if (distanceFilter == '1km' && dist > 1000)
                          return false;
                      }

                      return true;
                    }).toList();

                if (farms.isEmpty) {
                  return const Center(child: Text('No farms found.'));
                }

                return ListView.builder(
                  itemCount: farms.length,
                  itemBuilder: (context, index) {
                    final doc = farms[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final farmId = doc.id;
                    final requestDoc = _sentRequests[farmId];
                    final status = requestDoc?.get('status');

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: Image.network(
                          data['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(data['farmName'] ?? 'Unnamed Farm'),
                        subtitle: Text(
                          "Location: ${data['location'] ?? 'Unknown'}",
                        ),
                        trailing:
                            status == null
                                ? ElevatedButton(
                                  onPressed: () => _sendCollabRequest(farmId),
                                  child: const Text("Request"),
                                )
                                : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      status[0].toUpperCase() +
                                          status.substring(1),
                                      style: TextStyle(
                                        color:
                                            status == 'approved'
                                                ? Colors.green
                                                : status == 'rejected'
                                                ? Colors.red
                                                : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (status == 'pending')
                                      IconButton(
                                        icon: const Icon(Icons.cancel),
                                        color: Colors.red,
                                        onPressed:
                                            () => _cancelRequest(
                                              requestDoc!.id,
                                              farmId,
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
          ),
      ],
    );
  }

  Widget _buildPendingRequestsTab() {
    if (userFarmId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('collabRequests')
              .where('farmId', isEqualTo: userFarmId)
              .where('status', isEqualTo: 'pending')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const Center(child: Text('No pending requests.'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text("Request from: ${data['requesterId']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveRequest(requestId),
                      child: const Text("Approve"),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _rejectRequest(requestId),
                      child: const Text(
                        "Reject",
                        style: TextStyle(color: Colors.red),
                      ),
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

  Widget _buildMyCollaborationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('collabRequests')
              .where('requesterId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return const Center(child: Text('No collaborations yet.'));
        }
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final data = request.data() as Map<String, dynamic>;
            final farmId = data['farmId'];
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('farms')
                      .doc(farmId)
                      .get(),
              builder: (context, farmSnapshot) {
                if (!farmSnapshot.hasData || !farmSnapshot.data!.exists) {
                  return const SizedBox();
                }
                final farm = farmSnapshot.data!.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FarmCollabDetailPage(
                                farmId: farmId,
                                farmName: farm['farmName'] ?? 'Unnamed Farm',
                                imageUrl: farm['imageUrl'] ?? '',
                                owner: farm['owner'] ?? 'Unknown',
                              ),
                        ),
                      );
                    },
                    leading: Image.network(
                      farm['imageUrl'] ?? '',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(farm['farmName'] ?? 'Unnamed Farm'),
                    subtitle: Text("Owner: ${farm['owner'] ?? 'Unknown'}"),
                    trailing: TextButton(
                      onPressed: () => _endCollaboration(request.id),
                      child: const Text(
                        "End",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Farm Collaboration"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Apply Requests"),
            Tab(text: "Pending Requests"),
            Tab(text: "My Collaborations"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApplyRequestsTab(),
          _buildPendingRequestsTab(),
          _buildMyCollaborationsTab(),
        ],
      ),
    );
  }
}
