import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signature/signature.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/modules/auth/providers/auth_provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

// Step 3: Review & Final Authorization with Digital Signature
class Step3 extends StatefulWidget {
  final VoidCallback onBack;

  const Step3({super.key, required this.onBack});

  @override
  State<Step3> createState() => _Step3State();
}

class _Step3State extends State<Step3> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final reg = Provider.of<RegistrationProvider>(context, listen: false);

    if (reg.email.isEmpty || reg.password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Missing credentials from Step 1.')));
        return;
    }
    if (_controller.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a signature.')));
        return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. Create User
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: reg.email, password: reg.password
      );
      String uid = cred.user!.uid;

      // 2. Upload Files to Firebase Storage
      final storage = FirebaseStorage.instance.ref().child('operators/$uid');
      
      Future<String> uploadDoc(String path, String name) async {
        if (path.isEmpty) return '';
        TaskSnapshot task = await storage.child('$name.jpg').putFile(File(path));
        return await task.ref.getDownloadURL();
      }

      String nicFrontUrl = await uploadDoc(reg.nicFront, 'nic_front');
      String nicBackUrl = await uploadDoc(reg.nicBack, 'nic_back');
      String licenseFrontUrl = await uploadDoc(reg.licenseFront, 'license_front');
      String licenseBackUrl = await uploadDoc(reg.licenseBack, 'license_back');
      String medicalUrl = await uploadDoc(reg.medicalCertificate, 'medical');
      String trainingUrl = await uploadDoc(reg.trainingCertificate, 'training');

      // Handle signature upload
      final Uint8List? sigBytes = await _controller.toPngBytes();
      String signatureUrl = '';
      if (sigBytes != null) {
          TaskSnapshot sigTask = await storage.child('signature.png').putData(sigBytes);
          signatureUrl = await sigTask.ref.getDownloadURL();
      }

      // 3. Save to Firestore users
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': 'operator',
          'status': 'pending_review',
          'createdAt': FieldValue.serverTimestamp(),
          'displayName': reg.name,
          'email': reg.email,
          'phone': reg.phone,
      });

      // 4. Save to Firestore operators
      await FirebaseFirestore.instance.collection('operators').doc(uid).set({
          'name': reg.name,
          'email': reg.email,
          'phone': reg.phone,
          'heavyVehicleLicense': reg.heavyVehicleLicense,
          'yearOfIssuance': reg.yearOfIssuance,
          'status': 'pending_review',
          'documentUrls': {
              'nicFront': nicFrontUrl,
              'nicBack': nicBackUrl,
              'licenseFront': licenseFrontUrl,
              'licenseBack': licenseBackUrl,
              'medicalCertificate': medicalUrl,
              'trainingCertificate': trainingUrl,
              'signature': signatureUrl,
          }
      });

      // Update name in Firebase Auth metadata
      await cred.user!.updateDisplayName(reg.name);

      // Force refresh of auth state
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

      _showSuccessDialog();

    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppStyles.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Review',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Check your details before submission. By signing below, you authorize RideSync to verify your professional documents.',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Digital Signature',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Signature(
                controller: _controller,
                height: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _controller.clear(),
                child: Text(
                  'Clear Signature',
                  style: TextStyle(
                    color: isDark ? AppColors.primaryOrange : null,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          if (_isSubmitting)
             const Center(child: CircularProgressIndicator())
          else
            CustomButton(
              label: 'Submit Registration',
              onPressed: _handleSubmit,
            ),
          const SizedBox(height: 16),
          if (!_isSubmitting)
            TextButton(
              onPressed: widget.onBack,
              child: Center(
                child: Text(
                  'Review Previous Steps',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.textLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Registration Submitted'),
        content: const Text(
          'Your form is pending verification. Our team will review your professional documents shortly.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushNamedAndRemoveUntil(context, '/operator-main', (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}





