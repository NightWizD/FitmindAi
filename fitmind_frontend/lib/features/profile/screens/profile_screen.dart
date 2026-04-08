import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 3;
  String _username = 'User';
  String _email = 'user@example.com';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'User';
        _email = prefs.getString('email') ?? 'user@example.com';
      });
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
        Navigator.pushNamedAndRemoveUntil(context, '/nutrition', (route) => false);
        break;
      case 3:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 80),
                  _buildProfileHeader(),
                  const SizedBox(height: 48),
                  const Text('Settings', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 20),
                  _buildSettingCard('Personal Information', Icons.person_outline_rounded, AppColors.primary, () => Navigator.pushNamed(context, '/personal-info')),
                  const SizedBox(height: 16),
                  _buildSettingCard('Fitness Goals', Icons.flag_rounded, AppColors.success, () => Navigator.pushNamed(context, '/fitness-goals')),
                  const SizedBox(height: 16),
                  _buildSettingCard('Food Preferences', Icons.restaurant_rounded, AppColors.warning, () => Navigator.pushNamed(context, '/food-preferences')),
                  const SizedBox(height: 16),
                  _buildSettingCard('Security & Privacy', Icons.security_rounded, const Color(0xFF6366F1), () => Navigator.pushNamed(context, '/security')),
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          BottomNavBar(currentIndex: _currentIndex, onTap: _onNavTap),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryWithOpacity(0.3), width: 2),
            ),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondaryCard,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primaryWithOpacity(0.2), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.textPrimary, size: 50),
            ),
          ),
          const SizedBox(height: 20),
          Text(_username, style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSettingCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.textPrimary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => _showLogoutConfirmation(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.error.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text(
            'SIGN OUT PROTOCOL',
            style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.error.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 32),
              ),
              const SizedBox(height: 24),
              const Text('Terminate Session?', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'Are you sure you want to sign out? Your local biometric cache will be cleared.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
