import 'package:flutter/material.dart';
import 'dart:async';

class FallDetectionDialog extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onTriggerPanic;

  const FallDetectionDialog({
    super.key,
    required this.onCancel,
    required this.onTriggerPanic,
  });

  @override
  State<FallDetectionDialog> createState() => _FallDetectionDialogState();
}

class _FallDetectionDialogState extends State<FallDetectionDialog> {
  int _countdown = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
      }

      if (_countdown <= 0) {
        timer.cancel();
        widget.onTriggerPanic();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.accessibility_new,
              color: Colors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Fall Detected!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // Countdown Circle
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _countdown / 30,
                  strokeWidth: 12,
                  color: _countdown <= 10 ? Colors.red : Colors.orange,
                  backgroundColor: Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_countdown',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'seconds',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            'We detected a possible fall. Emergency services will be notified in $_countdown seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Are you okay?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: widget.onCancel,
          child: const Text(
            'I\'m OK - Cancel',
            style: TextStyle(fontSize: 16),
          ),
        ),

        // Emergency button
        ElevatedButton(
          onPressed: widget.onTriggerPanic,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            'I Need Help!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}