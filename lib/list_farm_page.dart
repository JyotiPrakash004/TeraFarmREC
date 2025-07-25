import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart'; // for currentUser
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // New import for geolocation
import 'address_map_picker.dart'; // Import your location picker widget

class ListFarmPage extends StatefulWidget {
  const ListFarmPage({super.key});

  @override
  _ListFarmPageState createState() => _ListFarmPageState();
}

class _ListFarmPageState extends State<ListFarmPage> {
  final _formKey = GlobalKey<FormState>();

  // Farm Details Controllers
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _upiIdController =
      TextEditingController(); // New UPI id controller
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _farmDescriptionController =
      TextEditingController();

  // Scale Option
  String _scaleOption = "Small Scale"; // default selection

  // Products: List of product entries
  final List<Map<String, TextEditingController>> _products = [];

  File? _selectedImage;
  bool _isUploading = false;

  // Store the chosen coordinates from the picker.
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    // Start with one product entry by default.
    _addProductField();
  }

  // Dispose controllers when not needed.
  @override
  void dispose() {
    _farmNameController.dispose();
    _contactNumberController.dispose();
    _upiIdController.dispose();
    _locationController.dispose();
    _farmDescriptionController.dispose();
    for (var product in _products) {
      product['cropName']?.dispose();
      product['stock']?.dispose();
      product['price']?.dispose();
    }
    super.dispose();
  }

  // Add a new product entry (cropName, stock, price).
  void _addProductField() {
    setState(() {
      _products.add({
        'cropName': TextEditingController(),
        'stock': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  // Remove a product entry.
  void _removeProductField(int index) {
    setState(() {
      _products.removeAt(index);
    });
  }

  // Pick an image from gallery.
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No image selected.")));
    }
  }

  // Automatically get the current location.
  Future<LatLng> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Location permissions are permanently denied. Please enable them in the settings.",
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(position.latitude, position.longitude);
  }

  // Opens the map picker with the device's current location pre-selected.
  Future<void> _openMapPicker() async {
    LatLng initialLocation;
    try {
      // Automatically fetch the current location.
      initialLocation = await _getCurrentLocation();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not fetch current location: $e")),
      );
      // Fall back to default location (San Francisco)
      initialLocation = LatLng(37.7749, -122.4194);
    }

    // Open a modal bottom sheet with your AddressMapPicker widget.
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled:
          true, // allows the bottom sheet to be full screen if needed
      builder: (context) => AddressMapPicker(initialLocation: initialLocation),
    );

    if (result != null) {
      setState(() {
        _locationController.text = result["address"] as String;
        _selectedLat = result["lat"] as double;
        _selectedLng = result["lng"] as double;
      });
    }
  }

  // Upload image & save farm details to Firestore.
  Future<void> _saveFarmDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String imageUrl = "";
    if (_selectedImage != null) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance.ref(
          "farm_images/$fileName.jpg",
        );
        imageUrl =
            await (await storageRef.putFile(
              _selectedImage!,
            )).ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
        setState(() => _isUploading = false);
        return;
      }
    }

    final productData =
        _products
            .map(
              (product) => {
                'cropName': product['cropName']!.text.trim(),
                'stock in kgs': product['stock']!.text.trim(),
                'pricePerKg': product['price']!.text.trim(),
              },
            )
            .toList();

    try {
      await FirebaseFirestore.instance.collection('farms').add({
        'farmName': _farmNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'upiId': _upiIdController.text.trim(), // Saving the UPI ID
        'location': _locationController.text.trim(),
        'farmDescription': _farmDescriptionController.text.trim(),
        'scale': _scaleOption,
        'products': productData,
        'imageUrl': imageUrl,
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': FieldValue.serverTimestamp(),
        // Optionally, store the selected coordinates.
        'latitude': _selectedLat,
        'longitude': _selectedLng,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Farm created successfully!")));
      _formKey.currentState!.reset();
      _products.clear();
      _addProductField();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving farm details: $e")));
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("List a Farm"), backgroundColor: Colors.green),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image upload section.
                Text(
                  "Please upload a square image:",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text("Choose File"),
                    ),
                    SizedBox(width: 10),
                    if (_selectedImage != null)
                      Text(
                        "File Chosen",
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                  ],
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Image.file(_selectedImage!, height: 100),
                  ),
                SizedBox(height: 12),
                // Farm Name
                TextFormField(
                  controller: _farmNameController,
                  decoration: InputDecoration(
                    labelText: "Farm Name",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Please enter a farm name" : null,
                ),
                SizedBox(height: 10),
                // Contact Number
                TextFormField(
                  controller: _contactNumberController,
                  decoration: InputDecoration(
                    labelText: "Contact Number",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? "Please enter a contact number"
                              : null,
                ),
                SizedBox(height: 10),
                // UPI ID Field (New)
                TextFormField(
                  controller: _upiIdController,
                  decoration: InputDecoration(
                    labelText: "Seller UPI ID",
                    hintText: "e.g., example@upi",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Please enter your UPI ID" : null,
                ),
                SizedBox(height: 10),
                // Location field with location picker
                TextFormField(
                  controller: _locationController,
                  readOnly:
                      true, // Make read-only so user taps to open the map picker.
                  onTap: _openMapPicker,
                  decoration: InputDecoration(
                    labelText: "Location",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.location_on),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty ? "Please select a location" : null,
                ),
                SizedBox(height: 10),
                // Farm Description
                TextFormField(
                  controller: _farmDescriptionController,
                  decoration: InputDecoration(
                    labelText: "Farm Description",
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value!.isEmpty
                              ? "Please enter a farm description"
                              : null,
                ),
                SizedBox(height: 12),
                // Scale Option (Small / Large)
                Text("Scale:", style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    Radio<String>(
                      value: "Small Scale",
                      groupValue: _scaleOption,
                      onChanged:
                          (value) => setState(() => _scaleOption = value!),
                    ),
                    Text("Small Scale"),
                    SizedBox(width: 20),
                    Radio<String>(
                      value: "Large Scale",
                      groupValue: _scaleOption,
                      onChanged:
                          (value) => setState(() => _scaleOption = value!),
                    ),
                    Text("Large Scale"),
                  ],
                ),
                SizedBox(height: 12),
                // Product Details
                Text(
                  "Product Details:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Column(
                  children:
                      _products.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, TextEditingController> product =
                            entry.value;
                        return _buildProductFields(product, index);
                      }).toList(),
                ),
                SizedBox(height: 10),
                // +Add Product Button
                Center(
                  child: ElevatedButton(
                    onPressed: _addProductField,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text("+Add product"),
                  ),
                ),
                SizedBox(height: 20),
                // Create Farm Button
                Center(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _saveFarmDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child:
                        _isUploading
                            ? CircularProgressIndicator()
                            : Text("Create a Farm"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build one product's text fields.
  Widget _buildProductFields(
    Map<String, TextEditingController> product,
    int index,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Product ${index + 1}",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          // Crop Name
          TextFormField(
            controller: product['cropName'],
            decoration: InputDecoration(
              labelText: "Crop Name",
              border: OutlineInputBorder(),
            ),
            validator:
                (value) => value!.isEmpty ? "Please enter crop name" : null,
          ),
          SizedBox(height: 10),
          // Stock
          TextFormField(
            controller: product['stock'],
            decoration: InputDecoration(
              labelText: "Stock",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? "Please enter stock" : null,
          ),
          SizedBox(height: 10),
          // Price
          TextFormField(
            controller: product['price'],
            decoration: InputDecoration(
              labelText: "Price per kg",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? "Please enter price" : null,
          ),
          SizedBox(height: 10),
          // Remove Product Button (if more than one product)
          if (_products.length > 1)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _removeProductField(index),
                child: Text("Remove", style: TextStyle(color: Colors.red)),
              ),
            ),
        ],
      ),
    );
  }
}
