import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/nutrition/screens/nutrition_screen.dart';
import 'features/profile/screens/food_preferences_screen.dart';
import 'features/profile/screens/personal_info_screen.dart';
import 'features/profile/screens/fitness_goals_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/security_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/onboarding/screens/basic_metrics_screen.dart';
import 'features/onboarding/screens/goal_selection_screen.dart';
import 'features/onboarding/screens/activity_level_selection_screen.dart';
import 'features/onboarding/screens/food_preference_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/workout/screens/workout_screen.dart';

import 'core/constants/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitMind AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.cardBackground,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/basic-metrics': (context) => const BasicMetricsScreen(),
        '/goal-selection': (context) => const GoalSelectionScreen(),
        '/activity-level': (context) => const ActivityLevelSelectionScreen(),
        '/food-preference': (context) => const FoodPreferenceScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/workout': (context) => const WorkoutScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/fitness-goals': (context) => const FitnessGoalsScreen(),
        '/personal-info': (context) => const PersonalInfoScreen(),
        '/food-preferences': (context) => const FoodPreferencesScreen(),
        '/security': (context) => const SecurityScreen(),
      },
    );
  }
}
