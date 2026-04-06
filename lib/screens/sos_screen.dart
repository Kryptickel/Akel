import 'package:flutter/material.dart';
import '../services/sos_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({Key? key}) : super(key: key);

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with SingleTickerProviderStateMixin {
  final SOSService _sosService = SOSService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();

  bool _isFlashing = false;
  bool _isAvailable = false;
  int _selectedCycles = 0; // 0 = infinite
  int _currentCycle = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkFlashlight();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Update cycle count periodically
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _isFlashing) {
        final status = _sosService.getStatus();
        setState(() {
          _currentCycle = status['cycleCount'];
          _isFlashing = status['isFlashing'];
        });
      }
      return mounted;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sosService.stopSOS();
    super.dispose();
  }

  Future<void> _checkFlashlight() async {
    final available = await _sosService.isFlashlightAvailable();
    if (mounted) {
      setState(() {
        _isAvailable = available;
      });
    }
  }

  Future<void> _startSOS() async {
    await _vibrationService.warning();
    await _soundService.playWarning();

    final success = await _sosService.startSOS(cycles: _selectedCycles);

    if (success) {
      if (mounted) {
        setState(() {
          _isFlashing = true;
          _currentCycle = 0;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start SOS signal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopSOS() async {
    await _sosService.stopSOS();
    await _vibrationService.light();
    await _soundService.playClick();

    if (mounted) {
      setState(() {
        _isFlashing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.grey[100],
      appBar: AppBar(
        title: const Text('SOS Morse Code'),
        backgroundColor: Colors.red,
      ),
      body: !_isAvailable
          ? _buildUnavailableView(isDark)
          : _buildSOSView(isDark),
    );
  }

  Widget _buildUnavailableView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flashlight_off,
              size: 100,
              color: isDark ? Colors.white38 : Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Flashlight Not Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your device does not support flashlight functionality',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoCard(isDark),
          const SizedBox(height: 24),
          _buildSOSButton(isDark),
          const SizedBox(height: 24),
          if (!_isFlashing) _buildCycleSelector(isDark),
          if (!_isFlashing) const SizedBox(height: 24),
          if (_isFlashing) _buildStatusCard(isDark),
          const SizedBox(height: 24),
          _buildPatternInfo(isDark),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E2740) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.sos,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'SOS Distress Signal',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'International Morse code for emergency situations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // FIXED: Use .withValues to avoid precision loss warnings
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Use only in real emergencies',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Transform.scale(
        scale: _isFlashing ? _pulseAnimation.value : 1.0,
        child: GestureDetector(
          onTap: _isFlashing ? _stopSOS : _startSOS,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: _isFlashing
                    ? [
                  Colors.orange.withValues(alpha: 0.9),
                  Colors.orange.withValues(alpha: 0.6),
                  Colors.orange.withValues(alpha: 0.2),
                ]
                    : [
                  Colors.red.withValues(alpha: 1.0),
                  Colors.red.withValues(alpha: 0.8),
                  Colors.red.withValues(alpha: 0.4),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isFlashing ? Colors.orange : Colors.red).withValues(alpha: 0.6),
                  blurRadius: 50,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFlashing ? Icons.stop : Icons.flashlight_on,
                    size: 70,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isFlashing ? 'STOP' : 'START SOS',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleSelector(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E2740) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Number of Cycles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCycleChip('Infinite', 0, isDark),
                _buildCycleChip('3 cycles', 3, isDark),
                _buildCycleChip('5 cycles', 5, isDark),
                _buildCycleChip('10 cycles', 10, isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleChip(String label, int cycles, bool isDark) {
    final isSelected = _selectedCycles == cycles;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCycles = cycles;
          });
        }
      },
      selectedColor: Colors.red,
      backgroundColor: isDark ? const Color(0xFF2A3F5F) : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildStatusCard(bool isDark) {
    final isInfinite = _selectedCycles == 0;

    return Card(
      color: isDark ? const Color(0xFF1E2740) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text(
                  'SOS IN PROGRESS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'Current Cycle',
                  '${_currentCycle + 1}',
                  Icons.loop,
                  isDark,
                ),
                _buildStatusItem(
                  'Total Cycles',
                  isInfinite ? '∞' : '$_selectedCycles',
                  Icons.all_inclusive,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPatternInfo(bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1E2740) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00BFA5)),
                const SizedBox(width: 12),
                Text(
                  'Morse Code Pattern',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPatternRow('S', '· · ·', '3 short flashes', isDark),
            const SizedBox(height: 12),
            _buildPatternRow('O', '— — —', '3 long flashes', isDark),
            const SizedBox(height: 12),
            _buildPatternRow('S', '· · ·', '3 short flashes', isDark),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF00BFA5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'One cycle takes approximately ${(SOSService.cycleDuration / 1000).toStringAsFixed(1)} seconds',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternRow(String letter, String pattern, String description, bool isDark) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pattern,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}