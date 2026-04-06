import 'package:flutter/material.dart';
import '../services/safety_education_service.dart';

class SafetyEducationScreen extends StatefulWidget {
  const SafetyEducationScreen({super.key});

  @override
  State<SafetyEducationScreen> createState() => _SafetyEducationScreenState();
}

class _SafetyEducationScreenState extends State<SafetyEducationScreen> {
  final SafetyEducationService _educationService = SafetyEducationService();
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() => _isLoading = true);
    await _educationService.initializeLessons();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<TutorialLesson> get _filteredLessons {
    if (_selectedCategory == 'All') {
      return _educationService.getAllLessons();
    }
    return _educationService.getLessonsByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    final stats = _educationService.getStatistics();
    final categories = ['All', ..._educationService.getCategories()];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Safety Education'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showStatistics(context, stats),
            icon: const Icon(Icons.assessment),
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Card
          _buildProgressCard(stats),

          // Category Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF00BFA5),
                    backgroundColor: const Color(0xFF1E2740),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Lessons Grid
          Expanded(
            child: _filteredLessons.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 2.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredLessons.length,
              itemBuilder: (context, index) {
                return _buildLessonCard(_filteredLessons[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> stats) {
    final completionRate = stats['completionRate'] as int;
    final completed = stats['completedLessons'] as int;
    final total = stats['totalLessons'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Keep learning to stay safe!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$completionRate%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: completionRate / 100,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed/$total Lessons Complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (stats['averageScore'] > 0)
                Text(
                  'Avg Score: ${stats['averageScore']}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(TutorialLesson lesson) {
    final difficultyColor =
    _educationService.getDifficultyColor(lesson.difficulty);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lesson.isCompleted
              ? const Color(0xFF00BFA5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLesson(lesson),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _educationService.getCategoryIcon(lesson.category),
                    color: difficultyColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            Icons.timer,
                            '${lesson.duration} min',
                            Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            Icons.signal_cellular_alt,
                            lesson.difficulty,
                            difficultyColor,
                          ),
                          if (lesson.isCompleted) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip(
                              Icons.check_circle,
                              '${lesson.quizScore}%',
                              const Color(0xFF00BFA5),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Icon
                Icon(
                  lesson.isCompleted
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                  color: lesson.isCompleted
                      ? const Color(0xFF00BFA5)
                      : Colors.white54,
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No lessons in this category',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _openLesson(TutorialLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewerScreen(lesson: lesson),
      ),
    ).then((_) => setState(() {})); // Refresh on return
  }

  void _showStatistics(BuildContext context, Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Row(
          children: [
            Icon(Icons.assessment, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text(
              'Learning Statistics',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Lessons', '${stats['totalLessons']}'),
            _buildStatRow('Completed', '${stats['completedLessons']}'),
            _buildStatRow('Completion Rate', '${stats['completionRate']}%'),
            if (stats['averageScore'] > 0)
              _buildStatRow('Average Score', '${stats['averageScore']}%'),
            _buildStatRow('Total Duration', '${stats['totalDuration']} min'),
            _buildStatRow(
                'Time Spent', '${stats['completedDuration']} min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// LESSON VIEWER SCREEN
class LessonViewerScreen extends StatefulWidget {
  final TutorialLesson lesson;

  const LessonViewerScreen({super.key, required this.lesson});

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalSteps = widget.lesson.steps.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $totalSteps',
                      style: const TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${((_currentStep + 1) / totalSteps * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    totalSteps,
                        (index) => Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index < totalSteps - 1 ? 8 : 0,
                        ),
                        decoration: BoxDecoration(
                          color: index <= _currentStep
                              ? const Color(0xFF00BFA5)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              itemCount: totalSteps,
              itemBuilder: (context, index) {
                final step = widget.lesson.steps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step Title
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Step Content
                      Text(
                        step.content,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),

                      // Bullet Points
                      if (step.bulletPoints.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2740),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.checklist,
                                    color: Color(0xFF00BFA5),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Key Points:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...step.bulletPoints.map((point) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF00BFA5),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        point,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],

                      // Key Takeaways on last step
                      if (index == totalSteps - 1) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.lightbulb, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Key Takeaways:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...widget.lesson.keyTakeaways
                                  .map((takeaway) => Padding(
                                padding:
                                const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        takeaway,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00BFA5),
                        side: const BorderSide(color: Color(0xFF00BFA5)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep < totalSteps - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Take quiz
                        _startQuiz();
                      }
                    },
                    icon: Icon(_currentStep < totalSteps - 1
                        ? Icons.arrow_forward
                        : Icons.quiz),
                    label: Text(_currentStep < totalSteps - 1
                        ? 'Next'
                        : 'Take Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFA5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(lesson: widget.lesson),
      ),
    );
  }
}

// QUIZ SCREEN
class QuizScreen extends StatefulWidget {
  final TutorialLesson lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final SafetyEducationService _educationService = SafetyEducationService();
  List<QuizQuestion>? _questions;
  int _currentQuestion = 0;
  int _correctAnswers = 0;
  int? _selectedAnswer;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    _questions = _educationService.getQuizForLesson(widget.lesson.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_questions == null || _questions!.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0E27),
        appBar: AppBar(
          title: const Text('Quiz'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text(
            'No quiz available for this lesson',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final question = _questions![_currentQuestion];
    final progress = (_currentQuestion + 1) / _questions!.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: Text('Quiz: ${widget.lesson.title}'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestion + 1} of ${_questions!.length}',
                      style: const TextStyle(
                        color: Color(0xFF00BFA5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Score: $_correctAnswers/${_questions!.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: const Color(0xFF00BFA5),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2740),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Options
                  ...List.generate(question.options.length, (index) {
                    final isSelected = _selectedAnswer == index;
                    final isCorrect = index == question.correctAnswerIndex;
                    final showResult = _answered;

                    Color borderColor = Colors.white24;
                    Color bgColor = const Color(0xFF1E2740);

                    if (showResult) {
                      if (isCorrect) {
                        borderColor = Colors.green;
                        bgColor = Colors.green.withValues(alpha: 0.2);
                      } else if (isSelected) {
                        borderColor = Colors.red;
                        bgColor = Colors.red.withValues(alpha: 0.2);
                      }
                    } else if (isSelected) {
                      borderColor = const Color(0xFF00BFA5);
                      bgColor = const Color(0xFF00BFA5).withValues(alpha: 0.2);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _answered
                              ? null
                              : () {
                            setState(() => _selectedAnswer = index);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: borderColor.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        color: borderColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (showResult && isCorrect)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                if (showResult && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Explanation
                  if (_answered) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF00BFA5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lightbulb,
                                  color: Color(0xFF00BFA5)),
                              SizedBox(width: 8),
                              Text(
                                'Explanation:',
                                style: TextStyle(
                                  color: Color(0xFF00BFA5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.explanation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Button
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAnswer == null
                    ? null
                    : () {
                  if (!_answered) {
                    _checkAnswer();
                  } else {
                    _nextQuestion();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text(_answered ? 'Next Question' : 'Submit Answer'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    final question = _questions![_currentQuestion];
    if (_selectedAnswer == question.correctAnswerIndex) {
      _correctAnswers++;
    }
    setState(() => _answered = true);
  }

  void _nextQuestion() {
    if (_currentQuestion < _questions!.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
        _answered = false;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    final score = (_correctAnswers / _questions!.length * 100).round();
    _educationService.completeLessonWithScore(widget.lesson.id, score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: Row(
          children: [
            Icon(
              score >= 70 ? Icons.emoji_events : Icons.info,
              color: score >= 70 ? Colors.amber : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text(
              'Quiz Complete!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: $score%',
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_correctAnswers out of ${_questions!.length} correct',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              score >= 70
                  ? ' Great job! You passed the quiz!'
                  : 'Keep learning! You can retake this quiz anytime.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close quiz
              Navigator.pop(context); // Close lesson
            },
            child: const Text('Done'),
          ),
          if (score < 70)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentQuestion = 0;
                  _correctAnswers = 0;
                  _selectedAnswer = null;
                  _answered = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
              ),
              child: const Text('Retake Quiz'),
            ),
        ],
      ),
    );
  }
}