import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class FitnessGoalsScreen extends StatefulWidget {
  const FitnessGoalsScreen({super.key});

  @override
  _FitnessGoalsScreenState createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen> {
  List<String> _selectedGoals = [];
  bool _isLoading = true;
  final Map<String, IconData> goalOptions = {
    'Fat Loss': Icons.local_fire_department_rounded,
    'Muscle Gain': Icons.fitness_center_rounded,
    'Maintenance': Icons.balance_rounded,
    'Endurance': Icons.bolt_rounded,
  };
  
  final TextEditingController _weightGoalController = TextEditingController();
  final TextEditingController _caloriesGoalController = TextEditingController();
  String _experienceLevel = 'Beginner';

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  Future<void> _loadCurrentGoals() async {
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
          if (data['goals'] != null) _selectedGoals = List<String>.from(data['goals']);
          else if (data['goal'] != null) _selectedGoals = [data['goal']];
          
          if (data['weight_goal'] != null) _weightGoalController.text = data['weight_goal'].toString();
          if (data['calories_goal'] != null) _caloriesGoalController.text = data['calories_goal'].toString();
          if (data['gym_level'] != null) _experienceLevel = data['gym_level'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) _selectedGoals.remove(goal);
      else _selectedGoals.add(goal);
    });
  }

  Future<void> _updateGoals() async {
    if (_selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one goal')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/goals'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'goals': _selectedGoals,
          'weight_goal': double.tryParse(_weightGoalController.text),
          'calories_goal': int.tryParse(_caloriesGoalController.text),
          'gym_level': _experienceLevel,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                          _buildFieldLabel('SELECT PRIMARY OBJECTIVES'),
                          ...goalOptions.keys.map((goal) => _buildGoalCard(goal, goalOptions[goal]!)),
                          const SizedBox(height: 32),
                          _buildFieldLabel('ATHLETE EXPERIENCE TIER'),
                          _buildExperienceSelector(),
                          const SizedBox(height: 32),
                          _buildFieldLabel('PRECISION METRICS'),
                          _buildInputField('Target Weight (kg)', _weightGoalController, 'e.g. 70.0', Icons.monitor_weight_outlined),
                          const SizedBox(height: 20),
                          _buildInputField('Daily Calorie Ceiling', _caloriesGoalController, 'e.g. 2400', Icons.local_fire_department_rounded),
                          const SizedBox(height: 48),
                          _buildUpdateButton(),
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
          IconButton(onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, '/profile'), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20)),
          const Text('Objective Calibration', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildGoalCard(String goal, IconData icon) {
    bool isSelected = _selectedGoals.contains(goal);
    return GestureDetector(
      onTap: () => _selectGoal(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWithOpacity(0.1) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textDim, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(goal, style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold))),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textPrimary.withOpacity(0.05))),
      child: TextFormField(
        controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          labelText: label, labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          hintText: hint, hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildExperienceSelector() {
    return Row(
      children: ['Beginner', 'Intermediate', 'Advanced'].map((level) {
        bool isSelected = _experienceLevel == level;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _experienceLevel = level),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryWithOpacity(0.12) : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
              ),
              child: Text(
                level,
                textAlign: TextAlign.center,
                style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateGoals,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8, shadowColor: AppColors.primaryWithOpacity(0.4),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text('Sync Objectives', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
