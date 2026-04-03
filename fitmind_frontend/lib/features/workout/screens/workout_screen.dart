import 'package:flutter/material.dart';
import '../../../widgets/bottom_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'workout_detail_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _currentIndex = 1; // Default to workout tab
  List<Map<String, dynamic>> workoutPlans = [];
  bool isLoading = true;
  bool gymAccess = true;
  int daysPerWeek = 3;
  double hoursPerSession = 1.0;
  String gymLevel = 'Beginner';
  bool isSelectionMode = false;
  Set<String> selectedPlans = {};

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      setState(() => isLoading = false);
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/v1/workout/list'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final plans = json.decode(response.body) as List;
      setState(() {
        workoutPlans = plans.map((plan) => plan as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load workout plans')),
      );
    }
  }

  void _showGenerateModal() {
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
                        Icons.fitness_center,
                        color: Color(0xFF3B82F6),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Generate Workout Plan',
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

                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customize your workout preferences',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gym Access
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: SwitchListTile(
                            title: const Text(
                              'Gym Access',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              gymAccess ? 'Access to gym equipment' : 'Bodyweight exercises only',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              ),
                            ),
                            value: gymAccess,
                            onChanged: (value) => setState(() => gymAccess = value),
                            activeColor: const Color(0xFF3B82F6),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Days per Week
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
                                'Days per Week',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButton<int>(
                                value: daysPerWeek,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1F2937),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                items: List.generate(7, (i) => DropdownMenuItem(
                                  value: i + 1,
                                  child: Text('${i + 1} days'),
                                )),
                                onChanged: (value) => setState(() => daysPerWeek = value!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Hours per Session
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
                                'Hours per Session',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Duration (hours)',
                                  labelStyle: TextStyle(color: Colors.white70, fontSize: 14),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white30),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF3B82F6)),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: hoursPerSession.toString()),
                                onChanged: (value) => setState(() => hoursPerSession = double.tryParse(value) ?? 1.0),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Gym Level
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
                                'Experience Level',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButton<String>(
                                value: gymLevel,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1F2937),
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                items: ['Beginner', 'Intermediate', 'Advanced'].map((level) => DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                )).toList(),
                                onChanged: (value) => setState(() => gymLevel = value!),
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
                        onPressed: _generatePlan,
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

  void _generatePlan() async {
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
              Text('Generating your workout plan...'),
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
        Uri.parse('http://10.0.2.2:8000/api/v1/workout/generate'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'gym_access': gymAccess,
          'days_per_week': daysPerWeek,
          'hours_per_session': hoursPerSession,
          'gym_level': gymLevel,
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout plan generated!')),
        );
        _loadWorkoutPlans(); // Refresh the list to show new plan
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

  void _onNavTap(BuildContext context, int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
        break;
      case 1:
        // Already on workout
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(context, '/nutrition', (route) => false);
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
              Text('Deleting selected workout plans...'),
            ],
          ),
        );
      },
    );

    try {
      for (String planId in selectedPlans) {
        final response = await http.delete(
          Uri.parse('http://10.0.2.2:8000/api/v1/workout/$planId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (response.statusCode != 200) {
          throw Exception('Failed to delete plan $planId');
        }
      }

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedPlans.length} workout plan(s) deleted')),
      );

      setState(() {
        isSelectionMode = false;
        selectedPlans.clear();
      });

      _loadWorkoutPlans(); // Refresh the list
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting plans: $e')),
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
                'Select Workouts to Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            : const Text(
                'My Workout Plans',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                          Text('Delete Workouts'),
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
                : workoutPlans.isEmpty
                    ? _buildEmptyView()
                    : _buildPlansListView(),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: _showGenerateModal,
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
            Icons.fitness_center,
            color: Colors.white70,
            size: 80,
          ),
          const SizedBox(height: 16),
          const Text(
            'No workout plans yet.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first workout plan.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workoutPlans.length,
      itemBuilder: (context, index) {
        final plan = workoutPlans[index];
        final isSelected = selectedPlans.contains(plan['id']);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: isSelected ? const Color(0xFF1F2937).withOpacity(0.8) : const Color(0xFF1F2937),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: isSelected ? const BorderSide(color: Color(0xFF3B82F6), width: 2) : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) => _togglePlanSelection(plan['id']),
                    activeColor: const Color(0xFF3B82F6),
                  )
                : null,
            title: Text(
              plan['name'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                decoration: isSelected ? TextDecoration.lineThrough : null,
                decorationColor: Colors.white54,
              ),
            ),
            trailing: isSelectionMode
                ? null
                : const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                  ),
            onTap: isSelectionMode
                ? () => _togglePlanSelection(plan['id'])
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        planId: plan['id'],
                        planName: plan['name'],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
