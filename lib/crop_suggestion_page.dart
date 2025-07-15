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
  final TextEditingController stateController = TextEditingController();

  String result = '';
  bool isLoading = false;

  Future<void> getSuggestion() async {
    final land = landController.text.trim();
    final budget = budgetController.text.trim();
    final duration = durationController.text.trim();
    final state = stateController.text.trim();

    if (land.isEmpty || budget.isEmpty || duration.isEmpty || state.isEmpty) {
      setState(() {
        result = '⚠️ Please fill in all fields.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      result = '';
    });

    final uri = Uri.parse('https://terafarm-backend.onrender.com/suggest_crop');

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'land_size': land,
          'budget': budget,
          'duration': duration,
          'state': state,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final crops = List<String>.from(data['suggested_crops'] ?? []);
        setState(() {
          result =
              crops.isNotEmpty
                  ? '🌱 Suggested Crops: ${crops.join(', ')}'
                  : '❌ No suitable crops found.';
        });
      } else {
        setState(() {
          result =
              '❌ Failed to get crop suggestion (Status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        result = '❌ Error: $e';
      });
    } finally {
      setState(() {
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: landController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Land Size (in acres)'),
              ),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Budget (in ₹)'),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Duration (in months)'),
              ),
              TextField(
                controller: stateController,
                decoration: InputDecoration(labelText: 'State'),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : getSuggestion,
                child:
                    isLoading
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : Text('Suggest Crops'),
              ),
              SizedBox(height: 24),
              Text(
                result,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
