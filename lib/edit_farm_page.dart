import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditFarmPage extends StatefulWidget {
  final String farmId;

  const EditFarmPage({super.key, required this.farmId});

  @override
  _EditFarmPageState createState() => _EditFarmPageState();
}

class _EditFarmPageState extends State<EditFarmPage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFarmData();
  }

  void _loadFarmData() async {
    DocumentSnapshot farmDoc = await FirebaseFirestore.instance.collection('farms').doc(widget.farmId).get();
    if (farmDoc.exists) {
      setState(() {
        _nameController.text = farmDoc['name'];
        _locationController.text = farmDoc['location'];
        isLoading = false;
      });
    }
  }

  void _updateFarm() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('farms').doc(widget.farmId).update({
        'name': _nameController.text,
        'location': _locationController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Farm updated successfully!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Farm")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Farm Name"),
                      validator: (value) => value!.isEmpty ? "Enter farm name" : null,
                    ),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: "Location"),
                      validator: (value) => value!.isEmpty ? "Enter location" : null,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateFarm,
                      child: Text("Update Farm"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
