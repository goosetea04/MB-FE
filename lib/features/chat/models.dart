import 'package:intl/intl.dart';


class ChatRequest {
final String message;
ChatRequest({required this.message});


Map<String, dynamic> toJson() => {"message": message};
}


class ChatResponse {
final String role;
final String message;
ChatResponse({required this.role, required this.message});


factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
role: json['role'] as String? ?? 'bot',
message: json['message'] as String? ?? '',
);
}


enum Sender { user, bot }


class ChatMessage {
final Sender sender;
final String text;
final DateTime time;


ChatMessage({required this.sender, required this.text, DateTime? time})
: time = time ?? DateTime.now();


String timeLabel() => DateFormat('HH:mm').format(time);
}