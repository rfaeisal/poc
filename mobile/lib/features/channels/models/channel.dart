class Channel {
  final String id;
  final String name;
  final String? description;
  final bool isPrivate;
  final int memberCount;

  const Channel({
    required this.id,
    required this.name,
    this.description,
    this.isPrivate = false,
    this.memberCount = 0,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        isPrivate: json['isPrivate'] as bool? ?? false,
        memberCount:
            (json['_count'] as Map<String, dynamic>?)?['members'] as int? ?? 0,
      );
}

class JoinChannelResult {
  final Channel channel;
  final String livekitToken;
  final String livekitUrl;

  const JoinChannelResult({
    required this.channel,
    required this.livekitToken,
    required this.livekitUrl,
  });

  factory JoinChannelResult.fromJson(Map<String, dynamic> json) =>
      JoinChannelResult(
        channel:
            Channel.fromJson(json['channel'] as Map<String, dynamic>),
        livekitToken: json['livekitToken'] as String,
        livekitUrl: json['livekitUrl'] as String,
      );
}
