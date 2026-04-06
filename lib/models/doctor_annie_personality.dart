/// Doctor Annie Personality Configuration
class DoctorAnniePersonality {
  // Bedside Manner
  final BedsideManner bedsideManner;

  // Communication Style
  final CommunicationStyle communicationStyle;

  // Emotional Response
  final EmotionalResponseLevel emotionalResponse;

  // Question Approach
  final QuestionApproach questionApproach;

  // Humor Level
  final HumorLevel humorLevel;

  // Professional Traits
  final bool isEncouraging;
  final bool isEmpathetic;
  final bool isDirective;
  final bool isEducational;

  const DoctorAnniePersonality({
    this.bedsideManner = BedsideManner.warm,
    this.communicationStyle = CommunicationStyle.balanced,
    this.emotionalResponse = EmotionalResponseLevel.moderate,
    this.questionApproach = QuestionApproach.thorough,
    this.humorLevel = HumorLevel.light,
    this.isEncouraging = true,
    this.isEmpathetic = true,
    this.isDirective = false,
    this.isEducational = true,
  });

  DoctorAnniePersonality copyWith({
    BedsideManner? bedsideManner,
    CommunicationStyle? communicationStyle,
    EmotionalResponseLevel? emotionalResponse,
    QuestionApproach? questionApproach,
    HumorLevel? humorLevel,
    bool? isEncouraging,
    bool? isEmpathetic,
    bool? isDirective,
    bool? isEducational,
  }) {
    return DoctorAnniePersonality(
      bedsideManner: bedsideManner ?? this.bedsideManner,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      emotionalResponse: emotionalResponse ?? this.emotionalResponse,
      questionApproach: questionApproach ?? this.questionApproach,
      humorLevel: humorLevel ?? this.humorLevel,
      isEncouraging: isEncouraging ?? this.isEncouraging,
      isEmpathetic: isEmpathetic ?? this.isEmpathetic,
      isDirective: isDirective ?? this.isDirective,
      isEducational: isEducational ?? this.isEducational,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bedsideManner': bedsideManner.name,
      'communicationStyle': communicationStyle.name,
      'emotionalResponse': emotionalResponse.name,
      'questionApproach': questionApproach.name,
      'humorLevel': humorLevel.name,
      'isEncouraging': isEncouraging,
      'isEmpathetic': isEmpathetic,
      'isDirective': isDirective,
      'isEducational': isEducational,
    };
  }

  factory DoctorAnniePersonality.fromJson(Map<String, dynamic> json) {
    return DoctorAnniePersonality(
      bedsideManner: BedsideManner.values.firstWhere(
            (e) => e.name == json['bedsideManner'],
        orElse: () => BedsideManner.warm,
      ),
      communicationStyle: CommunicationStyle.values.firstWhere(
            (e) => e.name == json['communicationStyle'],
        orElse: () => CommunicationStyle.balanced,
      ),
      emotionalResponse: EmotionalResponseLevel.values.firstWhere(
            (e) => e.name == json['emotionalResponse'],
        orElse: () => EmotionalResponseLevel.moderate,
      ),
      questionApproach: QuestionApproach.values.firstWhere(
            (e) => e.name == json['questionApproach'],
        orElse: () => QuestionApproach.thorough,
      ),
      humorLevel: HumorLevel.values.firstWhere(
            (e) => e.name == json['humorLevel'],
        orElse: () => HumorLevel.light,
      ),
      isEncouraging: json['isEncouraging'] as bool? ?? true,
      isEmpathetic: json['isEmpathetic'] as bool? ?? true,
      isDirective: json['isDirective'] as bool? ?? false,
      isEducational: json['isEducational'] as bool? ?? true,
    );
  }

  String getGreeting() {
    switch (bedsideManner) {
      case BedsideManner.warm:
        return "Hello! I'm so glad you're here. How are you feeling today?";
      case BedsideManner.direct:
        return "Hello. Let's get started. What brings you in today?";
      case BedsideManner.friendly:
        return "Hey there! Good to see you! What can I help you with?";
      case BedsideManner.calm:
        return "Hello. Take your time. I'm here to help. What's going on?";
      case BedsideManner.educational:
        return "Hello! I'm here to help you understand your health better. What would you like to discuss?";
      case BedsideManner.motivational:
        return "Hello! You're taking great steps for your health today. How can I support you?";
    }
  }

  String getEncouragement() {
    if (!isEncouraging) return "";

    switch (bedsideManner) {
      case BedsideManner.warm:
        return "You're doing wonderfully!";
      case BedsideManner.direct:
        return "Good progress.";
      case BedsideManner.friendly:
        return "That's awesome!";
      case BedsideManner.calm:
        return "You're doing well.";
      case BedsideManner.educational:
        return "Excellent understanding!";
      case BedsideManner.motivational:
        return "You're making amazing progress! Keep it up!";
    }
  }
}

// ==================== ENUMS ====================

enum BedsideManner {
  warm,
  direct,
  friendly,
  calm,
  educational,
  motivational,
}

enum CommunicationStyle {
  concise,
  balanced,
  detailed,
  conversational,
  technical,
}

enum EmotionalResponseLevel {
  reserved,
  moderate,
  expressive,
  highly_empathetic,
}

enum QuestionApproach {
  quick,
  thorough,
  investigative,
  holistic,
}

enum HumorLevel {
  none,
  subtle,
  light,
  moderate,
  frequent,
}

// ==================== HELPER EXTENSIONS ====================

extension BedsideMannerExtension on BedsideManner {
  String get displayName {
    switch (this) {
      case BedsideManner.warm:
        return 'Warm & Caring';
      case BedsideManner.direct:
        return 'Direct & Efficient';
      case BedsideManner.friendly:
        return 'Friendly & Casual';
      case BedsideManner.calm:
        return 'Calm & Reassuring';
      case BedsideManner.educational:
        return 'Educational & Informative';
      case BedsideManner.motivational:
        return 'Motivational & Encouraging';
    }
  }

  String get description {
    switch (this) {
      case BedsideManner.warm:
        return 'Compassionate and nurturing approach';
      case BedsideManner.direct:
        return 'Straightforward and efficient communication';
      case BedsideManner.friendly:
        return 'Casual and approachable style';
      case BedsideManner.calm:
        return 'Soothing and reassuring presence';
      case BedsideManner.educational:
        return 'Focus on teaching and explanation';
      case BedsideManner.motivational:
        return 'Inspiring and uplifting approach';
    }
  }
}