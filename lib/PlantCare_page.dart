// PlantCare_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'l10n/app_localizations.dart';
import 'address_map_picker.dart';
import 'main.dart' show LocaleProvider;

void main() {
  runApp(PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(const Locale('en')),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProv, _) {
          final loc = AppLocalizations.of(context)!;
          return MaterialApp(
            locale: localeProv.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            title: loc.appTitle,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            ),
            home: const FarmAiPage(),
          );
        },
      ),
    );
  }
}

class FarmAiPage extends StatefulWidget {
  const FarmAiPage({super.key});
  @override
  State<FarmAiPage> createState() => _FarmAiPageState();
}

class _FarmAiPageState extends State<FarmAiPage> {
  final _cityController = TextEditingController();
  final _plantController = TextEditingController(text: 'Carrot');

  bool _loadingWeather = false, _loadingAdvice = false;
  double? _temperature, _latitude, _longitude;
  int? _humidity;
  String? _condition, _advice, _currentAddress;

  late GenerativeModel _geminiModel;

  @override
  void initState() {
    super.initState();
    const geminiApiKey = 'AIzaSyDOCRunTsXQqmxo6oysjhWaxgrxavoUkrs';
    _geminiModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: geminiApiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topP: 0.9,
        topK: 40,
        maxOutputTokens: 256,
      ),
    );
  }

  /// Get current device location for centering the map picker
  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("Location services disabled.");
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied)
        throw Exception("Permissions denied.");
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception("Permissions permanently denied.");
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  /// Open your AddressMapPicker in a bottom sheet
  Future<void> _openMapPicker() async {
    LatLng initial;
    try {
      initial = await _getCurrentLocation();
    } catch (_) {
      initial = const LatLng(13.0827, 80.2707); // fallback
    }
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddressMapPicker(initialLocation: initial),
    );
    if (result != null) {
      setState(() {
        _latitude = result['lat'] as double;
        _longitude = result['lng'] as double;
        _currentAddress = result['address'] as String;
        _cityController.text = _currentAddress!;
      });
    }
  }

  /// Fetch only current weather (no forecast)
  Future<void> _getWeather() async {
    setState(() {
      _loadingWeather = true;
      _advice = null;
    });

    final key = '994SBTQFYTXZJPS5YLZP5FWGW';
    final query =
        (_latitude != null && _longitude != null)
            ? '$_latitude,$_longitude'
            : _cityController.text.trim();
    final uri = Uri.https(
      'weather.visualcrossing.com',
      '/VisualCrossingWebServices/rest/services/timeline/$query',
      {
        'unitGroup': 'metric',
        'include': 'current',
        'key': key,
        'contentType': 'json',
      },
    );

    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('Weather fetch failed: ${res.statusCode}');
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final curr = data['currentConditions'] as Map<String, dynamic>;
      setState(() {
        _temperature = (curr['temp'] as num).toDouble();
        _humidity = (curr['humidity'] as num).toInt();
        _condition = curr['conditions'] as String;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loadingWeather = false);
    }
  }

  Future<String> _translatePrompt(String text) async {
    final loc = AppLocalizations.of(context)!;
    if (loc.localeName == 'en') return text;
    final prompt = '${loc.translationInstruction}\n\n$text';
    final resp = await _geminiModel.generateContent([
      Content.multi([TextPart(prompt)]),
    ]);
    return (resp.text ?? resp.candidates.first.content as String).trim();
  }

  Future<void> _getAdvice() async {
    if (_temperature == null || _condition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fetchWeatherFirst),
        ),
      );
      return;
    }
    setState(() {
      _loadingAdvice = true;
      _advice = null;
    });

    final basePrompt = '''
You are an expert agricultural advisor.
Given:
• Plant: ${_plantController.text.trim()}
• Location: ${_currentAddress ?? _cityController.text.trim()}
• Current: ${_temperature!.toStringAsFixed(1)}°C, $_humidity% RH, $_condition

Provide creative, emoji‑enhanced, actionable tips. Short, engaging, specific.
Include YouTube links in the user’s language.
''';

    try {
      final prompt = await _translatePrompt(basePrompt);
      final resp = await _geminiModel.generateContent([
        Content.multi([TextPart(prompt)]),
      ]);
      setState(() {
        _advice =
            (resp.text ?? resp.candidates.first.content as String)
                .replaceAll('*', '')
                .trim();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loadingAdvice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appTitle),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.black),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(
                        l.languageCode.toUpperCase(),
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  }).toList(),
              onChanged: (l) {
                if (l != null) localeProv.setLocale(l);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // City field: manual or map pick, onSubmitted fires weather
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: loc.enterCity,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _openMapPicker,
                ),
              ),
              onChanged: (_) {
                // manual typing clears prior coords
                setState(() {
                  _latitude = null;
                  _longitude = null;
                  _currentAddress = null;
                });
              },
              onSubmitted: (_) => _getWeather(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadingWeather ? null : _getWeather,
              child: Text(_loadingWeather ? loc.loading : loc.getWeather),
            ),

            // Weather display
            if (_temperature != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_temperature!.toStringAsFixed(1)} °C'),
                      Text('$_humidity% RH'),
                      Text(
                        '${_condition![0].toUpperCase()}${_condition!.substring(1)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            // Plant input + advice
            TextField(
              controller: _plantController,
              decoration: InputDecoration(labelText: loc.enterPlant),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed:
                  (_loadingAdvice || _temperature == null) ? null : _getAdvice,
              child: Text(_loadingAdvice ? loc.loading : loc.getTips),
            ),

            if (_advice != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_advice!),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _temperature = null;
                    _humidity = null;
                    _condition = null;
                    _advice = null;
                  });
                },
                child: Text(loc.tryAnother),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
