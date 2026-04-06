import 'package:flutter/material.dart';
import '../services/trusted_person_service.dart';
import '../services/vibration_service.dart';

class PinVerifyScreen extends StatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  State<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends State<PinVerifyScreen> {
  final TrustedPersonService _pinService = TrustedPersonService();
  final VibrationService _vibrationService = VibrationService();
  final TextEditingController _pinController = TextEditingController();

  bool _isVerifying = false;
  TrustedPersonPin? _verifiedPin;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();

    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ PIN must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);
    await _vibrationService.light();

    final verifiedPin = await _pinService.verifyPin(pin);

    if (mounted) {
      setState(() {
        _isVerifying = false;
        _verifiedPin = verifiedPin;
      });

      if (verifiedPin != null) {
        await _vibrationService.success();
        _showStatusSelectionDialog(verifiedPin);
      } else {
        await _vibrationService.error();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid or expired PIN'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showStatusSelectionDialog(TrustedPersonPin pin) async {
    final status = await showDialog<TrustedPersonStatus>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Safety Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hi ${pin.contactName}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please confirm your current status:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(
                context,
                TrustedPersonStatus.safe,
              ),
              icon: const Icon(Icons.check_circle, size: 32),
              label: const Text(
                "I'm Safe",
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 60),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(
                context,
                TrustedPersonStatus.needHelp,
              ),
              icon: const Icon(Icons.sos, size: 32),
              label: const Text(
                'I Need Help',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                minimumSize: const Size(double.infinity, 60),
              ),
            ),
          ],
        ),
      ),
    );

    if (status != null && mounted) {
      final success = await _pinService.updateStatus(
        pinId: pin.id,
        status: status,
      );

      if (success && mounted) {
        await _vibrationService.success();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              status == TrustedPersonStatus.safe
                  ? '✅ Status Updated'
                  : '🆘 Help Alert Sent',
            ),
            content: Text(
              status == TrustedPersonStatus.safe
                  ? 'Your safety status has been confirmed. The person who sent you this PIN will be notified.'
                  : 'Emergency services have been alerted. Help is on the way.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify PIN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_open,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Enter Your PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter the 6-digit PIN you received',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 16,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: '000000',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: (_) => _verifyPin(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying ? null : _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Verify PIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}