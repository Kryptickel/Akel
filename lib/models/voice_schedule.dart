import 'dart:convert';

class VoiceScheduleEntry {
  final String id;
  final int startHour; // 0-23
  final int startMinute; // 0-59
  final int endHour;
  final int endMinute;
  final String profileId;
  final String profileName;
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final bool isEnabled;

  VoiceScheduleEntry({
    required this.id,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.profileId,
    required this.profileName,
    List<int>? daysOfWeek,
    this.isEnabled = true,
  }) : daysOfWeek = daysOfWeek ?? [1, 2, 3, 4, 5, 6, 7];

  String get timeRange {
    final startTime = '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final endTime = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String get daysString {
    if (daysOfWeek.length == 7) return 'Every day';
    if (daysOfWeek.length == 5 && daysOfWeek.contains(1) && daysOfWeek.contains(5)) {
      return 'Weekdays';
    }
    if (daysOfWeek.length == 2 && daysOfWeek.contains(6) && daysOfWeek.contains(7)) {
      return 'Weekends';
    }

    const dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return daysOfWeek.map((d) => dayNames[d]).join(', ');
  }

  bool isActiveNow() {
    if (!isEnabled) return false;

    final now = DateTime.now();
    final currentDay = now.weekday;

    if (!daysOfWeek.contains(currentDay)) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (endMinutes > startMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
// Handles overnight schedules
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'profileId': profileId,
      'profileName': profileName,
      'daysOfWeek': daysOfWeek,
      'isEnabled': isEnabled,
    };
  }

  factory VoiceScheduleEntry.fromJson(Map<String, dynamic> json) {
    return VoiceScheduleEntry(
      id: json['id'],
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      endHour: json['endHour'],
      endMinute: json['endMinute'],
      profileId: json['profileId'],
      profileName: json['profileName'],
      daysOfWeek: List<int>.from(json['daysOfWeek']),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  VoiceScheduleEntry copyWith({
    String? id,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? profileId,
    String? profileName,
    List<int>? daysOfWeek,
    bool? isEnabled,
  }) {
    return VoiceScheduleEntry(
      id: id ?? this.id,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      profileId: profileId ?? this.profileId,
      profileName: profileName ?? this.profileName,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}