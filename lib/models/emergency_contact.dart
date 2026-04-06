import 'package:flutter/material.dart';

// Priority enum for type safety and visual indicators
enum ContactPriority {
  high(1, 'High', Color(0xFFDC143C), Icons.priority_high), // Crimson Red
  medium(2, 'Medium', Color(0xFFFF9800), Icons.remove), // Orange
  low(3, 'Low', Color(0xFF00BFA5), Icons.arrow_downward); // Teal

  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const ContactPriority(this.value, this.label, this.color, this.icon);

  // Convert int to enum
  static ContactPriority fromValue(int value) {
    return ContactPriority.values.firstWhere(
          (p) => p.value == value,
      orElse: () => ContactPriority.medium,
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final int priority; // 1=High, 2=Medium, 3=Low
  final bool isActive;
  final bool isVerified; // For contact verification feature
  final DateTime createdAt;
  final DateTime? lastVerifiedAt;

  // NEW: Additional optional fields for Contact Command Center
  final String? email;
  final String? address;
  final String? notes;
  final DateTime? updatedAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.priority = 2, // Default to Medium
    this.isActive = true,
    this.isVerified = false,
    required this.createdAt,
    this.lastVerifiedAt,
    this.email,
    this.address,
    this.notes,
    this.updatedAt,
  });

  // Backward compatibility getter
  String get phoneNumber => phone;

  // Get priority enum from int value
  ContactPriority get priorityLevel => ContactPriority.fromValue(priority);

  // Helper to get priority display name
  String get priorityName => priorityLevel.label;

  // Helper to get priority color
  Color get priorityColor => priorityLevel.color;

  // Helper to get priority icon
  IconData get priorityIcon => priorityLevel.icon;

  // ENHANCED: Factory from map with more fields
  factory EmergencyContact.fromMap(Map<String, dynamic> map, [String? docId]) {
    return EmergencyContact(
      id: docId ?? map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? map['phoneNumber'] as String? ?? '',
      relationship: map['relationship'] as String?,
      priority: map['priority'] as int? ?? 2,
      isActive: map['isActive'] as bool? ?? true,
      isVerified: map['isVerified'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastVerifiedAt: _parseDateTime(map['lastVerifiedAt']),
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) return value;

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        debugPrint(' Error parsing DateTime: $e');
        return null;
      }
    }

    // Handle Firestore Timestamp
    if (value is Map && value.containsKey('_seconds')) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(
          (value['_seconds'] as int) * 1000,
        );
      } catch (e) {
        debugPrint(' Error parsing Timestamp: $e');
        return null;
      }
    }

    return null;
  }

  // ENHANCED: To map with all fields
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'priority': priority,
      'isActive': isActive,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
      'email': email,
      'address': address,
      'notes': notes,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // ENHANCED: Copy with all fields
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
    bool? isActive,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastVerifiedAt,
    String? email,
    String? address,
    String? notes,
    DateTime? updatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Compare method for sorting by priority
  int compareTo(EmergencyContact other) {
    return priority.compareTo(other.priority);
  }

  // NEW: Validation methods
  bool get hasEmail => email != null && email!.isNotEmpty;
  bool get hasAddress => address != null && address!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  bool get isComplete {
    return name.isNotEmpty &&
        phone.isNotEmpty &&
        relationship != null &&
        relationship!.isNotEmpty;
  }

  // NEW: Format phone number for display
  String get formattedPhone {
    if (phone.length == 10) {
      return '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  // NEW: Get initials for avatar
  String get initials {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // NEW: Contact info for display
  String get displayInfo {
    final parts = <String>[name];
    if (relationship != null && relationship!.isNotEmpty) {
      parts.add('($relationship)');
    }
    return parts.join(' ');
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, name: $name, phone: $phone, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Extension for sorting list of contacts
extension ContactListExtension on List<EmergencyContact> {
  // Sort by priority (High -> Medium -> Low)
  List<EmergencyContact> sortedByPriority() {
    final sorted = List<EmergencyContact>.from(this);
    sorted.sort((a, b) => a.compareTo(b));
    return sorted;
  }

  // Sort by name alphabetically
  List<EmergencyContact> sortedByName() {
    final sorted = List<EmergencyContact>.from(this);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  // Sort by creation date (newest first)
  List<EmergencyContact> sortedByDate() {
    final sorted = List<EmergencyContact>.from(this);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  // Get only high priority contacts
  List<EmergencyContact> get highPriority =>
      where((c) => c.priority == 1).toList();

  // Get medium priority contacts
  List<EmergencyContact> get mediumPriority =>
      where((c) => c.priority == 2).toList();

  // Get low priority contacts
  List<EmergencyContact> get lowPriority =>
      where((c) => c.priority == 3).toList();

  // Get only active contacts
  List<EmergencyContact> get activeContacts =>
      where((c) => c.isActive).toList();

  // Get only verified contacts
  List<EmergencyContact> get verifiedContacts =>
      where((c) => c.isVerified).toList();

  // Get contacts by relationship
  List<EmergencyContact> byRelationship(String relationship) =>
      where((c) => c.relationship?.toLowerCase() == relationship.toLowerCase()).toList();

  // Group contacts by relationship
  Map<String, List<EmergencyContact>> groupedByRelationship() {
    final groups = <String, List<EmergencyContact>>{};

    for (final contact in this) {
      final rel = contact.relationship ?? 'Other';
      if (!groups.containsKey(rel)) {
        groups[rel] = [];
      }
      groups[rel]!.add(contact);
    }

    return groups;
  }

  // Search contacts
  List<EmergencyContact> search(String query) {
    if (query.isEmpty) return this;

    final lowerQuery = query.toLowerCase();
    return where((contact) {
      return contact.name.toLowerCase().contains(lowerQuery) ||
          contact.phone.contains(query) ||
          (contact.relationship?.toLowerCase().contains(lowerQuery) ?? false) ||
          (contact.email?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get statistics
  Map<String, int> get statistics {
    return {
      'total': length,
      'active': activeContacts.length,
      'verified': verifiedContacts.length,
      'highPriority': highPriority.length,
      'mediumPriority': mediumPriority.length,
      'lowPriority': lowPriority.length,
      'withEmail': where((c) => c.hasEmail).length,
      'withAddress': where((c) => c.hasAddress).length,
      'complete': where((c) => c.isComplete).length,
    };
  }
}