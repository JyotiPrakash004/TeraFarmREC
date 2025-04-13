import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GrowPlantPage extends StatefulWidget {
  const GrowPlantPage({Key? key}) : super(key: key);

  @override
  _GrowPlantPageState createState() => _GrowPlantPageState();
}

class _GrowPlantPageState extends State<GrowPlantPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cropNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedStage;

  final List<String> _stages = ['Seed', 'Sapling', 'Bud', 'Flower', 'Fruit'];

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate() && _selectedStage != null) {
      String cropName = _cropNameController.text.trim();
      String city = _cityController.text.trim();
      String stage = _selectedStage!;
      String userId = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('plants').add({
        'userId': userId,
        'plantName': cropName,
        'growthStage': stage,
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
        'createdAtLocal': DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plant registered successfully!')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grow a Plant'),
        backgroundColor: Colors.green.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _cropNameController,
                decoration: const InputDecoration(
                  labelText: 'Crop Name',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the crop name'
                            : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Crop Stage',
                  border: OutlineInputBorder(),
                ),
                value: _selectedStage,
                items:
                    _stages
                        .map(
                          (stage) => DropdownMenuItem(
                            value: stage,
                            child: Text(stage),
                          ),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _selectedStage = value),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please select a crop stage'
                            : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter the city'
                            : null,
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
                child: const Text(
                  'Register Plant',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
