import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/enhanced_aws_polly_service.dart';
import '../services/google_tts_service.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import 'voice_center_screen.dart';

/// ==================== VOICE SETTINGS SCREEN ====================
///
/// Unified voice settings for Doctor Annie
/// Supports both AWS Polly and Google Cloud TTS
/// Quick access to Voice Center
///
/// BUILD 55 - Voice Center Integration
/// ================================================================

class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final GoogleTTSService _googleTTS = GoogleTTSService();

  TTSProvider _selectedProvider = TTSProvider.awsPolly;
  PollyVoice _selectedPollyVoice = PollyVoice.joanna;
  String _selectedGoogleVoice = 'en-US-Wavenet-F';
  String _selectedGoogleLang = 'en-US';

  double _volume = 1.0;
  double _speed = 1.0;
  double _pitch = 0.0;

  bool _isTestPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _pollyService.initialize();
    await _googleTTS.initialize();

    setState(() {
      _selectedProvider = _pollyService.currentProvider;
      _selectedPollyVoice = _pollyService.currentVoice;
      _volume = _pollyService.currentVolume;
      _speed = _pollyService.currentSpeechRate;
      _pitch = _pollyService.currentPitch;

      // Load Google settings
      _selectedGoogleVoice = _pollyService.googleVoiceId;
      _selectedGoogleLang = _pollyService.googleVoiceLang;
    });
  }

  Future<void> _saveSettings() async {
    await _pollyService.setProvider(_selectedProvider);
    await _pollyService.setVoice(_selectedPollyVoice);
    await _pollyService.setGoogleVoice(_selectedGoogleVoice, _selectedGoogleLang);
    await _pollyService.setVoiceSettings(
      volume: _volume,
      speed: _speed,
      pitch: _pitch,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Voice settings saved!'),
            ],
          ),
          backgroundColor: const Color(0xFF00BFA5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _testVoice() async {
    if (_isTestPlaying) return;

    setState(() => _isTestPlaying = true);

    try {
      await _pollyService.setProvider(_selectedProvider);
      await _pollyService.setVoice(_selectedPollyVoice);
      await _pollyService.setGoogleVoice(_selectedGoogleVoice, _selectedGoogleLang);
      await _pollyService.setVoiceSettings(
        volume: _volume,
        speed: _speed,
        pitch: _pitch,
      );

      final voiceName = _selectedProvider == TTSProvider.awsPolly
          ? _selectedPollyVoice.displayName
          : 'Google TTS';

      await _pollyService.speak(
        'Hello! I am Doctor Annie, your AI health assistant. This is how I sound with $voiceName voice.',
      );
    } catch (e) {
      debugPrint('Test voice error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing voice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isTestPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.settings_voice, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text(
              'Voice Settings',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF00BFA5)),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Voice Center Quick Access
          _buildVoiceCenterCard(),

          const SizedBox(height: 24),

          // Provider Selection
          _buildProviderSelector(),

          const SizedBox(height: 24),

          // Voice Selection based on provider
          if (_selectedProvider == TTSProvider.awsPolly)
            _buildPollyVoiceSelector()
          else
            _buildGoogleVoiceSelector(),

          const SizedBox(height: 24),

          // Voice Parameters
          _buildVoiceParameters(),

          const SizedBox(height: 24),

          // Test Button
          _buildTestButton(),

          const SizedBox(height: 24),

          // Info Card
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildVoiceCenterCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoiceCenterScreen()),
        );
        // Reload settings after returning
        _loadSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF00BFA5).withOpacity(0.3),
              const Color(0xFF00E5FF).withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00BFA5).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings_voice, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Center',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Access 50+ professional voices',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Profiles • Analytics • Scheduling • Accessibility',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildProviderSelector() {
    return RealisticGlassCard(
      enable3D: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hub, color: Color(0xFF00BFA5), size: 24),
              SizedBox(width: 12),
              Text(
                'Voice Provider',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AWS Polly Option
          _buildProviderOption(
            TTSProvider.awsPolly,
            'AWS Polly',
            'Premium neural voices (Joanna, Matthew, Amy, etc.)',
            Icons.cloud,
            Colors.orange,
          ),

          const SizedBox(height: 12),

          // Google TTS Option
          _buildProviderOption(
            TTSProvider.googleTTS,
            'Google Cloud TTS',
            '40+ WaveNet voices from Voice Center',
            Icons.g_mobiledata,
            const Color(0xFF00BFA5),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderOption(
      TTSProvider provider,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      ) {
    final isSelected = _selectedProvider == provider;

    return InkWell(
      onTap: () => setState(() => _selectedProvider = provider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          )
              : null,
          color: isSelected ? null : AkelDesign.carbonFiber.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildPollyVoiceSelector() {
    return RealisticGlassCard(
      enable3D: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'AWS Polly Voice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Polly voice list
          ...PollyVoice.values.map((voice) {
            final isSelected = _selectedPollyVoice.voiceId == voice.voiceId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedPollyVoice = voice),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.3),
                        Colors.orange.withOpacity(0.1),
                      ],
                    )
                        : null,
                    color: isSelected ? null : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.orange : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        voice.gender == 'Female' ? Icons.face : Icons.face_2,
                        color: isSelected ? Colors.orange : Colors.white70,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voice.displayName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${voice.gender} • ${voice.languageCode}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.orange, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGoogleVoiceSelector() {
    return RealisticGlassCard(
      enable3D: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.g_mobiledata, color: Color(0xFF00BFA5), size: 32),
              const SizedBox(width: 8),
              const Text(
                'Google Cloud Voice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BFA5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current: $_selectedGoogleVoice',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'For full access to 40+ voices, visit Voice Center',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VoiceCenterScreen()),
              );
              _loadSettings();
            },
            icon: const Icon(Icons.settings_voice),
            label: const Text('Open Voice Center'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BFA5),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceParameters() {
    return RealisticGlassCard(
      enable3D: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Color(0xFF00BFA5), size: 24),
              SizedBox(width: 12),
              Text(
                'Voice Parameters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Volume
          _buildSlider(
            'Volume',
            Icons.volume_up,
            _volume,
            0.0,
            1.0,
                (value) => setState(() => _volume = value),
            '${(_volume * 100).toInt()}%',
          ),

          const SizedBox(height: 24),

          // Speed
          _buildSlider(
            'Speed',
            Icons.speed,
            _speed,
            0.5,
            2.0,
                (value) => setState(() => _speed = value),
            '${_speed.toStringAsFixed(1)}x',
          ),

          const SizedBox(height: 24),

          // Pitch (Google TTS only)
          if (_selectedProvider == TTSProvider.googleTTS)
            _buildSlider(
              'Pitch',
              Icons.graphic_eq,
              _pitch,
              -20.0,
              20.0,
                  (value) => setState(() => _pitch = value),
              _pitch >= 0 ? '+${_pitch.toInt()}' : '${_pitch.toInt()}',
            ),
        ],
      ),
    );
  }

  Widget _buildSlider(
      String label,
      IconData icon,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      String displayValue,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00BFA5), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00BFA5),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: const Color(0xFF00E5FF),
            overlayColor: const Color(0xFF00BFA5).withOpacity(0.3),
            trackHeight: 4,
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

  Widget _buildTestButton() {
    return Glossy3DButton(
      text: _isTestPlaying ? 'Playing...' : 'Test Voice',
      icon: _isTestPlaying ? Icons.hourglass_empty : Icons.play_arrow,
      onPressed: _isTestPlaying ? () {} : _testVoice,
      color: _isTestPlaying ? Colors.grey : const Color(0xFF00BFA5),
      width: double.infinity,
      height: 56,
      elevation: 8,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Voice Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Current Provider', _selectedProvider == TTSProvider.awsPolly ? 'AWS Polly' : 'Google TTS'),
          const SizedBox(height: 8),
          _buildInfoRow('Current Voice', _selectedProvider == TTSProvider.awsPolly ? _selectedPollyVoice.displayName : _selectedGoogleVoice),
          const SizedBox(height: 8),
          _buildInfoRow('Total Voices Available', '50+'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00BFA5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}