// class TeamMember {
//   final String userId;
//   final String firstName;
//   final String lastName;
//   final String? profileUrl;
//   final String initials;
//   final String profile;
//   final bool isSelected;

//   TeamMember({
//     required this.userId,
//     required this.firstName,
//     required this.lastName,
//     this.profileUrl,
//     required this.initials,
//     required this.profile,
//     this.isSelected = false,
//   });

//   String get fullName => '$firstName $lastName';
//   String get firstLetter =>
//       firstName.isNotEmpty ? firstName[0].toUpperCase() : '';

//   factory TeamMember.fromJson(Map<String, dynamic> json) {
//     return TeamMember(
//       userId: json['user_id'] ?? '',
//       firstName: json['fname'] ?? '',
//       lastName: json['lname'] ?? '',
//       profileUrl: json['profile'],
//       initials: json['initials'] ?? '',
//       profile: json['profile'] ?? '',
//       isSelected: json['isSelected'] ?? false,
//     );
//   }

//   TeamMember copyWith({
//     String? userId,
//     String? firstName,
//     String? lastName,
//     String? profileUrl,
//     String? initials,
//     String? profile,
//     bool? isSelected,
//   }) {
//     return TeamMember(
//       userId: userId ?? this.userId,
//       firstName: firstName ?? this.firstName,
//       lastName: lastName ?? this.lastName,
//       profileUrl: profileUrl ?? this.profileUrl,
//       initials: initials ?? this.initials,
//       profile: profile ?? this.profile,
//       isSelected: isSelected ?? this.isSelected,
//     );
//   }

// }

// models/teams/team_member.dart
class TeamMember {
  final String userId;
  final String firstName;
  final String lastName;
  final String? profileUrl;
  final String initials;
  final String profile;
  final bool isSelected;

  TeamMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileUrl,
    required this.initials,
    required this.profile,
    this.isSelected = false,
  });

  String get fullName => '$firstName $lastName';
  String get firstLetter =>
      firstName.isNotEmpty ? firstName[0].toUpperCase() : '';

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      userId: json['user_id'] ?? '',
      firstName: json['fname'] ?? '',
      lastName: json['lname'] ?? '',
      profileUrl: json['profile'],
      initials: json['initials'] ?? '',
      profile: json['profile'] ?? '',
      isSelected: json['isSelected'] ?? false,
    );
  }

  // ✅ Add the missing toJson() method
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'fname': firstName,
      'lname': lastName,
      'profile': profile,
      'initials': initials,
      'isSelected': isSelected,
      'name': fullName, // Include computed full name
    };
  }

  TeamMember copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? profileUrl,
    String? initials,
    String? profile,
    bool? isSelected,
  }) {
    return TeamMember(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileUrl: profileUrl ?? this.profileUrl,
      initials: initials ?? this.initials,
      profile: profile ?? this.profile,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  String toString() {
    return 'TeamMember(userId: $userId, name: $fullName, profile: $profile)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamMember && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
