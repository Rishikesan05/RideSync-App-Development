import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/chatbot_provider.dart';

/// Full-screen premium AI chatbot screen for RideSync.
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnim;
  bool _isFocused = false;

  // Suggestion chips shown on fresh chat
  static const List<String> _suggestions = [
    '🚌 Colombo to Kandy route',
    '💰 How is fare calculated?',
    '🪑 Can I book multiple seats?',
    '📋 Show my bookings',
    '⏰ What time is next bus?',
    '❓ How do I cancel a booking?',
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnim = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final token = await authProvider.getIdToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use the AI assistant.')),
      );
      return;
    }

    await context.read<ChatbotProvider>().sendMessage(text, authToken: token);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatbot = context.watch<ChatbotProvider>();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF0F2F5),
      appBar: _buildAppBar(isDark, chatbot),
      body: Column(
        children: [
          Expanded(
            child: _buildMessageList(isDark, chatbot),
          ),
          if (chatbot.isLoading) _buildTypingIndicator(isDark),
          _buildInputBar(isDark, chatbot),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, ChatbotProvider chatbot) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFFD84315), const Color(0xFFBF360C)]
                : [AppColors.primaryOrange, AppColors.primaryOrangeDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RideSync Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    chatbot.isLoading ? 'Thinking...' : 'Online',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          tooltip: 'Clear chat',
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear Chat'),
                content: const Text('Start a new conversation?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.read<ChatbotProvider>().clearChat();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.primaryOrange)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(bool isDark, ChatbotProvider chatbot) {
    final showSuggestions = chatbot.messages.length == 1;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: chatbot.messages.length + (showSuggestions ? 1 : 0),
      itemBuilder: (context, index) {
        if (showSuggestions && index == chatbot.messages.length) {
          return _buildSuggestionChips(isDark);
        }
        final msg = chatbot.messages[index];
        return _buildMessageBubble(msg, isDark);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            // Bot avatar
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryOrange, AppColors.primaryOrangeDeep],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Colors.white, size: 16),
            ),
          ],
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: msg.isUser
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryOrange,
                              AppColors.primaryOrangeDeep,
                            ],
                          )
                        : null,
                    color: msg.isUser
                        ? null
                        : (isDark
                            ? AppColors.surfaceMutedDark
                            : Colors.white),
                    borderRadius: BorderRadius.circular(20).copyWith(
                      bottomRight:
                          msg.isUser ? const Radius.circular(4) : null,
                      bottomLeft:
                          !msg.isUser ? const Radius.circular(4) : null,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textDark),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.white38
                        : Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
          ),
          if (msg.isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((s) {
          return GestureDetector(
            onTap: () => _sendMessage(s),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceMutedDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textDark,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 56, bottom: 8),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceMutedDark : Colors.white,
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomLeft: const Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return _AnimatedDot(delay: Duration(milliseconds: i * 150));
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isDark, ChatbotProvider chatbot) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Focus(
              onFocusChange: (focused) =>
                  setState(() => _isFocused = focused),
              child: TextField(
                controller: _controller,
                enabled: !chatbot.isLoading,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask about routes, fares, bookings...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: _isFocused
                          ? AppColors.primaryOrange
                          : (isDark
                              ? AppColors.strokeDark
                              : AppColors.stroke),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color:
                          isDark ? AppColors.strokeDark : AppColors.stroke,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primaryOrange,
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceMutedDark
                      : const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(_controller.text),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ScaleTransition(
            scale: _fabScaleAnim,
            child: GestureDetector(
              onTapDown: (_) => _fabAnimController.forward(),
              onTapUp: (_) {
                _fabAnimController.reverse();
                _sendMessage(_controller.text);
              },
              onTapCancel: () => _fabAnimController.reverse(),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: chatbot.isLoading
                      ? null
                      : const LinearGradient(
                          colors: [
                            AppColors.primaryOrange,
                            AppColors.primaryOrangeDeep,
                          ],
                        ),
                  color: chatbot.isLoading
                      ? (isDark ? Colors.white12 : Colors.grey.shade200)
                      : null,
                  shape: BoxShape.circle,
                  boxShadow: chatbot.isLoading
                      ? null
                      : [
                          BoxShadow(
                            color: AppColors.primaryOrange.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: chatbot.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryOrange),
                        ),
                      )
                    : const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated pulsing dot for the typing indicator.
class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: const BoxDecoration(
          color: AppColors.primaryOrange,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
