import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class MessageTemplatesScreen extends StatefulWidget {
  const MessageTemplatesScreen({super.key});

  @override
  State<MessageTemplatesScreen> createState() => _MessageTemplatesScreenState();
}

class _MessageTemplatesScreenState extends State<MessageTemplatesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedTemplateId;

  // Default templates
  final List<Map<String, String>> _defaultTemplates = [
    {
      'id': 'default_1',
      'name': 'Emergency - General',
      'message': ' EMERGENCY! I need immediate help! My current location is attached. Please contact me or emergency services right away.',
    },
    {
      'id': 'default_2',
      'name': 'Emergency - Medical',
      'message': ' MEDICAL EMERGENCY! I need urgent medical assistance at my location. Please call an ambulance and notify emergency contacts.',
    },
    {
      'id': 'default_3',
      'name': 'Emergency - Security Threat',
      'message': ' SECURITY THREAT! I am in danger and need immediate help. Location attached. Please alert authorities.',
    },
    {
      'id': 'default_4',
      'name': 'Emergency - Accident',
      'message': ' ACCIDENT! I\'ve been in an accident and need help. Location: [GPS coordinates]. Please send assistance.',
    },
    {
      'id': 'default_5',
      'name': 'Help Needed',
      'message': 'I need help urgently. Please check on me or contact authorities. My location is attached.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSelectedTemplate();
  }

  Future<void> _loadSelectedTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTemplateId = prefs.getString('selected_template_id') ?? 'default_1';
    });
  }

  Future<void> _selectTemplate(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_template_id', templateId);

    setState(() {
      _selectedTemplateId = templateId;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Template selected for emergency alerts'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showCreateTemplateDialog() async {
    final nameController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text(
            'Create Custom Template',
            style: TextStyle(color: Colors.white),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Template Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'e.g., Home Emergency',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: 'Enter your emergency message...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Message is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tip: Your GPS location will be automatically added to the message.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (formKey.currentState!.validate()) {
                  setDialogState(() => isLoading = true);

                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final userId = authProvider.user?.uid;

                    if (userId == null) throw Exception('Not logged in');

                    await _firestore
                        .collection('users')
                        .doc(userId)
                        .collection('message_templates')
                        .add({
                      'name': nameController.text.trim(),
                      'message': messageController.text.trim(),
                      'createdAt': DateTime.now().toIso8601String(),
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Template created!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
              ),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteTemplate(String templateId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Delete Template?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$name"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.uid;

        if (userId == null) throw Exception('Not logged in');

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('message_templates')
            .doc(templateId)
            .delete();

        // If deleted template was selected, switch to default
        if (_selectedTemplateId == templateId) {
          await _selectTemplate('default_1');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Message Templates'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: userId == null
          ? const Center(
        child: Text('Please log in', style: TextStyle(color: Colors.white70)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: const Color(0xFF1E2740),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF00BFA5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select a template to use when triggering panic alerts. Your GPS location will be added automatically.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Default Templates
            const Text(
              'DEFAULT TEMPLATES',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _defaultTemplates.length,
                  (index) {
                final template = _defaultTemplates[index];
                final isSelected = _selectedTemplateId == template['id'];

                return _buildTemplateCard(
                  id: template['id']!,
                  name: template['name']!,
                  message: template['message']!,
                  isSelected: isSelected,
                  isDefault: true,
                );
              },
            ),

            const SizedBox(height: 32),

            // Custom Templates
            const Text(
              'CUSTOM TEMPLATES',
              style: TextStyle(
                color: Color(0xFF00BFA5),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('message_templates')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'Error loading templates',
                    style: TextStyle(color: Colors.red),
                  );
                }

                final templates = snapshot.data?.docs ?? [];

                if (templates.isEmpty) {
                  return Card(
                    color: const Color(0xFF1E2740),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.note_add_outlined,
                              size: 48,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No custom templates yet',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your own personalized\nemergency messages',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: List.generate(templates.length, (index) {
                    final doc = templates[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final templateId = doc.id;
                    final isSelected = _selectedTemplateId == templateId;

                    return _buildTemplateCard(
                      id: templateId,
                      name: data['name'] ?? 'Unnamed',
                      message: data['message'] ?? '',
                      isSelected: isSelected,
                      isDefault: false,
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTemplateDialog,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add),
        label: const Text('Create Template'),
      ),
    );
  }

  Widget _buildTemplateCard({
    required String id,
    required String name,
    required String message,
    required bool isSelected,
    required bool isDefault,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? const Color(0xFF00BFA5).withOpacity(0.15)
          : const Color(0xFF1E2740),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _selectTemplate(id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? const Color(0xFF00BFA5) : Colors.white38,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!isDefault)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteTemplate(id, name),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BFA5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '✓ Currently Active',
                    style: TextStyle(
                      color: Color(0xFF00BFA5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}