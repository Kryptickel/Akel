import 'package:flutter/material.dart';
import '../services/ultimate_ai_features_service.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== LANGUAGE SELECTOR DIALOG ====================
///
/// Beautiful language picker with:
/// - 100+ languages with flags
/// - Search functionality
/// - Currently selected language highlighted
/// - Smooth animations
///
/// ==============================================================

class LanguageSelectorDialog extends StatefulWidget {
  const LanguageSelectorDialog({super.key});

  @override
  State<LanguageSelectorDialog> createState() => _LanguageSelectorDialogState();
}

class _LanguageSelectorDialogState extends State<LanguageSelectorDialog> {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();
  final TextEditingController _searchController = TextEditingController();

  List<Language> _languages = [];
  List<Language> _filteredLanguages = [];
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _languages = _service.getSupportedLanguages();
    _filteredLanguages = _languages;
    _selectedLanguage = _service.targetLanguage;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = _languages;
      } else {
        _filteredLanguages = _languages
            .where((lang) =>
        lang.name.toLowerCase().contains(query.toLowerCase()) ||
            lang.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AkelDesign.deepBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AkelDesign.carbonFiber,
              AkelDesign.deepBlack,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildResultsCount(),
            const SizedBox(height: 8),
            Expanded(child: _buildLanguageList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFA5).withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.language, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Select Language',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search languages...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: Colors.white70),
          onPressed: () {
            _searchController.clear();
            _filterLanguages('');
          },
        )
            : null,
        filled: true,
        fillColor: AkelDesign.carbonFiber,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
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
      onChanged: _filterLanguages,
    );
  }

  Widget _buildResultsCount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_filteredLanguages.length} languages',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        if (_selectedLanguage.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.5),
              ),
            ),
            child: Text(
              'Current: $_selectedLanguage',
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageList() {
    if (_filteredLanguages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _filteredLanguages.length,
      itemBuilder: (context, index) {
        final language = _filteredLanguages[index];
        final isSelected = language.code == _selectedLanguage;

        return _buildLanguageTile(language, isSelected);
      },
    );
  }

  Widget _buildLanguageTile(Language language, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF00BFA5).withOpacity(0.2)
            : AkelDesign.carbonFiber,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00BFA5)
              : const Color(0xFF00BFA5).withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Text(
          language.flag,
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          language.name,
          style: TextStyle(
            color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          language.code.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Color(0xFF00BFA5))
            : const Icon(Icons.circle_outlined, color: Colors.white30),
        onTap: () async {
          await _service.setTargetLanguage(language.code);
          if (mounted) {
            Navigator.pop(context, language);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No languages found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}