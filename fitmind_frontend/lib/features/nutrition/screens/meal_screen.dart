import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/bottom_nav_bar.dart';
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
  String foodPreference = 'veg';
  String allergies = '';
  int mealsPerDay = 3;
  bool isSelectionMode = false;
  List<String> selectedPlans = [];

  @override
  void initState() {
    super.initState();
    _loadMealPlans();
  }

  Future<void> _loadMealPlans() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/v1/diet/list'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final plans = json.decode(response.body) as List;
      setState(() {
        mealPlans = plans.map((plan) => plan as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load meal plans')),
      );
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
        // Already on nutrition
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
        break;
    }
  }

  void _handleMenuSelection(String value) {
    if (value == 'delete') {
      setState(() {
        isSelectionMode = true;
        selectedPlans.clear();
      });
    }
  }

  void _cancelSelection() {
    setState(() {
      isSelectionMode = false;
      selectedPlans.clear();
    });
  }

  void _togglePlanSelection(String planId) {
    setState(() {
      if (selectedPlans.contains(planId)) {
        selectedPlans.remove(planId);
      } else {
        selectedPlans.add(planId);
      }
    });
  }

  void _deleteSelectedPlans() async {
    if (selectedPlans.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting selected meal plans...'),
            ],
          ),
        );
      },
    );

    try {
      for (String planId in selectedPlans) {
        final response = await http.delete(
          Uri.parse('http://10.0.2.2:8000/api/v1/diet/$planId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to delete plan $planId');
        }
      }

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedPlans.length} meal plan(s) deleted')),
      );

      setState(() {
        isSelectionMode = false;
        selectedPlans.clear();
      });

      _loadMealPlans(); // Refresh the list
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting plans: $e')),
      );
    }
  }

  void _showGenerateMealModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 380,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Generate Meal Plan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        // Meals per Day
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Meals per Day',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Slider(
                                      value: mealsPerDay.toDouble(),
                                      min: 2,
                                      max: 6,
                                      divisions: 4,
                                      label: mealsPerDay.toString(),
                                      activeColor: const Color(0xFF3B82F6),
                                      onChanged: (value) => setState(() => mealsPerDay = value.toInt()),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    mealsPerDay.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _generateMealPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Generate',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generateMealPlan() async {
    Navigator.pop(context); // Close the modal

    // Show loading dialog with proper context
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating your meal plan...'),
            ],
          ),
        );
      },
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/diet/generate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'food_preference': 'veg',
          'allergies': [],
          'meals_per_day': mealsPerDay,
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal plan generated!')),
        );
        _loadMealPlans(); // Refresh the list to show new plan
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate plan: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: isSelectionMode
            ? const Text(
                'Select Meals to Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Text(
                'Meal Plans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: isSelectionMode
            ? [
                TextButton(
                  onPressed: _cancelSelection,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedPlans.isEmpty ? null : _deleteSelectedPlans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: Text(
                    'Delete (${selectedPlans.length})',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
              ]
            : [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: _handleMenuSelection,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Meals'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mealPlans.isEmpty
                    ? _buildEmptyView()
                    : _buildMealPlansList(),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 50),
        child: FloatingActionButton(
          onPressed: _showGenerateMealModal,
          backgroundColor: const Color(0xFF3B82F6),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.white70,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'No meal plans yet.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first meal plan.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mealPlans.length,
      itemBuilder: (context, index) {
        final plan = mealPlans[index];
        final mealPlan = plan['meal_plan'] as Map<String, dynamic>;
        final preferences = plan['preferences'] as Map<String, dynamic>;
        final isSelected = selectedPlans.contains(plan['id']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isSelected ? const Color(0xFF1F2937).withOpacity(0.8) : const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected ? const BorderSide(color: Color(0xFF3B82F6), width: 2) : BorderSide.none,
          ),
          child: InkWell(
            onTap: isSelectionMode
                ? () => _togglePlanSelection(plan['id'])
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealDetailScreen(planId: plan['id']),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isSelectionMode) ...[
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) => _togglePlanSelection(plan['id']),
                          activeColor: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          'Meal Plan ${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: isSelected ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white54,
                          ),
                        ),
                      ),
                      if (!isSelectionMode)
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${mealPlan['daily_calories']} calories • ${mealPlan['meals'].length} meals',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preference: ${preferences['food_preference']}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Show first meal as preview
                  if (mealPlan['meals'].isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            mealPlan['meals'][0]['type'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Items: ${mealPlan['meals'][0]['items'].join(', ')}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMacroItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
