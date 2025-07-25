import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'address_map_picker.dart'; // <-- your location picker

class EditFarmPage extends StatefulWidget {
  final String farmId;
  const EditFarmPage({super.key, required this.farmId});

  @override
  _EditFarmPageState createState() => _EditFarmPageState();
}

class _EditFarmPageState extends State<EditFarmPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _scaleOption = "Small Scale";

  // New: store coords
  double? _selectedLat;
  double? _selectedLng;

  File? _selectedImage;
  String _imageUrl = "";
  bool _isLoading = true;

  List<Map<String, TextEditingController>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  Future<void> _loadFarmData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('farms')
              .doc(widget.farmId)
              .get();

      if (!doc.exists) throw 'Farm not found';

      final data = doc.data()!;
      setState(() {
        _nameController.text = data['farmName'] ?? '';
        _locationController.text = data['location'] ?? '';
        _contactController.text = data['contactNumber'] ?? '';
        _descriptionController.text = data['farmDescription'] ?? '';
        _scaleOption = data['scale'] ?? 'Small Scale';
        _imageUrl = data['imageUrl'] ?? '';

        // Load coords
        _selectedLat = (data['latitude'] as num?)?.toDouble();
        _selectedLng = (data['longitude'] as num?)?.toDouble();

        // Load products
        final productList = data['products'] as List<dynamic>? ?? [];
        _products =
            productList.map((p) {
              final m = p as Map<String, dynamic>;
              return {
                'cropName': TextEditingController(text: m['cropName'] ?? ''),
                'stock': TextEditingController(
                  text: m['stock in kgs']?.toString() ?? '',
                ),
                'price': TextEditingController(
                  text: m['pricePerKg']?.toString() ?? '',
                ),
              };
            }).toList();

        if (_products.isEmpty) _addProductField();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading farm: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addProductField() {
    setState(() {
      _products.add({
        'cropName': TextEditingController(),
        'stock': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeProductField(int idx) {
    setState(() => _products.removeAt(idx));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => _selectedImage = File(img.path));
  }

  /// Get current device location or fallback to last-selected.
  Future<LatLng> _getCurrentLocation() async {
    if (_selectedLat != null && _selectedLng != null) {
      return LatLng(_selectedLat!, _selectedLng!);
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw 'Location services disabled';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw 'Location permission denied';
      }
    }
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _openMapPicker() async {
    try {
      final initial = await _getCurrentLocation();
      final result = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (_) => AddressMapPicker(initialLocation: initial),
      );
      if (result != null) {
        setState(() {
          _locationController.text = result['address'] as String;
          _selectedLat = result['lat'] as double;
          _selectedLng = result['lng'] as double;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open map: $e")));
    }
  }

  Future<void> _updateFarm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Upload image if changed
      var imageUrl = _imageUrl;
      if (_selectedImage != null) {
        final name = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref("farm_images/$name.jpg");
        final snap = await ref.putFile(_selectedImage!);
        imageUrl = await snap.ref.getDownloadURL();
      }

      // Prepare products
      final products =
          _products
              .map(
                (p) => {
                  'cropName': p['cropName']!.text.trim(),
                  'stock in kgs': p['stock']!.text.trim(),
                  'pricePerKg': p['price']!.text.trim(),
                },
              )
              .toList();

      // Update document
      await FirebaseFirestore.instance
          .collection('farms')
          .doc(widget.farmId)
          .update({
            'farmName': _nameController.text.trim(),
            'location': _locationController.text.trim(),
            'latitude': _selectedLat,
            'longitude': _selectedLng,
            'contactNumber': _contactController.text.trim(),
            'farmDescription': _descriptionController.text.trim(),
            'scale': _scaleOption,
            'products': products,
            'imageUrl': imageUrl,
          });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Farm updated successfully!")));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error updating farm: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
    for (var p in _products) {
      p['cropName']!.dispose();
      p['stock']!.dispose();
      p['price']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Edit Farm")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Edit Farm")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image preview + picker
                if (_imageUrl.isNotEmpty) Image.network(_imageUrl, height: 100),
                if (_selectedImage != null)
                  Image.file(_selectedImage!, height: 100),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text("Change Image"),
                ),
                SizedBox(height: 10),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Farm Name"),
                  validator: (v) => v!.isEmpty ? "Enter farm name" : null,
                ),
                SizedBox(height: 10),

                // Location (map picker)
                TextFormField(
                  controller: _locationController,
                  readOnly: true,
                  onTap: _openMapPicker,
                  decoration: InputDecoration(
                    labelText: "Location",
                    suffixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Select a location" : null,
                ),
                SizedBox(height: 10),

                // Contact
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(labelText: "Contact Number"),
                  validator: (v) => v!.isEmpty ? "Enter contact number" : null,
                ),
                SizedBox(height: 10),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: "Farm Description"),
                  validator: (v) => v!.isEmpty ? "Enter description" : null,
                ),
                SizedBox(height: 10),

                // Scale radios
                Text("Scale:"),
                Row(
                  children: [
                    Radio<String>(
                      value: "Small Scale",
                      groupValue: _scaleOption,
                      onChanged: (v) => setState(() => _scaleOption = v!),
                    ),
                    Text("Small"),
                    Radio<String>(
                      value: "Large Scale",
                      groupValue: _scaleOption,
                      onChanged: (v) => setState(() => _scaleOption = v!),
                    ),
                    Text("Large"),
                  ],
                ),
                SizedBox(height: 10),

                // Products
                Text(
                  "Products:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._products.asMap().entries.map((e) {
                  final idx = e.key;
                  final p = e.value;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Product ${idx + 1}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: p['cropName'],
                            decoration: InputDecoration(labelText: "Crop Name"),
                            validator:
                                (v) => v!.isEmpty ? "Enter crop name" : null,
                          ),
                          TextFormField(
                            controller: p['stock'],
                            decoration: InputDecoration(
                              labelText: "Stock (kgs)",
                            ),
                            validator: (v) => v!.isEmpty ? "Enter stock" : null,
                          ),
                          TextFormField(
                            controller: p['price'],
                            decoration: InputDecoration(
                              labelText: "Price per Kg",
                            ),
                            validator: (v) => v!.isEmpty ? "Enter price" : null,
                          ),
                          if (_products.length > 1)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _removeProductField(idx),
                                child: Text(
                                  "Remove",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                ElevatedButton(
                  onPressed: _addProductField,
                  child: Text("+ Add Product"),
                ),
                SizedBox(height: 20),

                Center(
                  child: ElevatedButton(
                    onPressed: _updateFarm,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: Text("Update Farm"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
