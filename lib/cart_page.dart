import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartPage({Key? key, required this.cartItems}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String _deliveryMethod = "delivery";
  final int _deliveryFee = 30;

  void _emptyCart() {
    setState(() {
      widget.cartItems.clear();
    });
  }

  void _incrementQuantity(int index) {
    setState(() {
      widget.cartItems[index]["quantity"] =
          (widget.cartItems[index]["quantity"] as int) + 1;
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      final currentQty = widget.cartItems[index]["quantity"] as int;
      if (currentQty > 1) {
        widget.cartItems[index]["quantity"] = currentQty - 1;
      } else {
        widget.cartItems.removeAt(index);
      }
    });
  }

  int get _itemTotal {
    int total = 0;
    for (final item in widget.cartItems) {
      final price = item["price"] as int;
      final qty = item["quantity"] as int;
      total += price * qty;
    }
    return total;
  }

  int get _totalPayable {
    return _deliveryMethod == "delivery"
        ? _itemTotal + _deliveryFee
        : _itemTotal;
  }

  Future<void> _confirmOrder() async {
    if (widget.cartItems.isEmpty) return;

    try {
      final sellerId = widget.cartItems.first["sellerId"] ?? "unknown";
      final orderData = {
        "cartItems": widget.cartItems,
        "deliveryMethod": _deliveryMethod,
        "itemTotal": _itemTotal,
        "deliveryFee": _deliveryMethod == "delivery" ? _deliveryFee : 0,
        "totalPayable": _totalPayable,
        "status": "pending",
        "orderDate": DateTime.now().toIso8601String(),
        "buyerId": FirebaseAuth.instance.currentUser?.uid ?? "unknown",
        "sellerId": sellerId,
      };

      await FirebaseFirestore.instance.collection("orders").add(orderData);

      setState(() => widget.cartItems.clear());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Order Confirmed!")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error confirming order: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = widget.cartItems.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        title: Text("Cart ($cartCount)"),
        actions: [
          TextButton(
            onPressed: _emptyCart,
            child: const Text(
              "Empty Cart",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body:
          cartCount == 0
              ? const Center(child: Text("Your cart is empty."))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cartCount,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        final name = item["name"] ?? "Unnamed";
                        final price = item["price"] as int? ?? 0;
                        final quantity = item["quantity"] as int? ?? 1;
                        final imagePath =
                            item["image"] ?? "assets/placeholder.png";
                        final unit = item["unit"] ?? "500 gms";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  imagePath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(unit),
                                      const SizedBox(height: 5),
                                      Text("₹$price Each"),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () => _decrementQuantity(index),
                                  ),
                                  Text("$quantity"),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _incrementQuantity(index),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Item Total",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          "₹$_itemTotal",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Delivery Fee",
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          _deliveryMethod == "delivery"
                              ? "₹$_deliveryFee"
                              : "₹0",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Payable",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹$_totalPayable",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "How would you like to receive your order?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: "delivery",
                          groupValue: _deliveryMethod,
                          onChanged: (value) {
                            setState(() {
                              _deliveryMethod = value!;
                            });
                          },
                        ),
                        const Text("Delivery"),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: "pickup",
                          groupValue: _deliveryMethod,
                          onChanged: (value) {
                            setState(() {
                              _deliveryMethod = value!;
                            });
                          },
                        ),
                        const Text("Pick up"),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Delivering to you in between\n10 AM - 12 PM",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.home, color: Colors.red),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            "4202, T 4, Sultan Street, XYZ City",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "CHANGE ADDRESS",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _confirmOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Confirm Order",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
