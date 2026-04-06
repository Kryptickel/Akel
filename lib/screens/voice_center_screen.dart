import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/google_tts_service.dart';
import '../models/voice_profile.dart';
import '../models/voice_sample.dart';
import '../models/voice_analytics.dart';
import '../models/voice_schedule.dart';
import '../core/constants/themes/utils/akel_design_system.dart';
import '../widgets/glossy_3d_widgets.dart';

class VoiceCenterScreen extends StatefulWidget {
  const VoiceCenterScreen({super.key});

  @override
  State<VoiceCenterScreen> createState() => _VoiceCenterScreenState();
}

class _VoiceCenterScreenState extends State<VoiceCenterScreen>
    with SingleTickerProviderStateMixin {
  final GoogleTTSService _ttsService = GoogleTTSService();

  // Voice settings (existing)
  String _selectedVoiceId = 'en-US-Wavenet-F';
  String _selectedVoiceLang = 'en-US';
  String _selectedVoiceDisplay = ' American Female';
  double _volume = 1.0;
  double _speed = 1.0;
  double _pitch = 0.0;
  String _testText = 'Hello! This is a test of the selected voice.';

  // UI state (existing)
  late TabController _tabController;
  bool _isTesting = false;
  List<String> _favoriteVoices = [];
  String _searchQuery = '';

  // NEW: Additional features
  List<VoiceProfile> _profiles = [];
  VoiceProfile? _activeProfile;
  VoiceAnalytics _analytics = VoiceAnalytics.empty();
  List<VoiceScheduleEntry> _schedules = [];
  VoiceTone _selectedTone = VoiceTone.neutral;
  bool _accessibilityMode = false;
  bool _autoSwitchEnabled = true;
  bool _schedulingEnabled = true;

  // A/B Comparison
  String? _voiceA;
  String? _voiceB;
  String _comparisonText = 'This is a voice comparison test.';

  // Sample library
  List<VoiceSample> _samples = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this); // Changed from 5 to 10
    _samples = VoiceSample.getDefaultSamples();
    _loadAllSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // Basic settings
        _selectedVoiceDisplay = prefs.getString('current_voice_display') ?? ' American Female';
        _volume = prefs.getDouble('voice_volume') ?? 1.0;
        _speed = prefs.getDouble('voice_speed') ?? 1.0;
        _pitch = prefs.getDouble('voice_pitch') ?? 0.0;
        _favoriteVoices = prefs.getStringList('favorite_voices') ?? [];

        // Advanced settings
        _accessibilityMode = prefs.getBool('voice_accessibility') ?? false;
        _autoSwitchEnabled = prefs.getBool('voice_auto_switch') ?? true;
        _schedulingEnabled = prefs.getBool('voice_scheduling') ?? true;
      });

      // Load from service
      _profiles = _ttsService.getProfiles();
      _activeProfile = _ttsService.activeProfile;
      _analytics = _ttsService.getAnalytics();
      _schedules = _ttsService.getSchedules();

    } catch (e) {
      debugPrint('Error loading voice settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_voice_display', _selectedVoiceDisplay);
      await prefs.setDouble('voice_volume', _volume);
      await prefs.setDouble('voice_speed', _speed);
      await prefs.setDouble('voice_pitch', _pitch);
      await prefs.setStringList('favorite_voices', _favoriteVoices);
      await prefs.setBool('voice_accessibility', _accessibilityMode);
      await prefs.setBool('voice_auto_switch', _autoSwitchEnabled);
      await prefs.setBool('voice_scheduling', _schedulingEnabled);

      // Update TTS service
      await _ttsService.setVoice(_selectedVoiceId, _selectedVoiceLang);
      await _ttsService.setVoiceSettings(
        pitch: _pitch,
        speed: _speed,
        volume: _volume,
      );
      await _ttsService.setAccessibilityMode(_accessibilityMode);
      await _ttsService.setAutoSwitch(_autoSwitchEnabled);
      await _ttsService.setScheduling(_schedulingEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('All settings saved!'),
              ],
            ),
            backgroundColor: const Color(0xFF00BFA5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving voice settings: $e');
    }
  }

  Future<void> _testVoice() async {
    setState(() => _isTesting = true);

    try {
      await _ttsService.setVoice(_selectedVoiceId, _selectedVoiceLang);
      await _ttsService.setVoiceSettings(pitch: _pitch, speed: _speed, volume: _volume);
      await _ttsService.speak(_testText);
    } catch (e) {
      debugPrint('Error testing voice: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  void _toggleFavorite(String voiceId) {
    setState(() {
      if (_favoriteVoices.contains(voiceId)) {
        _favoriteVoices.remove(voiceId);
      } else {
        _favoriteVoices.add(voiceId);
      }
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCurrentVoiceCard(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllVoicesTab(), // Tab 1
                _buildProfilesTab(), // Tab 2 - NEW
                _buildSampleLibraryTab(), // Tab 3 - NEW
                _buildABComparisonTab(), // Tab 4 - NEW
                _buildSettingsTab(), // Tab 5 (was Tab 3)
                _buildAnalyticsTab(), // Tab 6 - NEW
                _buildRecommendationsTab(), // Tab 7 - NEW
                _buildSchedulingTab(), // Tab 8 - NEW
                _buildAccessibilityTab(), // Tab 9 - NEW
                _buildAdvancedTab(), // Tab 10 (was Tab 5)
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildTestButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AkelDesign.carbonFiber,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_voice, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Center',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Complete Voice Control',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline, color: Colors.white),
          onPressed: _showHelp,
          tooltip: 'Help',
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Color(0xFF00BFA5)),
          onPressed: _saveSettings,
          tooltip: 'Save All',
        ),
      ],
    );
  }

  Widget _buildCurrentVoiceCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.2),
            const Color(0xFF00E5FF).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.record_voice_over, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _activeProfile?.typeEmoji ?? ' ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Voice',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeProfile?.name ?? _selectedVoiceDisplay,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_activeProfile != null)
                      Text(
                        _activeProfile!.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      _favoriteVoices.contains(_selectedVoiceId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _favoriteVoices.contains(_selectedVoiceId)
                          ? Colors.red
                          : Colors.white70,
                    ),
                    onPressed: () => _toggleFavorite(_selectedVoiceId),
                  ),
                  Text(
                    _selectedTone.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickStat('Speed', '${_speed.toStringAsFixed(1)}x', Icons.speed),
              const SizedBox(width: 12),
              _buildQuickStat('Pitch', _pitch >= 0 ? '+${_pitch.toInt()}' : '${_pitch.toInt()}', Icons.graphic_eq),
              const SizedBox(width: 12),
              _buildQuickStat('Volume', '${(_volume * 100).toInt()}%', Icons.volume_up),
            ],
          ),
          if (_analytics.totalCharacters > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Uses', _analytics.usageByVoice.values.fold(0, (a, b) => a + b).toString()),
                  _buildMiniStat('Chars', _formatNumber(_analytics.totalCharacters)),
                  _buildMiniStat('Time', '${_analytics.totalDuration ~/ 60}m'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AkelDesign.carbonFiber.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00BFA5), size: 16),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF00BFA5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildTabBar() {
    return Container(
      color: AkelDesign.carbonFiber,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF00BFA5),
        labelColor: const Color(0xFF00BFA5),
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        tabs: const [
          Tab(icon: Icon(Icons.library_music, size: 20), text: 'All Voices'),
          Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Profiles'),
          Tab(icon: Icon(Icons.audiotrack, size: 20), text: 'Samples'),
          Tab(icon: Icon(Icons.compare, size: 20), text: 'Compare'),
          Tab(icon: Icon(Icons.tune, size: 20), text: 'Settings'),
          Tab(icon: Icon(Icons.analytics, size: 20), text: 'Analytics'),
          Tab(icon: Icon(Icons.recommend, size: 20), text: 'Suggest'),
          Tab(icon: Icon(Icons.schedule, size: 20), text: 'Schedule'),
          Tab(icon: Icon(Icons.accessibility, size: 20), text: 'Access'),
          Tab(icon: Icon(Icons.settings, size: 20), text: 'Advanced'),
        ],
      ),
    );
  }

  // =========================
  // TAB 1: ALL VOICES (Existing - Keep as is)
  // =========================

  Widget _buildAllVoicesTab() {
    final voiceCategories = _getVoiceCategories();

    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: voiceCategories.entries.map((category) {
              final filteredVoices = _searchQuery.isEmpty
                  ? category.value
                  : Map.fromEntries(
                category.value.entries.where((voice) =>
                    voice.key.toLowerCase().contains(_searchQuery.toLowerCase())
                ),
              );

              if (filteredVoices.isEmpty) return const SizedBox.shrink();

              return _buildVoiceCategory(category.key, filteredVoices);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BFA5).withOpacity(0.3),
        ),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search 40+ voices...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          icon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
          border: InputBorder.none,
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white70),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildVoiceCategory(String category, Map<String, Map<String, String>> voices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: const TextStyle(
                  color: Color(0xFF00BFA5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${voices.length})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ...voices.entries.map((voice) => _buildVoiceTile(
          voice.key,
          voice.value['id']!,
          voice.value['lang']!,
        )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildVoiceTile(String displayName, String voiceId, String lang) {
    final isSelected = _selectedVoiceId == voiceId;
    final isFavorite = _favoriteVoices.contains(voiceId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
        )
            : null,
        color: isSelected ? null : AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Colors.white.withOpacity(0.2)
              : const Color(0xFF00BFA5).withOpacity(0.2),
          child: Text(
            displayName.substring(0, 2),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF00BFA5),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          lang,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.white70,
                size: 20,
              ),
              onPressed: () => _toggleFavorite(voiceId),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 24),
              onPressed: () async {
                await _ttsService.setVoice(voiceId, lang);
                await _ttsService.speak('Hello! This is how I sound.');
              },
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
        onTap: () async {
          setState(() {
            _selectedVoiceId = voiceId;
            _selectedVoiceLang = lang;
            _selectedVoiceDisplay = displayName;
          });
          await _saveSettings();
          await _testVoice();
        },
      ),
    );
  }
  // =========================
  // TAB 2: PROFILES (NEW)
  // =========================

  Widget _buildProfilesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick profile switcher
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA5).withOpacity(0.1),
                const Color(0xFF00E5FF).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.flash_on, color: Color(0xFF00BFA5), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Quick Switch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildQuickProfileButton(VoiceProfile.personal()),
                  const SizedBox(width: 8),
                  _buildQuickProfileButton(VoiceProfile.medical()),
                  const SizedBox(width: 8),
                  _buildQuickProfileButton(VoiceProfile.emergency()),
                  const SizedBox(width: 8),
                  _buildQuickProfileButton(VoiceProfile.nightMode()),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // All profiles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Profiles',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _createNewProfile,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ..._profiles.map((profile) => _buildProfileCard(profile)),
      ],
    );
  }

  Widget _buildQuickProfileButton(VoiceProfile profile) {
    final isActive = _activeProfile?.id == profile.id;

    return Expanded(
      child: InkWell(
        onTap: () async {
          await _ttsService.applyProfile(profile);
          setState(() {
            _activeProfile = profile;
            _selectedVoiceId = profile.voiceId;
            _selectedVoiceLang = profile.voiceLang;
            _selectedVoiceDisplay = profile.voiceDisplay;
            _speed = profile.speed;
            _pitch = profile.pitch;
            _volume = profile.volume;
            _selectedTone = profile.tone;
          });
          await _saveSettings();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Switched to ${profile.name}'),
                backgroundColor: const Color(0xFF00BFA5),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
              colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
            )
                : null,
            color: isActive ? null : AkelDesign.carbonFiber,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Text(
                profile.typeEmoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                profile.name.split(' ').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(VoiceProfile profile) {
    final isActive = _activeProfile?.id == profile.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.3),
            const Color(0xFF00E5FF).withOpacity(0.2),
          ],
        )
            : null,
        color: isActive ? null : AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF00BFA5)
              : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFF00BFA5), const Color(0xFF00E5FF)]
                  : [
                const Color(0xFF00BFA5).withOpacity(0.3),
                const Color(0xFF00E5FF).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              profile.typeEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              profile.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildProfileBadge(profile.voiceDisplay.split(' ').first),
                  const SizedBox(width: 4),
                  _buildProfileBadge('${profile.speed.toStringAsFixed(1)}x'),
                  const SizedBox(width: 4),
                  _buildProfileBadge(profile.toneEmoji),
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow, color: Color(0xFF00BFA5)),
          onPressed: () async {
            await _ttsService.applyProfile(profile);
            setState(() => _activeProfile = profile);
            await _loadAllSettings();
          },
        ),
      ),
    );
  }

  Widget _buildProfileBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
        ),
      ),
    );
  }

  void _createNewProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom profile creation coming soon!'),
        backgroundColor: Color(0xFF00BFA5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================
  // TAB 3: SAMPLE LIBRARY (NEW)
  // =========================

  Widget _buildSampleLibraryTab() {
    final categories = VoiceSample.getCategories();
    final filteredSamples = _selectedCategory == 'All'
        ? _samples
        : _samples.where((s) => s.category == _selectedCategory).toList();

    return Column(
      children: [
        // Category filter
        Container(
          height: 50,
          margin: const EdgeInsets.all(16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: const Color(0xFF00BFA5),
                  backgroundColor: AkelDesign.carbonFiber,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              );
            },
          ),
        ),

        // Sample list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredSamples.length,
            itemBuilder: (context, index) {
              final sample = filteredSamples[index];
              return _buildSampleCard(sample);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSampleCard(VoiceSample sample) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
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
                  color: const Color(0xFF00BFA5).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.audiotrack, color: Color(0xFF00BFA5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${sample.category} • ~${sample.durationSeconds}s',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await _ttsService.speak(sample.text);
                },
                icon: const Icon(Icons.play_circle_filled, color: Color(0xFF00BFA5), size: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              sample.text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TAB 4: A/B COMPARISON (NEW)
  // =========================

  Widget _buildABComparisonTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA5).withOpacity(0.1),
                const Color(0xFF00E5FF).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.compare_arrows, color: Color(0xFF00BFA5), size: 48),
              SizedBox(height: 8),
              Text(
                'Compare Voices Side-by-Side',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                'Select two voices and hear the difference',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: _buildComparisonColumn('A', _voiceA)),
            const SizedBox(width: 16),
            Expanded(child: _buildComparisonColumn('B', _voiceB)),
          ],
        ),

        const SizedBox(height: 24),

        // Comparison text
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AkelDesign.carbonFiber,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Test Text:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _comparisonText),
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter text to compare...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => _comparisonText = value,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Play both button
        ElevatedButton.icon(
          onPressed: _voiceA != null && _voiceB != null
              ? () async {
            await _playComparisonVoice(_voiceA!);
            await Future.delayed(const Duration(seconds: 1));
            await _playComparisonVoice(_voiceB!);
          }
              : null,
          icon: const Icon(Icons.playlist_play),
          label: const Text('Play Both'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00BFA5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonColumn(String label, String? selectedVoice) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Voice $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AkelDesign.carbonFiber,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: selectedVoice == null
              ? InkWell(
            onTap: () => _selectComparisonVoice(label),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Color(0xFF00BFA5), size: 48),
                  SizedBox(height: 8),
                  Text(
                    'Tap to select',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selectedVoice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _playComparisonVoice(selectedVoice),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text('Play $label'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BFA5),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (label == 'A') {
                      _voiceA = null;
                    } else {
                      _voiceB = null;
                    }
                  });
                },
                child: const Text('Change', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _selectComparisonVoice(String label) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AkelDesign.darkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final voices = _getVoiceCategories();
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Voice $label',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: voices.entries.expand((category) {
                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          category.key,
                          style: const TextStyle(
                            color: Color(0xFF00BFA5),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...category.value.entries.map((voice) {
                        return ListTile(
                          title: Text(
                            voice.key,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          onTap: () {
                            setState(() {
                              if (label == 'A') {
                                _voiceA = voice.key;
                              } else {
                                _voiceB = voice.key;
                              }
                            });
                            Navigator.pop(context);
                          },
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playComparisonVoice(String voiceDisplay) async {
    final voices = _getVoiceCategories();
    String? voiceId;
    String? lang;

    for (var category in voices.values) {
      final entry = category.entries.firstWhere(
            (e) => e.key == voiceDisplay,
        orElse: () => const MapEntry('', {}),
      );
      if (entry.key.isNotEmpty) {
        voiceId = entry.value['id'];
        lang = entry.value['lang'];
        break;
      }
    }

    if (voiceId != null && lang != null) {
      await _ttsService.setVoice(voiceId, lang);
      await _ttsService.speak(_comparisonText);
    }
  }

  // =========================
  // TAB 5: SETTINGS (Existing - Enhanced)
  // =========================

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingCard(
          'Volume',
          Icons.volume_up,
          _volume,
          0.0,
          1.0,
              (value) => setState(() => _volume = value),
          '${(_volume * 100).toInt()}%',
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          'Speed',
          Icons.speed,
          _speed,
          0.5,
          2.0,
              (value) => setState(() => _speed = value),
          '${_speed.toStringAsFixed(1)}x',
        ),
        const SizedBox(height: 16),
        _buildSettingCard(
          'Pitch',
          Icons.graphic_eq,
          _pitch,
          -20.0,
          20.0,
              (value) => setState(() => _pitch = value),
          _pitch >= 0 ? '+${_pitch.toInt()}' : '${_pitch.toInt()}',
        ),
        const SizedBox(height: 24),

        // Voice Tone Selector (NEW)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AkelDesign.carbonFiber.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.mood, color: Color(0xFF00BFA5), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Voice Tone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: VoiceTone.values.map((tone) {
                  final isSelected = _selectedTone == tone;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedTone = tone);
                      _applyTone(tone);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                          colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                        )
                            : null,
                        color: isSelected ? null : AkelDesign.carbonFiber,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getToneEmoji(tone),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tone.toString().split('.').last,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _buildTestTextCard(),
        const SizedBox(height: 24),
        _buildSaveButton(),
      ],
    );
  }

  String _getToneEmoji(VoiceTone tone) {
    switch (tone) {
      case VoiceTone.friendly:
        return ' ';
      case VoiceTone.calm:
        return ' ';
      case VoiceTone.professional:
        return ' ';
      case VoiceTone.enthusiastic:
        return ' ';
      case VoiceTone.neutral:
        return ' ';
      case VoiceTone.empathetic:
        return ' ';
    }
  }

  void _applyTone(VoiceTone tone) {
    switch (tone) {
      case VoiceTone.friendly:
        setState(() {
          _speed = 1.1;
          _pitch = 2.0;
        });
        break;
      case VoiceTone.calm:
        setState(() {
          _speed = 0.9;
          _pitch = -2.0;
        });
        break;
      case VoiceTone.professional:
        setState(() {
          _speed = 1.0;
          _pitch = 0.0;
        });
        break;
      case VoiceTone.enthusiastic:
        setState(() {
          _speed = 1.2;
          _pitch = 5.0;
        });
        break;
      case VoiceTone.neutral:
        setState(() {
          _speed = 1.0;
          _pitch = 0.0;
        });
        break;
      case VoiceTone.empathetic:
        setState(() {
          _speed = 0.95;
          _pitch = 1.0;
        });
        break;
    }
  }

  Widget _buildSettingCard(
      String title,
      IconData icon,
      double value,
      double min,
      double max,
      Function(double) onChanged,
      String displayValue,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF00BFA5), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      ),
    );
  }

  Widget _buildTestTextCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.text_fields, color: Color(0xFF00BFA5), size: 24),
              SizedBox(width: 12),
              Text(
                'Test Text',
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
            controller: TextEditingController(text: _testText),
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter text to test the voice...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF00BFA5).withOpacity(0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF00BFA5),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) => _testText = value,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _saveSettings,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFA5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Save All Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  // =========================
  // TAB 6: ANALYTICS (NEW)
  // =========================

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview cards
        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Total Uses',
                _analytics.usageByVoice.values.fold(0, (a, b) => a + b).toString(),
                Icons.mic,
                const Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Characters',
                _formatNumber(_analytics.totalCharacters),
                Icons.text_fields,
                const Color(0xFF00E5FF),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildAnalyticsCard(
                'Duration',
                '${_analytics.totalDuration ~/ 60}m',
                Icons.timer,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAnalyticsCard(
                'Most Active',
                '${_analytics.mostActiveHour}:00',
                Icons.schedule,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Most used voice
        if (_analytics.usageByVoice.isNotEmpty) ...[
          const Text(
            'Voice Usage',
            style: TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          ..._analytics.usageByVoice.entries.map((entry) {
            final percentage = _analytics.getVoiceUsagePercentage(entry.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AkelDesign.carbonFiber.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Color(0xFF00BFA5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00BFA5)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),
        ],

        // Usage by context
        if (_analytics.usageByContext.isNotEmpty) ...[
          const Text(
            'Usage by Context',
            style: TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AkelDesign.carbonFiber.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _analytics.usageByContext.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          const SizedBox(width: 12),
                          Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        entry.value.toString(),
                        style: const TextStyle(
                          color: Color(0xFF00BFA5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        if (_analytics.totalCharacters == 0) ...[
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.analytics,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No analytics yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start using voices to see statistics',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
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
      ),
    );
  }

  // =========================
  // TAB 7: RECOMMENDATIONS (NEW)
  // =========================

  Widget _buildRecommendationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA5).withOpacity(0.2),
                const Color(0xFF00E5FF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF00BFA5), size: 48),
              SizedBox(height: 12),
              Text(
                'Smart Recommendations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI-powered voice suggestions based on your preferences',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Most popular
        const Row(
          children: [
            Icon(Icons.trending_up, color: Color(0xFF00BFA5), size: 20),
            SizedBox(width: 8),
            Text(
              'Most Popular',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildRecommendationCard(
          ' American Female',
          'en-US-Wavenet-F',
          'en-US',
          'Clear, warm, and professional - #1 choice',
        ),

        _buildRecommendationCard(
          ' British Female',
          'en-GB-Wavenet-A',
          'en-GB',
          'Elegant and sophisticated tone',
        ),

        const SizedBox(height: 24),

        // Best for medical
        const Row(
          children: [
            Icon(Icons.medical_services, color: Color(0xFF00BFA5), size: 20),
            SizedBox(width: 8),
            Text(
              'Best for Medical Conversations',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildRecommendationCard(
          ' Indian Female',
          'en-IN-Wavenet-A',
          'en-IN',
          'Warm, empathetic, perfect for healthcare',
        ),

        _buildRecommendationCard(
          ' British Male',
          'en-GB-Wavenet-B',
          'en-GB',
          'Authoritative and reassuring',
        ),

        const SizedBox(height: 24),

        // Best for emergencies
        const Row(
          children: [
            Icon(Icons.emergency, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Best for Emergencies',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildRecommendationCard(
          ' American Male',
          'en-US-Wavenet-D',
          'en-US',
          'Clear, urgent, and commanding',
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
      String displayName,
      String voiceId,
      String lang,
      String reason, {
        Color? color,
      }) {
    final isCurrentVoice = _selectedVoiceId == voiceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentVoice ? const Color(0xFF00BFA5) : Colors.white.withOpacity(0.1),
          width: isCurrentVoice ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (color ?? const Color(0xFF00BFA5)).withOpacity(0.3),
                (color ?? const Color(0xFF00E5FF)).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.recommend,
              color: color ?? const Color(0xFF00BFA5),
              size: 28,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              displayName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isCurrentVoice ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isCurrentVoice) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CURRENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            reason,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 24),
              onPressed: () async {
                await _ttsService.setVoice(voiceId, lang);
                await _ttsService.speak('Hello! This is how I sound.');
              },
            ),
            if (!isCurrentVoice)
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00BFA5), size: 24),
                onPressed: () async {
                  setState(() {
                    _selectedVoiceId = voiceId;
                    _selectedVoiceLang = lang;
                    _selectedVoiceDisplay = displayName;
                  });
                  await _saveSettings();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched to $displayName'),
                        backgroundColor: const Color(0xFF00BFA5),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  // =========================
  // TAB 8: SCHEDULING (NEW)
  // =========================

  Widget _buildSchedulingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Scheduling toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA5).withOpacity(0.2),
                const Color(0xFF00E5FF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF00BFA5), size: 32),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Scheduling',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Automatically switch voices by time',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _schedulingEnabled,
                onChanged: (value) async {
                  setState(() => _schedulingEnabled = value);
                  await _ttsService.setScheduling(value);
                  await _saveSettings();
                },
                activeColor: const Color(0xFF00BFA5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Schedule list
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Schedules',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_schedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AkelDesign.carbonFiber.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.schedule,
                  size: 64,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No schedules yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a schedule to automatically switch voices',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._schedules.map((schedule) => _buildScheduleCard(schedule)),

        const SizedBox(height: 24),

        // Coming soon message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Schedule creation coming soon! You can enable/disable scheduling for existing profiles.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(VoiceScheduleEntry schedule) {
    final isActive = schedule.isActiveNow();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.3),
            const Color(0xFF00E5FF).withOpacity(0.2),
          ],
        )
            : null,
        color: isActive ? null : AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF00BFA5) : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFF00BFA5), const Color(0xFF00E5FF)]
                  : [
                const Color(0xFF00BFA5).withOpacity(0.3),
                const Color(0xFF00E5FF).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.schedule, color: Colors.white, size: 28),
          ),
        ),
        title: Row(
          children: [
            Text(
              schedule.profileName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ACTIVE NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white60, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    schedule.timeRange,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white60, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    schedule.daysString,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TAB 9: ACCESSIBILITY (NEW)
  // =========================

  Widget _buildAccessibilityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(0.2),
                Colors.blue.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.accessibility_new, color: Colors.blue, size: 48),
              SizedBox(height: 12),
              Text(
                'Accessibility Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enhanced voice options for everyone',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Master accessibility toggle
        _buildAccessibilityToggle(
          'Accessibility Mode',
          'Optimizes voice for clarity and understanding',
          Icons.accessible,
          _accessibilityMode,
              (value) async {
            setState(() => _accessibilityMode = value);
            await _ttsService.setAccessibilityMode(value);
            await _saveSettings();
          },
        ),

        const SizedBox(height: 16),

        // Individual features
        _buildAccessibilityFeature(
          'Hearing Aid Compatible',
          'Optimized frequency range for hearing aids',
          Icons.hearing,
          true,
        ),

        _buildAccessibilityFeature(
          'Extra Clarity',
          'Enhanced consonants and clearer pronunciation',
          Icons.volume_up,
          _accessibilityMode,
        ),

        _buildAccessibilityFeature(
          'Slower Speed',
          'Reduced default speaking rate for easier comprehension',
          Icons.speed,
          _accessibilityMode,
        ),

        _buildAccessibilityFeature(
          'Extra Pauses',
          'Additional pauses between sentences',
          Icons.pause_circle,
          _accessibilityMode,
        ),

        const SizedBox(height: 24),

        // Recommended voices
        const Text(
          'Recommended Voices',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        _buildAccessibilityVoiceCard(
          ' American Female',
          'en-US-Wavenet-F',
          'en-US',
          'Clear articulation, excellent for hearing assistance',
        ),

        _buildAccessibilityVoiceCard(
          ' British Male',
          'en-GB-Wavenet-B',
          'en-GB',
          'Deep, authoritative tone with clear pronunciation',
        ),

        const SizedBox(height: 24),

        // Tips
        Container(
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
                  Icon(Icons.lightbulb_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tips for Better Accessibility',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTip('Use headphones for clearer sound'),
              _buildTip('Increase device volume to 70-80%'),
              _buildTip('Find a quiet environment'),
              _buildTip('Enable accessibility mode for medical conversations'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccessibilityToggle(
      String title,
      String description,
      IconData icon,
      bool value,
      Function(bool) onChanged,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value
              ? [
            Colors.blue.withOpacity(0.3),
            Colors.blue.withOpacity(0.2),
          ]
              : [
            AkelDesign.carbonFiber.withOpacity(0.5),
            AkelDesign.carbonFiber.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? Colors.blue : Colors.white.withOpacity(0.1),
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? Colors.blue : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityFeature(
      String title,
      String description,
      IconData icon,
      bool isActive,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? Colors.blue : Colors.white.withOpacity(0.5),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isActive ? Colors.white60 : Colors.white.withOpacity(0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            color: isActive ? Colors.blue : Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityVoiceCard(
      String displayName,
      String voiceId,
      String lang,
      String reason,
      ) {
    final isCurrentVoice = _selectedVoiceId == voiceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkelDesign.carbonFiber.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentVoice ? Colors.blue : Colors.white.withOpacity(0.1),
          width: isCurrentVoice ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.accessibility, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.blue, size: 28),
            onPressed: () async {
              await _ttsService.setVoice(voiceId, lang);
              await _ttsService.speak('Hello! This voice is optimized for accessibility.');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.check_circle, color: Colors.blue, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // =========================
  // TAB 10: ADVANCED (Enhanced)
  // =========================

  Widget _buildAdvancedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Context-aware switching
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BFA5).withOpacity(0.2),
                const Color(0xFF00E5FF).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF00BFA5), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Context-Aware Switching',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Switch(
                    value: _autoSwitchEnabled,
                    onChanged: (value) async {
                      setState(() => _autoSwitchEnabled = value);
                      await _ttsService.setAutoSwitch(value);
                      await _saveSettings();
                    },
                    activeColor: const Color(0xFF00BFA5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Automatically switch voices based on app context (emergency, medical chat, etc.)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),

              if (_autoSwitchEnabled) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auto-Switch Rules:',
                        style: TextStyle(
                          color: Color(0xFF00BFA5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAutoSwitchRule(' Panic Button', 'Emergency Profile'),
                      _buildAutoSwitchRule(' Doctor Annie', 'Medical Profile'),
                      _buildAutoSwitchRule(' Night (10PM-6AM)', 'Night Mode Profile'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Voice statistics
        const Text(
          'System Information',
          style: TextStyle(
            color: Color(0xFF00BFA5),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        RealisticGlassCard(
          child: Column(
            children: [
              _buildStatRow('Total Voices', '40+'),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Favorite Voices', '${_favoriteVoices.length}'),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Current Language', _selectedVoiceLang),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Engine', 'Google WaveNet'),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Profiles Created', '${_profiles.length}'),
              const Divider(color: Colors.white24, height: 24),
              _buildStatRow('Schedules Active', '${_schedules.where((s) => s.isEnabled).length}'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Quick Actions
        RealisticGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildActionButton('Reset to Default', Icons.refresh, () {
                setState(() {
                  _speed = 1.0;
                  _pitch = 0.0;
                  _volume = 1.0;
                  _selectedVoiceId = 'en-US-Wavenet-F';
                  _selectedVoiceLang = 'en-US';
                  _selectedVoiceDisplay = ' American Female';
                  _selectedTone = VoiceTone.neutral;
                  _accessibilityMode = false;
                });
                _saveSettings();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset to default settings'),
                      backgroundColor: Color(0xFF00BFA5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }),
              const SizedBox(height: 8),
              _buildActionButton('Clear Favorites', Icons.clear_all, () {
                setState(() => _favoriteVoices.clear());
                _saveSettings();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Favorites cleared'),
                      backgroundColor: Color(0xFF00BFA5),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSwitchRule(String trigger, String profile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF00BFA5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trigger,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          const Icon(Icons.arrow_forward, color: Colors.white38, size: 12),
          const SizedBox(width: 8),
          Text(
            profile,
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
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
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00BFA5),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AkelDesign.carbonFiber,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // FLOATING ACTION BUTTON
  // =========================

  Widget _buildTestButton() {
    return FloatingActionButton.extended(
      onPressed: _isTesting ? null : _testVoice,
      backgroundColor: _isTesting ? Colors.grey : const Color(0xFF00BFA5),
      icon: Icon(
        _isTesting ? Icons.hourglass_empty : Icons.play_arrow,
        color: Colors.white,
      ),
      label: Text(
        _isTesting ? 'Testing...' : 'Test Voice',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================
  // HELP DIALOG
  // =========================

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text('Voice Center Help', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection('All Voices', 'Browse and select from 40+ professional voices'),
              _buildHelpSection('Profiles', 'Save voice configurations for different contexts'),
              _buildHelpSection('Samples', 'Test voices with pre-written medical phrases'),
              _buildHelpSection('Compare', 'Compare two voices side-by-side'),
              _buildHelpSection('Settings', 'Adjust volume, speed, pitch, and tone'),
              _buildHelpSection('Analytics', 'Track your voice usage statistics'),
              _buildHelpSection('Recommendations', 'AI-powered voice suggestions'),
              _buildHelpSection('Scheduling', 'Auto-switch voices by time of day'),
              _buildHelpSection('Accessibility', 'Enhanced options for easier listening'),
              _buildHelpSection('Advanced', 'Context-aware switching and system info'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Tips:',
                      style: TextStyle(
                        color: Color(0xFF00BFA5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Tap to favorite a voice\n'
                          '• Tap to preview a voice\n'
                          '• Tap a voice to select it\n'
                          '• Swipe tabs to explore features\n'
                          '• Don\'t forget to save your settings!',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle,
              color: Color(0xFF00BFA5),
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // HELPER METHODS
  // =========================

  Map<String, Map<String, Map<String, String>>> _getVoiceCategories() {
    return {
      ' ENGLISH ACCENTS': {
        ' American Female': {'id': 'en-US-Wavenet-F', 'lang': 'en-US'},
        ' American Male': {'id': 'en-US-Wavenet-D', 'lang': 'en-US'},
        ' British Female': {'id': 'en-GB-Wavenet-A', 'lang': 'en-GB'},
        ' British Male': {'id': 'en-GB-Wavenet-B', 'lang': 'en-GB'},
        ' Indian Female': {'id': 'en-IN-Wavenet-A', 'lang': 'en-IN'},
        ' Indian Male': {'id': 'en-IN-Wavenet-B', 'lang': 'en-IN'},
        ' Australian Female': {'id': 'en-AU-Wavenet-A', 'lang': 'en-AU'},
        ' Australian Male': {'id': 'en-AU-Wavenet-B', 'lang': 'en-AU'},
        ' Canadian Female': {'id': 'en-US-Wavenet-C', 'lang': 'en-US'},
        ' Canadian Male': {'id': 'en-US-Wavenet-A', 'lang': 'en-US'},
        ' South African Female': {'id': 'en-GB-Wavenet-C', 'lang': 'en-GB'},
        ' South African Male': {'id': 'en-GB-Wavenet-D', 'lang': 'en-GB'},
      },
      ' ASIAN LANGUAGES': {
        ' Hindi Female': {'id': 'hi-IN-Wavenet-A', 'lang': 'hi-IN'},
        ' Hindi Male': {'id': 'hi-IN-Wavenet-B', 'lang': 'hi-IN'},
        ' Japanese Female': {'id': 'ja-JP-Wavenet-A', 'lang': 'ja-JP'},
        ' Japanese Male': {'id': 'ja-JP-Wavenet-C', 'lang': 'ja-JP'},
        ' Korean Female': {'id': 'ko-KR-Wavenet-A', 'lang': 'ko-KR'},
        ' Korean Male': {'id': 'ko-KR-Wavenet-C', 'lang': 'ko-KR'},
        ' Mandarin Female': {'id': 'cmn-CN-Wavenet-A', 'lang': 'cmn-CN'},
        ' Mandarin Male': {'id': 'cmn-CN-Wavenet-B', 'lang': 'cmn-CN'},
      },
      ' EUROPEAN LANGUAGES': {
        ' Spanish Female': {'id': 'es-ES-Wavenet-A', 'lang': 'es-ES'},
        ' Spanish Male': {'id': 'es-ES-Wavenet-B', 'lang': 'es-ES'},
        ' Mexican Spanish Female': {'id': 'es-US-Wavenet-A', 'lang': 'es-US'},
        ' Mexican Spanish Male': {'id': 'es-US-Wavenet-B', 'lang': 'es-US'},
        ' French Female': {'id': 'fr-FR-Wavenet-A', 'lang': 'fr-FR'},
        ' French Male': {'id': 'fr-FR-Wavenet-B', 'lang': 'fr-FR'},
        ' French Canadian Female': {'id': 'fr-CA-Wavenet-A', 'lang': 'fr-CA'},
        ' French Canadian Male': {'id': 'fr-CA-Wavenet-B', 'lang': 'fr-CA'},
        ' German Female': {'id': 'de-DE-Wavenet-A', 'lang': 'de-DE'},
        ' German Male': {'id': 'de-DE-Wavenet-B', 'lang': 'de-DE'},
        ' Italian Female': {'id': 'it-IT-Wavenet-A', 'lang': 'it-IT'},
        ' Italian Male': {'id': 'it-IT-Wavenet-C', 'lang': 'it-IT'},
        ' Portuguese Female': {'id': 'pt-BR-Wavenet-A', 'lang': 'pt-BR'},
        ' Portuguese Male': {'id': 'pt-BR-Wavenet-B', 'lang': 'pt-BR'},
        ' Russian Female': {'id': 'ru-RU-Wavenet-A', 'lang': 'ru-RU'},
        ' Russian Male': {'id': 'ru-RU-Wavenet-B', 'lang': 'ru-RU'},
      },
      ' OTHER LANGUAGES': {
        ' Arabic Female': {'id': 'ar-XA-Wavenet-A', 'lang': 'ar-XA'},
        ' Arabic Male': {'id': 'ar-XA-Wavenet-B', 'lang': 'ar-XA'},
        ' Turkish Female': {'id': 'tr-TR-Wavenet-A', 'lang': 'tr-TR'},
        ' Turkish Male': {'id': 'tr-TR-Wavenet-B', 'lang': 'tr-TR'},
        ' Indonesian Female': {'id': 'id-ID-Wavenet-A', 'lang': 'id-ID'},
        ' Indonesian Male': {'id': 'id-ID-Wavenet-B', 'lang': 'id-ID'},
        ' Vietnamese Female': {'id': 'vi-VN-Wavenet-A', 'lang': 'vi-VN'},
        ' Vietnamese Male': {'id': 'vi-VN-Wavenet-B', 'lang': 'vi-VN'},
        ' Thai Female': {'id': 'th-TH-Wavenet-A', 'lang': 'th-TH'},
      },
    };
  }

  Map<String, Map<String, String>> _getAllVoicesFlat() {
    final Map<String, Map<String, String>> allVoices = {};
    final categories = _getVoiceCategories();

    for (var category in categories.values) {
      for (var entry in category.entries) {
        allVoices[entry.value['id']!] = {
          'display': entry.key,
          'id': entry.value['id']!,
          'lang': entry.value['lang']!,
        };
      }
    }

    return allVoices;
  }
}


