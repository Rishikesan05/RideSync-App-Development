import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

// Step 1: Personal Information & Identity for Bus Operator Registration
class Step1 extends StatefulWidget {
  final VoidCallback onNext;

  const Step1({super.key, required this.onNext});

  @override
  State<Step1> createState() => _Step1State();
}

class _Step1State extends State<Step1> {
  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController passC = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = Provider.of<RegistrationProvider>(context, listen: false);
    nameC.text = p.name;
    emailC.text = p.email;
    phoneC.text = p.phone;
    passC.text = p.password;
  }

  Future<void> _pickImage(String field) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!mounted) return;
      final p = Provider.of<RegistrationProvider>(context, listen: false);
      setState(() {
        if (field == 'nicFront') p.nicFront = image.path;
        if (field == 'nicBack') p.nicBack = image.path;
        if (field == 'licenseFront') p.licenseFront = image.path;
        if (field == 'licenseBack') p.licenseBack = image.path;
      });
    }
  }

  void _handleNext() {
    if (nameC.text.isEmpty || emailC.text.isEmpty || phoneC.text.isEmpty || passC.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all text fields')));
      return;
    }
    Provider.of<RegistrationProvider>(context, listen: false).updateStep1(
      n: nameC.text.trim(),
      e: emailC.text.trim(),
      p: phoneC.text.trim(),
      pass: passC.text.trim()
    );
    widget.onNext();
  }

  @override
  void dispose() {
    nameC.dispose();
    emailC.dispose();
    phoneC.dispose();
    passC.dispose();
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
            'Personal Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? Colors.white10 : AppColors.primaryNavy.withValues(alpha: 0.1),
                  child: Icon(Icons.person, size: 50, color: isDark ? Colors.white70 : AppColors.primaryNavy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(context, 'Full Name', Icons.person_outline, nameC),
          const SizedBox(height: 16),
          _buildTextField(context, 'Email Address', Icons.email_outlined, emailC),
          const SizedBox(height: 16),
           _buildTextField(context, 'Password', Icons.lock_outline, passC, obscure: true),
          const SizedBox(height: 16),
          _buildTextField(context, 'Phone Number', Icons.phone_outlined, phoneC),
          const SizedBox(height: 32),
          Text(
            'Identity Documents',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 16),
          _buildUploadSlot(context, 'NIC (Front Side)', p.nicFront, () => _pickImage('nicFront')),
          _buildUploadSlot(context, 'NIC (Back Side)', p.nicBack, () => _pickImage('nicBack')),
          _buildUploadSlot(context, 'Driving License (Front)', p.licenseFront, () => _pickImage('licenseFront')),
          _buildUploadSlot(context, 'Driving License (Back)', p.licenseBack, () => _pickImage('licenseBack')),
          const SizedBox(height: 40),
          CustomButton(label: 'Continue to Step 2', onPressed: _handleNext),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label, IconData icon, TextEditingController c, {bool obscure = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: c,
      obscureText: obscure,
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

  Widget _buildUploadSlot(BuildContext context, String label, String value, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasFile = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? Colors.green.withValues(alpha: 0.1) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          border: Border.all(color: hasFile ? Colors.green : (isDark ? Colors.white12 : AppColors.textLight.withValues(alpha: 0.3))),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(hasFile ? 'Uploaded: $label' : label, style: TextStyle(color: hasFile ? Colors.green : (isDark ? Colors.white70 : AppColors.textLight))),
            Icon(hasFile ? Icons.check_circle : Icons.upload_file, color: hasFile ? Colors.green : AppColors.primaryOrange),
          ],
        ),
      ),
    );
  }
}





