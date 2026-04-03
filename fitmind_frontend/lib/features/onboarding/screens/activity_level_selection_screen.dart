import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityLevelSelectionScreen extends StatefulWidget {
  const ActivityLevelSelectionScreen({super.key});

  @override
  _ActivityLevelSelectionScreenState createState() => _ActivityLevelSelectionScreenState();
}

class _ActivityLevelSelectionScreenState extends State<ActivityLevelSelectionScreen> {
  String _selectedLevel = '';

  final List<Map<String, dynamic>> levels = [
    {'name': 'Sedentary', 'icon': Icons.chair},
    {'name': 'Lightly Active', 'icon': Icons.directions_walk},
    {'name': 'Moderately Active', 'icon': Icons.directions_run},
    {'name': 'Very Active', 'icon': Icons.fitness_center},
    {'name': 'Athlete', 'icon': Icons.sports_soccer},
  ];

  void _selectLevel(String level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _continue() async {
    if (_selectedLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an activity level')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8000/api/v1/user/update-metrics'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'activity_level': _selectedLevel,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity level saved successfully')),
      );
      Navigator.pushNamed(context, '/food-preference');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save activity level')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Step indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) => Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < 3 ? const Color(0xFF3B82F6) : const Color(0xFF374151),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Your Activity Level',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...levels.map((level) => GestureDetector(
                      onTap: () => _selectLevel(level['name']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedLevel == level['name'] ? const Color(0xFF3B82F6) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              level['icon'],
                              color: _selectedLevel == level['name'] ? const Color(0xFF3B82F6) : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                level['name'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              _selectedLevel == level['name'] ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: _selectedLevel == level['name'] ? const Color(0xFF3B82F6) : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
