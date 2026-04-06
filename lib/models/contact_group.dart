import 'package:cloud_firestore/cloud_firestore.dart';

class ContactGroup {
  final String id;
  final String name;
  final String icon;
  final String color;
  final List<String> contactIds;
  final DateTime createdAt;

  ContactGroup({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.contactIds,
    required this.createdAt,
  });

  factory ContactGroup.fromMap(Map<String, dynamic> map, String id) {
    return ContactGroup(
      id: id,
      name: map['name'] as String,
      icon: map['icon'] as String,
      color: map['color'] as String,
      contactIds: List<String>.from(map['contactIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'contactIds': contactIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ContactGroup copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    List<String>? contactIds,
    DateTime? createdAt,
  }) {
    return ContactGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      contactIds: contactIds ?? this.contactIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}