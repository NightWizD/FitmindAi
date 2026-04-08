import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class ActivityLevelSelectionScreen extends StatefulWidget {
  const ActivityLevelSelectionScreen({super.key});

  @override
  _ActivityLevelSelectionScreenState createState() => _ActivityLevelSelectionScreenState();
}

class _ActivityLevelSelectionScreenState extends State<ActivityLevelSelectionScreen> {
  String _selectedLevel = '';
  bool _isLoading = false;

  final List<Map<String, dynamic>> levels = [
    {'name': 'Sedentary', 'icon': Icons.chair_rounded, 'desc': 'Minimal physical output'},
    {'name': 'Lightly Active', 'icon': Icons.directions_walk_rounded, 'desc': 'Light exercise 1-3 days/week'},
    {'name': 'Moderately Active', 'icon': Icons.directions_run_rounded, 'desc': 'Steady exercise 3-5 days/week'},
    {'name': 'Very Active', 'icon': Icons.fitness_center_rounded, 'desc': 'Hard exercise 6-7 days/week'},
    {'name': 'Elite Athlete', 'icon': Icons.bolt_rounded, 'desc': 'Professional training load'},
  ];

  void _selectLevel(String level) {
    setState(() => _selectedLevel = level);
  }

  void _continue() async {
    if (_selectedLevel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an activity level')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/user/update-metrics'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({'activity_level': _selectedLevel}),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/food-preference');
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
            _buildProgress(2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader('Metabolic Tier', 'Define your daily energy output'),
                    const SizedBox(height: 32),
                    ...levels.map((l) => _buildLevelCard(l)),
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

  Widget _buildLevelCard(Map<String, dynamic> level) {
    bool isSelected = _selectedLevel == level['name'];
    return GestureDetector(
      onTap: () => _selectLevel(level['name']),
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
              child: Icon(level['icon'], color: isSelected ? AppColors.primary : AppColors.textDim, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(level['name'], style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(level['desc'], style: TextStyle(color: AppColors.textPrimary.withOpacity(isSelected ? 0.5 : 0.2), fontSize: 12)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24),
          ],
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
          child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text('Synchronize Output', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
