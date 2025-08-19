import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import 'models.dart';


class ChatRepository {
final http.Client _client;
ChatRepository({http.Client? client}) : _client = client ?? http.Client();


Future<ChatResponse> sendMessage(String message) async {
final req = ChatRequest(message: message);
final res = await _client.post(
ApiConfig.chatUri(),
headers: {"Content-Type": "application/json"},
body: jsonEncode(req.toJson()),
);


if (res.statusCode >= 200 && res.statusCode < 300) {
final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
return ChatResponse.fromJson(json);
}


throw Exception("Backend error ${res.statusCode}: ${res.body}");
}
}