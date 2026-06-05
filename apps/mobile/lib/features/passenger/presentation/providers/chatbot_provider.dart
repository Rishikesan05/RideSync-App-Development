import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ridesync/core/constants.dart';

/// Represents a single message in the chat.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Manages the state of the RideSync AI chatbot.
/// Communicates with the backend /api/chatbot/message endpoint
/// so the Gemini API key is never exposed on the client.
class ChatbotProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hi! I'm RideSync Assistant 🚌\nHow can I help you today? Ask me about routes, schedules, fares, or your bookings!",
      isUser: false,
    ),
  ];

  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The backend base URL. Update this to your deployed Firebase Functions URL.
  /// For local development with emulator, use: http://10.0.2.2:5001/...
  static const String _backendBaseUrl = AppConstants.backendBaseUrl;

  /// Sends a message to the backend AI endpoint and appends the reply.
  /// [authToken] — Firebase ID token from the authenticated user.
  Future<void> sendMessage(String text, {required String authToken}) async {
    if (text.trim().isEmpty) return;

    // Add user's message immediately
    _messages.add(ChatMessage(text: text.trim(), isUser: true));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_backendBaseUrl/api/chatbot/message');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'message': text.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['data']?['reply'] as String? ??
            "I received your message but couldn't generate a response. Please try again.";

        _messages.add(ChatMessage(text: reply, isUser: false));
      } else {
        String errMsg = 'Something went wrong. Please try again.';
        try {
          final errorData = jsonDecode(response.body);
          errMsg = errorData['error'] ?? errMsg;
        } catch (_) {}

        if (response.statusCode == 503) {
          errMsg = 'The AI assistant is temporarily unavailable. Please try again shortly.';
        } else if (response.statusCode == 401) {
          errMsg = 'Authentication error. Please log out and back in.';
        }

        _messages.add(ChatMessage(text: '⚠️ $errMsg', isUser: false));
        _errorMessage = errMsg;
      }
    } on Exception catch (e) {
      final connErrMsg = 'Connection error. Please check your internet and try again.';
      _messages.add(ChatMessage(text: '⚠️ $connErrMsg', isUser: false));
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the chat history and resets to the welcome message.
  void clearChat() {
    _messages.clear();
    _messages.add(ChatMessage(
      text: "Hi! I'm RideSync Assistant 🚌\nHow can I help you today? Ask me about routes, schedules, fares, or your bookings!",
      isUser: false,
    ));
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
