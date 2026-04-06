import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/contact_group_service.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import '../models/contact_group.dart';

class GroupEditorScreen extends StatefulWidget {
  final String userId;
  final ContactGroup? group;

  const GroupEditorScreen({
    super.key,
    required this.userId,
    this.group,
  });

  @override
  State<GroupEditorScreen> createState() => _GroupEditorScreenState();
}

class _GroupEditorScreenState extends State<GroupEditorScreen> {
  final ContactGroupService _groupService = ContactGroupService();
  final VibrationService _vibrationService = VibrationService();
  final SoundService _soundService = SoundService();
  final TextEditingController _nameController = TextEditingController();

  String _selectedIcon = '👥';
  String _selectedColor = 'blue';
  List<String> _selectedContactIds = [];
  List<Map<String, dynamic>> _allContacts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _availableIcons = [
    '👨‍👩‍👧‍👦', '💼', '👥', '⚕️', '🏠', '🎓', '⚽', '🍕',
    '🎵', '🎮', '📚', '✈️', '🚗', '💪', '🎨', '🔧'
  ];

  final List<Map<String, dynamic>> _availableColors = [
    {'name': 'red', 'color': Colors.red},
    {'name': 'blue', 'color': Colors.blue},
    {'name': 'green', 'color': Colors.green},
    {'name': 'purple', 'color': Colors.purple},
    {'name': 'orange', 'color': Colors.orange},
    {'name': 'pink', 'color': Colors.pink},
    {'name': 'teal', 'color': Colors.teal},
    {'name': 'amber', 'color': Colors.amber},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
// Load all contacts
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('contacts')
        .get();

    _allContacts = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data()};
    }).toList();

// If editing, load group data
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _selectedIcon = widget.group!.icon;
      _selectedColor = widget.group!.color;
      _selectedContactIds = List.from(widget.group!.contactIds);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter a group name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _vibrationService.success();
      await _soundService.playSuccess();

      if (widget.group == null) {
// Create new group
        await _groupService.createGroup(
          userId: widget.userId,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          contactIds: _selectedContactIds,
        );
      } else {
// Update existing group
        await _groupService.updateGroup(
          userId: widget.userId,
          groupId: widget.group!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          color: _selectedColor,
          contactIds: _selectedContactIds,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.group == null
                  ? '✅ Group created successfully'
                  : '✅ Group updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getColorFromString(String colorName) {
    final colorMap = _availableColors.firstWhere(
          (c) => c['name'] == colorName,
      orElse: () => _availableColors[1],
    );
    return colorMap['color'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.group != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Group' : 'Create Group'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveGroup,
              tooltip: 'Save',
            ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
// Name Field
            Text(
              'GROUP NAME',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Enter group name',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

// Icon Selection
            Text(
              'ICON',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return InkWell(
                  onTap: () async {
                    await _vibrationService.light();
                    setState(() => _selectedIcon = icon);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getColorFromString(_selectedColor).withOpacity(0.2)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? _getColorFromString(_selectedColor)
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

// Color Selection
            Text(
              'COLOR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((colorData) {
                final colorName = colorData['name'] as String;
                final color = colorData['color'] as Color;
                final isSelected = colorName == _selectedColor;

                return InkWell(
                  onTap: () async {
                    await _vibrationService.light();
                    setState(() => _selectedColor = colorName);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: isSelected
                        ? const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    )
                        : null,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

// Contact Selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CONTACTS (${_selectedContactIds.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 1,
                  ),
                ),
                if (_selectedContactIds.length < _allContacts.length)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedContactIds = _allContacts
                            .map((c) => c['id'] as String)
                            .toList();
                      });
                    },
                    child: const Text('Select All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (_allContacts.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.contacts,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No contacts yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add emergency contacts first',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allContacts.length,
                itemBuilder: (context, index) {
                  final contact = _allContacts[index];
                  final contactId = contact['id'] as String;
                  final isSelected = _selectedContactIds.contains(contactId);

                  return Card(
                    child: CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) async {
                        await _vibrationService.light();
                        setState(() {
                          if (value == true) {
                            _selectedContactIds.add(contactId);
                          } else {
                            _selectedContactIds.remove(contactId);
                          }
                        });
                      },
                      title: Text(
                        contact['name'] as String? ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.headlineMedium?.color,
                        ),
                      ),
                      subtitle: Text(
                        contact['phone'] as String? ?? '',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      secondary: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _getColorFromString(_selectedColor).withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (contact['name'] as String? ?? 'U')[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? _getColorFromString(_selectedColor)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      activeColor: _getColorFromString(_selectedColor),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}