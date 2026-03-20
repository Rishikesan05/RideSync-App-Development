import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

// Step 2: Official Certifications & Vehicle details for Bus Operator Registration
class Step2 extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2({super.key, required this.onNext, required this.onBack});

  @override
  State<Step2> createState() => _Step2State();
}

class _Step2State extends State<Step2> {
  final TextEditingController hvController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = Provider.of<RegistrationProvider>(context, listen: false);
    hvController.text = p.heavyVehicleLicense;
    yearController.text = p.yearOfIssuance;
  }

  Future<void> _pickImage(String field) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      final p = Provider.of<RegistrationProvider>(context, listen: false);
      setState(() {
        if (field == 'medicalCertificate') p.medicalCertificate = image.path;
        if (field == 'trainingCertificate') p.trainingCertificate = image.path;
      });
    }
  }

  void _handleNext() {
    if (hvController.text.isEmpty || yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all text fields')));
      return;
    }
    Provider.of<RegistrationProvider>(context, listen: false).updateStep2(
      hv: hvController.text.trim(),
      year: yearController.text.trim(),
    );
    widget.onNext();
  }

  @override
  void dispose() {
    hvController.dispose();
    yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = Provider.of<RegistrationProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Professional Credentials',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 24),
          _buildInfoBox(context, 'Ensure all uploaded certificates are valid and clearly visible for verification.'),
          const SizedBox(height: 24),
          _buildTextField(context, 'Heavy Vehicle License Number', Icons.badge_outlined, hvController),
          const SizedBox(height: 16),
          _buildTextField(context, 'Year of Issuance', Icons.calendar_today_outlined, yearController, isNumber: true),
          const SizedBox(height: 32),
          Text(
            'Certificates',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          _buildUploadButton(context, 'Medical Fitness Certificate', p.medicalCertificate, () => _pickImage('medicalCertificate')),
          _buildUploadButton(context, 'Official Training Certificate', p.trainingCertificate, () => _pickImage('trainingCertificate')),
          const SizedBox(height: 48),
          CustomButton(label: 'Enter Final Step', onPressed: _handleNext),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onBack,
            child: Center(
              child: Text(
                'Back to Personal Info',
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.textLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, IconData icon, TextEditingController c, {bool isNumber = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryOrange)),
      ),
    );
  }

  Widget _buildUploadButton(BuildContext context, String label, String value, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(hasFile ? Icons.check_circle : Icons.cloud_upload_outlined, color: hasFile ? Colors.green : (isDark ? Colors.white : Colors.black87)),
        label: Text(hasFile ? 'Uploaded: $label' : label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: hasFile ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade300)),
          foregroundColor: hasFile ? Colors.green : (isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.primaryNavy.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : AppColors.primaryNavy.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: isDark ? Colors.white70 : AppColors.primaryNavy),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.primaryNavy))),
        ],
      ),
    );
  }
}





