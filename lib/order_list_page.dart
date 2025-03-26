import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  _OrderListPageState createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateOrderStatus(String orderId, String newStatus) {
    _firestore.collection('orders').doc(orderId).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    String sellerId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('orders')
                .where('sellerId', isEqualTo: sellerId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children:
                snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> order =
                      doc.data() as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text("Order #${doc.id}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Buyer: ${order['buyerName']}"),
                          Text("Product: ${order['product']}"),
                          Text(
                            "Status: ${order['status']}",
                            style: TextStyle(
                              color:
                                  order['status'] == 'Completed'
                                      ? Colors.green
                                      : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      trailing: DropdownButton<String>(
                        value: order['status'],
                        items:
                            ["Pending", "Completed", "Cancelled"].map((status) {
                              return DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              );
                            }).toList(),
                        onChanged:
                            (newStatus) =>
                                _updateOrderStatus(doc.id, newStatus!),
                      ),
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
