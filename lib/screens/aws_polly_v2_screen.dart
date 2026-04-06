import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/aws_config.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== AWS POLLY V2 SCREEN ====================
///
/// PRODUCTION READY - BUILD 58 - FIXED & UPDATED
///
/// Features:
/// - Voice testing with Flutter TTS (replacing AWS Polly for now)
/// - Voice customization (rate, pitch, volume)
/// - Text input for testing
/// - Voice selection
/// - Usage tracking
/// - Cost estimation
///
/// Note: Using Flutter TTS as AWS Polly replacement for demo
/// In production, integrate actual AWS Polly SDK
///
/// ============================================================

class AwsPollyV2Screen extends StatefulWidget {
  const AwsPollyV2Screen({super.key});

  @override
  State<AwsPollyV2Screen> createState() => _AwsPollyV2ScreenState();
}

class _AwsPollyV2ScreenState extends State<AwsPollyV2Screen> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _textController = TextEditingController();

  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isLoading = true;

  // Voice settings
  String _selectedVoice = AWSConfig.voiceId;
  double _speechRate = 0.5; // 0.0 - 1.0 (0.5 = medium)
  double _pitch = 1.0; // 0.5 - 2.0 (1.0 = normal)
  double _volume = 1.0; // 0.0 - 1.0

  // Usage tracking
  int _totalCharactersSpoken = 0;
  int _totalRequests = 0;
  double _totalCost = 0.0;

  // Predefined test phrases
  final List<String> _testPhrases = [
    'Emergency! Calling 911 and notifying your emergency contacts.',
    'Routing you to City General Hospital, 5 minutes away. ER wait time: 15 minutes.',
    'Your safety score has dropped to 35. Entering high-crime area. Consider alternative route.',
    'Panic mode activated. All doors locked, lights on, cameras recording.',
    'Turn left in 200 feet onto Medical Center Drive. Destination on right.',
    'Warning: Unusual movement pattern detected. Possible follower.',
    'Check-in reminder: Please confirm you are safe.',
    'Your vital signs are being monitored. Heart rate: 72 BPM.',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTTS();
    _loadUsageStats();
  }

  @override
  void dispose() {
    _tts.stop();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initializeTTS() async {
    setState(() => _isLoading = true);

    try {
      // Initialize TTS
      await _tts.setLanguage(AWSConfig.languageCode);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Set up callbacks
      _tts.setStartHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = true);
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _isSpeaking = false);
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) {
          setState(() => _isSpeaking = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $msg'),
              backgroundColor: AkelDesign.errorRed,
            ),
          );
        }
      });

      setState(() {
        _isInitialized = true;
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: AkelDesign.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _totalCharactersSpoken = prefs.getInt('tts_total_chars') ?? 0;
        _totalRequests = prefs.getInt('tts_total_requests') ?? 0;
        _totalCost = prefs.getDouble('tts_total_cost') ?? 0.0;
      });
    } catch (e) {
      debugPrint('Error loading usage stats: $e');
    }
  }

  Future<void> _saveUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('tts_total_chars', _totalCharactersSpoken);
      await prefs.setInt('tts_total_requests', _totalRequests);
      await prefs.setDouble('tts_total_cost', _totalCost);
    } catch (e) {
      debugPrint('Error saving usage stats: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text to speak'),
          backgroundColor: AkelDesign.warningOrange,
        ),
      );
      return;
    }

    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    try {
      // Update settings
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Speak
      await _tts.speak(text);

      // Update usage stats
      setState(() {
        _totalCharactersSpoken += text.length;
        _totalRequests += 1;
        _totalCost += AWSConfig.calculateCost(text, neural: true);
      });

      await _saveUsageStats();

    } catch (e) {
      debugPrint('Error speaking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AkelDesign.errorRed,
        ),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _resetStats() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.carbonFiber,
        title: const Text(
          'Reset Statistics?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will reset all usage statistics.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AkelDesign.primaryRed,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _totalCharactersSpoken = 0;
        _totalRequests = 0;
        _totalCost = 0.0;
      });
      await _saveUsageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statistics reset'),
            backgroundColor: AkelDesign.successGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AWS Polly V2 (TTS Demo)'),
        backgroundColor: AkelDesign.carbonFiber,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Statistics',
            onPressed: _resetStats,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      backgroundColor: AkelDesign.deepBlack,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AkelDesign.neonBlue),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            _buildStatusBanner(),

            const SizedBox(height: 24),

            // Voice Selection
            _buildVoiceSelector(),

            const SizedBox(height: 24),

            // Voice Controls
            _buildVoiceControls(),

            const SizedBox(height: 24),

            // Text Input
            _buildTextInput(),

            const SizedBox(height: 24),

            // Quick Test Phrases
            _buildTestPhrases(),

            const SizedBox(height: 24),

            // Usage Statistics
            _buildUsageStats(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton.extended(
        onPressed: _isSpeaking
            ? _stopSpeaking
            : () => _speak(_textController.text),
        backgroundColor: _isSpeaking
            ? AkelDesign.errorRed
            : AkelDesign.neonBlue,
        icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up),
        label: Text(_isSpeaking ? 'Stop' : 'Speak'),
      )
          : null,
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AkelDesign.neonBlue.withValues(alpha: 0.2),
            Colors.purple.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AkelDesign.neonBlue.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isInitialized
                      ? AkelDesign.successGreen.withValues(alpha: 0.2)
                      : AkelDesign.warningOrange.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isInitialized ? Icons.check_circle : Icons.warning,
                  color: _isInitialized
                      ? AkelDesign.successGreen
                      : AkelDesign.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isInitialized ? 'TTS Engine Ready' : 'Initializing...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Using Flutter TTS (AWS Polly Demo)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(color: Colors.white24, height: 24),

          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  'Region',
                  AWSConfig.region.toUpperCase(),
                  Icons.public,
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Voice',
                  _selectedVoice,
                  Icons.record_voice_over,
                ),
              ),
              Expanded(
                child: _buildStatusItem(
                  'Engine',
                  AWSConfig.engine.toUpperCase(),
                  Icons.settings_voice,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AkelDesign.neonBlue, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.person, color: AkelDesign.neonBlue),
                const SizedBox(width: 12),
                const Text(
                  'Voice Selection',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _selectedVoice,
              dropdownColor: AkelDesign.carbonFiber,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Select Voice',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.record_voice_over, color: AkelDesign.neonBlue),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 2),
                ),
              ),
              items: AWSConfig.availableVoices.map((voice) {
                final gender = AWSConfig.getVoiceGender(voice);
                final description = AWSConfig.getVoiceDescription(voice);

                return DropdownMenuItem(
                  value: voice,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$voice ($gender)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVoice = value!);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Recommended: ${AWSConfig.getVoiceRecommendation(_selectedVoice)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControls() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: AkelDesign.neonBlue),
              const SizedBox(width: 12),
              const Text(
                'Voice Controls',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Speech Rate
          _buildSliderControl(
            'Speech Rate',
            _speechRate,
            0.0,
            1.0,
            Icons.speed,
                (value) {
              setState(() => _speechRate = value);
              _tts.setSpeechRate(value);
            },
            valueLabel: _getSpeechRateLabel(_speechRate),
          ),

          const SizedBox(height: 16),

          // Pitch
          _buildSliderControl(
            'Pitch',
            _pitch,
            0.5,
            2.0,
            Icons.graphic_eq,
                (value) {
              setState(() => _pitch = value);
              _tts.setPitch(value);
            },
            valueLabel: _getPitchLabel(_pitch),
          ),

          const SizedBox(height: 16),

          // Volume
          _buildSliderControl(
            'Volume',
            _volume,
            0.0,
            1.0,
            Icons.volume_up,
                (value) {
              setState(() => _volume = value);
              _tts.setVolume(value);
            },
            valueLabel: '${(_volume * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl(
      String label,
      double value,
      double min,
      double max,
      IconData icon,
      ValueChanged<double> onChanged, {
        String? valueLabel,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AkelDesign.neonBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AkelDesign.neonBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                valueLabel ?? value.toStringAsFixed(2),
                style: const TextStyle(
                  color: AkelDesign.neonBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AkelDesign.neonBlue,
            inactiveTrackColor: Colors.white24,
            thumbColor: AkelDesign.neonBlue,
            overlayColor: AkelDesign.neonBlue.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _getSpeechRateLabel(double rate) {
    if (rate < 0.25) return 'X-Slow';
    if (rate < 0.4) return 'Slow';
    if (rate < 0.6) return 'Medium';
    if (rate < 0.8) return 'Fast';
    return 'X-Fast';
  }

  String _getPitchLabel(double pitch) {
    if (pitch < 0.8) return 'Low';
    if (pitch < 1.2) return 'Normal';
    if (pitch < 1.6) return 'High';
    return 'X-High';
  }

  Widget _buildTextInput() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.text_fields, color: AkelDesign.neonBlue),
              const SizedBox(width: 12),
              const Text(
                'Custom Text',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _textController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter text to speak...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AkelDesign.neonBlue, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Text(
                  '${_textController.text.length} characters',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                'Est. cost: ${AWSConfig.formatCost(AWSConfig.calculateCost(_textController.text))}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestPhrases() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.format_quote, color: AkelDesign.neonBlue),
                const SizedBox(width: 12),
                const Text(
                  'Quick Test Phrases',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _testPhrases.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withValues(alpha: 0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final phrase = _testPhrases[index];

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AkelDesign.neonBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: AkelDesign.neonBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  phrase,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(
                    _isSpeaking ? Icons.stop : Icons.play_arrow,
                    color: AkelDesign.neonBlue,
                  ),
                  onPressed: () => _speak(phrase),
                ),
                onTap: () {
                  _textController.text = phrase;
                  setState(() {});
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStats() {
    return Container(
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AkelDesign.successGreen),
              const SizedBox(width: 12),
              const Text(
                'Usage Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Characters',
                  _totalCharactersSpoken.toString(),
                  Icons.text_fields,
                  AkelDesign.neonBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Requests',
                  _totalRequests.toString(),
                  Icons.sync,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildStatCard(
            'Total Cost (Neural)',
            AWSConfig.formatCost(_totalCost),
            Icons.attach_money,
            AkelDesign.successGreen,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color, {
        bool fullWidth = false,
      }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: fullWidth
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.carbonFiber,
        title: const Text(
          'AWS Polly V2 Info',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Configuration:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Region', AWSConfig.region),
              _buildInfoRow('Engine', AWSConfig.engine),
              _buildInfoRow('Language', AWSConfig.languageCode),
              _buildInfoRow('Voice', _selectedVoice),

              const Divider(color: Colors.white24, height: 24),

              const Text(
                'Pricing:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Neural',
                '\$${AWSConfig.costPerMillionCharsNeural}/M chars',
              ),
              _buildInfoRow(
                'Standard',
                '\$${AWSConfig.costPerMillionCharsStandard}/M chars',
              ),

              const Divider(color: Colors.white24, height: 24),

              Text(
                'Note: Currently using Flutter TTS for demo purposes. In production, this will use actual AWS Polly Neural TTS.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AkelDesign.neonBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}