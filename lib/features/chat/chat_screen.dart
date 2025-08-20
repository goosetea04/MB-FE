import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _language = 'English';

  // Brand palette to match the Figma (tweak as desired)
  static const Color _brand = Color(0xFFE07A5F); // warm orange header + assistant bubbles
  static const Color _bg = Color(0xFFFFF7F0);    // warm background
  static const Color _userBubble = Colors.white; // user bubble fill

  @override
  void initState() {
    super.initState();
    // (Removed ref.listen from initState — Riverpod requires listen in build or use listenManual.)
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);

    // ✅ Riverpod rule: do listen in build (or use listenManual). This triggers after state changes.
    ref.listen<ChatState>(chatControllerProvider, (prev, next) {
      final addedMsg = (prev?.messages.length ?? 0) < next.messages.length;
      final typingStopped = (prev?.isTyping ?? false) && !next.isTyping;
      if (addedMsg || typingStopped) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          // Top capsule header in brand color (Figma-style)
          Container(
            height: 84,
            decoration: const BoxDecoration(
              color: _brand,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 44),
            alignment: Alignment.center,
            child: const Text(
              'First Responder Bot',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),

          if (state.error != null)
            MaterialBanner(
              backgroundColor: Colors.red.shade50,
              content: Text(state.error!),
              actions: [
                TextButton(
                  onPressed: () => ref.read(chatControllerProvider.notifier).clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),

          // Chat list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              itemCount: state.messages.length + (state.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                final isTypingRow = state.isTyping && index == state.messages.length;
                if (isTypingRow) return const _TypingBubble();

                final msg = state.messages[index];
                final isUser = msg.sender == Sender.user;
                if (isUser) {
                  return _UserBubble(text: msg.text, time: msg.timeLabel());
                } else {
                  return _AssistantBubble(text: msg.text, time: msg.timeLabel());
                }
              },
            ),
          ),

          const Divider(height: 1),

          // Language row (bottom, left-aligned), matches Figma
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Text('Language:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Indonesian', child: Text('Indonesian')),
                    DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                  ],
                  onChanged: (v) => setState(() => _language = v ?? _language),
                ),
              ],
            ),
          ),

          // Input area styled like the Figma: rounded field + mic icon
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Type Your Response',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: _brand),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.mic_none_rounded),
                              color: Colors.black87,
                              onPressed: () {}, // hook up to recorder later
                            ),
                            IconButton(
                              icon: const Icon(Icons.send_rounded),
                              color: _brand,
                              onPressed: state.isTyping ? null : _send,
                            ),
                          ],
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatControllerProvider.notifier).send(text);
    _controller.clear();
  }
}

// --------------------
// Assistant (left) bubble with avatar, brand color, and mini audio row
// --------------------
class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text, required this.time});
  final String text;
  final String time;

  static const Color _brand = _ChatScreenState._brand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundImage: AssetImage('assets/assistant_avatar.png'), // add a friendly avatar asset
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _brand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 8),
                const _AudioRow(durationLabel: '0:35'), // visual-only for now
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// User (right) bubble: white with subtle border
// --------------------
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text, required this.time});
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: _ChatScreenState._userBubble,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 15),
                    textAlign: TextAlign.left,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------
// Visual-only audio row like in the Figma mock (play icon + slider + duration)
// --------------------
class _AudioRow extends StatelessWidget {
  const _AudioRow({required this.durationLabel});
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.play_circle_fill_rounded, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: 0.25, // static preview; wire to real audio later
              backgroundColor: Colors.black.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(durationLabel, style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 36, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _Dot(), SizedBox(width: 3), _Dot(), SizedBox(width: 3), _Dot(),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.2, end: 1.0).animate(_c),
      child: const CircleAvatar(radius: 3.5),
    );
  }
}