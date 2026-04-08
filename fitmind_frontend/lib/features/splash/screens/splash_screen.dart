import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.elasticOut)));
    
    _controller.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      if (token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Energy Ring
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryWithOpacity(0.03),
                        ),
                      ),
                      // Middle Glow
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryWithOpacity(0.05),
                        ),
                      ),
                      // Core Icon Container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.primaryWithOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary,
                            size: 56,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'FitMind AI',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PRECISION PERFORMANCE AI',
                    style: TextStyle(color: AppColors.primaryWithOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
