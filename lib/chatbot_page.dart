import 'package:flutter/material.dart';
import 'api_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController cropController = TextEditingController();
  TextEditingController locationController = TextEditingController();
  String responseText = "Ask for plant care advice!";

  void fetchAdvice() async {
    String crop = cropController.text;
    String location = locationController.text;
    String response = await getPlantCareAdvice(crop, location);

    setState(() {
      responseText = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AI Plant Care Chatbot")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: cropController, decoration: InputDecoration(labelText: "Enter Crop Name")),
            TextField(controller: locationController, decoration: InputDecoration(labelText: "Enter Location")),
            SizedBox(height: 10),
            ElevatedButton(onPressed: fetchAdvice, child: Text("Get Advice")),
            SizedBox(height: 20),
            Text(responseText, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
