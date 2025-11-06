class AnalyticsData {
  final int teamSize;
  final int totalConnected;
  final int totalDuration;
  final int declined;
  final List<MemberAnalytics> members;

  AnalyticsData({
    required this.teamSize,
    required this.totalConnected,
    required this.totalDuration,
    required this.declined,
    required this.members,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      teamSize: json['teamSize'] ?? 0,
      totalConnected: json['TotalConnected'] ?? 0,
      totalDuration: json['TotalDuration'] ?? 0,
      declined: json['Declined'] ?? 0,
      members: (json['members'] as List? ?? [])
          .map((m) => MemberAnalytics.fromJson(m))
          .toList(),
    );
  }
}

class MemberAnalytics {
  final String userId;
  final String name;
  final String? profileImage;
  final int incoming;
  final int outgoing;
  final int connected;
  final int duration;
  final int declined;

  MemberAnalytics({
    required this.userId,
    required this.name,
    this.profileImage,
    required this.incoming,
    required this.outgoing,
    required this.connected,
    required this.duration,
    required this.declined,
  });

  factory MemberAnalytics.fromJson(Map<String, dynamic> json) {
    return MemberAnalytics(
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'],
      incoming: json['incoming'] ?? 0,
      outgoing: json['outgoing'] ?? 0,
      connected: json['connected'] ?? 0,
      duration: json['duration'] ?? 0,
      declined: json['declined'] ?? 0,
    );
  }
}
