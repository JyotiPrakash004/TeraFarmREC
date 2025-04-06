import 'package:flutter/material.dart';
import 'plantcare_page.dart'; // Import the PlantCarePage
import 'teradoc_page.dart'; // Import the TeraDocPage
import 'recommendation_ai_page.dart'; // Import the RecommendationAIPage

class AIPage extends StatelessWidget {
  const AIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "TeraAI",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Set back button color to white
        backgroundColor: Colors.green.shade800,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlantCareApp()),
                );
              },
              icon: const Icon(Icons.local_florist, size: 24, color: Colors.white), // Set icon color to white
              label: const Text(
                "Tera Care AI",
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60), // Increase button size
                backgroundColor: Colors.orange, // Set button color to orange
              ),
            ),
            const SizedBox(height: 20), // Adjust spacing
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeradocApp()),
                );
              },
              icon: const Icon(Icons.medical_services, size: 24, color: Colors.white), // Set icon color to white
              label: const Text(
                "TeraDoc AI",
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60), // Increase button size
                backgroundColor: Colors.orange, // Set button color to orange
              ),
            ),
            const SizedBox(height: 20), // Adjust spacing
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecommendationService()),
                );
              },
              icon: const Icon(Icons.recommend, size: 24, color: Colors.white), // Set icon color to white
              label: const Text(
                "Tera Recommend AI",
                style: TextStyle(color: Colors.white), // Set text color to white
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 60), // Increase button size
                backgroundColor: Colors.orange, // Set button color to orange
              ),
            ),
          ],
        ),
      ),
    );
  }
}
