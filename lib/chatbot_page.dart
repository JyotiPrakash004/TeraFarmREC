import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Care Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PlantCareHomePage(),
    );
  }
}

class PlantCareHomePage extends StatefulWidget {
  const PlantCareHomePage({super.key});

  @override
  _PlantCareHomePageState createState() => _PlantCareHomePageState();
}

class _PlantCareHomePageState extends State<PlantCareHomePage> {
  final _cityController = TextEditingController();
  final _plantController = TextEditingController();

  String? weatherInfo; // Holds weather details string.
  Map<String, dynamic>? weatherData;
  String? advice;
  bool isLoadingWeather = false;
  bool isLoadingAdvice = false;

  final String openWeatherApiKey = "5a0ae185b7294f390b903805280d65c0";
  // Updated backend URL for Google Cloud deployment.
  final String backendUrl = "https://tera-242561185203.asia-south1.run.app/";

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoadingWeather = true;
      weatherInfo = null;
      weatherData = null;
      advice = null; // Reset advice if new city is entered.
    });
    final url = Uri.parse(
        "http://api.openweathermap.org/data/2.5/weather?q=$city&appid=$openWeatherApiKey&units=metric");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weatherData = data;
          weatherInfo =
              "Temperature: ${data['main']['temp']}°C\nHumidity: ${data['main']['humidity']}%\nCondition: ${data['weather'][0]['description']}";
        });
      } else {
        setState(() {
          weatherInfo = "Error: Unable to fetch weather data for $city.";
        });
      }
    } catch (e) {
      setState(() {
        weatherInfo = "Error: $e";
      });
    }
    setState(() {
      isLoadingWeather = false;
    });
  }

  Future<void> fetchAdvice(String plant, String city) async {
    setState(() {
      isLoadingAdvice = true;
      advice = null;
    });
    // Construct the URL for the backend endpoint.
    final url = Uri.parse("$backendUrl?plant_name=$plant&location=$city");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          advice = data['plant_care_advice'];
        });
      } else {
        setState(() {
          advice = "Error: Unable to fetch plant care advice.";
        });
      }
    } catch (e) {
      setState(() {
        advice = "Error: $e";
      });
    }
    setState(() {
      isLoadingAdvice = false;
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _plantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plant Care Advisor"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Ask for the city.
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: "Enter City",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  final city = _cityController.text.trim();
                  if (city.isNotEmpty) {
                    fetchWeather(city);
                  }
                },
                child: isLoadingWeather
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text("Get Weather"),
              ),
              const SizedBox(height: 20),
              // Display weather information.
              if (weatherInfo != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      weatherInfo!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              // Step 2: Ask for the plant name if weather data is available.
              if (weatherData != null) ...[
                TextField(
                  controller: _plantController,
                  decoration: const InputDecoration(
                    labelText: "Enter Plant Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final plant = _plantController.text.trim();
                    final city = _cityController.text.trim();
                    if (plant.isNotEmpty && city.isNotEmpty) {
                      fetchAdvice(plant, city);
                    }
                  },
                  child: isLoadingAdvice
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Get Plant Care Advice"),
                ),
              ],
              const SizedBox(height: 20),
              // Display the plant care advice.
              if (advice != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      advice!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}