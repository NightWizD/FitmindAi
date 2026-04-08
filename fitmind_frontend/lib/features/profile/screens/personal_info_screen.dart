import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  _PersonalInfoScreenState createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/metrics'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SafeArea(
              child: Column(
                children: [
                   _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildFieldLabel('BIOMETRIC TELEMETRY'),
                          _buildInfoModule([
                            _buildInfoRow('Age', '${_userData['age'] ?? '--'} yrs'),
                            _buildInfoRow('Gender', (_userData['gender'] ?? '--').toString().toUpperCase()),
                            _buildInfoRow('Height', '${_userData['height'] ?? '--'} cm'),
                            _buildInfoRow('Weight', '${_userData['weight'] ?? '--'} kg'),
                            _buildInfoRow('BMI Index', _userData['bmi']?.toStringAsFixed(1) ?? '--'),
                          ]),
                          const SizedBox(height: 32),
                          _buildFieldLabel('PERFORMANCE PROFILE'),
                          _buildInfoModule([
                            _buildInfoRow('Activity Tier', _userData['activity_level'] ?? '--'),
                            _buildInfoRow('Target Goal', '${_userData['weight_goal'] ?? '--'} kg'),
                            _buildInfoRow('Ceiling', '${_userData['calories_goal'] ?? '--'} kcal'),
                          ]),
                          const SizedBox(height: 48),
                          Center(
                            child: Column(
                              children: [
                                Text('ID: ${_userData['id'] ?? '---'}', style: TextStyle(color: AppColors.textPrimary.withOpacity(0.05), fontSize: 10, letterSpacing: 2)),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : Navigator.pushReplacementNamed(context, '/profile'), icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20)),
          const Text('Identity Summary', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 12, left: 4), child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)));

  Widget _buildInfoModule(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.05)),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textPrimary.withOpacity(0.03)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
