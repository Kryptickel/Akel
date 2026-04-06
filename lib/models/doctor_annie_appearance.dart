import 'package:flutter/material.dart';

/// Doctor Annie Physical Appearance Configuration
class DoctorAnnieAppearance {
// Hair
  final HairStyle hairStyle;
  final HairLength hairLength;
  final Color hairColor;

// Face
  final EthnicityType ethnicity;
  final Color skinTone;
  final AgeAppearance ageAppearance;
  final bool hasGlasses;
  final GlassesStyle? glassesStyle;

// Clothing
  final ClothingType clothing;
  final Color clothingColor;

// Accessories
  final bool hasStethoscope;
  final bool hasTablet;
  final bool hasMedicalBag;
  final List<AccessoryType> extraAccessories;

// Visual Effects
  final double glossyIntensity; // 0.0 to 1.0
  final double glassyTransparency; // 0.0 to 1.0
  final bool enableReflections;
  final bool enableShadows;

  const DoctorAnnieAppearance({
    this.hairStyle = HairStyle.shoulder,
    this.hairLength = HairLength.medium,
    this.hairColor = const Color(0xFF8B4513),
    this.ethnicity = EthnicityType.caucasian,
    this.skinTone = const Color(0xFFFFDBAC),
    this.ageAppearance = AgeAppearance.thirties,
    this.hasGlasses = true,
    this.glassesStyle = GlassesStyle.modern,
    this.clothing = ClothingType.labCoat,
    this.clothingColor = Colors.white,
    this.hasStethoscope = true,
    this.hasTablet = true,
    this.hasMedicalBag = false,
    this.extraAccessories = const [],
    this.glossyIntensity = 0.7,
    this.glassyTransparency = 0.3,
    this.enableReflections = true,
    this.enableShadows = true,
  });

  DoctorAnnieAppearance copyWith({
    HairStyle? hairStyle,
    HairLength? hairLength,
    Color? hairColor,
    EthnicityType? ethnicity,
    Color? skinTone,
    AgeAppearance? ageAppearance,
    bool? hasGlasses,
    GlassesStyle? glassesStyle,
    ClothingType? clothing,
    Color? clothingColor,
    bool? hasStethoscope,
    bool? hasTablet,
    bool? hasMedicalBag,
    List<AccessoryType>? extraAccessories,
    double? glossyIntensity,
    double? glassyTransparency,
    bool? enableReflections,
    bool? enableShadows,
  }) {
    return DoctorAnnieAppearance(
      hairStyle: hairStyle ?? this.hairStyle,
      hairLength: hairLength ?? this.hairLength,
      hairColor: hairColor ?? this.hairColor,
      ethnicity: ethnicity ?? this.ethnicity,
      skinTone: skinTone ?? this.skinTone,
      ageAppearance: ageAppearance ?? this.ageAppearance,
      hasGlasses: hasGlasses ?? this.hasGlasses,
      glassesStyle: glassesStyle ?? this.glassesStyle,
      clothing: clothing ?? this.clothing,
      clothingColor: clothingColor ?? this.clothingColor,
      hasStethoscope: hasStethoscope ?? this.hasStethoscope,
      hasTablet: hasTablet ?? this.hasTablet,
      hasMedicalBag: hasMedicalBag ?? this.hasMedicalBag,
      extraAccessories: extraAccessories ?? this.extraAccessories,
      glossyIntensity: glossyIntensity ?? this.glossyIntensity,
      glassyTransparency: glassyTransparency ?? this.glassyTransparency,
      enableReflections: enableReflections ?? this.enableReflections,
      enableShadows: enableShadows ?? this.enableShadows,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hairStyle': hairStyle.name,
      'hairLength': hairLength.name,
      'hairColor': hairColor.value,
      'ethnicity': ethnicity.name,
      'skinTone': skinTone.value,
      'ageAppearance': ageAppearance.name,
      'hasGlasses': hasGlasses,
      'glassesStyle': glassesStyle?.name,
      'clothing': clothing.name,
      'clothingColor': clothingColor.value,
      'hasStethoscope': hasStethoscope,
      'hasTablet': hasTablet,
      'hasMedicalBag': hasMedicalBag,
      'extraAccessories': extraAccessories.map((a) => a.name).toList(),
      'glossyIntensity': glossyIntensity,
      'glassyTransparency': glassyTransparency,
      'enableReflections': enableReflections,
      'enableShadows': enableShadows,
    };
  }

  factory DoctorAnnieAppearance.fromJson(Map<String, dynamic> json) {
    return DoctorAnnieAppearance(
      hairStyle: HairStyle.values.firstWhere(
            (e) => e.name == json['hairStyle'],
        orElse: () => HairStyle.shoulder,
      ),
      hairLength: HairLength.values.firstWhere(
            (e) => e.name == json['hairLength'],
        orElse: () => HairLength.medium,
      ),
      hairColor: Color(json['hairColor'] as int),
      ethnicity: EthnicityType.values.firstWhere(
            (e) => e.name == json['ethnicity'],
        orElse: () => EthnicityType.caucasian,
      ),
      skinTone: Color(json['skinTone'] as int),
      ageAppearance: AgeAppearance.values.firstWhere(
            (e) => e.name == json['ageAppearance'],
        orElse: () => AgeAppearance.thirties,
      ),
      hasGlasses: json['hasGlasses'] as bool? ?? true,
      glassesStyle: json['glassesStyle'] != null
          ? GlassesStyle.values.firstWhere(
            (e) => e.name == json['glassesStyle'],
        orElse: () => GlassesStyle.modern,
      )
          : null,
      clothing: ClothingType.values.firstWhere(
            (e) => e.name == json['clothing'],
        orElse: () => ClothingType.labCoat,
      ),
      clothingColor: Color(json['clothingColor'] as int),
      hasStethoscope: json['hasStethoscope'] as bool? ?? true,
      hasTablet: json['hasTablet'] as bool? ?? true,
      hasMedicalBag: json['hasMedicalBag'] as bool? ?? false,
      extraAccessories: (json['extraAccessories'] as List<dynamic>?)
          ?.map((e) => AccessoryType.values
          .firstWhere((a) => a.name == e, orElse: () => AccessoryType.badge))
          .toList() ??
          [],
      glossyIntensity: (json['glossyIntensity'] as num?)?.toDouble() ?? 0.7,
      glassyTransparency: (json['glassyTransparency'] as num?)?.toDouble() ?? 0.3,
      enableReflections: json['enableReflections'] as bool? ?? true,
      enableShadows: json['enableShadows'] as bool? ?? true,
    );
  }
}

// ==================== ENUMS ====================

enum HairStyle {
  straight,
  wavy,
  curly,
  bun,
  ponytail,
  shoulder,
  pixie,
  bob,
  braided,
}

enum HairLength {
  short,
  medium,
  long,
  veryLong,
}

enum EthnicityType {
  caucasian,
  african,
  asian,
  hispanic,
  middleEastern,
  indian,
  mixed,
}

enum AgeAppearance {
  twenties,
  thirties,
  forties,
  fifties,
  sixties,
}

enum GlassesStyle {
  modern,
  classic,
  rimless,
  catEye,
round,
rectangular,
}

enum ClothingType {
  labCoat,
  scrubs,
  business,
  businessCasual,
  casual,
  formal,
}

enum AccessoryType {
  badge,
  watch,
  earrings,
  necklace,
  pen,
  clipboard,
}

// ==================== HELPER EXTENSIONS ====================

extension HairStyleExtension on HairStyle {
  String get displayName {
    switch (this) {
      case HairStyle.straight:
        return 'Straight';
      case HairStyle.wavy:
        return 'Wavy';
      case HairStyle.curly:
        return 'Curly';
      case HairStyle.bun:
        return 'Bun';
      case HairStyle.ponytail:
        return 'Ponytail';
      case HairStyle.shoulder:
        return 'Shoulder Length';
      case HairStyle.pixie:
        return 'Pixie Cut';
      case HairStyle.bob:
        return 'Bob Cut';
      case HairStyle.braided:
        return 'Braided';
    }
  }
}

extension ClothingTypeExtension on ClothingType {
  String get displayName {
    switch (this) {
      case ClothingType.labCoat:
        return 'Lab Coat';
      case ClothingType.scrubs:
        return 'Scrubs';
      case ClothingType.business:
        return 'Business Suit';
      case ClothingType.businessCasual:
        return 'Business Casual';
      case ClothingType.casual:
        return 'Casual';
      case ClothingType.formal:
        return 'Formal';
    }
  }
}