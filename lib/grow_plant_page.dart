import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class GrowPlantPage extends StatefulWidget {
  const GrowPlantPage({Key? key}) : super(key: key);

  @override
  State<GrowPlantPage> createState() => _GrowPlantPageState();
}

class _GrowPlantPageState extends State<GrowPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final _cropNameController = TextEditingController();
  final _cityController = TextEditingController();
  String? _selectedStage;

  final List<String> _stages = ['seed', 'sapling', 'bud', 'flower', 'fruit'];

  @override
  void dispose() {
    _cropNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _savePlant() async {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate() && _selectedStage != null) {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('plants').add({
        'userId': userId,
        'plantName': _cropNameController.text.trim(),
        'growthStage': _selectedStage!,
        'city': _cityController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.plantRegisteredSuccess)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.growPlantTitle),
        backgroundColor: Colors.green.shade900,
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
                if (newLocale != null) {
                  localeProv.setLocale(newLocale);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cropNameController,
                decoration: InputDecoration(
                  labelText: loc.cropNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v == null || v.isEmpty ? loc.errorEnterCropName : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: loc.cropStageLabel,
                  border: const OutlineInputBorder(),
                ),
                value: _selectedStage,
                items:
                    _stages.map((stageKey) {
                      final stageLabel =
                          {
                            'seed': loc.stageSeed,
                            'sapling': loc.stageSapling,
                            'bud': loc.stageBud,
                            'flower': loc.stageFlower,
                            'fruit': loc.stageFruit,
                          }[stageKey]!;
                      return DropdownMenuItem(
                        value: stageKey,
                        child: Text(stageLabel),
                      );
                    }).toList(),
                onChanged: (v) => setState(() => _selectedStage = v),
                validator:
                    (_) => _selectedStage == null ? loc.errorSelectStage : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: loc.cityLabel,
                  border: const OutlineInputBorder(),
                ),
                validator:
                    (v) => v == null || v.isEmpty ? loc.errorEnterCity : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  loc.registerPlantButton,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
