class VoiceSample {
  final String id;
  final String text;
  final String category;
  final String description;
  final int durationSeconds;

  VoiceSample({
    required this.id,
    required this.text,
    required this.category,
    required this.description,
    required this.durationSeconds,
  });

  static List<VoiceSample> getDefaultSamples() {
    return [
      VoiceSample(
        id: 'greeting',
        text: 'Hello! How can I help you today?',
        category: 'Greetings',
        description: 'Standard greeting',
        durationSeconds: 3,
      ),
      VoiceSample(
        id: 'medical_intro',
        text: 'Hello, I\'m Doctor Annie, your AI medical assistant. I\'m here to help with any medical questions you might have.',
        category: 'Medical',
        description: 'Doctor Annie introduction',
        durationSeconds: 7,
      ),
      VoiceSample(
        id: 'emergency',
        text: 'Please remain calm. Emergency services have been notified and help is on the way. Stay where you are.',
        category: 'Emergency',
        description: 'Emergency response',
        durationSeconds: 8,
      ),
      VoiceSample(
        id: 'medication',
        text: 'It\'s time to take your medication. Please take two tablets with water, and remember to eat something first.',
        category: 'Medical',
        description: 'Medication reminder',
        durationSeconds: 8,
      ),
      VoiceSample(
        id: 'vital_signs',
        text: 'Your vital signs are within normal range. Heart rate is 72 beats per minute, blood pressure is 120 over 80.',
        category: 'Medical',
        description: 'Vital signs report',
        durationSeconds: 8,
      ),
      VoiceSample(
        id: 'calming',
        text: 'Take a deep breath in... and slowly breathe out. You\'re doing great. Everything is going to be okay.',
        category: 'Calming',
        description: 'Breathing exercise',
        durationSeconds: 9,
      ),
      VoiceSample(
        id: 'encouragement',
        text: 'You\'re making excellent progress! Keep up the great work. I\'m proud of how far you\'ve come.',
        category: 'Encouragement',
        description: 'Motivational message',
        durationSeconds: 7,
      ),
      VoiceSample(
        id: 'appointment',
        text: 'You have a doctor\'s appointment tomorrow at 2 PM. Please remember to bring your medical records and insurance card.',
        category: 'Reminders',
        description: 'Appointment reminder',
        durationSeconds: 8,
      ),
      VoiceSample(
        id: 'long_text',
        text: 'Medical history: The patient is a 45-year-old individual with a history of hypertension and type 2 diabetes. Current medications include metformin 500mg twice daily and lisinopril 10mg once daily. Blood pressure readings have been stable over the past month, averaging 125 over 82. Recent lab work shows HbA1c at 6.8%, which indicates good diabetes control.',
        category: 'Medical Records',
        description: 'Sample medical history',
        durationSeconds: 25,
      ),
      VoiceSample(
        id: 'quick_test',
        text: 'Testing, one, two, three. How does this voice sound?',
        category: 'Test',
        description: 'Quick voice test',
        durationSeconds: 4,
      ),
    ];
  }

  static List<String> getCategories() {
    return [
      'All',
      'Greetings',
      'Medical',
      'Emergency',
      'Calming',
      'Encouragement',
      'Reminders',
      'Medical Records',
      'Test',
    ];
  }
}