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

  // Update the status of an order (e.g., accepted, rejected, delivered)
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    // The seller must be logged in; we use that seller's UID to filter orders
    final String sellerId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        title: const Text(
          "Orders",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('orders')
            .where('sellerId', isEqualTo: sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Separate orders into pending vs. completed
          final allOrders = snapshot.data!.docs;
          final pendingOrders = allOrders
              .where((doc) => (doc['status'] ?? 'pending') == 'pending')
              .toList();
          final completedOrders = allOrders
              .where((doc) => (doc['status'] ?? 'pending') != 'pending')
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: Pending requests
                const Text(
                  "Pending requests",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                // List of pending orders
                if (pendingOrders.isEmpty)
                  const Text("No pending orders.")
                else
                  ...pendingOrders.map(
                    (orderDoc) => _buildOrderCard(orderDoc, isPending: true),
                  ),

                const SizedBox(height: 20),

                // Title: History
                const Text(
                  "History",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                // List of completed orders
                if (completedOrders.isEmpty)
                  const Text("No completed orders.")
                else
                  ...completedOrders.map(
                    (orderDoc) => _buildOrderCard(orderDoc, isPending: false),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Builds the UI card for each order, matching the style in your screenshot.
  Widget _buildOrderCard(DocumentSnapshot orderDoc, {required bool isPending}) {
    final data = orderDoc.data() as Map<String, dynamic>;
    final String orderId = orderDoc.id;

    // Fields from Firestore (change to match your structure)
    final String buyerName = data['buyerName'] ?? "Unknown";
    final String location = data['location'] ?? "Unknown";
    final String deliveryType = data['delivery'] ?? "pickup";
    final String status = data['status'] ?? "pending";

    // Example: Show first product image if desired
    // If your 'cartItems' is a list, you can do something like:
    String productImage = "assets/placeholder.png";
    if (data.containsKey("cartItems") &&
        data["cartItems"] is List &&
        (data["cartItems"] as List).isNotEmpty) {
      final firstItem = (data["cartItems"] as List).first;
      if (firstItem is Map && firstItem["image"] != null) {
        productImage = firstItem["image"];
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Left: Product image (or a default)
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
            // Middle: Buyer name, location, delivery
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
            // Right: Accept/Reject or Status
            isPending
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _updateOrderStatus(orderId, 'accepted'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _updateOrderStatus(orderId, 'rejected'),
                      ),
                    ],
                  )
                : _buildStatusLabel(status),
          ],
        ),
      ),
    );
  }

  /// Builds a small status label for completed orders (e.g., "Delivered", "Cancelled")
  Widget _buildStatusLabel(String status) {
    // Decide color based on status
    Color bgColor;
    String text;
    switch (status.toLowerCase()) {
      case 'accepted':
        bgColor = Colors.green;
        text = "Delivered"; // Or "Accepted"
        break;
      case 'rejected':
        bgColor = Colors.red;
        text = "Cancelled"; // Or "Rejected"
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
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
