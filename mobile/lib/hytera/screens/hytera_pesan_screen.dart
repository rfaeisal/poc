import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HyteraPesanScreen extends ConsumerStatefulWidget {
  const HyteraPesanScreen({super.key});

  @override
  ConsumerState<HyteraPesanScreen> createState() =>
      _HyteraPesanScreenState();
}

class _HyteraPesanScreenState extends ConsumerState<HyteraPesanScreen> {
  int _activeTab = 0;
  final _inputController = TextEditingController();

  final _tabs = const ['SECURITY', 'OPERASIONAL', 'PRIBADI'];

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      sender: 'BUDI-201',
      text: 'Siap di pos utara, over',
      time: '09:12',
      isMe: false,
    ),
    _ChatMessage(
      sender: null,
      text: 'Roger, lanjut ke sektor C',
      time: '09:19',
      isMe: true,
    ),
    _ChatMessage(
      sender: 'TONO-087',
      text: 'Ada kendaraan mencurigakan di gate 3',
      time: '09:24',
      isMe: false,
    ),
  ];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        sender: null,
        text: text,
        time: TimeOfDay.now().format(context),
        isMe: true,
      ));
    });
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFF060C18),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: const Row(
            children: [
              Text(
                'PESAN',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: Color(0xFF4A9EFF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF0F1E2E)),
            ),
          ),
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final isActive = i == _activeTab;
              return GestureDetector(
                onTap: () => setState(() => _activeTab = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isActive
                            ? const Color(0xFF4A9EFF)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: isActive
                          ? const Color(0xFF4A9EFF)
                          : const Color(0xFF2A4A6A),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Channel info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF0A1020)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CH 01 — ${_tabs[_activeTab]}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFF2A4A6A),
                ),
              ),
              const Text(
                '12 online',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: Color(0xFF2A4A6A),
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return _MessageBubble(message: msg);
            },
          ),
        ),

        // Input
        Container(
          color: const Color(0xFF060910),
          padding: const EdgeInsets.all(5),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    color: Color(0xFFDBE4F0),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8,
                      color: Color(0xFF64748B),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF0F1E2E),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E2A3A)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E2A3A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide:
                          const BorderSide(color: Color(0xFF4A9EFF)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E4A8A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.send,
                    size: 11,
                    color: Color(0xFF4A9EFF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  final String? sender;
  final String text;
  final String time;
  final bool isMe;

  const _ChatMessage({
    this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!message.isMe && message.sender != null)
            Text(
              message.sender!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 6.5,
                color: Color(0xFF4A6A8A),
              ),
            ),
          if (!message.isMe && message.sender != null)
            const SizedBox(height: 1),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: message.isMe
                  ? const Color(0xFF0F2A4A)
                  : const Color(0xFF0F1E2E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(5),
                topRight: const Radius.circular(5),
                bottomLeft:
                    Radius.circular(message.isMe ? 5 : 1),
                bottomRight:
                    Radius.circular(message.isMe ? 1 : 5),
              ),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: message.isMe
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            message.time,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 6.5,
              color: Color(0xFF2A4A6A),
            ),
          ),
        ],
      ),
    );
  }
}
