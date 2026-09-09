class UserProfile {
  final String? callsign;
  final String? name;
  final String? photoUrl;
  final String? bio;

  const UserProfile({this.callsign, this.name, this.photoUrl, this.bio});

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        callsign: json['callsign'] as String?,
        name: json['name'] as String?,
        photoUrl: json['photoUrl'] as String?,
        bio: json['bio'] as String?,
      );
}

class User {
  final String id;
  final String email;
  final String role;
  final UserProfile profile;

  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String? ?? 'USER',
        profile: json['profile'] != null
            ? UserProfile.fromJson(json['profile'] as Map<String, dynamic>)
            : const UserProfile(),
      );
}
