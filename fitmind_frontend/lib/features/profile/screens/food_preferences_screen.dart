import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

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

  final Map<String, IconData> _preferenceOptions = {
    'veg': Icons.eco_rounded,
    'non-veg': Icons.set_meal_rounded,
    'vegan': Icons.spa_rounded,
    'eggitarian': Icons.egg_rounded,
  };

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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _foodPreference = data['food_preference'] ?? 'veg';
          _dailyFoods.clear();
          if (data['daily_foods'] != null) _dailyFoods.addAll(List<String>.from(data['daily_foods']));
          _allergies.clear();
          if (data['allergies'] != null) _allergies.addAll(List<String>.from(data['allergies']));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePreferences() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/food-preferences'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'food_preference': _foodPreference,
          'daily_foods': _dailyFoods,
          'allergies': _allergies,
        }),
      );
      if (response.statusCode == 200) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences updated')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem(TextEditingController controller, List<String> list) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !list.contains(text)) {
      setState(() { list.add(text); controller.clear(); });
    }
  }

  void _removeItem(String item, List<String> list) => setState(() => list.remove(item));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildFieldLabel('DIETARY PROTOCOL'),
                          _buildDietGrid(),
                          const SizedBox(height: 32),
                          _buildFieldLabel('DAILY INTAKE'),
                          _buildTagInput(
                            controller: _foodController,
                            hint: 'e.g. Rice, Dal, Oats...',
                            items: _dailyFoods,
                            accentColor: AppColors.primary,
                          ),
                          const SizedBox(height: 32),
                          _buildFieldLabel('ALLERGEN FLAGS'),
                          _buildTagInput(
                            controller: _allergyController,
                            hint: 'e.g. Peanuts, Gluten...',
                            items: _allergies,
                            accentColor: AppColors.error,
                          ),
                          const SizedBox(height: 48),
                          _buildSaveButton(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, '/profile'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const Text('Fuel Protocol', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _buildDietGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: _preferenceOptions.entries.map((entry) {
        final isSelected = _foodPreference == entry.key;
        return GestureDetector(
          onTap: () => setState(() => _foodPreference = entry.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryWithOpacity(0.12) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.value, color: isSelected ? AppColors.primary : AppColors.textDim, size: 18),
                const SizedBox(width: 8),
                Text(entry.key.toUpperCase(), style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagInput({
    required TextEditingController controller,
    required String hint,
    required List<String> items,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _addItem(controller, items),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _addItem(controller, items),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.add_rounded, color: accentColor, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _removeItem(item, items),
                    child: Icon(Icons.close_rounded, size: 14, color: accentColor.withOpacity(0.7)),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updatePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          shadowColor: AppColors.primaryWithOpacity(0.4),
        ),
        child: Text('Sync Fuel Protocol', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
