import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error fetching personal info: $e');
    }
  }

  String _calculateBMI() {
    if (_userData['weight'] != null && _userData['height'] != null) {
      double weight = _userData['weight'].toDouble();
      double height = _userData['height'].toDouble() / 100;
      if (height > 0) {
        return (weight / (height * height)).toStringAsFixed(1);
      }
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Personal Information',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Basic Metrics'),
                  _buildInfoCard([
                    _buildInfoRow('Age', '${_userData['age'] ?? 'N/A'} years'),
                    _buildInfoRow('Gender', _userData['gender'] ?? 'N/A'),
                    _buildInfoRow('Height', '${_userData['height'] ?? 'N/A'} cm'),
                    _buildInfoRow('Weight', '${_userData['weight'] ?? 'N/A'} kg'),
                    _buildInfoRow('BMI', _userData['bmi'] != null ? _userData['bmi'].toStringAsFixed(1) : _calculateBMI()),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Fitness Profile'),
                  _buildInfoCard([
                    _buildInfoRow('Current Goal', _userData['goal'] ?? 'N/A'),
                    _buildInfoRow('Activity Level', _userData['activity_level'] ?? 'N/A'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Target Goals'),
                  _buildInfoCard([
                    _buildInfoRow('Weight Goal', '${_userData['weight_goal'] ?? 'N/A'} kg'),
                    _buildInfoRow('Calories Goal', '${_userData['calories_goal'] ?? 'N/A'} kcal'),
                  ]),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'Account linked to ${_userData['name'] ?? 'User'}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
