import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class FoodPreferenceScreen extends StatefulWidget {
  const FoodPreferenceScreen({super.key});

  @override
  _FoodPreferenceScreenState createState() => _FoodPreferenceScreenState();
}

class _FoodPreferenceScreenState extends State<FoodPreferenceScreen> {
  String _selectedPreference = 'veg';
  final TextEditingController _allergyController = TextEditingController();
  bool _isLoading = false;

  final Map<String, IconData> prefOptions = {
    'Veg': Icons.spa_rounded,
    'Non-Veg': Icons.restaurant_menu_rounded,
    'Vegan': Icons.eco_rounded,
    'Eggitarian': Icons.egg_rounded,
  };

  void _selectPreference(String pref) {
    setState(() => _selectedPreference = pref.toLowerCase());
  }

  void _continue() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/food-preferences'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'food_preference': _selectedPreference,
          'allergies': _allergyController.text.isNotEmpty ? _allergyController.text.split(',').map((e) => e.trim()).toList() : [],
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(3),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader('Fuel Protocol', 'Select your dietary alignment'),
                    const SizedBox(height: 32),
                    ...prefOptions.keys.map((p) => _buildPrefCard(p, prefOptions[p]!)),
                    const SizedBox(height: 32),
                    _buildFieldLabel('KNOWN ALLERGIES (OPTIONAL)'),
                    _buildTextField(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int step) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: List.generate(4, (index) => Expanded(
          child: Container(
            height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= step ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
              boxShadow: index <= step ? [BoxShadow(color: AppColors.primaryWithOpacity(0.3), blurRadius: 8)] : null,
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildPrefCard(String name, IconData icon) {
    bool isSelected = _selectedPreference == name.toLowerCase();
    return GestureDetector(
      onTap: () => _selectPreference(name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWithOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (isSelected ? AppColors.primary : AppColors.textPrimary).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textDim, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(name, style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold))),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textPrimary.withOpacity(0.05))),
      child: TextFormField(
        controller: _allergyController, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 18),
          hintText: 'e.g. Peanuts, Shellfish', hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity, height: 64,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8, shadowColor: AppColors.primaryWithOpacity(0.4),
          ),
          child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text('Complete Calibration', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
