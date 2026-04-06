import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/panic_service.dart';
import '../services/vibration_service.dart';
import '../services/sos_button_service.dart';

class FloatingSosButton extends StatefulWidget {
  const FloatingSosButton({super.key});

  @override
  State<FloatingSosButton> createState() => _FloatingSosButtonState();
}

class _FloatingSosButtonState extends State<FloatingSosButton>
    with SingleTickerProviderStateMixin {
  final PanicService _panicService = PanicService();
  final VibrationService _vibrationService = VibrationService();
  final SosButtonService _sosButtonService = SosButtonService();
  late AnimationController _pulseController;
  bool _isPressed = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _checkVisibility();
  }

  Future<void> _checkVisibility() async {
    final visible = await _sosButtonService.isSosButtonVisible();
    if (mounted) {
      setState(() => _isVisible = visible);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSOS() async {
    if (_isPressed) return;

    setState(() => _isPressed = true);

    await _vibrationService.error();

// Increment SOS button usage counter
    await _sosButtonService.incrementSosCount();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;
    final userName = authProvider.user?.displayName ?? 'User';

    if (userId != null) {
      try {
        await _panicService.triggerPanic(userId, userName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🚨 SOS Alert Sent!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ SOS trigger error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ SOS Failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

// Reset after 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
// Don't show button if visibility is disabled
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? 0.9 : (1.0 + (_pulseController.value * 0.1)),
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: _isPressed
                    ? [Colors.red[900]!, Colors.red[700]!]
                    : [Colors.red, Colors.red[700]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: _pulseController.value),
                  blurRadius: 20 + (_pulseController.value * 10),
                  spreadRadius: 5 + (_pulseController.value * 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isPressed ? null : _triggerSOS,
                borderRadius: BorderRadius.circular(35),
                child: Center(
                  child: _isPressed
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}