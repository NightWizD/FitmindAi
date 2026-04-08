import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  _GoalSelectionScreenState createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  final List<String> _selectedGoals = [];
  bool _isLoading = false;

  final Map<String, IconData> goalOptions = {
    'Fat Loss': Icons.local_fire_department_rounded,
    'Muscle Gain': Icons.fitness_center_rounded,
    'Maintenance': Icons.balance_rounded,
    'Endurance': Icons.bolt_rounded,
  };

  void _selectGoal(String goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  void _continue() async {
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
        body: json.encode({'goals': _selectedGoals}),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/activity-level');
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
      backgroundColor: const Color(0xFF0B1326),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader('Strategic Profile', 'Select your primary focus'),
                    const SizedBox(height: 32),
                    ...goalOptions.keys.map((goal) => _buildGoalCard(goal, goalOptions[goal]!)),
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
              color: index <= step ? const Color(0xFF3B82F6) : Colors.white10,
              borderRadius: BorderRadius.circular(2),
              boxShadow: index <= step ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.3), blurRadius: 8)] : null,
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
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
      ],
    );
  }

  Widget _buildGoalCard(String goal, IconData icon) {
    bool isSelected = _selectedGoals.contains(goal);
    return GestureDetector(
      onTap: () => _selectGoal(goal),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : const Color(0xFF131B2E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.white.withOpacity(0.05), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: (isSelected ? const Color(0xFF3B82F6) : Colors.white).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: isSelected ? const Color(0xFF3B82F6) : Colors.white38, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(child: Text(goal, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 18, fontWeight: FontWeight.bold))),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF3B82F6), size: 24),
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
            backgroundColor: const Color(0xFF3B82F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8, shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
          ),
          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Establish Goals', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
