import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecommendationServiceApi {
  static const String baseUrl = 'https://recommendation-242561185203.asia-south1.run.app';

  Future<Map<String, dynamic>> getRecommendation({
    required String city,
    required String spaceType,
    required int areaSize,
    required int dailyTime,
    required String dailyUnit,
  }) async {
    final url = Uri.parse('$baseUrl/recommend');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'city': city,
        'space_type': spaceType,
        'area_size': areaSize,
        'daily_time': dailyTime,
        'daily_unit': dailyUnit,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load recommendation: ${response.statusCode}");
    }
  }
}

class RecommendationService extends StatefulWidget {
  @override
  final Key? key;

  const RecommendationService({this.key}) : super(key: key);
  @override
  _RecommendationServiceState createState() => _RecommendationServiceState();
}

class _RecommendationServiceState extends State<RecommendationService> {
  final RecommendationServiceApi _api = RecommendationServiceApi();
  String _result = '';
  bool _isLoading = false;

  void fetchRecommendation({
    required String city,
    required String spaceType,
    required int areaSize,
    required int dailyTime,
    required String dailyUnit,
  }) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _api.getRecommendation(
        city: city,
        spaceType: spaceType,
        areaSize: areaSize,
        dailyTime: dailyTime,
        dailyUnit: dailyUnit,
      );
      final recommendationText = data['recommendation']
          .toString()
          .replaceAll('*', '');
      setState(() {
        _result = "Weather: ${data['weather']['description']}\n\n"
                  "Recommendation:\n$recommendationText";
      });
    } catch (e) {
      setState(() {
        _result = "Error: Unable to fetch recommendation. Please check your input and try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          Center(child: CircularProgressIndicator())
        else if (_result.isNotEmpty)
          Text(
            _result,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          )
        else
          Center(
            child: Text(
              "Enter details and press the button to get recommendations.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

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

  final GlobalKey<_RecommendationServiceState> _serviceKey = GlobalKey<_RecommendationServiceState>();

  void _getRecommendation() {
    _serviceKey.currentState?.fetchRecommendation(
      city: _cityController.text,
      spaceType: _selectedSpaceType.toLowerCase(),
      areaSize: int.parse(_areaSizeController.text),
      dailyTime: int.parse(_dailyTimeController.text),
      dailyUnit: _selectedTimeUnit,
    );
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
        title: Text("Terafarm Crop Recommendations"),
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
                decoration: InputDecoration(
                  labelText: "Enter Your City",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 15),
              // Area Size Input
              TextField(
                controller: _areaSizeController,
                decoration: InputDecoration(
                  labelText: "Area Size (in square meters)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 15),
              // Dropdown for Type of Space
              Row(
                children: [
                  Text("Select Space Type: ",
                      style: TextStyle(fontSize: 16)),
                  SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedSpaceType,
                    items: _spaceTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,
                            style: TextStyle(fontSize: 16)),
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
              SizedBox(height: 15),
              // Daily Care Time Input and Time Unit Dropdown
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dailyTimeController,
                      decoration: InputDecoration(
                        labelText: "Daily Care Time",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 20),
                  DropdownButton<String>(
                    value: _selectedTimeUnit,
                    items: _timeUnits.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(fontSize: 16)),
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
              SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _getRecommendation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "Get My Recommendation",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 30),
              RecommendationService(key: _serviceKey),
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
    home: RecommendationForm(),
    theme: ThemeData(
      primarySwatch: Colors.green,
    ),
  ));
}