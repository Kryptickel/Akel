import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/relationship_tag_service.dart';
import '../services/vibration_service.dart';

class RelationshipTagsScreen extends StatefulWidget {
  const RelationshipTagsScreen({super.key});

  @override
  State<RelationshipTagsScreen> createState() => _RelationshipTagsScreenState();
}

class _RelationshipTagsScreenState extends State<RelationshipTagsScreen> {
  final RelationshipTagService _tagService = RelationshipTagService();
  final VibrationService _vibrationService = VibrationService();

  List<RelationshipTag> _tags = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTags();
    _loadStatistics();
  }

  Future<void> _loadTags() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final tags = await _tagService.getTags(userId);

        if (mounted) {
          setState(() {
            _tags = tags;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('❌ Load tags error: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final stats = await _tagService.getTagStatistics(userId);

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

  Future<void> _createDefaultTags() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    await _vibrationService.light();

    setState(() => _isLoading = true);

    await _tagService.createDefaultTags(userId);

    setState(() => _isLoading = false);

    if (mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Default relationship tags created'),
          backgroundColor: Colors.green,
        ),
      );

      _loadTags();
      _loadStatistics();
    }
  }

  Future<void> _createCustomTag() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    final nameController = TextEditingController();
    String selectedColor = RelationshipTagService.getDefaultColors().first;
    int priority = 2;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Custom Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - High Priority')),
                    DropdownMenuItem(value: 2, child: Text('2 - Medium Priority')),
                    DropdownMenuItem(value: 3, child: Text('3 - Low Priority')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Color:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RelationshipTagService.getDefaultColors().map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      setState(() => _isLoading = true);

      final tag = await _tagService.createTag(
        userId: userId,
        name: nameController.text,
        color: selectedColor,
        priority: priority,
      );

      setState(() => _isLoading = false);

      if (tag != null && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Custom tag created'),
            backgroundColor: Colors.green,
          ),
        );

        _loadTags();
        _loadStatistics();
      }
    }
  }

  Future<void> _editTag(RelationshipTag tag) async {
    final nameController = TextEditingController(text: tag.name);
    String selectedColor = tag.color;
    int priority = tag.priority;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Tag'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tag Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 - High Priority')),
                    DropdownMenuItem(value: 2, child: Text('2 - Medium Priority')),
                    DropdownMenuItem(value: 3, child: Text('3 - Low Priority')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Color:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RelationshipTagService.getDefaultColors().map((color) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() => selectedColor = color);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hexToColor(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: selectedColor == color
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final success = await _tagService.updateTag(
        tagId: tag.id,
        name: nameController.text,
        color: selectedColor,
        priority: priority,
      );

      if (success && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tag updated'),
            backgroundColor: Colors.green,
          ),
        );

        _loadTags();
      }
    }
  }

  Future<void> _deleteTag(RelationshipTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tag?'),
        content: Text('Are you sure you want to delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _tagService.deleteTag(tag.id);

      if (success && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tag deleted'),
            backgroundColor: Colors.green,
          ),
        );

        _loadTags();
        _loadStatistics();
      }
    }
  }

  Future<void> _viewTagContacts(RelationshipTag tag) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    final contacts = await _tagService.getContactsByTag(
      userId: userId,
      tagId: tag.id,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${RelationshipTagService.getTagIcon(tag.type)} ${tag.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${contacts.length} contact(s) with this tag',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (contacts.isEmpty)
                const Text('No contacts with this tag yet.')
              else
                ...contacts.map((contact) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _hexToColor(tag.color),
                      child: Text(
                        (contact['name'] as String)[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(contact['name'] as String),
                    subtitle: Text(contact['phone'] as String),
                  );
                }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relationship Tags'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadTags();
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

// Tags List
          _buildSectionHeader('Available Tags'),
          if (_tags.isEmpty)
            _buildEmptyState()
          else
            ..._tags.map((tag) => _buildTagCard(tag)),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'custom_tag',
            onPressed: _createCustomTag,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'default_tags',
            onPressed: _createDefaultTags,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Create Defaults'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalTags'] as int;
    final mostUsed = _statistics!['mostUsedTag'] as String;
    final mostUsedCount = _statistics!['mostUsedCount'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple,
            Colors.purple.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Tags', '$total', Icons.label),
          _buildStatItem('Most Used', mostUsed, Icons.star),
          _buildStatItem('Contacts', '$mostUsedCount', Icons.people),
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
            fontSize: 18,
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
                  'Relationship Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organize contacts by relationship type for easier management.',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.label_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Tags Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create relationship tags to organize your contacts',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTagCard(RelationshipTag tag) {
    final tagColor = _hexToColor(tag.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _viewTagContacts(tag);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    RelationshipTagService.getTagIcon(tag.type),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tag.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Priority: ${tag.priority}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editTag(tag),
                tooltip: 'Edit',
              ),
              if (tag.type == RelationshipType.custom)
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteTag(tag),
                  tooltip: 'Delete',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
  }
}