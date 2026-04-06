import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TutorialLesson {
  final String id;
  final String title;
  final String category;
  final String description;
  final int duration; // minutes
  final String difficulty; // beginner, intermediate, advanced
  final List<LessonStep> steps;
  final List<String> keyTakeaways;
  bool isCompleted;
  DateTime? completedAt;
  int? quizScore;

  TutorialLesson({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.difficulty,
    required this.steps,
    required this.keyTakeaways,
    this.isCompleted = false,
    this.completedAt,
    this.quizScore,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'description': description,
    'duration': duration,
    'difficulty': difficulty,
    'steps': steps.map((s) => s.toJson()).toList(),
    'keyTakeaways': keyTakeaways,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'quizScore': quizScore,
  };

  factory TutorialLesson.fromJson(Map<String, dynamic> json) => TutorialLesson(
    id: json['id'],
    title: json['title'],
    category: json['category'],
    description: json['description'],
    duration: json['duration'],
    difficulty: json['difficulty'],
    steps: (json['steps'] as List)
        .map((s) => LessonStep.fromJson(s))
        .toList(),
    keyTakeaways: List<String>.from(json['keyTakeaways']),
    isCompleted: json['isCompleted'] ?? false,
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
    quizScore: json['quizScore'],
  );
}

class LessonStep {
  final String title;
  final String content;
  final String? imageUrl;
  final List<String> bulletPoints;

  LessonStep({
    required this.title,
    required this.content,
    this.imageUrl,
    this.bulletPoints = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'imageUrl': imageUrl,
    'bulletPoints': bulletPoints,
  };

  factory LessonStep.fromJson(Map<String, dynamic> json) => LessonStep(
    title: json['title'],
    content: json['content'],
    imageUrl: json['imageUrl'],
    bulletPoints: List<String>.from(json['bulletPoints'] ?? []),
  );
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });
}

class SafetyEducationService {
  static final SafetyEducationService _instance =
  SafetyEducationService._internal();
  factory SafetyEducationService() => _instance;
  SafetyEducationService._internal();

  static const String _progressKey = 'education_progress';

  List<TutorialLesson> _lessons = [];
  Map<String, List<QuizQuestion>> _quizzes = {};

  /// Initialize lessons
  Future<void> initializeLessons() async {
    _lessons = [
      // LESSON 1: Using the Panic Button
      TutorialLesson(
        id: '1',
        title: 'Using the Panic Button',
        category: 'Basic Safety',
        description: 'Learn how to quickly activate emergency alerts',
        duration: 5,
        difficulty: 'beginner',
        steps: [
          LessonStep(
            title: 'Finding the Panic Button',
            content:
            'The panic button is prominently displayed on your home screen. It\'s the large red button that says "Emergency" or shows a shield icon.',
            bulletPoints: [
              'Always accessible from home screen',
              'Large and easy to tap',
              'Red color for quick identification',
            ],
          ),
          LessonStep(
            title: 'One-Tap Activation',
            content:
            'Simply tap the panic button once to activate. A countdown will begin, giving you 10 seconds to cancel if pressed accidentally.',
            bulletPoints: [
              'Single tap activates',
              '10-second countdown',
              'Cancel option available',
              'Haptic feedback confirms',
            ],
          ),
          LessonStep(
            title: 'Silent Mode',
            content:
            'For dangerous situations, long-press the button (hold for 3 seconds) to activate silently without countdown or sounds.',
            bulletPoints: [
              'Long-press for silent mode',
              'No countdown timer',
              'No audible alerts',
              'Discreet emergency notification',
            ],
          ),
          LessonStep(
            title: 'What Happens Next',
            content:
            'Once activated, your emergency contacts receive SMS alerts with your location. If enabled, emergency services are notified.',
            bulletPoints: [
              'SMS sent to all contacts',
              'GPS location shared',
              'Optional 911 call',
              'Evidence recording starts',
            ],
          ),
        ],
        keyTakeaways: [
          'Panic button is always accessible',
          'Use long-press for silent activation',
          'Contacts are notified immediately',
          'Practice using it regularly',
        ],
      ),

      // LESSON 2: First Aid Basics
      TutorialLesson(
        id: '2',
        title: 'First Aid Essentials',
        category: 'Medical',
        description: 'Critical first aid procedures everyone should know',
        duration: 15,
        difficulty: 'beginner',
        steps: [
          LessonStep(
            title: 'The ABC Approach',
            content:
            'Always start with ABC: Airway, Breathing, Circulation. Check if the person\'s airway is clear, if they\'re breathing, and if they have a pulse.',
            bulletPoints: [
              'A - Check airway is clear',
              'B - Look for chest movement',
              'C - Feel for pulse at neck or wrist',
              'Call 911 immediately if any are compromised',
            ],
          ),
          LessonStep(
            title: 'CPR Basics',
            content:
            'If someone is not breathing and has no pulse, begin CPR immediately. Push hard and fast on the center of the chest.',
            bulletPoints: [
              'Place hands center of chest',
              'Push down 2 inches deep',
              '100-120 compressions per minute',
              'Continue until help arrives',
            ],
          ),
          LessonStep(
            title: 'Controlling Bleeding',
            content:
            'For severe bleeding, apply direct pressure with a clean cloth. Elevate the wound above the heart if possible.',
            bulletPoints: [
              'Apply firm, direct pressure',
              'Don\'t remove cloth if soaked',
              'Add more cloths on top',
              'Elevate wound if able',
              'Call 911 for severe bleeding',
            ],
          ),
          LessonStep(
            title: 'Choking Response',
            content:
            'If someone is choking and can\'t cough or speak, perform the Heimlich maneuver by giving quick upward thrusts below the ribcage.',
            bulletPoints: [
              'Stand behind person',
              'Fist above navel, below ribs',
              'Quick upward thrusts',
              '5 thrusts, then check',
              'Call 911 if object won\'t dislodge',
            ],
          ),
          LessonStep(
            title: 'When to Call 911',
            content:
            'Call immediately for: unconsciousness, chest pain, difficulty breathing, severe bleeding, suspected stroke, or any life-threatening situation.',
            bulletPoints: [
              'Unconscious or unresponsive',
              'Chest pain or pressure',
              'Difficulty breathing',
              'Severe bleeding',
              'Signs of stroke (FAST)',
            ],
          ),
        ],
        keyTakeaways: [
          'ABC is your first priority',
          'CPR saves lives - learn it',
          'Direct pressure stops bleeding',
          'Don\'t hesitate to call 911',
        ],
      ),

      // LESSON 3: Personal Safety Awareness
      TutorialLesson(
        id: '3',
        title: 'Situational Awareness',
        category: 'Personal Safety',
        description: 'Stay alert and recognize dangerous situations',
        duration: 10,
        difficulty: 'intermediate',
        steps: [
          LessonStep(
            title: 'The Cooper Color Code',
            content:
            'Maintain a state of relaxed alertness. Know your surroundings, identify exits, and trust your instincts.',
            bulletPoints: [
              'White: Unaware (avoid this)',
              'Yellow: Relaxed alert (normal state)',
              'Orange: Specific alert (potential threat)',
              'Red: Fight or flight (immediate danger)',
            ],
          ),
          LessonStep(
            title: 'Recognizing Suspicious Behavior',
            content:
            'Watch for people who seem overly interested in you, following you, or exhibiting unusual behavior for the environment.',
            bulletPoints: [
              'Excessive staring or watching',
              'Following at a distance',
              'Loitering without purpose',
              'Attempting unwanted conversation',
              'Blocking your path',
            ],
          ),
          LessonStep(
            title: 'Safe Positioning',
            content:
            'Always position yourself with exits in view. Keep your back to walls when possible, maintain personal space, and avoid corners.',
            bulletPoints: [
              'Identify all exits immediately',
              'Keep back to wall if possible',
              'Maintain 6-foot personal space',
              'Avoid dead ends and corners',
              'Stay in well-lit areas',
            ],
          ),
          LessonStep(
            title: 'Trust Your Instincts',
            content:
            'If something feels wrong, it probably is. Your subconscious picks up on subtle danger signals. Don\'t ignore that feeling.',
            bulletPoints: [
              'Listen to your gut feeling',
              'Don\'t worry about being rude',
              'It\'s okay to leave situations',
              'Better safe than sorry',
              'Your safety comes first',
            ],
          ),
        ],
        keyTakeaways: [
          'Always maintain yellow alert state',
          'Know your exits',
          'Trust your instincts',
          'Awareness prevents incidents',
        ],
      ),

      // LESSON 4: Self-Defense Fundamentals
      TutorialLesson(
        id: '4',
        title: 'Basic Self-Defense',
        category: 'Self-Defense',
        description: 'Essential self-defense techniques for emergencies',
        duration: 20,
        difficulty: 'intermediate',
        steps: [
          LessonStep(
            title: 'Avoidance is Best Defense',
            content:
            'The best self-defense is avoiding dangerous situations entirely. Be aware, trust instincts, and remove yourself from threats early.',
            bulletPoints: [
              'Awareness prevents most attacks',
              'Leave uncomfortable situations',
              'Don\'t engage with aggressors',
              'Run away if possible',
              'Your ego isn\'t worth your safety',
            ],
          ),
          LessonStep(
            title: 'Vulnerable Target Areas',
            content:
            'If forced to defend yourself, target vulnerable areas: eyes, nose, throat, groin, and knees.',
            bulletPoints: [
              'Eyes - poke or gouge',
              'Nose - palm strike upward',
              'Throat - punch or chop',
              'Groin - kick or knee',
              'Knees - kick from side',
            ],
          ),
          LessonStep(
            title: 'Breaking Grabs',
            content:
            'If grabbed, attack the weakest point - the thumb. Pull against the thumb to break wrist grabs. Scream and fight aggressively.',
            bulletPoints: [
              'Wrist grab: pull against thumb',
              'Bear hug: stomp foot, elbow back',
              'Hair pull: grab their hand, push forward',
              'Choke: tuck chin, attack eyes/throat',
              'Always make noise and fight back',
            ],
          ),
          LessonStep(
            title: 'Creating Distance',
            content:
            'After any strike, immediately create distance. Push away, run to safety, and call for help. Don\'t stick around.',
            bulletPoints: [
              'Strike and immediately run',
              'Create as much distance as possible',
              'Run toward people and lights',
              'Yell "Fire!" to get attention',
              'Call 911 once safe',
            ],
          ),
        ],
        keyTakeaways: [
          'Avoidance is the best defense',
          'Target vulnerable areas if necessary',
          'Fight aggressively and loudly',
          'Create distance and escape immediately',
        ],
      ),

      // LESSON 5: Home Security
      TutorialLesson(
        id: '5',
        title: 'Home Safety & Security',
        category: 'Home Safety',
        description: 'Secure your home and create safe environments',
        duration: 12,
        difficulty: 'beginner',
        steps: [
          LessonStep(
            title: 'Entry Point Security',
            content:
            'All doors should have deadbolts. Windows need locks. Sliding doors should have security bars. Check all entry points daily.',
            bulletPoints: [
              'Install deadbolts on all doors',
              'Use window locks',
              'Security bars for sliding doors',
              'Check locks before bed',
              'Don\'t hide spare keys outside',
            ],
          ),
          LessonStep(
            title: 'Lighting & Visibility',
            content:
            'Motion-activated lights deter intruders. Keep bushes trimmed. Ensure good visibility around your property.',
            bulletPoints: [
              'Motion sensor lights at entrances',
              'Timer lights when away',
              'Trim bushes and trees',
              'Remove hiding spots',
              'Light up dark areas',
            ],
          ),
          LessonStep(
            title: 'Emergency Planning',
            content:
            'Create and practice a home emergency plan. Know multiple escape routes. Designate a meeting point outside.',
            bulletPoints: [
              'Plan two escape routes per room',
              'Designate outdoor meeting point',
              'Practice drills regularly',
              'Keep phone by bed',
              'Know where emergency supplies are',
            ],
          ),
          LessonStep(
            title: 'Stranger Safety',
            content:
            'Never open doors to strangers. Use peepholes or cameras. Verify identities before opening. Trust your instincts.',
            bulletPoints: [
              'Use peephole or camera',
              'Ask for ID before opening',
              'Keep chain lock on',
              'Call company to verify',
              'Don\'t let strangers in',
            ],
          ),
        ],
        keyTakeaways: [
          'Secure all entry points',
          'Good lighting deters crime',
          'Have an emergency escape plan',
          'Never open door to strangers',
        ],
      ),

      // LESSON 6: Digital Safety
      TutorialLesson(
        id: '6',
        title: 'Digital & Online Safety',
        category: 'Digital Safety',
        description: 'Stay safe online and protect your privacy',
        duration: 15,
        difficulty: 'intermediate',
        steps: [
          LessonStep(
            title: 'Social Media Privacy',
            content:
            'Review privacy settings regularly. Don\'t share real-time locations. Be careful about what personal information you post.',
            bulletPoints: [
              'Set profiles to private',
              'Don\'t share live locations',
              'Avoid posting vacation plans',
              'Don\'t share daily routines',
              'Review tagged photos',
            ],
          ),
          LessonStep(
            title: 'Recognizing Scams',
            content:
            'Phishing, fake profiles, and online predators are common. Verify identities before sharing information. If it seems too good to be true, it is.',
            bulletPoints: [
              'Verify sender identities',
              'Don\'t click suspicious links',
              'No legitimate company asks for passwords',
              'Watch for urgency tactics',
              'Research before acting',
            ],
          ),
          LessonStep(
            title: 'Password Security',
            content:
            'Use strong, unique passwords for each account. Enable two-factor authentication everywhere possible. Use a password manager.',
            bulletPoints: [
              'Unique password per account',
              'Minimum 12 characters',
              'Mix letters, numbers, symbols',
              'Enable 2FA everywhere',
              'Use password manager',
            ],
          ),
          LessonStep(
            title: 'Protecting Personal Information',
            content:
            'Guard your personal information carefully. Don\'t share addresses, phone numbers, or financial info online unless absolutely necessary.',
            bulletPoints: [
              'Minimize personal info shared',
              'Use separate email for signups',
              'Don\'t share financial data',
              'Be wary of surveys',
              'Check app permissions',
            ],
          ),
        ],
        keyTakeaways: [
          'Privacy settings are your first defense',
          'Verify before trusting online',
          'Use strong, unique passwords',
          'Guard personal information carefully',
        ],
      ),
    ];

    // Initialize quizzes for each lesson
    _initializeQuizzes();

    // Load progress
    await _loadProgress();

    debugPrint(' Initialized ${_lessons.length} safety lessons');
  }

  void _initializeQuizzes() {
    _quizzes = {
      '1': [
        QuizQuestion(
          question: 'How do you activate the panic button silently?',
          options: [
            'Double tap quickly',
            'Long-press for 3 seconds',
            'Shake your phone',
            'Say "emergency"'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Long-pressing the panic button for 3 seconds activates silent mode without countdown or sounds.',
        ),
        QuizQuestion(
          question: 'What happens when you activate the panic button?',
          options: [
            'Nothing until you confirm',
            'Only your phone vibrates',
            'Contacts receive SMS with your location',
            'It calls 911 immediately'
          ],
          correctAnswerIndex: 2,
          explanation:
          'Emergency contacts receive SMS alerts with your GPS location when the panic button is activated.',
        ),
        QuizQuestion(
          question: 'How long is the countdown before alert sends?',
          options: ['5 seconds', '10 seconds', '15 seconds', '30 seconds'],
          correctAnswerIndex: 1,
          explanation:
          'The countdown is 10 seconds, giving you time to cancel if pressed accidentally.',
        ),
      ],
      '2': [
        QuizQuestion(
          question: 'What does ABC stand for in first aid?',
          options: [
            'Alert, Breathe, Call',
            'Assess, Bandage, Comfort',
            'Airway, Breathing, Circulation',
            'Ambulance, Blood, CPR'
          ],
          correctAnswerIndex: 2,
          explanation:
          'ABC stands for Airway, Breathing, and Circulation - the three critical checks in first aid.',
        ),
        QuizQuestion(
          question: 'How deep should chest compressions be during CPR?',
          options: ['1 inch', '2 inches', '3 inches', '4 inches'],
          correctAnswerIndex: 1,
          explanation:
          'Chest compressions should be approximately 2 inches deep for effective CPR.',
        ),
        QuizQuestion(
          question: 'What should you do first for severe bleeding?',
          options: [
            'Apply a tourniquet',
            'Apply direct pressure',
            'Elevate above heart',
            'Clean the wound'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Apply firm, direct pressure with a clean cloth as the first step to control bleeding.',
        ),
      ],
      '3': [
        QuizQuestion(
          question: 'What is the recommended normal alert state?',
          options: [
            'White - Unaware',
            'Yellow - Relaxed alert',
            'Orange - Specific alert',
            'Red - Fight or flight'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Yellow (relaxed alert) is the recommended normal state where you\'re aware of surroundings but not paranoid.',
        ),
        QuizQuestion(
          question:
          'What should you do first when entering an unfamiliar place?',
          options: [
            'Find the bathroom',
            'Identify exits',
            'Check your phone',
            'Order food'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Always identify exits first when entering any new location for emergency preparedness.',
        ),
      ],
      '4': [
        QuizQuestion(
          question: 'What is the best self-defense?',
          options: [
            'Learning martial arts',
            'Carrying weapons',
            'Avoiding dangerous situations',
            'Being physically strong'
          ],
          correctAnswerIndex: 2,
          explanation:
          'Avoiding dangerous situations entirely is always the best defense strategy.',
        ),
        QuizQuestion(
          question: 'Which area is NOT a vulnerable target?',
          options: ['Eyes', 'Shoulder', 'Throat', 'Groin'],
          correctAnswerIndex: 1,
          explanation:
          'The shoulder is not a particularly vulnerable target. Focus on eyes, throat, nose, and groin.',
        ),
      ],
      '5': [
        QuizQuestion(
          question: 'What type of lock should all exterior doors have?',
          options: [
            'Standard knob lock',
            'Deadbolt',
            'Chain lock',
            'Smart lock'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Deadbolts provide the best security for exterior doors and should be installed on all entry points.',
        ),
        QuizQuestion(
          question: 'Where should you NOT hide a spare key?',
          options: [
            'With a trusted neighbor',
            'Under doormat',
            'In a lockbox',
            'At your workplace'
          ],
          correctAnswerIndex: 1,
          explanation:
          'Never hide keys in obvious outdoor spots like under doormats, rocks, or planters.',
        ),
      ],
      '6': [
        QuizQuestion(
          question: 'What should you enable on all accounts for security?',
          options: [
            'Password reset',
            'Email notifications',
            'Two-factor authentication',
            'Security questions'
          ],
          correctAnswerIndex: 2,
          explanation:
          'Two-factor authentication (2FA) adds an essential extra layer of security to all accounts.',
        ),
        QuizQuestion(
          question: 'What is a sign of a phishing email?',
          options: [
            'Professional design',
            'Company logo',
            'Urgent action required',
            'Long explanation'
          ],
          correctAnswerIndex: 2,
          explanation:
          'Urgency tactics (act now, immediate action required) are common signs of phishing attempts.',
        ),
      ],
    };
  }

  /// Get all lessons
  List<TutorialLesson> getAllLessons() => _lessons;

  /// Get lesson by ID
  TutorialLesson? getLessonById(String id) {
    try {
      return _lessons.firstWhere((l) => l.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get lessons by category
  List<TutorialLesson> getLessonsByCategory(String category) {
    return _lessons.where((l) => l.category == category).toList();
  }

  /// Get quiz for lesson
  List<QuizQuestion>? getQuizForLesson(String lessonId) {
    return _quizzes[lessonId];
  }

  /// Mark lesson as complete
  Future<void> completeLessonWithScore(String lessonId, int score) async {
    final lesson = getLessonById(lessonId);
    if (lesson != null) {
      lesson.isCompleted = true;
      lesson.completedAt = DateTime.now();
      lesson.quizScore = score;
      await _saveProgress();
      debugPrint(' Lesson completed: ${lesson.title} (Score: $score%)');
    }
  }

  /// Get completion statistics
  Map<String, dynamic> getStatistics() {
    final completed = _lessons.where((l) => l.isCompleted).length;
    final total = _lessons.length;
    final avgScore = _lessons
        .where((l) => l.quizScore != null)
        .fold<int>(0, (sum, l) => sum + l.quizScore!) /
        (completed > 0 ? completed : 1);

    return {
      'totalLessons': total,
      'completedLessons': completed,
      'completionRate': (completed / total * 100).round(),
      'averageScore': avgScore.round(),
      'totalDuration': _lessons.fold<int>(0, (sum, l) => sum + l.duration),
      'completedDuration':
      _lessons.where((l) => l.isCompleted).fold<int>(0, (sum, l) => sum + l.duration),
    };
  }

  /// Get categories
  List<String> getCategories() {
    return _lessons.map((l) => l.category).toSet().toList();
  }

  /// Load progress
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);
      if (progressJson != null) {
        final Map<String, dynamic> progress = json.decode(progressJson);
        for (final lesson in _lessons) {
          final lessonProgress = progress[lesson.id];
          if (lessonProgress != null) {
            lesson.isCompleted = lessonProgress['isCompleted'] ?? false;
            lesson.completedAt = lessonProgress['completedAt'] != null
                ? DateTime.parse(lessonProgress['completedAt'])
                : null;
            lesson.quizScore = lessonProgress['quizScore'];
          }
        }
      }
    } catch (e) {
      debugPrint(' Load progress error: $e');
    }
  }

  /// Save progress
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> progress = {};
      for (final lesson in _lessons) {
        progress[lesson.id] = {
          'isCompleted': lesson.isCompleted,
          'completedAt': lesson.completedAt?.toIso8601String(),
          'quizScore': lesson.quizScore,
        };
      }
      await prefs.setString(_progressKey, json.encode(progress));
      debugPrint(' Progress saved');
    } catch (e) {
      debugPrint(' Save progress error: $e');
    }
  }

  /// Get difficulty color
  Color getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get category icon
  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Basic Safety':
        return Icons.security;
      case 'Medical':
        return Icons.medical_services;
      case 'Personal Safety':
        return Icons.person_pin_circle;
      case 'Self-Defense':
        return Icons.sports_kabaddi;
      case 'Home Safety':
        return Icons.home;
      case 'Digital Safety':
        return Icons.phone_android;
      default:
        return Icons.school;
    }
  }
}