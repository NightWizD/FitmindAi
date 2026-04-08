import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../core/constants/app_colors.dart';
import 'meal_screen.dart';
import 'supplement_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  _NutritionScreenState createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final int _currentIndex = 2; // Default to nutrition tab
  int _targetCalories = 2400;
  int _targetProtein = 160;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserMetrics();
  }

  Future<void> _loadUserMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/metrics'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _targetCalories = data['calories_goal'] ?? 2400;
            // Protein logic: if not explicit, use a standard 2g per kg rule or 30% of calories
            _targetProtein = data['protein_goal'] ?? ((_targetCalories * 0.25) / 4).round();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(context, '/workout', (route) => false);
        break;
      case 2:
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStatsCard(),
                  const SizedBox(height: 32),
                  const Text(
                    'Management',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
                  _buildNavCard(
                    'Meal Plan',
                    'Breakfast, Lunch, Dinner, Snacks',
                    Icons.restaurant_menu_rounded,
                    AppColors.warning,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MealScreen())),
                  ),
                  const SizedBox(height: 16),
                  _buildNavCard(
                    'Supplement Stack',
                    'Clinical markers & Recommendations',
                    Icons.medication_liquid_rounded,
                    AppColors.primary,
                    () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupplementScreen())),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nutrition',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Manage your health fuel',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryWithOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('TARGET', '$_targetCalories', 'KCAL'),
          Container(width: 1, height: 40, color: AppColors.textPrimary.withOpacity(0.05)),
          _buildStatItem('PROTEIN', '$_targetProtein', 'G'),
          Container(width: 1, height: 40, color: AppColors.textPrimary.withOpacity(0.05)),
          _buildStatItem('WATER', '3.5', 'L'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 2),
            Text(unit, style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildNavCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
          ],
        ),
      ),
    );
  }
}
