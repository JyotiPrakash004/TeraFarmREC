import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PlantGrowthAnalysisPage extends StatefulWidget {
  const PlantGrowthAnalysisPage({Key? key}) : super(key: key);

  @override
  State<PlantGrowthAnalysisPage> createState() =>
      _PlantGrowthAnalysisPageState();
}

class _PlantGrowthAnalysisPageState extends State<PlantGrowthAnalysisPage> {
  // Your backend URL for fetching plant suggestions.
  final String backendUrl = "https://tera-242561185203.asia-south1.run.app/";

  String? _expandedPlantId;
  final Map<String, bool> _loadingAdvice = {};
  final Map<String, String> _adviceCache = {};

  // Static tasks mapping per plant.
  Map<String, Map<String, List<String>>> plantTasks = {
    'apple': {
      'daily': [
        'Check for pest signs',
        'Water the apple tree base (if needed)',
        'Observe leaf color',
      ],
      'weekly': [
        'Inspect for fungal diseases',
        'Apply organic fertilizer',
        'Prune small branches',
      ],
    },
    'beans': {
      'daily': [
        'Water soil (keep moist)',
        'Ensure 6+ hrs of sunlight',
        'Check soil temperature',
      ],
      'weekly': [
        'Add compost or mulch',
        'Inspect for aphids',
        'Weed around base',
      ],
    },
    'tomato': {
      'daily': [
        'Water at base (avoid leaves)',
        'Check for curling leaves',
        'Ensure full sunlight exposure',
      ],
      'weekly': [
        'Apply balanced fertilizer',
        'Prune lower stems',
        'Inspect for pests',
      ],
    },
    'onion': {
      'daily': [
        'Water lightly',
        'Monitor bulb exposure',
        'Clear surrounding weeds',
      ],
      'weekly': [
        'Fertilize with nitrogen source',
        'Loosen surrounding soil',
        'Check for rot signs',
      ],
    },
  };

  /// Returns an asset image based on the crop name.
  String _getImageAsset(String cropName) {
    String lowerName = cropName.toLowerCase();
    if (lowerName.contains('tomato')) return 'assets/tomato.png';
    if (lowerName.contains('beans')) return 'assets/beans.png';
    if (lowerName.contains('onion')) return 'assets/onion.png';
    if (lowerName.contains('apple')) return 'assets/apple.png';
    return 'assets/default.png';
  }

  /// Returns the number of days since the plant was added.
  int _calculateDaysSincePlanted(int createdAtMillis) {
    DateTime planted = DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
    return DateTime.now().difference(planted).inDays;
  }

  /// Fetches plant care advice suggestion from your backend.
  Future<String> _fetchPlantAdvice({
    required String plantName,
    required String city,
    required String growthStage,
    required int daysSincePlanted,
  }) async {
    final uri = Uri.parse(
      "$backendUrl?plant_name=${Uri.encodeComponent(plantName)}"
      "&location=${Uri.encodeComponent(city)}"
      "&growth_stage=${Uri.encodeComponent(growthStage)}"
      "&days_since_planted=$daysSincePlanted",
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['plant_care_advice'] ?? "No advice received.";
      } else {
        return "Error: Unable to fetch advice.";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  /// Determines whether a task is marked as complete.
  /// Daily tasks are complete only if marked today.
  /// Weekly tasks are complete if marked within the past 7 days.
  bool _isTaskChecked(
    Map<String, dynamic> completedTasksMap,
    String task, {
    required bool isWeekly,
  }) {
    if (!completedTasksMap.containsKey(task)) return false;
    final parts = completedTasksMap[task].split('-');
    if (parts.length != 3) return false;
    final taskDate = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    if (isWeekly) {
      return now.difference(taskDate).inDays < 7;
    } else {
      return taskDate.year == now.year &&
          taskDate.month == now.month &&
          taskDate.day == now.day;
    }
  }

  /// Returns the XP threshold for leveling up.
  /// The threshold increases by 5 with each new level.
  int _getLevelUpThreshold(int level) {
    return 20 + (level - 1) * 5;
  }

  /// Updates the task completion state and handles XP/level logic.
  Future<void> _toggleTask(
    String plantId,
    String task,
    bool isChecked, {
    required bool isWeekly,
  }) async {
    final plantDoc = FirebaseFirestore.instance
        .collection('plants')
        .doc(plantId);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    final today = DateTime.now();
    final todayStr =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    if (isChecked) {
      // Mark the task as completed.
      await plantDoc.set({
        'completedTasks': {task: todayStr},
      }, SetOptions(merge: true));

      final int xpGain = isWeekly ? 10 : 5;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        int currentXp = snapshot.data()?['xp'] ?? 0;
        int currentLevel = snapshot.data()?['level'] ?? 1;

        int newXp = currentXp + xpGain;
        bool leveledUp = false;

        // Dynamic level up: threshold increases by 5 per level.
        while (newXp >= _getLevelUpThreshold(currentLevel)) {
          newXp -= _getLevelUpThreshold(currentLevel);
          currentLevel++;
          leveledUp = true;
        }

        transaction.update(userDoc, {'xp': newXp, 'level': currentLevel});

        if (leveledUp) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _showLevelUpPopup(currentLevel);
          });
        }
      });
    } else {
      // Removing a task completion simply deletes its record.
      await plantDoc.update({'completedTasks.$task': FieldValue.delete()});
    }
  }

  /// Shows a level-up popup when the user levels up.
  void _showLevelUpPopup(int newLevel) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade700,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Level Up!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You’ve reached level $newLevel 🎉',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    child: const Text('Awesome!'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  /// Handles the fetching and caching of plant care advice.
  void _handleSuggestion({
    required String plantId,
    required String plantName,
    required String city,
    required String growthStage,
    required int daysSincePlanted,
  }) {
    setState(() {
      _loadingAdvice[plantId] = true;
    });
    _fetchPlantAdvice(
      plantName: plantName,
      city: city,
      growthStage: growthStage,
      daysSincePlanted: daysSincePlanted,
    ).then((advice) {
      setState(() {
        _adviceCache[plantId] = advice;
        _loadingAdvice[plantId] = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Growth Analysis'),
        backgroundColor: Colors.green.shade900,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('plants')
                .where('userId', isEqualTo: userId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No plants found.'));
          }
          final plants = snapshot.data!.docs;
          return ListView.builder(
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plantData = plants[index].data() as Map<String, dynamic>;
              final plantId = plants[index].id;
              final String plantNameRaw = (plantData['plantName'] ?? '');
              final String plantName = plantNameRaw.toLowerCase();
              final growthStage = plantData['growthStage'] ?? 'N/A';
              final city = plantData['city'] ?? 'Unknown City';
              final createdAt = plantData['createdAtLocal'] ?? 0;
              final int daysSincePlanted = _calculateDaysSincePlanted(
                createdAt,
              );
              final bool isExpanded = _expandedPlantId == plantId;
              final String imageAsset = _getImageAsset(plantName);

              // Ensure that completedTasks field exists.
              final Map<String, dynamic> completedTasksMap =
                  (plantData['completedTasks'] is Map<String, dynamic>)
                      ? plantData['completedTasks'] as Map<String, dynamic>
                      : {};

              final tasks =
                  plantTasks[plantName] ?? {'daily': [], 'weekly': []};

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.asset(imageAsset, width: 50, height: 50),
                      title: Text(
                        plantNameRaw.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Stage: $growthStage\nCity: $city\nPlanted: $daysSincePlanted day(s) ago',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.lightbulb,
                              color: Colors.orange,
                            ),
                            onPressed: () {
                              setState(() {
                                _expandedPlantId = plantId;
                                _loadingAdvice[plantId] = true;
                              });
                              _handleSuggestion(
                                plantId: plantId,
                                plantName: plantNameRaw,
                                city: city,
                                growthStage: growthStage,
                                daysSincePlanted: daysSincePlanted,
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              setState(() {
                                _expandedPlantId = isExpanded ? null : plantId;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🌿 Daily Tasks:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...tasks['daily']!.map((task) {
                              final bool isChecked = _isTaskChecked(
                                completedTasksMap,
                                task,
                                isWeekly: false,
                              );
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text("• $task"),
                                value: isChecked,
                                onChanged: (bool? val) {
                                  _toggleTask(
                                    plantId,
                                    task,
                                    val ?? false,
                                    isWeekly: false,
                                  );
                                },
                              );
                            }).toList(),
                            const SizedBox(height: 8),
                            Text(
                              '🌱 Weekly Tasks:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ...tasks['weekly']!.map((task) {
                              final bool isChecked = _isTaskChecked(
                                completedTasksMap,
                                task,
                                isWeekly: true,
                              );
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text("• $task"),
                                value: isChecked,
                                onChanged: (bool? val) {
                                  _toggleTask(
                                    plantId,
                                    task,
                                    val ?? false,
                                    isWeekly: true,
                                  );
                                },
                              );
                            }).toList(),
                            if (_adviceCache.containsKey(plantId))
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  "💡 Advice:\n${_adviceCache[plantId]}",
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
