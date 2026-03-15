import 'package:flutter/material.dart';
import 'step1.dart';
import 'step2.dart';
import 'step3.dart';

// 3-Step Driver Registration wizard
class DriverRegistrationFlow extends StatefulWidget {
  const DriverRegistrationFlow({super.key});

  @override
  State<DriverRegistrationFlow> createState() => _DriverRegistrationFlowState();
}

class _DriverRegistrationFlowState extends State<DriverRegistrationFlow> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      ),
      body: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_currentStep) {
      case 0:
        return Step1(onNext: () => setState(() => _currentStep = 1));
      case 1:
        return Step2(
          onNext: () => setState(() => _currentStep = 2),
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return Step3(onBack: () => setState(() => _currentStep = 1));
      default:
        return const Center(child: Text('Complete'));
    }
  }
}
