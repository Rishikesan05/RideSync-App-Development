import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/passenger/presentation/screens/chatbot_screen.dart';

/// Floating Action Button that opens the RideSync AI Assistant full-screen.
/// The actual chat UI and logic live in [ChatbotScreen] + [ChatbotProvider].
class AIAssistantFAB extends StatefulWidget {
  const AIAssistantFAB({super.key});

  @override
  State<AIAssistantFAB> createState() => _AIAssistantFABState();
}

class _AIAssistantFABState extends State<AIAssistantFAB>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openChatbot() {
    Navigator.pushNamed(context, '/chatbot');
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryOrange, AppColors.primaryOrangeDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: AppColors.glowShadow,
              blurRadius: 22,
              spreadRadius: 2,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          heroTag: 'ai_assistant_fab',
          onPressed: _openChatbot,
          tooltip: 'RideSync AI Assistant',
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}
