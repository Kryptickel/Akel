import 'package:flutter/material.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';

  final List<LanguageOption> _languages = [
    LanguageOption('English', 'en', ' ', isPopular: true),
    LanguageOption('Spanish', 'es', ' ', isPopular: true),
    LanguageOption('French', 'fr', ' ', isPopular: true),
    LanguageOption('German', 'de', ' ', isPopular: true),
    LanguageOption('Chinese (Simplified)', 'zh-CN', ' ', isPopular: true),
    LanguageOption('Japanese', 'ja', ' ', isPopular: true),
    LanguageOption('Korean', 'ko', ' ', isPopular: true),
    LanguageOption('Arabic', 'ar', ' ', isPopular: true),
    LanguageOption('Hindi', 'hi', ' ', isPopular: true),
    LanguageOption('Portuguese', 'pt', ' ', isPopular: true),
    LanguageOption('Russian', 'ru', ' '),
    LanguageOption('Italian', 'it', ' '),
    LanguageOption('Dutch', 'nl', ' '),
    LanguageOption('Polish', 'pl', ' '),
    LanguageOption('Turkish', 'tr', ' '),
    LanguageOption('Swedish', 'sv', ' '),
    LanguageOption('Norwegian', 'no', ' '),
    LanguageOption('Danish', 'da', ' '),
    LanguageOption('Finnish', 'fi', ' '),
    LanguageOption('Greek', 'el', ' '),
    LanguageOption('Hebrew', 'he', ' '),
    LanguageOption('Thai', 'th', ' '),
    LanguageOption('Vietnamese', 'vi', ' '),
    LanguageOption('Indonesian', 'id', ' '),
    LanguageOption('Malay', 'ms', ' '),
    LanguageOption('Filipino', 'fil', ' '),
    LanguageOption('Ukrainian', 'uk', ' '),
    LanguageOption('Czech', 'cs', ' '),
    LanguageOption('Romanian', 'ro', ' '),
    LanguageOption('Hungarian', 'hu', ' '),
  ];

  List<LanguageOption> get _popularLanguages =>
      _languages.where((l) => l.isPopular).toList();

  List<LanguageOption> get _allLanguages => _languages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Language Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Language Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Language',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLanguageFlag(_selectedLanguage) +
                            ' ' +
                            _selectedLanguage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Features Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2740),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoItem(
                  Icons.translate,
                  'Real-Time Translation',
                  'Emergency messages auto-translated',
                ),
                const Divider(color: Colors.white12),
                _buildInfoItem(
                  Icons.record_voice_over,
                  'Voice Commands',
                  'Use voice in your language',
                ),
                const Divider(color: Colors.white12),
                _buildInfoItem(
                  Icons.local_hospital,
                  'Medical Terms',
                  'Critical medical phrases included',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Popular Languages
          _buildSectionHeader('Popular Languages'),
          const SizedBox(height: 12),
          ..._popularLanguages.map((lang) => _buildLanguageCard(lang)),

          const SizedBox(height: 24),

          // All Languages
          _buildSectionHeader('All Languages (${_allLanguages.length})'),
          const SizedBox(height: 12),
          ..._allLanguages
              .where((l) => !l.isPopular)
              .map((lang) => _buildLanguageCard(lang)),

          const SizedBox(height: 24),

          // Download Languages
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2740),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.download_for_offline,
                  color: Color(0xFF00BFA5),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Offline Language Packs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Download language packs for offline use',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(' Downloading language pack...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download for Offline'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BFA5), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(LanguageOption language) {
    final isSelected = _selectedLanguage == language.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectLanguage(language.name),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Flag
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),

                // Language Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        language.code.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Popular Badge
                if (language.isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                      ),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(width: 12),

                // Selection Icon
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected
                      ? const Color(0xFF00BFA5)
                      : Colors.white38,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ' Language changed to ${_getLanguageFlag(language)} $language',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _getLanguageFlag(String languageName) {
    final lang = _languages.firstWhere(
          (l) => l.name == languageName,
      orElse: () => _languages.first,
    );
    return lang.flag;
  }
}

class LanguageOption {
  final String name;
  final String code;
  final String flag;
  final bool isPopular;

  LanguageOption(
      this.name,
      this.code,
      this.flag, {
        this.isPopular = false,
      });
}