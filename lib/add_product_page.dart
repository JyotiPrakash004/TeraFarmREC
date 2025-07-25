import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'main.dart' show LocaleProvider;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _categoryKey = 'vegetables'; // keys: vegetables, fruits, herbs

  Future<void> _addProduct() async {
    final loc = AppLocalizations.of(context)!;
    final sellerId = _auth.currentUser!.uid;

    await _firestore.collection('products').add({
      'name': _nameCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
      'category': _categoryKey,
      'description': _descCtrl.text.trim(),
      'sellerId': sellerId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loc.productAddedMessage)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context, listen: false);

    final categoryOptions = <String>['vegetables', 'fruits', 'herbs'];

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.addProductPageTitle),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<Locale>(
              icon: const Icon(Icons.language, color: Colors.white),
              value: localeProv.locale,
              items:
                  AppLocalizations.supportedLocales.map((l) {
                    return DropdownMenuItem(
                      value: l,
                      child: Text(l.languageCode.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (locale) {
                if (locale != null) {
                  localeProv.setLocale(locale);
                }
              },
            ),
          ),
        ],
        backgroundColor: Colors.green.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: loc.productNameLabel),
            ),
            TextField(
              controller: _priceCtrl,
              decoration: InputDecoration(labelText: loc.priceLabel),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryKey,
              decoration: InputDecoration(labelText: loc.categoryLabel),
              items:
                  categoryOptions.map((key) {
                    final title =
                        {
                          'vegetables': loc.categoryVegetables,
                          'fruits': loc.categoryFruits,
                          'herbs': loc.categoryHerbs,
                        }[key]!;
                    return DropdownMenuItem(value: key, child: Text(title));
                  }).toList(),
              onChanged: (v) => setState(() => _categoryKey = v!),
            ),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: loc.descriptionLabel),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addProduct,
              child: Text(loc.addProductButton),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
