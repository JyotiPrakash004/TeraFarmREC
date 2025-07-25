import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

void main() {
  runApp(const TeradocApp());
}

class TeradocApp extends StatelessWidget {
  const TeradocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleProvider(const Locale('en')),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProv, _) {
          return MaterialApp(
            locale: localeProv.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            title: AppLocalizations.of(context)!.teradocTitle,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(primarySwatch: Colors.green),
            home: const PlantHealthScreen(),
          );
        },
      ),
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
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
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
      final promptText =
          loc.teradocPrompt +
          "\n\n"
              "Explain in clear, simple language for farmers: describe visible symptoms, "
              "likely causes, and provide step-by-step treatment recommendations using locally available resources.Add emojis to make it engaging.\n\n";
      final content = Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', bytes),
      ]);
      final response = await _model.generateContent([content]);
      final generated =
          response.text ??
          (response.candidates.isNotEmpty
              ? response.candidates.first.content as String
              : '');
      final cleaned = generated.replaceAll('*', '').trim();

      setState(() {
        _analysisResult = cleaned.isNotEmpty ? cleaned : loc.noAnalysisYet;
      });
    } catch (e) {
      setState(() {
        _analysisResult = loc.errorAnalyzing(e.toString());
      });
    } finally {
      setState(() => _loading = false);
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
              icon: const Icon(
                Icons.language,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem<Locale>(
                      value: l,
                      child: Text(
                        l.languageCode.toUpperCase(),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (newLoc) {
                if (newLoc != null) localeProv.setLocale(newLoc);
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!)
            else
              Container(
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
            if (_loading)
              const CircularProgressIndicator()
            else
              Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _analysisResult,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
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
