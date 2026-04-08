import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class MealDetailScreen extends StatefulWidget {
  final String planId;
  const MealDetailScreen({super.key, required this.planId});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  int _currentIndex = 2;
  Map<String, dynamic>? mealPlanData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMealPlanDetail();
  }

  void _onNavTap(BuildContext context, int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false); break;
      case 1: Navigator.pushNamedAndRemoveUntil(context, '/workout', (r) => false); break;
      case 2: break;
      case 3: Navigator.pushNamedAndRemoveUntil(context, '/profile', (r) => false); break;
    }
  }

  Future<void> _loadMealPlanDetail() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) { setState(() { errorMessage = 'Not authenticated'; isLoading = false; }); return; }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/diet/${widget.planId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() { mealPlanData = json.decode(response.body); isLoading = false; });
      } else {
        setState(() { errorMessage = 'Failed to load: ${response.statusCode}'; isLoading = false; });
      }
    } catch (e) {
      setState(() { errorMessage = 'Error: $e'; isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : errorMessage != null
                    ? _buildErrorView()
                    : _buildBody(),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text(errorMessage!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadMealPlanDetail,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Retry', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (mealPlanData == null) return const SizedBox();
    final mealPlan = mealPlanData!['meal_plan'] as Map<String, dynamic>;
    final preferences = mealPlanData!['preferences'] as Map<String, dynamic>;
    final meals = mealPlan['meals'] as List<dynamic>;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSummaryCard(mealPlan, preferences),
                  const SizedBox(height: 28),
                  _buildFieldLabel('MACRO BREAKDOWN'),
                  _buildMacroRow(mealPlan['macros']),
                  const SizedBox(height: 28),
                  _buildFieldLabel('DAILY MEALS'),
                  ...meals.asMap().entries.map((e) => _buildMealCard(e.key + 1, e.value)),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Generated · ${DateTime.parse(mealPlanData!['created_at']).toString().split('T')[0]}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, '/nutrition'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const Text('Meal Plan', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _buildSummaryCard(Map<String, dynamic> mealPlan, Map<String, dynamic> preferences) {
    final hasAllergies = preferences['allergies'] != null && (preferences['allergies'] as List).isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${mealPlan['daily_calories']}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: -1)),
                    const Text('KCAL / DAY', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryWithOpacity(0.3)),
                ),
                child: Text(
                  '${mealPlan['meals'].length} Meals',
                  style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.textPrimary.withOpacity(0.05)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                (preferences['food_preference'] ?? 'Standard').toString().toUpperCase(),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              if (hasAllergies) ...[
                const SizedBox(width: 16),
                const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    (preferences['allergies'] as List).join(', '),
                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroRow(Map<String, dynamic> macros) {
    return Row(
      children: [
        Expanded(child: _buildMacroTile('Protein', macros['protein'], AppColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroTile('Carbs', macros['carbs'], AppColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _buildMacroTile('Fats', macros['fats'], AppColors.warning)),
      ],
    );
  }

  Widget _buildMacroTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMealCard(int index, dynamic meal) {
    final items = meal['items'] as List<dynamic>? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                meal['type'] ?? 'Meal $index',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${meal['calories']} kcal',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...items.map<Widget>((item) {
              final name = item is Map ? (item['name'] ?? item.toString()) : item.toString();
              final qty = item is Map ? item['quantity'] : null;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2),
                          ),
                          if (qty != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              qty.toString(),
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }
}
