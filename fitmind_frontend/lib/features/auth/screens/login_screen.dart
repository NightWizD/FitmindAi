import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        final userResponse = await http.get(
          Uri.parse('${ApiConstants.baseUrl}/auth/me'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (userResponse.statusCode == 200) {
          final userData = json.decode(userResponse.body);
          await prefs.setString('username', userData['username']);
          await prefs.setString('email', userData['email']);

          final metricsResponse = await http.get(
            Uri.parse('${ApiConstants.baseUrl}/user/metrics'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (metricsResponse.statusCode == 200) {
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
          } else {
            Navigator.pushNamed(context, '/basic-metrics');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Invalid credentials')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connection Error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtle glow effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: AppColors.primaryWithOpacity(0.05), 
                boxShadow: [
                  BoxShadow(color: AppColors.primaryWithOpacity(0.05), blurRadius: 100, spreadRadius: 50)
                ]
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 80),
                    _buildLogoHeader(),
                    const SizedBox(height: 60),
                    _buildFieldLabel('EMAIL ADDRESS'),
                    _buildTextField(_emailController, Icons.alternate_email_rounded, false),
                    const SizedBox(height: 24),
                    _buildFieldLabel('SECURE PASSWORD'),
                    _buildTextField(_passwordController, Icons.lock_outline_rounded, true),
                    const SizedBox(height: 48),
                    _buildLoginButton(),
                    const SizedBox(height: 24),
                    _buildSignUpLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 32),
        const Text(
          'Welcome to\nFitMind AI',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Sign in to access your elite health dashboard',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        validator: (v) => v!.isEmpty ? 'Field required' : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8, shadowColor: AppColors.primaryWithOpacity(0.4),
        ),
        child: _isLoading 
            ? const CircularProgressIndicator(color: AppColors.textPrimary)
            : const Text('Sign In', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/register'),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(text: "Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
              const TextSpan(text: "Sign Up", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
