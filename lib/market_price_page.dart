import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketPricePage extends StatefulWidget {
  @override
  _MarketPricePageState createState() => _MarketPricePageState();
}

class _MarketPricePageState extends State<MarketPricePage> {
  String? selectedState;
  String? selectedCommodity;

  final List<String> states = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Delhi",
  ];
  List<String> commodities = [];
  List<Map<String, dynamic>> priceHistory = [];

  bool loadingCommodities = false;
  bool loadingPrices = false;
  String? error;

  // ▶️ Point this at your Render service URL
  final String baseUrl = 'https://terafarm-backend.onrender.com';

  Future<void> _fetchCommodities() async {
    if (selectedState == null) return;
    setState(() {
      loadingCommodities = true;
      commodities = [];
      selectedCommodity = null;
      priceHistory = [];
      error = null;
    });

    final uri = Uri.parse('$baseUrl/available_commodities');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'state': selectedState}),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() {
        commodities = List<String>.from(data['commodities'] ?? []);
        if (commodities.isEmpty) {
          error = 'No produce found for $selectedState.';
        }
      });
    } else {
      setState(() {
        error = 'Failed to load produce (status ${resp.statusCode}).';
      });
    }

    setState(() => loadingCommodities = false);
  }

  Future<void> _fetchPrices() async {
    if (selectedState == null || selectedCommodity == null) return;
    setState(() {
      loadingPrices = true;
      priceHistory = [];
      error = null;
    });

    final uri = Uri.parse('$baseUrl/market_price_by_commodity');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'state': selectedState,
        'commodity': selectedCommodity,
      }),
    );

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      setState(() {
        priceHistory = List<Map<String, dynamic>>.from(data['records'] ?? []);
        if (priceHistory.isEmpty) {
          error = 'No price data for $selectedCommodity in $selectedState.';
        }
      });
    } else {
      setState(() {
        error = 'Failed to load prices (status ${resp.statusCode}).';
      });
    }

    setState(() => loadingPrices = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Market Price Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select State'),
              value: selectedState,
              items:
                  states
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
              onChanged: (s) {
                setState(() => selectedState = s);
                _fetchCommodities();
              },
            ),
            const SizedBox(height: 16),
            if (loadingCommodities)
              CircularProgressIndicator()
            else if (commodities.isNotEmpty)
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Select Produce'),
                value: selectedCommodity,
                items:
                    commodities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                onChanged: (c) {
                  setState(() => selectedCommodity = c);
                  _fetchPrices();
                },
              ),
            const SizedBox(height: 16),
            if (loadingPrices)
              CircularProgressIndicator()
            else if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (!loadingPrices && error == null && priceHistory.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: priceHistory.length,
                  itemBuilder: (_, i) {
                    final row = priceHistory[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          '${row['market']} — ₹${row['modal_price']} per quintal',
                        ),
                        subtitle: Text(row['date']),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
