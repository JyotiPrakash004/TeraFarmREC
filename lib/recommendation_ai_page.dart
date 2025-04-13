import 'package:flutter/material.dart';

class RecommendationForm extends StatefulWidget {
  const RecommendationForm({super.key});

  @override
  _RecommendationFormState createState() => _RecommendationFormState();
}

class _RecommendationFormState extends State<RecommendationForm> {
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaSizeController = TextEditingController();
  final TextEditingController _dailyTimeController = TextEditingController();

  // Dropdown values for space type and time unit
  final List<String> _spaceTypes = ['Balcony', 'Terrace', 'Garden'];
  String _selectedSpaceType = 'Balcony';

  final List<String> _timeUnits = ['hours', 'mins'];
  String _selectedTimeUnit = 'hours';

  String _result = '';

  // This function collects the input and prints a static recommendation message.
  void _getRecommendation() {
    // Retrieve input values
    final String city = _cityController.text;
    final String areaSize = _areaSizeController.text;
    final String dailyTime = _dailyTimeController.text;
    final String spaceType = _selectedSpaceType;
    final String timeUnit = _selectedTimeUnit;

    // Build a static recommendation message based on the input
    final String recommendation = "Based on your input:\n"
        "City: $city\n"
        "Area Size: $areaSize m²\n"
        "Space Type: $spaceType\n"
        "Daily Care Time: $dailyTime $timeUnit\n\n"
        "We recommend trying a high-light exposure plant care system for optimal growth.";

    // Update the UI to display the result
    setState(() {
      _result = recommendation;
    });

    // Optionally, print the output to the console for debugging
    print("Static Recommendation:\n$recommendation");
  }

  @override
  void dispose() {
    _cityController.dispose();
    _areaSizeController.dispose();
    _dailyTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terafarm Crop Recommendations"),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // City Input
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: "Enter Your City",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Area Size Input
              TextField(
                controller: _areaSizeController,
                decoration: const InputDecoration(
                  labelText: "Area Size (in square meters)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              // Dropdown for Type of Space
              Row(
                children: [
                  const Text("Select Space Type:", style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedSpaceType,
                    items: _spaceTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSpaceType = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Daily Care Time Input and Time Unit Dropdown
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dailyTimeController,
                      decoration: const InputDecoration(
                        labelText: "Daily Care Time",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedTimeUnit,
                    items: _timeUnits.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: const TextStyle(fontSize: 16)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedTimeUnit = newValue!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Button to trigger the static recommendation
              Center(
                child: ElevatedButton(
                  onPressed: _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    "Get My Recommendation",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Display the static result
              Text(
                _result,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Terafarm Crop Recommendations',
    home: const RecommendationForm(),
    theme: ThemeData(
      primarySwatch: Colors.green,
    ),
  ));
}
