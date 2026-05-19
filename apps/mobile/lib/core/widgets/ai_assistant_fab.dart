import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/ridesync_ui.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

// Floating AI Bot widget for intelligent assistance
class AIAssistantFAB extends StatefulWidget {
  const AIAssistantFAB({super.key});

  @override
  State<AIAssistantFAB> createState() => _AIAssistantFABState();
}

class _AIAssistantFABState extends State<AIAssistantFAB> {
  bool _isExpanded = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final GenerativeModel? _model;
  
  List<ChatMessage> _messages = [
    ChatMessage(text: 'Hi! I am the RideSync AI. How can I help you today?', isUser: false),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }
  
  void _initializeAI() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey != null && apiKey.isNotEmpty) {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );
      } else {
        _model = null;
      }
    } catch (e) {
      _model = null;
    }
  }

  void _sendMessage({String? presetText}) async {
    final text = presetText ?? _controller.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _controller.clear();
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    
    _scrollToBottom();

    if (_model == null) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _messages.add(ChatMessage(text: 'Please add a GEMINI_API_KEY to your .env file to enable real AI.', isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final prompt = 'You are a helpful AI assistant for the RideSync public transit app in Sri Lanka. Answer concisely. User: $text';
      final response = await _model.generateContent([Content.text(prompt)]);
      
      setState(() {
        _messages.add(ChatMessage(text: response.text ?? 'I could not process that request.', isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(text: 'Error connecting to AI: $e', isUser: false));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded)
          Container(
            width: 320,
            height: 460,
            margin: const EdgeInsets.only(bottom: 16),
            child: RideSyncSurfaceCard(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.smart_toy_outlined, color: AppColors.primaryOrange),
                        const SizedBox(width: 8),
                        const Text('RideSync AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() {
                            _messages = [ChatMessage(text: 'Hi! I am the RideSync AI. How can I help you today?', isUser: false)];
                          }),
                          child: const Icon(Icons.refresh, size: 20, color: AppColors.primaryOrange),
                        )
                      ],
                    ),
                  ),
                  // Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_messages.length == 1 ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_messages.length == 1 && index == 1) {
                          // Suggestion chips
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildSuggestionChip('Colombo to Kandy route'),
                                _buildSuggestionChip('How is fare calculated?'),
                                _buildSuggestionChip('Can I book multiple seats?'),
                                _buildSuggestionChip('Help me find a route'),
                              ],
                            ),
                          );
                        }
                        
                        final msg = _messages[index];
                        return Align(
                          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: const BoxConstraints(maxWidth: 240),
                            decoration: BoxDecoration(
                              color: msg.isUser 
                                  ? AppColors.primaryOrange 
                                  : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: msg.isUser ? Radius.zero : null,
                                bottomLeft: !msg.isUser ? Radius.zero : null,
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isUser 
                                    ? Colors.white 
                                    : (isDark ? Colors.white : Colors.black87),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange)),
                    ),
                  // Input Area
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Ask about routes, fares...',
                              hintStyle: const TextStyle(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _sendMessage(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryOrange, AppColors.primaryOrangeDeep],
            ),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: AppColors.glowShadow,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () => setState(() => _isExpanded = !_isExpanded),
            child: Icon(
              _isExpanded ? Icons.close : Icons.auto_awesome,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _sendMessage(presetText: text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ),
    );
  }
}
