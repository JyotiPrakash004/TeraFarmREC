import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CropSuggestionPage extends StatefulWidget {
  @override
  _CropSuggestionPageState createState() => _CropSuggestionPageState();
}

class _CropSuggestionPageState extends State<CropSuggestionPage> {
  final TextEditingController landController = TextEditingController();
  final TextEditingController budgetController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController weatherController = TextEditingController();

  String result = '';
  bool isLoading = false;

  Future<void> getSuggestion() async {
    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse('http://<YOUR_FLASK_API_URL>/suggest_crop'); // Replace with real endpoint
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        'land_size': landController.text,
        'budget': budgetController.text,
        'duration': durationController.text,
        'weather': weatherController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        result = data['suggested_crops'].join(', ');
        isLoading = false;
      });
    } else {
      setState(() {
        result = 'Failed to get crop suggestion';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Crop Suggestion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: landController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Land Size (in acres)')),
          TextField(controller: budgetController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Budget (in ₹)')),
          TextField(controller: durationController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Duration (in months)')),
          TextField(controller: weatherController, decoration: InputDecoration(labelText: 'Weather Conditions')),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: getSuggestion,
            child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Suggest Crops'),
          ),
          SizedBox(height: 20),
          Text(result, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
