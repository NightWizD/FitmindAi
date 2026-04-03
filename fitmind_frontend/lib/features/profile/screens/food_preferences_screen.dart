import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class FoodPreferencesScreen extends StatefulWidget {
  const FoodPreferencesScreen({super.key});

  @override
  _FoodPreferencesScreenState createState() => _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends State<FoodPreferencesScreen> {
  bool _isLoading = true;
  String _foodPreference = 'veg';
  final List<String> _dailyFoods = [];
  final List<String> _allergies = [];

  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _allergyController = TextEditingController();

  final List<String> _preferenceOptions = ['veg', 'non-veg', 'vegan', 'eggitarian'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _foodController.dispose();
    _allergyController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/metrics'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _foodPreference = data['food_preference'] ?? 'veg';
          _dailyFoods.clear();
          if (data['daily_foods'] != null) {
            _dailyFoods.addAll(List<String>.from(data['daily_foods']));
          }
          _allergies.clear();
          if (data['allergies'] != null) {
            _allergies.addAll(List<String>.from(data['allergies']));
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading preferences: $e');
    }
  }

  Future<void> _updatePreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/food-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'food_preference': _foodPreference,
          'daily_foods': _dailyFoods,
          'allergies': _allergies,
        }),
      );

        if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences updated successfully')),
        );
        // Removed Navigator.pop(context); to stay on the same screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update preferences')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItem(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !list.contains(text)) {
      setState(() {
        list.add(text);
        controller.clear();
      });
    }
  }

  void _removeItem(String item, List<String> list) {
    setState(() {
      list.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Food Preferences',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dietary Type',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _preferenceOptions.map((opt) {
                      final isSelected = _foodPreference == opt;
                      return ChoiceChip(
                        label: Text(opt.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) => setState(() => _foodPreference = opt),
                        selectedColor: const Color(0xFF3B82F6),
                        backgroundColor: const Color(0xFF1F2937),
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildInputSection(
                    title: 'Daily Food Items',
                    hint: 'Add food you eat normally (e.g. Rice, Dal)',
                    controller: _foodController,
                    items: _dailyFoods,
                    icon: Icons.restaurant,
                  ),
                  const SizedBox(height: 24),
                  _buildInputSection(
                    title: 'Allergies',
                    hint: 'Add items you are allergic to',
                    controller: _allergyController,
                    items: _allergies,
                    icon: Icons.warning_amber_rounded,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _updatePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Save Preferences',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInputSection({
    required String title,
    required String hint,
    required TextEditingController controller,
    required List<String> items,
    required IconData icon,
    Color color = const Color(0xFF3B82F6),
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1F2937),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => _addItem(controller, items),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _addItem(controller, items),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(backgroundColor: color),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Chip(
            label: Text(item, style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF374151),
            deleteIcon: const Icon(Icons.close, size: 18, color: Colors.white70),
            onDeleted: () => _removeItem(item, items),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          )).toList(),
        ),
      ],
    );
  }
}
