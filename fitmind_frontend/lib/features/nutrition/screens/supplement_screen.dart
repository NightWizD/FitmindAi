import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

class SupplementScreen extends StatefulWidget {
  const SupplementScreen({super.key});

  @override
  _SupplementScreenState createState() => _SupplementScreenState();
}

class _SupplementScreenState extends State<SupplementScreen> {
  bool _isLoading = true;
  bool _isAnalyzing = false;
  List<dynamic> _supplements = [];
  List<dynamic> _reportSupplements = [];

  @override
  void initState() {
    super.initState();
    _fetchSupplements();
  }

  Future<void> _fetchSupplements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/diet/supplements'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _supplements = data['supplements'] ?? [];
          _reportSupplements = data['report_supplements'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndAnalyzeReport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() => _isAnalyzing = true);
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/diet/analyze-report'),
        );
        request.headers['Authorization'] = 'Bearer $token';
        
        PlatformFile file = result.files.first;
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path!,
          contentType: MediaType('application', file.extension == 'pdf' ? 'pdf' : 'octet-stream'),
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          setState(() {
            _isAnalyzing = false;
          });
          // Refresh list to see the new report_supplements
          _fetchSupplements();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report analyzed successfully!')));
        } else {
          setState(() => _isAnalyzing = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to analyze report')));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isAnalyzing = false);
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
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          if (_reportSupplements.isNotEmpty) ...[
                            _buildFieldLabel('CLINICAL CORRECTIONS'),
                            ..._reportSupplements.map((supp) => _buildSupplementCard(supp, isClinical: true)).toList(),
                            const SizedBox(height: 32),
                          ],
                          _buildSectionTitle('Protocol Recommendation'),
                          const SizedBox(height: 20),
                          ..._supplements.map((supp) => _buildSupplementCard(supp)).toList(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAnalyzing ? null : _pickAndAnalyzeReport,
        backgroundColor: AppColors.primary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: _isAnalyzing 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2))
            : const Icon(Icons.document_scanner_rounded, color: AppColors.textPrimary),
        label: Text(
          _isAnalyzing ? 'SYNCHRONIZING...' : 'SCAN BIOMETRIC REPORT',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          ),
          const Text('Supplement protocol', style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  );

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        Text(
          'Optimized for your BMI and health markers',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSupplementCard(Map<String, dynamic> supp, {bool isClinical = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isClinical ? AppColors.primary : AppColors.primaryWithOpacity(0.1), width: isClinical ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isClinical ? AppColors.primary : AppColors.primaryWithOpacity(0.1), 
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Icon(
                  isClinical ? Icons.analytics_rounded : Icons.medication_rounded, 
                  color: isClinical ? Colors.white : AppColors.primary, 
                  size: 24
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      supp['name'] ?? 'Unknown',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold),
                      softWrap: true,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isClinical ? 'Clinical Correction' : (supp['timing'] ?? 'Anytime'),
                      style: TextStyle(color: isClinical ? AppColors.primary : AppColors.textSecondary, fontSize: 13, fontWeight: isClinical ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWithOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryWithOpacity(0.3)),
                  ),
                  child: Text(
                    supp['dosage'] ?? 'N/A',
                    style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          if (supp['description'] != null || (supp['dosage'] != null && supp['dosage']!.length > 15) || isClinical) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isClinical ? (supp['benefit'] ?? "Based on latest clinical telemetry.") : (supp['description'] ?? (supp['dosage']!.length > 15 ? "Dosage Protocol: ${supp['dosage']}" : "")),
                style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7), fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
