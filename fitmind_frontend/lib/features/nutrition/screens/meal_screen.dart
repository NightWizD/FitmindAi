import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import 'meal_detail_screen.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({super.key});

  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  int _currentIndex = 2; // Default to nutrition tab
  List<Map<String, dynamic>> mealPlans = [];
  bool isLoading = true;
  bool isSelectionMode = false;
  Set<String> selectedPlans = {};

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/diet/list'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final plans = json.decode(response.body) as List;
        setState(() {
          mealPlans = plans.map((plan) => plan as Map<String, dynamic>).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false); break;
      case 1: Navigator.pushNamedAndRemoveUntil(context, '/workout', (route) => false); break;
      case 2: break;
      case 3: Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false); break;
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
                : _buildBody(),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
      floatingActionButton: isSelectionMode ? null : _buildFAB(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(
            child: mealPlans.isEmpty ? _buildEmptyView() : _buildMealList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSelectionMode ? 'Select Meals' : 'Daily Logs',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                isSelectionMode ? '${selectedPlans.length} chosen' : 'Your generated nutrition plans',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          if (isSelectionMode)
            Row(
              children: [
                TextButton(onPressed: () => setState(() => isSelectionMode = false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
                IconButton(onPressed: selectedPlans.isEmpty ? null : _deleteSelectedPlans, icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error)),
              ],
            )
          else if (mealPlans.isNotEmpty)
            IconButton(onPressed: () => setState(() => isSelectionMode = true), icon: const Icon(Icons.edit_note_rounded, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.secondaryCard, shape: BoxShape.circle, border: Border.all(color: AppColors.primaryWithOpacity(0.1), width: 8)),
            child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.primary, size: 64),
          ),
          const SizedBox(height: 32),
          const Text('No Meal Logs', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Go back to generate your first plan', style: TextStyle(color: AppColors.textDim, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMealList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: mealPlans.length,
      itemBuilder: (context, index) {
        final plan = mealPlans[index];
        final id = plan['id'].toString();
        final isSelected = selectedPlans.contains(id);
        final mealPlan = plan['meal_plan'] as Map<String, dynamic>;

        return GestureDetector(
          onTap: () {
            if (isSelectionMode) {
              setState(() => isSelected ? selectedPlans.remove(id) : selectedPlans.add(id));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MealDetailScreen(planId: id)));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primaryWithOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(isSelectionMode ? (isSelected ? Icons.check_circle_rounded : Icons.circle_outlined) : Icons.restaurant_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Text('Meal ${index + 1}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 14),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMacroTag('${mealPlan['daily_calories']}', 'KCAL'),
                    _buildMacroTag('${mealPlan['meals'].length}', 'MEALS'),
                    _buildMacroTag('${plan['preferences']['food_preference'].toString().toUpperCase()}', 'PREF'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroTag(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: _showGenerateModal,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.auto_awesome_rounded, color: AppColors.textPrimary, size: 28),
      ),
    );
  }

  int mealsPerDay = 3;

  void _showGenerateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textDim, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nutritional Calibration', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    const Text('Configure your AI meal synthesis parameters', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MEAL FREQUENCY', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        Text('${mealsPerDay} meals / day', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.textPrimary.withOpacity(0.08),
                        thumbColor: Colors.white,
                        overlayColor: AppColors.primaryWithOpacity(0.15),
                        trackHeight: 6,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 6),
                      ),
                      child: Slider(
                        value: mealsPerDay.toDouble(),
                        min: 3, max: 6, divisions: 3,
                        onChanged: (v) => setModalState(() => mealsPerDay = v.round()),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: AppColors.primaryWithOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: ElevatedButton(
                        onPressed: _generateMealPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: AppColors.textPrimary, size: 20),
                            SizedBox(width: 12),
                            Text('START SYNTHESIS', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateMealPlan() async {
    if (Navigator.canPop(context)) Navigator.pop(context); // Dismiss modal
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/diet/generate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'food_preference': 'veg', // Backend will override with stored pref
          'allergies': [], 
          'meals_per_day': mealsPerDay
        }),
      );

      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Dismiss loader
      
      if (response.statusCode == 200) {
        _loadMealPlans();
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Dismiss loader
    }
  }

  void _deleteSelectedPlans() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      for (var id in selectedPlans) {
        await http.delete(Uri.parse('${ApiConstants.baseUrl}/diet/$id'), headers: {'Authorization': 'Bearer $token'});
      }
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Dismiss loader
      setState(() { isSelectionMode = false; selectedPlans.clear(); });
      _loadMealPlans();
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Dismiss loader
    }
  }
}
