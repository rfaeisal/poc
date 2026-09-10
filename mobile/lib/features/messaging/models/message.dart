class ChatMessage {
  final String id;
  final String senderId;
  final String senderCallsign;
  final String content;
  final DateTime timestamp;
  final String channelId;
  final bool isPersonal;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderCallsign,
    required this.content,
    required this.timestamp,
    required this.channelId,
    this.isPersonal = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        senderId: json['senderId'] as String,
        senderCallsign: json['senderCallsign'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        channelId: json['channelId'] as String,
        isPersonal: json['isPersonal'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderCallsign': senderCallsign,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'channelId': channelId,
        'isPersonal': isPersonal,
      };
}
