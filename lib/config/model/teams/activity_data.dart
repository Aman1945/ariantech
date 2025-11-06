class ActivityData {
  final String leadId;
  final String name;
  final String subject;
  final String date;
  final String vehicle;
  final ActivityType type;

  ActivityData({
    required this.leadId,
    required this.name,
    required this.subject,
    required this.date,
    required this.vehicle,
    required this.type,
  });

  factory ActivityData.fromJson(Map<String, dynamic> json, ActivityType type) {
    return ActivityData(
      leadId: json['lead_id'] ?? '',
      name: json['name'] ?? '',
      subject: json['subject'] ?? '',
      date: json[_getDateKey(type)] ?? '',
      vehicle: json['PMI'] ?? '',
      type: type,
    );
  }

  static String _getDateKey(ActivityType type) {
    switch (type) {
      case ActivityType.followup:
        return 'due_date';
      case ActivityType.appointment:
      case ActivityType.testDrive:
        return 'start_date';
    }
  }
}

enum ActivityType { followup, appointment, testDrive }
