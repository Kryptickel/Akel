import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/advanced_ai_copilot_service.dart';

/// ==================== ULTIMATE CHAT FEATURES ====================
///
/// Premium Components:
/// Advanced Message Search with Filters
/// Chat Export (PDF, TXT, JSON)
/// AI Memory Visualization (Mind Map)
/// Conversation Analytics Dashboard
/// Smart Suggestions
/// Message Bookmarks
/// Chat History Timeline
/// Conversation Backup & Restore
///
/// ==============================================================

// ==================== MESSAGE SEARCH ====================

class MessageSearchDialog extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onMessageSelected;

  const MessageSearchDialog({
    super.key,
    required this.messages,
    required this.onMessageSelected,
  });

  @override
  State<MessageSearchDialog> createState() => _MessageSearchDialogState();
}

class _MessageSearchDialogState extends State<MessageSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatMessage> _searchResults = [];
  String _selectedFilter = 'all';
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.messages;
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = widget.messages);
      return;
    }

    setState(() {
      _searchResults = widget.messages.where((message) {
        final text = _caseSensitive ? message.text : message.text.toLowerCase();
        final searchQuery = _caseSensitive ? query : query.toLowerCase();

        // Filter by type
        if (_selectedFilter == 'user' && !message.isUser) return false;
        if (_selectedFilter == 'ai' && message.isUser) return false;

        // Filter by emotion
        if (_selectedFilter != 'all' &&
            _selectedFilter != 'user' &&
            _selectedFilter != 'ai') {
          if (message.emotion != _selectedFilter) return false;
        }

        return text.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF00BFA5)),
                const SizedBox(width: 12),
                const Text(
                  'Search Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search in conversation...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00BFA5)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _performSearch('');
                  },
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1E3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _performSearch,
            ),

            const SizedBox(height: 16),

            // Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', Icons.all_inclusive),
                  _buildFilterChip('User', 'user', Icons.person),
                  _buildFilterChip('AI', 'ai', Icons.psychology),
                  _buildFilterChip('Happy', 'happy', Icons.sentiment_satisfied),
                  _buildFilterChip('Sad', 'sad', Icons.sentiment_dissatisfied),
                  _buildFilterChip('Anxious', 'anxious', Icons.sentiment_neutral),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Case sensitive toggle
            Row(
              children: [
                Checkbox(
                  value: _caseSensitive,
                  onChanged: (value) {
                    setState(() => _caseSensitive = value ?? false);
                    _performSearch(_searchController.text);
                  },
                  activeColor: const Color(0xFF00BFA5),
                ),
                const Text(
                  'Case sensitive',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  '${_searchResults.length} results',
                  style: const TextStyle(
                    color: Color(0xFF00BFA5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results
            Expanded(
              child: _searchResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final message = _searchResults[index];
                  return _buildSearchResultItem(message);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
            _performSearch(_searchController.text);
          });
        },
        selectedColor: const Color(0xFF00BFA5),
        backgroundColor: const Color(0xFF1A1E3A),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(ChatMessage message) {
    final query = _searchController.text;
    final highlightedText = _highlightText(message.text, query);

    return InkWell(
      onTap: () {
        widget.onMessageSelected(message);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E3A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  message.isUser ? Icons.person : Icons.psychology,
                  color: message.isUser
                      ? const Color(0xFF00E5FF)
                      : const Color(0xFF00BFA5),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  message.isUser ? 'You' : 'Annie',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, HH:mm').format(message.timestamp),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: highlightedText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _highlightText(String text, String query) {
    if (query.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white70),
      );
    }

    final lowerText = _caseSensitive ? text : text.toLowerCase();
    final lowerQuery = _caseSensitive ? query : query.toLowerCase();

    final List<TextSpan> spans = [];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: Colors.white70),
        ));
        break;
      }

      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: const TextStyle(color: Colors.white70),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: Color(0xFF00BFA5),
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xFF00BFA5).withOpacity(0.2),
        ),
      ));

      start = index + query.length;
    }

    return TextSpan(children: spans);
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
            'No messages found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== CHAT EXPORT ====================

class ChatExportService {
  static Future<void> exportChat({
    required BuildContext context,
    required List<ChatMessage> messages,
    required String format,
  }) async {
    try {
      switch (format) {
        case 'txt':
          await _exportAsText(context, messages);
          break;
        case 'json':
          await _exportAsJson(context, messages);
          break;
        case 'pdf':
          await _exportAsPdf(context, messages);
          break;
        default:
          throw Exception('Unsupported format');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static Future<void> _exportAsText(
      BuildContext context,
      List<ChatMessage> messages,
      ) async {
    final buffer = StringBuffer();
    buffer.writeln('=================================');
    buffer.writeln('AKEL AI Co-Pilot Conversation');
    buffer.writeln('Exported: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('=================================\n');

    for (final message in messages) {
      final sender = message.isUser ? 'You' : 'Annie';
      final timestamp = DateFormat('HH:mm').format(message.timestamp);

      buffer.writeln('[$timestamp] $sender:');
      buffer.writeln(message.text);
      if (message.emotion != 'neutral') {
        buffer.writeln('(Emotion: ${message.emotion})');
      }
      buffer.writeln();
    }

    buffer.writeln('\n=================================');
    buffer.writeln('Total messages: ${messages.length}');
    buffer.writeln('=================================');

    final content = buffer.toString();
    await _saveAndShare(context, content, 'conversation.txt');
  }

  static Future<void> _exportAsJson(
      BuildContext context,
      List<ChatMessage> messages,
      ) async {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'app': 'AKEL AI Co-Pilot',
      'message_count': messages.length,
      'messages': messages.map((m) => {
        'timestamp': m.timestamp.toIso8601String(),
        'sender': m.isUser ? 'user' : 'ai',
        'text': m.text,
        'emotion': m.emotion,
        'context': m.context,
      }).toList(),
    };

    final jsonContent = const JsonEncoder.withIndent(' ').convert(data);
    await _saveAndShare(context, jsonContent, 'conversation.json');
  }

  static Future<void> _exportAsPdf(
      BuildContext context,
      List<ChatMessage> messages,
      ) async {
    // For PDF export, you would use the 'pdf' package
    // This is a placeholder - implement with actual PDF generation

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF export coming soon! Use TXT or JSON for now.'),
        backgroundColor: Color(0xFF00BFA5),
      ),
    );
  }

  static Future<void> _saveAndShare(
      BuildContext context,
      String content,
      String filename,
      ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'AKEL AI Co-Pilot Conversation',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported to $filename'),
          backgroundColor: const Color(0xFF00BFA5),
        ),
      );
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }
}

class ExportDialog extends StatelessWidget {
  final List<ChatMessage> messages;

  const ExportDialog({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1E3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.file_download, color: Color(0xFF00BFA5)),
                const SizedBox(width: 12),
                const Text(
                  'Export Conversation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _buildExportOption(
              context,
              'Text File (.txt)',
              'Plain text format, easy to read',
              Icons.text_snippet,
                  () => ChatExportService.exportChat(
                context: context,
                messages: messages,
                format: 'txt',
              ),
            ),

            const SizedBox(height: 12),

            _buildExportOption(
              context,
              'JSON File (.json)',
              'Structured data with metadata',
              Icons.code,
                  () => ChatExportService.exportChat(
                context: context,
                messages: messages,
                format: 'json',
              ),
            ),

            const SizedBox(height: 12),

            _buildExportOption(
              context,
              'PDF Document (.pdf)',
              'Professional formatted document',
              Icons.picture_as_pdf,
                  () => ChatExportService.exportChat(
                context: context,
                messages: messages,
                format: 'pdf',
              ),
            ),

            const SizedBox(height: 24),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E27),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF00BFA5)),
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
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}

// ==================== AI MEMORY VISUALIZATION ====================

class MemoryVisualizationScreen extends StatefulWidget {
  const MemoryVisualizationScreen({super.key});

  @override
  State<MemoryVisualizationScreen> createState() =>
      _MemoryVisualizationScreenState();
}

class _MemoryVisualizationScreenState extends State<MemoryVisualizationScreen> {
  final AdvancedAICopilotService _copilot = AdvancedAICopilotService();
  List<Map<String, dynamic>> _memories = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  void _loadMemories() {
    setState(() {
      _memories = _copilot.getLongTermMemories(limit: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1E3A),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Color(0xFF00BFA5)),
            SizedBox(width: 12),
            Text('AI Memory'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(),

          // Category filters
          _buildCategoryFilters(),

          // Memory timeline
          Expanded(
            child: _memories.isEmpty
                ? _buildEmptyState()
                : _buildMemoryTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    final insights = _copilot.getInsights();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA5).withOpacity(0.2),
            const Color(0xFF00E5FF).withOpacity(0.2),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Memories',
                '${insights['long_term_memories']}',
                Icons.storage,
              ),
              _buildStatItem(
                'Conversations',
                '${insights['total_conversations']}',
                Icons.chat,
              ),
              _buildStatItem(
                'Relationship',
                '${insights['relationship_level']}/100',
                Icons.favorite,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['all', 'emergency', 'problem_solving', 'companionship'];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: const Color(0xFF00BFA5),
              backgroundColor: const Color(0xFF1A1E3A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemoryTimeline() {
    final filteredMemories = _selectedCategory == 'all'
        ? _memories
        : _memories.where((m) => m['intent'] == _selectedCategory).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredMemories.length,
      itemBuilder: (context, index) {
        final memory = filteredMemories[index];
        final isFirst = index == 0;

        return _buildMemoryCard(memory, isFirst);
      },
    );
  }

  Widget _buildMemoryCard(Map<String, dynamic> memory, bool isFirst) {
    final date = DateTime.parse(memory['date'] as String);
    final importance = memory['importance'] as double;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(
                    const Color(0xFF00BFA5),
                    const Color(0xFFFF4081),
                    importance,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFA5).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (!isFirst)
                Container(
                  width: 2,
                  height: 60,
                  color: const Color(0xFF00BFA5).withOpacity(0.3),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Memory content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1E3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF00BFA5),
                    const Color(0xFFFF4081),
                    importance,
                  )!
                      .withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIntentIcon(memory['intent'] as String),
                        color: const Color(0xFF00BFA5),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(date),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                            const Color(0xFF00BFA5),
                            const Color(0xFFFF4081),
                            importance,
                          )!
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(importance * 100).toInt()}%',
                          style: TextStyle(
                            color: Color.lerp(
                              const Color(0xFF00BFA5),
                              const Color(0xFFFF4081),
                              importance,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Text(
                    memory['summary'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    children: [
                      _buildTag(memory['intent'] as String),
                      _buildTag(memory['emotion'] as String),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIntentIcon(String intent) {
    switch (intent) {
      case 'emergency':
        return Icons.warning;
      case 'problem_solving':
        return Icons.lightbulb;
      case 'companionship':
        return Icons.favorite;
      case 'planning':
        return Icons.calendar_today;
      default:
        return Icons.chat;
    }
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00BFA5).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF00BFA5),
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No memories yet',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start chatting with Annie to create memories',
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

// ==================== CONVERSATION ANALYTICS ====================

class ConversationAnalytics extends StatelessWidget {
  final List<ChatMessage> messages;

  const ConversationAnalytics({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    final analytics = _calculateAnalytics();

    return Dialog(
      backgroundColor: const Color(0xFF0A0E27),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Color(0xFF00BFA5)),
                  const SizedBox(width: 12),
                  const Text(
                    'Conversation Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildAnalyticCard(
                'Total Messages',
                '${analytics['total_messages']}',
                Icons.message,
                const Color(0xFF00BFA5),
              ),

              const SizedBox(height: 12),

              _buildAnalyticCard(
                'Average Response Time',
                '${analytics['avg_response_time']}s',
                Icons.timer,
                const Color(0xFF2196F3),
              ),

              const SizedBox(height: 12),

              _buildAnalyticCard(
                'Most Common Emotion',
                analytics['dominant_emotion'],
                Icons.sentiment_satisfied,
                const Color(0xFFFF9800),
              ),

              const SizedBox(height: 12),

              _buildAnalyticCard(
                'Longest Conversation',
                '${analytics['longest_streak']} messages',
                Icons.trending_up,
                const Color(0xFFFF4081),
              ),

              const SizedBox(height: 24),

              // Emotion distribution
              _buildEmotionDistribution(analytics['emotion_distribution']),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionDistribution(Map<String, int> distribution) {
    final total = distribution.values.fold(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1E3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emotion Distribution',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...distribution.entries.map((entry) {
            final percentage = (entry.value / total * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Color(0xFF00BFA5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF00BFA5)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateAnalytics() {
    final emotionCounts = <String, int>{};
    int totalResponseTime = 0;
    int responseCount = 0;
    int currentStreak = 0;
    int longestStreak = 0;

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];

      // Count emotions
      emotionCounts[message.emotion] = (emotionCounts[message.emotion] ?? 0) + 1;

      // Calculate response times
      if (i > 0 && !message.isUser && messages[i - 1].isUser) {
        final responseTime = message.timestamp.difference(messages[i - 1].timestamp);
        totalResponseTime += responseTime.inSeconds;
        responseCount++;
      }

      // Calculate streaks
      currentStreak++;
      if (i < messages.length - 1 && messages[i + 1].isUser == message.isUser) {
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        currentStreak = 0;
      }
    }

    final dominantEmotion = emotionCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'total_messages': messages.length,
      'avg_response_time': responseCount > 0
          ? (totalResponseTime / responseCount).toStringAsFixed(1)
          : '0',
      'dominant_emotion': dominantEmotion,
      'longest_streak': longestStreak,
      'emotion_distribution': emotionCounts,
    };
  }
}

// ==================== MESSAGE BOOKMARKS ====================

class MessageBookmarkManager {
  static final List<int> _bookmarkedIndexes = [];

  static void toggleBookmark(int index) {
    if (_bookmarkedIndexes.contains(index)) {
      _bookmarkedIndexes.remove(index);
    } else {
      _bookmarkedIndexes.add(index);
    }
  }

  static bool isBookmarked(int index) {
    return _bookmarkedIndexes.contains(index);
  }

  static List<int> getBookmarks() {
    return List.from(_bookmarkedIndexes);
  }

  static void clearAll() {
    _bookmarkedIndexes.clear();
  }
}

// Model class placeholder
class ChatMessage {
  final String text;
  final bool isUser;
  final String emotion;
  final DateTime timestamp;
  final String? context;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.emotion,
    required this.timestamp,
    this.context,
  });
}