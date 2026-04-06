import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/language_service.dart';
import '../services/vibration_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final LanguageService _languageService = LanguageService();
  final VibrationService _vibrationService = VibrationService();

  SupportedLanguage? _currentLanguage;
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
    _loadStatistics();
  }

  Future<void> _loadCurrentLanguage() async {
    setState(() => _isLoading = true);

    try {
      final language = await _languageService.getCurrentLanguage();

      if (mounted) {
        setState(() {
          _currentLanguage = language;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Load current language error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final stats = await _languageService.getLanguageStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint('❌ Load statistics error: $e');
      }
    }
  }

  Future<void> _selectLanguage(SupportedLanguage language) async {
    await _vibrationService.light();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    setState(() => _isLoading = true);

// Set language locally
    final success = await _languageService.setLanguage(language);

// Save to user profile
    if (userId != null) {
      await _languageService.saveUserLanguagePreference(
        userId: userId,
        language: language,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      await _vibrationService.success();

      final languageData = _languageService.getLanguageData(language);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${languageData.flag} Language changed to ${languageData.name}'),
          backgroundColor: Colors.green,
        ),
      );

      _loadCurrentLanguage();
      _loadStatistics();
    }
  }

  Future<void> _previewEmergencyMessage(SupportedLanguage language) async {
    await _vibrationService.light();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.userProfile?['name'] ?? 'User';

    final message = await _languageService.getEmergencyMessage(
      userName: userName,
      location: 'Sample Location: 123 Main St',
      language: language,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_languageService.getLanguageData(language).flag} Emergency Message Preview'),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadCurrentLanguage();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
// Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

          const SizedBox(height: 24),

// Info Card
          _buildInfoCard(),

          const SizedBox(height: 24),

// Language List
          _buildSectionHeader('Select Language'),
          ..._languageService.getAllLanguages().map((languageData) {
            return _buildLanguageCard(languageData);
          }),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final currentLanguage = _statistics!['currentLanguage'] as String;
    final currentNative = _statistics!['currentLanguageNative'] as String;
    final flag = _statistics!['currentLanguageFlag'] as String;
    final total = _statistics!['totalSupportedLanguages'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Current', '$flag\n$currentNative', Icons.language),
              _buildStatItem('Available', '$total', Icons.translate),
              _buildStatItem('Type', currentLanguage, Icons.flag),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Language Support',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Emergency messages will be sent in your selected language.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLanguageCard(LanguageData languageData) {
    final isSelected = _currentLanguage == languageData.language;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 4,
      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: () => _selectLanguage(languageData.language),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    languageData.flag,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageData.nativeName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blue : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageData.name,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (languageData.isRTL) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'RTL',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _previewEmergencyMessage(languageData.language),
                tooltip: 'Preview Message',
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
            ],
          ),
        ),
      ),
    );
  }
}