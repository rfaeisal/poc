class ChannelMember {
  final String userId;
  final String callsign;
  final String? name;
  final String? role;
  final bool isOnline;
  final bool isTransmitting;

  const ChannelMember({
    required this.userId,
    required this.callsign,
    this.name,
    this.role,
    this.isOnline = true,
    this.isTransmitting = false,
  });

  factory ChannelMember.fromApiJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    return ChannelMember(
      userId: user['id'] as String,
      callsign: profile['callsign'] as String? ?? '???',
      name: profile['name'] as String?,
      role: json['role'] as String?,
      isOnline: true,
    );
  }

  ChannelMember copyWith({
    bool? isOnline,
    bool? isTransmitting,
  }) =>
      ChannelMember(
        userId: userId,
        callsign: callsign,
        name: name,
        role: role,
        isOnline: isOnline ?? this.isOnline,
        isTransmitting: isTransmitting ?? this.isTransmitting,
      );
}
