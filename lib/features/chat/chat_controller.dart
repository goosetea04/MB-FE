import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_repository.dart';
import 'models.dart';


class ChatState {
final List<ChatMessage> messages;
final bool isTyping;
final String? error;


ChatState({required this.messages, this.isTyping = false, this.error});


ChatState copyWith({List<ChatMessage>? messages, bool? isTyping, String? error}) =>
ChatState(
messages: messages ?? this.messages,
isTyping: isTyping ?? this.isTyping,
error: error,
);
}


final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());


final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
return ChatController(ref.read(chatRepositoryProvider));
});


class ChatController extends StateNotifier<ChatState> {
final ChatRepository _repo;


ChatController(this._repo) : super(ChatState(messages: []));


void addUserMessage(String text) {
final updated = List<ChatMessage>.from(state.messages)
..add(ChatMessage(sender: Sender.user, text: text));
state = state.copyWith(messages: updated);
}


Future<void> send(String text) async {
// Show user bubble immediately
addUserMessage(text);


// Show typing indicator
state = state.copyWith(isTyping: true, error: null);


try {
final res = await _repo.sendMessage(text);
final updated = List<ChatMessage>.from(state.messages)
..add(ChatMessage(sender: Sender.bot, text: res.message));
state = state.copyWith(messages: updated, isTyping: false);
} catch (e) {
state = state.copyWith(isTyping: false, error: e.toString());
}
}


void clearError() => state = state.copyWith(error: null);
}