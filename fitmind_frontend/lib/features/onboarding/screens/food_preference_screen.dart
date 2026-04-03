import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FoodPreferenceScreen extends StatefulWidget {
  const FoodPreferenceScreen({super.key});

  @override
  _FoodPreferenceScreenState createState() => _FoodPreferenceScreenState();
}

class _FoodPreferenceScreenState extends State<FoodPreferenceScreen> {
  List<String> _selectedPreferences = [];
  final TextEditingController _allergyController = TextEditingController();

  final List<String> preferences = ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Eggitarian'];

  void _selectPreference(String pref) {
    setState(() {
      if (_selectedPreferences.contains(pref)) {
        _selectedPreferences.remove(pref);
      } else {
        _selectedPreferences.add(pref);
      }
    });
  }

  void _continue() async {
    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one preference')),
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

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/v1/user/food-preferences'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'preferences': _selectedPreferences,
        'allergy': _allergyController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Food preferences saved successfully')),
      );
      // Navigate to home or dashboard
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save preferences')),
      );
    }
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
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
                    color: const Color(0xFF3B82F6),
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
                      'Select Your Food Preferences',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...preferences.map((pref) => GestureDetector(
                      onTap: () => _selectPreference(pref),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPreferences.contains(pref) ? const Color(0xFF3B82F6) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedPreferences.contains(pref) ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: _selectedPreferences.contains(pref) ? const Color(0xFF3B82F6) : Colors.grey,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              pref,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _allergyController,
                      decoration: InputDecoration(
                        labelText: 'Allergies (optional)',
                        labelStyle: const TextStyle(color: Colors.white),
                        filled: true,
                        fillColor: const Color(0xFF374151),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
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
