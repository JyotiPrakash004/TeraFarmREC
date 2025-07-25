import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({Key? key}) : super(key: key);

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // List of userIds you’re in collaboration with
  List<String> _collaboratorUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadCollaborators();
  }

  // NEW: Load all approved collaborator userIds
  Future<void> _loadCollaborators() async {
    final currentUserId = _auth.currentUser!.uid;

    // 1) Find this user's farm
    final farmQuery =
        await _firestore
            .collection('farms')
            .where('sellerId', isEqualTo: currentUserId)
            .limit(1)
            .get();
    if (farmQuery.docs.isEmpty) return;
    final userFarmId = farmQuery.docs.first.id;

    // 2) Fetch approved collaborations where this farm is requester
    final collabQuery =
        await _firestore
            .collection('collabRequests')
            .where('requesterId', isEqualTo: currentUserId)
            .where('status', isEqualTo: 'approved')
            .get();

    // 3) For each approved farmId, get its sellerId (the collaborator)
    final List<String> ids = [];
    for (var doc in collabQuery.docs) {
      final farmDoc =
          await _firestore.collection('farms').doc(doc['farmId']).get();
      if (farmDoc.exists) ids.add(farmDoc['sellerId'] as String);
    }

    setState(() => _collaboratorUserIds = ids);
  }

  // Update the status of an order
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  // NEW: Send order-level collaboration requests to all collaborators
  Future<void> _sendOrderCollabRequests(String orderId) async {
    final currentUserId = _auth.currentUser!.uid;

    // Fetch the current user's farmId
    final farmQuery =
        await _firestore
            .collection('farms')
            .where('sellerId', isEqualTo: currentUserId)
            .limit(1)
            .get();

    if (farmQuery.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No farm found for current user.')),
      );
      return;
    }

    final farmId = farmQuery.docs.first.id;

    for (var toUserId in _collaboratorUserIds) {
      await _firestore.collection('orderCollabRequests').add({
        'orderId': orderId,
        'fromFarmerId': currentUserId,
        'toFarmerId': toUserId,
        'farmId': farmId, // ✅ Automatically included
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Collaboration request sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String sellerId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        title: const Text("Orders", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('orders')
                .where('sellerId', isEqualTo: sellerId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data!.docs;

          // Separate orders by status
          final pendingOrders =
              allOrders
                  .where((doc) => (doc['status'] ?? 'pending') == 'pending')
                  .toList();
          final acceptedOrders =
              allOrders
                  .where((doc) => (doc['status'] ?? '') == 'accepted')
                  .toList();
          final completedOrders =
              allOrders.where((doc) {
                final s = (doc['status'] ?? '').toString().toLowerCase();
                return s == 'rejected' || s == 'delivered' || s == 'cancelled';
              }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PENDING REQUESTS
                const Text(
                  "Pending requests",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                if (pendingOrders.isEmpty && acceptedOrders.isEmpty)
                  const Text("No pending orders.")
                else ...[
                  for (final doc in pendingOrders)
                    _buildOrderCard(doc, status: 'pending'),
                  for (final doc in acceptedOrders)
                    _buildOrderCard(doc, status: 'accepted'),
                ],

                const SizedBox(height: 20),

                // HISTORY
                const Text(
                  "History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                if (completedOrders.isEmpty)
                  const Text("No completed orders.")
                else
                  for (final doc in completedOrders)
                    _buildOrderCard(doc, status: doc['status']),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds each order card.
  Widget _buildOrderCard(DocumentSnapshot orderDoc, {required String status}) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final String orderId = orderDoc.id;
    final String buyerId = data['buyerId'] ?? "unknown";
    final String location = data['location'] ?? "Unknown";
    final String deliveryType = data['delivery'] ?? "pickup";
    final String productImage =
        (data["cartItems"] as List?)?.first["image"] ??
        "assets/placeholder.png";

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(buyerId).get(),
      builder: (context, snapshot) {
        final buyerName =
            snapshot.hasData && snapshot.data!.exists
                ? snapshot.data!.get('username') ?? "Unknown"
                : "Unknown";

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    productImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),

                // Buyer info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        buyerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text("Location: $location"),
                      Text("Delivery: $deliveryType"),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status / Action buttons
                _buildActionButtons(status, orderId),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the right-side area for each status.
  Widget _buildActionButtons(String status, String orderId) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _updateOrderStatus(orderId, 'accepted'),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _updateOrderStatus(orderId, 'rejected'),
            ),
            if (_collaboratorUserIds.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.group, color: Colors.blue),
                onPressed: () => _sendOrderCollabRequests(orderId),
              ),
            ],
          ],
        );

      case 'accepted':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => _updateOrderStatus(orderId, 'delivered'),
              child: const Text("Delivered", style: TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => _updateOrderStatus(orderId, 'cancelled'),
              child: const Text("Cancelled", style: TextStyle(fontSize: 14)),
            ),
          ],
        );

      case 'rejected':
      case 'cancelled':
        return _buildStatusLabel("cancelled");

      case 'delivered':
        return _buildStatusLabel("delivered");

      default:
        return _buildStatusLabel(status);
    }
  }

  /// Color-coded label for final statuses
  Widget _buildStatusLabel(String status) {
    late Color bgColor;
    late String text;
    switch (status.toLowerCase()) {
      case 'rejected':
      case 'cancelled':
        bgColor = Colors.red;
        text = "Cancelled";
        break;
      case 'delivered':
        bgColor = Colors.green;
        text = "Delivered";
        break;
      default:
        bgColor = Colors.grey;
        text = status[0].toUpperCase() + status.substring(1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
