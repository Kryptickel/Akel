import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/doctor_annie_appearance.dart';
import '../models/doctor_annie_personality.dart';
import '../models/doctor_annie_voice_config.dart';
import '../widgets/doctor_annie_avatar_widget.dart';
import '../services/facial_animation_service.dart';
import '../services/aws_polly_service.dart';

/// Doctor Annie Complete Customization Screen
class DoctorAnnieCustomizerScreen extends StatefulWidget {
  const DoctorAnnieCustomizerScreen({super.key});

  @override
  State<DoctorAnnieCustomizerScreen> createState() =>
      _DoctorAnnieCustomizerScreenState();
}

class _DoctorAnnieCustomizerScreenState
    extends State<DoctorAnnieCustomizerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

// Default Pixar-style appearance
  DoctorAnnieAppearance _appearance = const DoctorAnnieAppearance(
    hairStyle: HairStyle.braided,
    hairLength: HairLength.long,
    hairColor: Color(0xFF2C1810), // Dark brown
    ethnicity: EthnicityType.indian,
    skinTone: Color(0xFFC68642), // Warm tan
    ageAppearance: AgeAppearance.twenties,
    hasGlasses: false,
    clothing: ClothingType.labCoat,
    clothingColor: Colors.white,
    hasStethoscope: true,
    hasTablet: false,
    hasMedicalBag: false,
    glossyIntensity: 0.8,
    glassyTransparency: 0.3,
    enableReflections: true,
    enableShadows: true,
  );

  DoctorAnniePersonality _personality = const DoctorAnniePersonality(
    bedsideManner: BedsideManner.warm,
    communicationStyle: CommunicationStyle.balanced,
    emotionalResponse: EmotionalResponseLevel.moderate,
    questionApproach: QuestionApproach.thorough,
    humorLevel: HumorLevel.light,
    isEncouraging: true,
    isEmpathetic: true,
    isEducational: true,
  );

  DoctorAnnieVoiceConfig _voiceConfig = const DoctorAnnieVoiceConfig(
    pitch: VoicePitch.medium,
    speakingSpeed: 1.0,
    accent: VoiceAccent.indian,
    formality: FormalityLevel.professional,
    verbosity: VerbosityLevel.balanced,
    pollyVoiceId: 'Aditi',
    volume: 1.0,
    enableEmphasis: true,
  );

  final FacialAnimationService _facialService = FacialAnimationService();
  final AwsPollyService _pollyService = AwsPollyService();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedCustomization();
    _facialService.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCustomization() async {
    final prefs = await SharedPreferences.getInstance();

    final appearanceJson = prefs.getString('doctor_annie_appearance');
    if (appearanceJson != null) {
      setState(() {
        _appearance = DoctorAnnieAppearance.fromJson(jsonDecode(appearanceJson));
      });
    }

    final personalityJson = prefs.getString('doctor_annie_personality');
    if (personalityJson != null) {
      setState(() {
        _personality = DoctorAnniePersonality.fromJson(jsonDecode(personalityJson));
      });
    }

    final voiceJson = prefs.getString('doctor_annie_voice');
    if (voiceJson != null) {
      setState(() {
        _voiceConfig = DoctorAnnieVoiceConfig.fromJson(jsonDecode(voiceJson));
      });
    }
  }

  Future<void> _saveCustomization() async {
    setState(() => _isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('doctor_annie_appearance', jsonEncode(_appearance.toJson()));
    await prefs.setString('doctor_annie_personality', jsonEncode(_personality.toJson()));
    await prefs.setString('doctor_annie_voice', jsonEncode(_voiceConfig.toJson()));

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Doctor Annie customization saved!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testVoice() async {
    final greeting = _personality.getGreeting();

    _facialService.startLipSync(
      greeting,
      duration: Duration(milliseconds: greeting.length * 80),
    );

    await _pollyService.speak(
      text: greeting,
      voiceId: _voiceConfig.getPollyVoiceIdForAccent(),
      engine: _voiceConfig.pollyEngine,
      rate: _voiceConfig.speakingSpeed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Doctor Annie'),
        backgroundColor: const Color(0xFF2C5F7C),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Test Voice',
            onPressed: _testVoice,
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save Changes',
              onPressed: _saveCustomization,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.face), text: 'Appearance'),
            Tab(icon: Icon(Icons.psychology), text: 'Personality'),
            Tab(icon: Icon(Icons.record_voice_over), text: 'Voice'),
            Tab(icon: Icon(Icons.preview), text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppearanceTab(),
          _buildPersonalityTab(),
          _buildVoiceTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

// ==================== APPEARANCE TAB ====================

  Widget _buildAppearanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Hair Style'),
        _buildHairStyleSelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Hair Color'),
        _buildColorPicker(
          currentColor: _appearance.hairColor,
          onColorChanged: (color) {
            setState(() {
              _appearance = _appearance.copyWith(hairColor: color);
            });
          },
          presetColors: [
            const Color(0xFF000000), // Black
            const Color(0xFF2C1810), // Dark brown
            const Color(0xFF8B4513), // Brown
            const Color(0xFFFFA500), // Blonde
            const Color(0xFFDC143C), // Red
            const Color(0xFF808080), // Gray
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Skin Tone'),
        _buildColorPicker(
          currentColor: _appearance.skinTone,
          onColorChanged: (color) {
            setState(() {
              _appearance = _appearance.copyWith(skinTone: color);
            });
          },
          presetColors: [
            const Color(0xFFFFF0DC), // Very light
            const Color(0xFFFFDBAC), // Light
            const Color(0xFFC68642), // Tan
            const Color(0xFF8D5524), // Brown
            const Color(0xFF654321), // Dark brown
            const Color(0xFF3D2817), // Very dark
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Ethnicity'),
        _buildEthnicitySelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Age Appearance'),
        _buildAgeSelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Glasses'),
        SwitchListTile(
          title: const Text('Wear Glasses'),
          value: _appearance.hasGlasses,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(hasGlasses: value);
            });
          },
        ),
        if (_appearance.hasGlasses) _buildGlassesStyleSelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Clothing'),
        _buildClothingSelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Accessories'),
        SwitchListTile(
          title: const Text('Stethoscope'),
          value: _appearance.hasStethoscope,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(hasStethoscope: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Tablet'),
          value: _appearance.hasTablet,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(hasTablet: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Medical Bag'),
          value: _appearance.hasMedicalBag,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(hasMedicalBag: value);
            });
          },
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Visual Effects'),
        _buildSlider(
          label: 'Glossy Intensity',
          value: _appearance.glossyIntensity,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(glossyIntensity: value);
            });
          },
        ),
        _buildSlider(
          label: 'Glass Transparency',
          value: _appearance.glassyTransparency,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(glassyTransparency: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Enable Reflections'),
          value: _appearance.enableReflections,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(enableReflections: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Enable Shadows'),
          value: _appearance.enableShadows,
          onChanged: (value) {
            setState(() {
              _appearance = _appearance.copyWith(enableShadows: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildHairStyleSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: HairStyle.values.map((style) {
        final isSelected = _appearance.hairStyle == style;
        return ChoiceChip(
          label: Text(style.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _appearance = _appearance.copyWith(hairStyle: style);
              });
            }
          },
          selectedColor: Colors.blue.withValues(alpha: 0.3),
        );
      }).toList(),
    );
  }

  Widget _buildEthnicitySelector() {
    return DropdownButtonFormField<EthnicityType>(
      value: _appearance.ethnicity,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: EthnicityType.values.map((ethnicity) {
        return DropdownMenuItem(
          value: ethnicity,
          child: Text(ethnicity.name.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _appearance = _appearance.copyWith(ethnicity: value);
          });
        }
      },
    );
  }

  Widget _buildAgeSelector() {
    return SegmentedButton<AgeAppearance>(
      segments: AgeAppearance.values.map((age) {
        return ButtonSegment(
          value: age,
          label: Text(age.name.toUpperCase()),
        );
      }).toList(),
      selected: {_appearance.ageAppearance},
      onSelectionChanged: (Set<AgeAppearance> selected) {
        setState(() {
          _appearance = _appearance.copyWith(ageAppearance: selected.first);
        });
      },
    );
  }

  Widget _buildGlassesStyleSelector() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: GlassesStyle.values.map((style) {
          final isSelected = _appearance.glassesStyle == style;
          return ChoiceChip(
            label: Text(style.name.toUpperCase()),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _appearance = _appearance.copyWith(glassesStyle: style);
                });
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildClothingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ClothingType.values.map((type) {
            final isSelected = _appearance.clothing == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _appearance = _appearance.copyWith(clothing: type);
                  });
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text('Clothing Color:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildColorPicker(
          currentColor: _appearance.clothingColor,
          onColorChanged: (color) {
            setState(() {
              _appearance = _appearance.copyWith(clothingColor: color);
            });
          },
          presetColors: [
            Colors.white,
            Colors.blue,
            Colors.green,
            Colors.grey,
            Colors.black,
            Colors.purple,
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required Color currentColor,
    required ValueChanged<Color> onColorChanged,
    required List<Color> presetColors,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: presetColors.map((color) {
        final isSelected = currentColor.value == color.value;
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ${(value * 100).toInt()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
          divisions: 10,
        ),
      ],
    );
  }

// ==================== PERSONALITY TAB ====================

  Widget _buildPersonalityTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Bedside Manner'),
        _buildBedsideMannerSelector(),
        const SizedBox(height: 24),

        _buildSectionHeader('Communication Style'),
        _buildDropdown<CommunicationStyle>(
          value: _personality.communicationStyle,
          items: CommunicationStyle.values,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(communicationStyle: value);
            });
          },
          itemLabel: (style) => style.name.toUpperCase(),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Emotional Response Level'),
        _buildDropdown<EmotionalResponseLevel>(
          value: _personality.emotionalResponse,
          items: EmotionalResponseLevel.values,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(emotionalResponse: value);
            });
          },
          itemLabel: (level) => level.name.toUpperCase().replaceAll('_', ' '),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Question Approach'),
        _buildDropdown<QuestionApproach>(
          value: _personality.questionApproach,
          items: QuestionApproach.values,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(questionApproach: value);
            });
          },
          itemLabel: (approach) => approach.name.toUpperCase(),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Humor Level'),
        _buildDropdown<HumorLevel>(
          value: _personality.humorLevel,
          items: HumorLevel.values,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(humorLevel: value);
            });
          },
          itemLabel: (level) => level.name.toUpperCase(),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Professional Traits'),
        SwitchListTile(
          title: const Text('Encouraging'),
          subtitle: const Text('Provides positive reinforcement'),
          value: _personality.isEncouraging,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(isEncouraging: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Empathetic'),
          subtitle: const Text('Shows understanding and compassion'),
          value: _personality.isEmpathetic,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(isEmpathetic: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Directive'),
          subtitle: const Text('Gives clear instructions and guidance'),
          value: _personality.isDirective,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(isDirective: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Educational'),
          subtitle: const Text('Focuses on teaching and explaining'),
          value: _personality.isEducational,
          onChanged: (value) {
            setState(() {
              _personality = _personality.copyWith(isEducational: value);
            });
          },
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Sample Greeting'),
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _personality.getGreeting(),
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBedsideMannerSelector() {
    return Column(
      children: BedsideManner.values.map((manner) {
        final isSelected = _personality.bedsideManner == manner;
        return RadioListTile<BedsideManner>(
          title: Text(manner.displayName),
          subtitle: Text(manner.description),
          value: manner,
          groupValue: _personality.bedsideManner,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _personality = _personality.copyWith(bedsideManner: value);
              });
            }
          },
          selected: isSelected,
        );
      }).toList(),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(itemLabel(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

// ==================== VOICE TAB ====================

  Widget _buildVoiceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Voice Pitch'),
        _buildSegmentedButton<VoicePitch>(
          selected: _voiceConfig.pitch,
          segments: VoicePitch.values,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(pitch: value);
            });
          },
          labelBuilder: (pitch) => pitch.name.toUpperCase(),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Speaking Speed'),
        _buildSlider(
          label: 'Speed',
          value: _voiceConfig.speakingSpeed,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(speakingSpeed: value);
            });
          },
        ),
        Text(
          'Current: ${(_voiceConfig.speakingSpeed * 100).toInt()}%',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Accent'),
        _buildDropdown<VoiceAccent>(
          value: _voiceConfig.accent,
          items: VoiceAccent.values,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _voiceConfig = _voiceConfig.copyWith(accent: value);
              });
            }
          },
          itemLabel: (accent) => accent.displayName,
        ),
        const SizedBox(height: 8),
        Text(
          'Polly Voice: ${_voiceConfig.getPollyVoiceIdForAccent()}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Formality Level'),
        _buildDropdown<FormalityLevel>(
          value: _voiceConfig.formality,
          items: FormalityLevel.values,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _voiceConfig = _voiceConfig.copyWith(formality: value);
              });
            }
          },
          itemLabel: (level) => level.displayName,
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.amber.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Example: ${_voiceConfig.formality.example}',
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Verbosity Level'),
        _buildDropdown<VerbosityLevel>(
          value: _voiceConfig.verbosity,
          items: VerbosityLevel.values,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _voiceConfig = _voiceConfig.copyWith(verbosity: value);
              });
            }
          },
          itemLabel: (level) => level.name.toUpperCase(),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Volume'),
        _buildSlider(
          label: 'Volume',
          value: _voiceConfig.volume,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(volume: value);
            });
          },
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Audio Effects'),
        SwitchListTile(
          title: const Text('Enable Emphasis'),
          subtitle: const Text('Adds emotional emphasis to speech'),
          value: _voiceConfig.enableEmphasis,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(enableEmphasis: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Enable Breaths'),
          subtitle: const Text('Adds natural breathing sounds'),
          value: _voiceConfig.enableBreaths,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(enableBreaths: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Enable Whisper Mode'),
          subtitle: const Text('Softer, quieter voice'),
          value: _voiceConfig.enableWhisper,
          onChanged: (value) {
            setState(() {
              _voiceConfig = _voiceConfig.copyWith(enableWhisper: value);
            });
          },
        ),
        const SizedBox(height: 24),

        ElevatedButton.icon(
          icon: const Icon(Icons.volume_up),
          label: const Text('TEST VOICE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          onPressed: _testVoice,
        ),
      ],
    );
  }

  Widget _buildSegmentedButton<T>({
    required T selected,
    required List<T> segments,
    required ValueChanged<T> onChanged,
    required String Function(T) labelBuilder,
  }) {
    return SegmentedButton<T>(
      segments: segments.map((item) {
        return ButtonSegment(
          value: item,
          label: Text(labelBuilder(item)),
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (Set<T> newSelection) {
        onChanged(newSelection.first);
      },
    );
  }

// ==================== PREVIEW TAB ====================

  Widget _buildPreviewTab() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Doctor Annie Preview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

// Main avatar preview
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade50,
                    Colors.cyan.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: DoctorAnnieAvatarWidget(
                appearance: _appearance,
                size: 350,
                enableAnimations: true,
                showHolographicBackground: true,
              ),
            ),

            const SizedBox(height: 32),

// Quick stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatRow('Bedside Manner', _personality.bedsideManner.displayName),
                    const Divider(),
                    _buildStatRow('Voice Accent', _voiceConfig.accent.displayName),
                    const Divider(),
                    _buildStatRow('Communication', _personality.communicationStyle.name),
                    const Divider(),
                    _buildStatRow('Formality', _voiceConfig.formality.displayName),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

// Test expressions
            _buildSectionHeader('Test Facial Expressions'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FacialExpression.values.map((expression) {
                return ElevatedButton(
                  onPressed: () {
                    _facialService.setExpression(expression);
                  },
                  child: Text(expression.name.toUpperCase()),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              icon: const Icon(Icons.chat),
              label: const Text('START CONVERSATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
// Navigate to chat with Doctor Annie
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

// ==================== HELPER WIDGETS ====================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C5F7C),
        ),
      ),
    );
  }
}