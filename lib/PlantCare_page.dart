import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const PlantCareApp());
}

class PlantCareApp extends StatelessWidget {
  const PlantCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriGuru Farm AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const FarmAiPage(),
    );
  }
}

class FarmAiPage extends StatefulWidget {
  const FarmAiPage({super.key});

  @override
  State<FarmAiPage> createState() => _FarmAiPageState();
}

class _FarmAiPageState extends State<FarmAiPage> {
  final _cityController = TextEditingController(text: 'Chennai');
  final _plantController = TextEditingController(text: 'Carrot');

  bool _loadingWeather = false;
  bool _loadingAdvice = false;

  double? _temperature;
  int? _humidity;
  String? _condition;
  String? _advice;

  String _selectedLanguage = 'English';
  final List<String> _languages = ['English', 'Hindi', 'Tamil'];

  late GenerativeModel _geminiModel;

  /// UI strings in each language
  final Map<String, Map<String, String>> _uiText = {
    'appTitle': {
      'English': 'AgriGuru Farm AI',
      'Hindi': 'एग्रीगुरु फार्म एआई',
      'Tamil': 'அக்ரி குரு பண்ணை ஏஐ',
    },
    'enterCity': {
      'English': 'Enter City',
      'Hindi': 'शहर दर्ज करें',
      'Tamil': 'நகரத்தை உள்ளிடவும்',
    },
    'getWeather': {
      'English': 'Get Weather',
      'Hindi': 'मौसम प्राप्त करें',
      'Tamil': 'வானிலை பெறவும்',
    },
    'enterPlant': {
      'English': 'Enter Plant Name',
      'Hindi': 'पौधे का नाम दर्ज करें',
      'Tamil': 'தாவரப் பெயரை உள்ளிடவும்',
    },
    'getTips': {
      'English': 'Get Sustainable Tips',
      'Hindi': 'स्थायी सुझाव प्राप्त करें',
      'Tamil': 'நிலைத்திருக்கும் குறிப்புகள் பெறவும்',
    },
    'tryAnother': {
      'English': 'Try Another Plant',
      'Hindi': 'एक और प्रयास करें',
      'Tamil': 'மறு முயற்சி செய்க',
    },
  };
  String _t(String key) => _uiText[key]![_selectedLanguage]!;

  @override
  void initState() {
    super.initState();
    const geminiApiKey = 'AIzaSyDOCRunTsXQqmxo6oysjhWaxgrxavoUkrs';
    final generationConfig = GenerationConfig(
      temperature: 0.7,
      topP: 0.9,
      topK: 40,
      maxOutputTokens: 256,
    );
    _geminiModel = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: geminiApiKey,
      generationConfig: generationConfig,
    );
  }

  Future<void> _getWeather() async {
    setState(() {
      _loadingWeather = true;
      _advice = null;
    });

    final city = _cityController.text.trim();
    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city,
      'appid': '5a0ae185b7294f390b903805280d65c0',
      'units': 'metric',
    });

    try {
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _temperature = (data['main']['temp'] as num).toDouble();
          _humidity = data['main']['humidity'];
          _condition = (data['weather'] as List).first['description'];
        });
      } else {
        throw Exception('Weather fetch failed: ${res.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _loadingWeather = false);
    }
  }

  /// Translate [text] into the selected language, using an instruction in that language.
  Future<String> _translate(String text) async {
    if (_selectedLanguage == 'English') return text;

    String instruction;
    if (_selectedLanguage == 'Hindi') {
      instruction = 'निम्नलिखित पाठ का अनुवाद हिंदी में करें, अर्थ बनाए रखें:';
    } else {
      instruction =
          'பின்வரும் உரையை தமிழ் மொழியில் மொழிபெயர்க்கவும், பொருள் மாறாமிருக்கும் வடிவில்:';
    }

    final prompt = '$instruction\n\n$text';
    final content = Content.multi([TextPart(prompt)]);
    final response = await _geminiModel.generateContent([content]);
    final translated =
        response.text ??
        (response.candidates.isNotEmpty
            ? response.candidates.first.content as String
            : '');
    return translated.trim();
  }

  Future<void> _getAdvice() async {
    if (_temperature == null || _condition == null) {
      final msg =
          _selectedLanguage == 'Hindi'
              ? 'पहले मौसम प्राप्त करें।'
              : _selectedLanguage == 'Tamil'
              ? 'முதலில் வானிலை பெறவும்.'
              : 'Please fetch weather first.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() {
      _loadingAdvice = true;
      _advice = null;
    });

    // Base English prompt
    final basePrompt = '''
You are an expert agricultural advisor.
Given:
• Plant: ${_plantController.text.trim()}
• Temperature: ${_temperature!.toStringAsFixed(1)}°C
• Humidity: $_humidity%
• Weather condition: $_condition

Provide 4 short, emoji-enhanced, sustainable farming tips.
''';

    try {
      // 1) translate the prompt entirely into target language (or leave English)
      final prompt = await _translate(basePrompt);

      // 2) send that prompt to Gemini to generate tips
      final content = Content.multi([TextPart(prompt)]);
      final response = await _geminiModel.generateContent([content]);
      final output =
          response.text ??
          (response.candidates.isNotEmpty
              ? response.candidates.first.content as String
              : '');

      setState(() {
        _advice = output.replaceAll('*', '').trim();
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
    return Scaffold(
      appBar: AppBar(title: Text(_t('appTitle')), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Language dropdown
            Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<String>(
                value: _selectedLanguage,
                items:
                    _languages
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                onChanged: (v) {
                  setState(() => _selectedLanguage = v!);
                },
              ),
            ),

            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: _t('enterCity'),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadingWeather ? null : _getWeather,
                child: Text(_loadingWeather ? '...' : _t('getWeather')),
              ),
            ),

            if (_temperature != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.thermostat,
                        size: 40,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_temperature!.toStringAsFixed(1)} °C'),
                            Text('${_humidity}%'),
                            Text(
                              '${_condition![0].toUpperCase()}${_condition!.substring(1)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            TextField(
              controller: _plantController,
              decoration: InputDecoration(
                labelText: _t('enterPlant'),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    (_loadingAdvice || _temperature == null)
                        ? null
                        : _getAdvice,
                child: Text(_loadingAdvice ? '...' : _t('getTips')),
              ),
            ),

            if (_advice != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_advice!, style: const TextStyle(fontSize: 16)),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                child: Text(_t('tryAnother')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
