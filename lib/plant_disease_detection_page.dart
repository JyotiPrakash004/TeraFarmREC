import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class TeradocApp extends StatelessWidget {
  const TeradocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teradoc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const PlantHealthScreen(),
    );
  }
}

class PlantHealthScreen extends StatefulWidget {
  const PlantHealthScreen({super.key});

  @override
  State<PlantHealthScreen> createState() => _PlantHealthScreenState();
}

class _PlantHealthScreenState extends State<PlantHealthScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _analysisResult = '';
  bool _loading = false;
  late GenerativeModel _model;

  @override
  void initState() {
    super.initState();
    const apiKey = 'AIzaSyDOCRunTsXQqmxo6oysjhWaxgrxavoUkrs';
    final generationConfig = GenerationConfig(
      temperature: 0.8,
      topP: 0.9,
      topK: 2,
      maxOutputTokens: 2048,
    );
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: generationConfig,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      _analyzeImage();
    }
  }

  Future<void> _analyzeImage() async {
    final loc = AppLocalizations.of(context)!;
    if (_selectedImage == null) return;
    setState(() {
      _loading = true;
      _analysisResult = '';
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final promptText = loc.teradocPrompt;
      final content = Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', bytes),
      ]);
      final response = await _model.generateContent([content]);
      final gen =
          response.text ?? response.candidates.first.content as String? ?? '';
      setState(() {
        _analysisResult = gen.replaceAll('*', '').trim();
      });
    } catch (e) {
      setState(() {
        _analysisResult = loc.errorAnalyzing(e.toString());
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.teradocTitle),
        centerTitle: true,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(
                        l.languageCode.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              onChanged: (Locale? newLocale) {
                if (newLocale != null) localeProv.setLocale(newLocale);
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!)
                : Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, size: 100, color: Colors.grey),
                ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(loc.camera),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(loc.gallery),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _analysisResult.isEmpty
                          ? loc.noAnalysisYet
                          : _analysisResult,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            Text(
              loc.teradocWarning,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
