import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../widgets/bottom_nav_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _username = 'User';
  double _bmi = 0.0;
  int _steps = 0;
  int _stepGoal = 6000;
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _activeWorkout;
  int _currentBpm = 72;
  String _pedestrianStatus = 'stationary';

  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initPedometer();
    _startBpmSimulation();
  }

  void _startBpmSimulation() {
    // Change BPM slightly every 2 seconds for "Real" feel
    Stream.periodic(const Duration(seconds: 2)).listen((_) {
      if (!mounted) return;
      setState(() {
        if (_pedestrianStatus == 'walking') {
          // Dynamic range for walking: 105 - 125
          _currentBpm = 105 + (DateTime.now().millisecond % 20);
        } else {
          // Dynamic range for resting: 65 - 75
          _currentBpm = 65 + (DateTime.now().millisecond % 10);
        }
      });
    });
  }

  Future<void> _initPedometer() async {
    try {
      if (await Permission.activityRecognition.request().isGranted) {
        _stepCountStream = Pedometer.stepCountStream;
        _stepCountStream.listen((event) {
          if (mounted) setState(() => _steps = event.steps);
        });

        _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
        _pedestrianStatusStream.listen((event) {
          if (mounted) {
            setState(() {
              _pedestrianStatus = event.status;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Pedometer failed: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _username = prefs.getString('username') ?? 'User';
    final token = prefs.getString('token');

    if (token != null) {
      try {
        // Parallel fetch for speed
        final futures = await Future.wait([
          http.get(Uri.parse('${ApiConstants.baseUrl}/user/metrics'), headers: {'Authorization': 'Bearer $token'}),
          http.get(Uri.parse('${ApiConstants.baseUrl}/workout/active'), headers: {'Authorization': 'Bearer $token'}),
        ]).timeout(const Duration(seconds: 10));

        final metricsRes = futures[0];
        final workoutRes = futures[1];

        if (metricsRes.statusCode == 200) {
          final data = json.decode(metricsRes.body);
          _bmi = (data['bmi'] as num?)?.toDouble() ?? 0.0;
        }

        if (workoutRes.statusCode == 200) {
          final workoutData = json.decode(workoutRes.body);
          if (workoutData != null) {
            _activeWorkout = workoutData;
          }
        }
      } catch (e) {
        debugPrint('Error fetching dashboard data: $e');
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _onNavTap(BuildContext context, int index) {
    if (index == _currentIndex) return;
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/workout',
          (route) => false,
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/nutrition',
          (route) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile',
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = _stepGoal > 0 ? _steps / _stepGoal : 0.0;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
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
                        _buildCircularTracker(progress),
                        const SizedBox(height: 40),
                        _buildMetricsGrid(),
                        const SizedBox(height: 24),
                        _buildActivityCard(),
                        const SizedBox(height: 24),
                        _buildBMICard(),
                        const SizedBox(height: 24),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hello, $_username',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondaryCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularTracker(double progress) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 20,
              backgroundColor: AppColors.secondaryCard,
              color: AppColors.primary,
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$_steps',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'STEPS',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    int kcal = (_steps * 0.045).round();
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'BPM',
            _currentBpm.toString(),
            Icons.favorite_rounded,
            AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'KCAL',
            kcal.toString(),
            Icons.local_fire_department_rounded,
            AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 24),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BMI Status',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Healthy Range',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
          Text(
            _bmi.toStringAsFixed(1),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    // Determine today's exercises if available
    List<dynamic> todayExercises = [];
    String todayLabel = 'Today';
    
    if (_activeWorkout != null && _activeWorkout!['plan']['days'] != null) {
      final now = DateTime.now();
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final currentDayName = weekdays[now.weekday - 1];
      
      final days = _activeWorkout!['plan']['days'] as List;
      // Try to match by day name or just fallback to Day 1, Day 2 etc mapping
      var matchedDay = days.firstWhere(
        (d) => d['day'].toString().toLowerCase() == currentDayName.toLowerCase(),
        orElse: () => null,
      );
      
      // Fallback: If no day name match, map weekday index to list index (mod length)
      matchedDay ??= days[now.weekday % days.length];
      
      if (matchedDay != null) {
        todayExercises = matchedDay['exercises'] as List? ?? [];
        todayLabel = matchedDay['day'].toString();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.secondaryCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primaryWithOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Workout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (_activeWorkout != null) ...[
            Text(
              "Current Target: $todayLabel",
              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ...todayExercises.take(3).map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.primary, size: 6),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ex['name'],
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${ex['sets']}×${ex['reps']}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )).toList(),
            if (todayExercises.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text('+ ${todayExercises.length - 3} more exercises', style: TextStyle(color: AppColors.textDim, fontSize: 11, fontStyle: FontStyle.italic)),
              ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showTodayWorkout(todayExercises, todayLabel),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Text("TODAY'S WORKOUT", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Icon(Icons.fitness_center_outlined, color: AppColors.textDim, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      'No Active Protocol',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/workout'),
                      child: const Text('ACTIVATE NOW', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTodayWorkout(List<dynamic> exercises, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.primaryWithOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 4),
                        const Text('Daily Protocol', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.close_rounded, color: AppColors.textDim, size: 20),
                    style: IconButton.styleFrom(backgroundColor: AppColors.secondaryCard),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: exercises.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryWithOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex['name'], style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Performance Target', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text('${ex['sets']}×${ex['reps']}', style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
