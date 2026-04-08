import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Network error')));
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
          Positioned(
            top: -100, left: -100,
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
                    const SizedBox(height: 60),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildFieldLabel('FULL NAME'),
                    _buildTextField(_nameController, Icons.person_outline_rounded, false),
                    const SizedBox(height: 20),
                    _buildFieldLabel('EMAIL ADDRESS'),
                    _buildTextField(_emailController, Icons.alternate_email_rounded, false),
                    const SizedBox(height: 20),
                    _buildFieldLabel('SECURE PASSWORD'),
                    _buildTextField(_passwordController, Icons.lock_outline_rounded, true),
                    const SizedBox(height: 20),
                    _buildFieldLabel('CONFIRM PASSWORD'),
                    _buildTextField(_confirmPasswordController, Icons.shield_outlined, true),
                    const SizedBox(height: 48),
                    _buildRegisterButton(),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryWithOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 30),
        ),
        const SizedBox(height: 24),
        const Text('Create Your\nElite Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1, height: 1.1)),
        const SizedBox(height: 12),
        Text('Join the clinical-grade fitness revolution', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildTextField(TextEditingController controller, IconData icon, bool isPassword) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textPrimary.withOpacity(0.05))),
      child: TextFormField(
        controller: controller, obscureText: isPassword, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(prefixIcon: Icon(icon, color: AppColors.primary, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18)),
        validator: (v) => v!.isEmpty ? 'Field required' : null,
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity, height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8, shadowColor: AppColors.primaryWithOpacity(0.4),
        ),
        child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text('Create Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14),
            children: [
              TextSpan(text: "Already have an account? ", style: TextStyle(color: AppColors.textSecondary)),
              const TextSpan(text: "Sign In", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
