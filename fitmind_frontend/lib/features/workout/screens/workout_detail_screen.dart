import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const WorkoutDetailScreen({super.key, required this.planId, required this.planName});

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Map<String, dynamic>? workoutPlan;
  bool isLoading = true;
  bool _isActive = false;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  Future<void> _loadWorkoutPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/workout/${widget.planId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          workoutPlan = data;
          _isActive = data['is_active'] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleActivation() async {
    if (_isToggling) return;
    
    setState(() => _isToggling = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/workout/${widget.planId}/activate'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _isActive = true;
          _isToggling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protocol Activated on Dashboard'), backgroundColor: AppColors.primary)
        );
      } else {
        setState(() => _isToggling = false);
      }
    } catch (e) {
      setState(() => _isToggling = false);
    }
  }

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false); break;
      case 1: Navigator.pushNamedAndRemoveUntil(context, '/workout', (route) => false); break;
      case 2: Navigator.pushNamedAndRemoveUntil(context, '/nutrition', (route) => false); break;
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
          BottomNavBar(currentIndex: 1, onTap: _onNavTap),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppBar(),
          Expanded(
            child: workoutPlan == null
                ? const Center(child: Text('Failed to load telemetry', style: TextStyle(color: AppColors.textDim)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        ...workoutPlan!['plan']['days'].map<Widget>((day) => _buildDayModule(day)).toList(),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context), 
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20)
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.planName, 
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            children: [
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: _isActive,
                  onChanged: (val) => _toggleActivation(),
                  activeColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withOpacity(0.2),
                  inactiveThumbColor: AppColors.textDim,
                  inactiveTrackColor: AppColors.cardBackground,
                ),
              ),
              const Text('ACTIVE', style: TextStyle(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayModule(dynamic day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryWithOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_rounded, color: AppColors.textPrimary, size: 16),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    day['day'].toString().toUpperCase(),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          ...day['exercises'].map<Widget>((exercise) => _buildExerciseLine(exercise)).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExerciseLine(dynamic exercise) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.textPrimary.withOpacity(0.05)))),
      child: Row(
        children: [
          Expanded(
            child: Text(exercise['name'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Text(
            '${exercise['sets']} × ${exercise['reps']}',
            style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
