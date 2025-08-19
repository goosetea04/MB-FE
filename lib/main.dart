import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/chat/chat_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MentalBuddyApp()));
}

class MentalBuddyApp extends StatelessWidget {
  const MentalBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Mental Buddy',
      theme: theme,
      home: const ChatScreen(),
    );
  }
}