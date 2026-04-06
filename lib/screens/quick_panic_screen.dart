import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/quick_panic_service.dart';
import '../providers/auth_provider.dart';
import 'dart:math' as math;

class QuickPanicScreen extends StatefulWidget {
  const QuickPanicScreen({super.key});

  @override
  State<QuickPanicScreen> createState() => _QuickPanicScreenState();
}

class _QuickPanicScreenState extends State<QuickPanicScreen>
    with SingleTickerProviderStateMixin {
  final QuickPanicService _panicService = QuickPanicService();

  bool _isPanicActive = false;
  int _countdownSeconds = 0;
  int _selectedCountdown = 10;
  Map<String, dynamic> _statistics = {};

  AnimationController? _pulseController;

  @override
  void initState() {
    super.initState();
    _initializePanic();
    _loadStatistics();
  }

  Future<void> _initializePanic() async {
    await _panicService.initialize(
      onCountdownTick: _handleCountdownTick,
      onPanicTriggered: _handlePanicTriggered,
      onPanicCancelled: _handlePanicCancelled,
    );

    // Setup pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  void _loadStatistics() {
    setState(() {
      _statistics = _panicService.getStatistics();
    });
  }

  void _handleCountdownTick(int seconds) {
    if (mounted) {
      setState(() {
        _countdownSeconds = seconds;
        _isPanicActive = true;
      });

      if (!_pulseController!.isAnimating) {
        _pulseController!.repeat();
      }
    }
  }

  void _handlePanicTriggered() {
    if (mounted) {
      _pulseController?.stop();

      setState(() {
        _isPanicActive = false;
        _countdownSeconds = 0;
      });

      _loadStatistics();

      _showPanicTriggeredDialog();
    }
  }

  void _handlePanicCancelled() {
    if (mounted) {
      _pulseController?.stop();

      setState(() {
        _isPanicActive = false;
        _countdownSeconds = 0;
      });

      _loadStatistics();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Panic cancelled'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showPanicTriggeredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              ' PANIC TRIGGERED!',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency alerts have been sent to your contacts!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '• Location shared\n'
                  '• Emergency contacts notified\n'
                  '• Event logged',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPanic() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Please sign in first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(' Start Emergency Panic?'),
        content: Text(
          'Emergency alerts will be sent in $_selectedCountdown seconds.\n\n'
              'You can cancel anytime before the countdown ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('START PANIC'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _panicService.startPanicCountdown(
        userId: userId,
        countdownSeconds: _selectedCountdown,
      );
    }
  }

  Future<void> _cancelPanic() async {
    await _panicService.cancelPanicCountdown();
  }

  Future<void> _triggerPanicNow() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 12),
            Text(
              ' INSTANT PANIC',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Emergency alerts will be sent IMMEDIATELY.\n\n'
              'No countdown. Are you sure?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.red[900],
            ),
            child: const Text('SEND NOW'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _panicService.triggerPanicNow(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Quick Panic'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isPanicActive) ...[
                // Countdown Display
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    final scale = 1.0 + (math.sin(_pulseController!.value * 2 * math.pi) * 0.1);

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 50,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$_countdownSeconds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 80,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'SECONDS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                const Text(
                  'PANIC COUNTDOWN',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Emergency alerts will be sent when countdown ends',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cancelPanic,
                    icon: const Icon(Icons.close, size: 24),
                    label: const Text(
                      'CANCEL PANIC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Main Panic Button
                GestureDetector(
                  onTap: _startPanic,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF1744),
                          Color(0xFFD50000),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'PANIC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Countdown Selection
                const Text(
                  'COUNTDOWN TIME',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00BFA5),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [5, 10, 15, 30].map((seconds) {
                    final isSelected = _selectedCountdown == seconds;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ChoiceChip(
                        label: Text('${seconds}s'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCountdown = seconds;
                            });
                          }
                        },
                        selectedColor: const Color(0xFF00BFA5),
                        backgroundColor: const Color(0xFF1E2740),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 40),

                // Instant Panic
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _triggerPanicNow,
                    icon: const Icon(Icons.bolt, size: 24),
                    label: const Text(
                      'INSTANT PANIC (No Countdown)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Statistics
                Card(
                  color: const Color(0xFF1E2740),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'STATISTICS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BFA5),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              'Triggered',
                              '${_statistics['totalPanicsTriggered'] ?? 0}',
                              Colors.red,
                            ),
                            _buildStatItem(
                              'Cancelled',
                              '${_statistics['totalPanicsCancelled'] ?? 0}',
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'How It Works',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '• Tap the panic button to start\n'
                            '• Countdown begins (customizable)\n'
                            '• Cancel anytime before countdown ends\n'
                            '• When countdown ends:\n'
                            ' - Location is shared\n'
                            ' - Emergency contacts are alerted\n'
                            ' - Event is logged\n'
                            '• Use "Instant Panic" for immediate alerts',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
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
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _panicService.dispose();
    super.dispose();
  }
}