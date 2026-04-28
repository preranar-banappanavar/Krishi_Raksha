import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// Persists chat history across sessions using SharedPreferences.
/// Abstracted here so screens have no direct dependency on the package.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _chatKey = 'krishi_chat_history';
  static const _maxMessages = 100; // cap to avoid unbounded growth

  Future<List<ChatMessage>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chatKey) ?? [];
    return raw.map(ChatMessage.deserialize).whereType<ChatMessage>().toList();
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final capped = messages.length > _maxMessages
        ? messages.sublist(messages.length - _maxMessages)
        : messages;
    await prefs.setStringList(_chatKey, capped.map((m) => m.serialize()).toList());
  }

  Future<void> clearChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chatKey);
  }
}
