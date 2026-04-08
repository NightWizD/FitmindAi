import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class BasicMetricsScreen extends StatefulWidget {
  const BasicMetricsScreen({super.key});

  @override
  _BasicMetricsScreenState createState() => _BasicMetricsScreenState();
}

class _BasicMetricsScreenState extends State<BasicMetricsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = '';
  bool _isLoading = false;

  void _next() async {
    if (!_formKey.currentState!.validate() || _gender.isEmpty) {
      if (_gender.isEmpty) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select gender')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final double h = double.parse(_heightController.text);
      final double w = double.parse(_weightController.text);
      final double bmi = w / ((h / 100) * (h / 100));

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/user/metrics'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: json.encode({
          'age': int.parse(_ageController.text),
          'gender': _gender,
          'height': h, 'weight': w, 'bmi': bmi,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pushNamed(context, '/goal-selection');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save metrics')));
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgress(0),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      _buildHeader('Biometric Calibration', 'Enter your foundational markers'),
                      const SizedBox(height: 32),
                      _buildFieldLabel('SELECT GENDER'),
                      _buildGenderSelection(),
                      const SizedBox(height: 32),
                      _buildFieldLabel('CURRENT AGE'),
                      _buildTextField(_ageController, 'Years', Icons.cake_outlined),
                      const SizedBox(height: 32),
                      _buildFieldLabel('STATURE & MASS'),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_heightController, 'Height (cm)', Icons.height_rounded)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_weightController, 'Weight (kg)', Icons.monitor_weight_outlined)),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
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
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: index <= step ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
              boxShadow: index <= step ? [BoxShadow(color: AppColors.primaryWithOpacity(0.3), blurRadius: 8)] : null,
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
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildGenderSelection() {
    return Row(
      children: [
        _buildGenderCard('male', Icons.male_rounded, 'Male'),
        const SizedBox(width: 16),
        _buildGenderCard('female', Icons.female_rounded, 'Female'),
      ],
    );
  }

  Widget _buildGenderCard(String value, IconData icon, String label) {
    bool isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryWithOpacity(0.1) : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.textPrimary.withOpacity(0.05), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textDim, size: 32),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? AppColors.textPrimary : AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.textPrimary.withOpacity(0.05))),
      child: TextFormField(
        controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          hintText: hint, hintStyle: TextStyle(color: AppColors.textDim, fontSize: 14),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        validator: (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity, height: 64,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8, shadowColor: AppColors.primaryWithOpacity(0.4),
          ),
          child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text('Continue Alignment', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
