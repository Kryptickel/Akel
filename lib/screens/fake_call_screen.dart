import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../services/fake_call_service.dart';
import '../services/vibration_service.dart';
import '../models/fake_call.dart';
import 'incoming_call_screen.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final FakeCallService _fakeCallService = FakeCallService();
  final VibrationService _vibrationService = VibrationService();

  final TextEditingController _callerNameController = TextEditingController();
  final TextEditingController _callerNumberController = TextEditingController();

  int _selectedDelaySeconds = 30;
  bool _isScheduling = false;
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  String? _activeCallId;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _checkActiveCall();
  }

  @override
  void dispose() {
    _callerNameController.dispose();
    _callerNumberController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _loadDefaults() {
    _callerNameController.text = 'Mom';
    _callerNumberController.text = '+1 (555) 123-4567';
  }

  Future<void> _checkActiveCall() async {
    final callId = await _fakeCallService.getActiveFakeCallId();
    if (callId != null && mounted) {
      setState(() {
        _activeCallId = callId;
      });
      _startCountdown();
    }
  }

  void _selectPreset(Map<String, String> preset) {
    setState(() {
      _callerNameController.text = preset['name']!;
      _callerNumberController.text = preset['number']!;
    });
  }

  Future<void> _scheduleFakeCall() async {
    if (_callerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please enter caller name')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Not logged in')),
      );
      return;
    }

    setState(() => _isScheduling = true);

    try {
      final callId = await _fakeCallService.scheduleFakeCall(
        userId: userId,
        callerName: _callerNameController.text,
        callerNumber: _callerNumberController.text,
        delaySeconds: _selectedDelaySeconds,
      );

      await _vibrationService.success();

      setState(() {
        _activeCallId = callId;
        _remainingSeconds = _selectedDelaySeconds;
        _isScheduling = false;
      });

      _startCountdown();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Fake call scheduled in $_selectedDelaySeconds seconds'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await _vibrationService.error();
      setState(() => _isScheduling = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _triggerFakeCall();
      }
    });
  }

  void _triggerFakeCall() {
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IncomingCallScreen(
          callerName: _callerNameController.text,
          callerNumber: _callerNumberController.text,
          onAnswer: () => _handleCallAnswer(),
          onDecline: () => _handleCallDecline(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _handleCallAnswer() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null && _activeCallId != null) {
      await _fakeCallService.completeFakeCall(userId, _activeCallId!);
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close incoming call screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Call answered - You\'re safe!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    setState(() {
      _activeCallId = null;
      _remainingSeconds = 0;
    });
  }

  Future<void> _handleCallDecline() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null && _activeCallId != null) {
      await _fakeCallService.completeFakeCall(userId, _activeCallId!);
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close incoming call screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📵 Call declined'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _activeCallId = null;
      _remainingSeconds = 0;
    });
  }

  Future<void> _cancelScheduledCall() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null && _activeCallId != null) {
      await _fakeCallService.cancelFakeCall(userId, _activeCallId!);
      await _vibrationService.warning();

      _countdownTimer?.cancel();

      setState(() {
        _activeCallId = null;
        _remainingSeconds = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Fake call cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final secs = seconds % 60;
      return secs > 0 ? '${minutes}m ${secs}s' : '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Active Call Banner
          if (_activeCallId != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.withValues(alpha: 0.2), Colors.purple.withValues(alpha: 0.2)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Call Scheduled',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Incoming in ${_formatTime(_remainingSeconds)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelScheduledCall,
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

// Caller Presets
          const Text(
            'QUICK PRESETS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FakeCallService.getCallerPresets().map((preset) {
              return ChoiceChip(
                label: Text(preset['name']!),
                selected: _callerNameController.text == preset['name'],
                onSelected: (selected) {
                  if (selected) {
                    _vibrationService.light();
                    _selectPreset(preset);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

// Caller Details
          const Text(
            'CALLER DETAILS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _callerNameController,
            decoration: InputDecoration(
              labelText: 'Caller Name',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _callerNumberController,
            decoration: InputDecoration(
              labelText: 'Caller Number',
              prefixIcon: const Icon(Icons.phone),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

// Delay Selection
          const Text(
            'CALL DELAY',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFA5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FakeCallService.getDelayPresets().map((preset) {
              return ChoiceChip(
                label: Text(preset['label']),
                selected: _selectedDelaySeconds == preset['seconds'],
                onSelected: (selected) {
                  if (selected) {
                    _vibrationService.light();
                    setState(() => _selectedDelaySeconds = preset['seconds']);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

// Schedule Button
          if (_activeCallId == null)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isScheduling ? null : _scheduleFakeCall,
                icon: _isScheduling
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.phone_callback, size: 24),
                label: Text(
                  _isScheduling ? 'Scheduling...' : 'Schedule Fake Call',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

// Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1. Choose a caller preset or enter custom details\n'
                      '2. Select how long to wait before the call\n'
                      '3. Tap "Schedule Fake Call"\n'
                      '4. A realistic incoming call screen will appear\n'
                      '5. Answer or decline to exit the situation',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

// Use Cases
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      'Perfect for',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Awkward social situations\n'
                      '• Uncomfortable dates\n'
                      '• Pushy salespeople\n'
                      '• Feeling unsafe\n'
                      '• Need a polite exit',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}