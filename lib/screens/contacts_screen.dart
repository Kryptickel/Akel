import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/priority_selector.dart';
import '../services/contact_verification_service.dart';
import '../services/contact_group_service.dart';
import '../models/contact_group.dart';
import 'contact_groups_screen.dart';

/// ==================== CONTACTS SCREEN ====================
/// Manage emergency contacts with verification
/// BUILD 55 - FIXED & PRODUCTION READY
/// ================================================================

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ContactVerificationService _verificationService = ContactVerificationService();
  final ContactGroupService _groupService = ContactGroupService();

  String _selectedGroup = 'All';
  String? _selectedCustomGroupId;
  List<ContactGroup> _customGroups = [];
  static const int MAX_CONTACTS = 5;

  bool _isVerifying = false;
  int _verificationProgress = 0;
  int _verificationTotal = 0;

  final List<String> _groups = ['All', 'Family', 'Friends', 'Medical', 'Emergency Services'];

  final Map<String, IconData> _groupIcons = {
    'All': Icons.people,
    'Family': Icons.family_restroom,
    'Friends': Icons.groups,
    'Medical': Icons.local_hospital,
    'Emergency Services': Icons.emergency,
  };

  final Map<String, Color> _groupColors = {
    'All': const Color(0xFF00BFA5),
    'Family': Colors.purple,
    'Friends': Colors.blue,
    'Medical': Colors.red,
    'Emergency Services': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomGroups();
  }

  void _loadCustomGroups() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      _groupService.getGroups(userId).listen((groups) {
        if (mounted) {
          setState(() {
            _customGroups = groups;
          });
        }
      });
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'amber':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  // ==================== VERIFICATION ====================

  Future<void> _verifySingleContact(String contactId, String name, String phone) async {
    setState(() => _isVerifying = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() => _isVerifying = false);
      return;
    }

    try {
      final result = await _verificationService.sendVerificationCode(
        userId: userId,
        contactId: contactId,
        phoneNumber: phone,
        contactName: name,
      );

      if (mounted) {
        setState(() => _isVerifying = false);

        if (result['success'] == true) {
          // Show dialog to enter code
          _showVerificationCodeDialog(contactId, name, userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showVerificationCodeDialog(String contactId, String name, String userId) async {
    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: Text(
          'Verify $name',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the 6-digit verification code sent via SMS:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 8),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00BFA5), width: 2),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.length == 6) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final code = codeController.text;

      final verifyResult = await _verificationService.verifyCode(
        userId: userId,
        contactId: contactId,
        code: code,
      );

      if (verifyResult['success'] == true) {
        // Update contact in Firestore
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('contacts')
            .doc(contactId)
            .update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' $name verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' ${verifyResult['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    codeController.dispose();
  }

  Future<void> _verifyAllContacts(List<QueryDocumentSnapshot> contacts) async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' No contacts to verify'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(' Please verify ${contacts.length} contacts individually'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== CONTACT MANAGEMENT ====================

  Future<void> _handleAddNewContact(String userId) async {
    final snapshot = await _firestore.collection('users').doc(userId).collection('contacts').get();
    if (snapshot.docs.length >= MAX_CONTACTS) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text('Limit Reached', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'You can only add up to 5 emergency contacts. Please delete an existing contact to add a new one.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00BFA5))),
            ),
          ],
        ),
      );
    } else {
      _showContactDialog();
    }
  }

  Widget _buildContactCountIndicator(int count) {
    final progress = (count / MAX_CONTACTS).clamp(0.0, 1.0);
    final statusColor = progress >= 1.0
        ? Colors.red
        : (progress >= 0.8 ? Colors.orange : const Color(0xFF00BFA5));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count of $MAX_CONTACTS Contacts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    count >= MAX_CONTACTS ? 'Limit reached' : 'Remaining: ${MAX_CONTACTS - count}',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
              Icon(Icons.shield, color: statusColor.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            color: statusColor,
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Future<void> _showContactDialog({
    String? contactId,
    String? existingName,
    String? existingPhone,
    String? existingEmail,
    String? existingGroup,
    int? existingPriority,
  }) async {
    final nameController = TextEditingController(text: existingName);
    final phoneController = TextEditingController(text: existingPhone);
    final emailController = TextEditingController(text: existingEmail);
    String selectedGroup = existingGroup ?? 'Family';
    int selectedPriority = existingPriority ?? 2;
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: Text(
            contactId == null ? 'Add Emergency Contact' : 'Edit Contact',
            style: const TextStyle(color: Colors.white),
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
                      labelText: 'Name',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.person, color: Color(0xFF00BFA5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    controller: phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.phone, color: Color(0xFF00BFA5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
                      if (!phoneRegex.hasMatch(value)) {
                        return 'Invalid phone number format';
                      }
                      if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                        return 'Phone number too short';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email (Optional)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF00BFA5)),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Invalid email format';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGroup,
                    dropdownColor: const Color(0xFF1E2740),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Group',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: Icon(
                        _groupIcons[selectedGroup] ?? Icons.group,
                        color: _groupColors[selectedGroup] ?? const Color(0xFF00BFA5),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _groups
                        .where((g) => g != 'All')
                        .map((group) => DropdownMenuItem(
                      value: group,
                      child: Row(
                        children: [
                          Icon(_groupIcons[group], color: _groupColors[group], size: 20),
                          const SizedBox(width: 8),
                          Text(group),
                        ],
                      ),
                    ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedGroup = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  PrioritySelector(
                    selectedPriority: selectedPriority,
                    onPriorityChanged: (priority) {
                      setDialogState(() {
                        selectedPriority = priority;
                      });
                    },
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

                    final contactData = {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'group': selectedGroup,
                      'priority': selectedPriority,
                      'verified': false, // New contacts start unverified
                      'updatedAt': DateTime.now().toIso8601String(),
                    };

                    if (contactId == null) {
                      contactData['createdAt'] = DateTime.now().toIso8601String();
                      await _firestore
                          .collection('users')
                          .doc(userId)
                          .collection('contacts')
                          .add(contactData);
                    } else {
                      await _firestore
                          .collection('users')
                          .doc(userId)
                          .collection('contacts')
                          .doc(contactId)
                          .update(contactData);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            contactId == null
                                ? ' Contact added successfully!'
                                : ' Contact updated successfully!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(' Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
              child: isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(contactId == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
  }

  Future<void> _deleteContact(String contactId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Delete Contact?', style: TextStyle(color: Colors.white)),
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

        await _firestore.collection('users').doc(userId).collection('contacts').doc(contactId).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(' Contact deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(' Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_work),
            tooltip: 'Manage Groups',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactGroupsScreen()),
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: userId != null
                ? _firestore.collection('users').doc(userId).collection('contacts').snapshots()
                : null,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: _isVerifying
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.verified_user),
                tooltip: 'Verify All Contacts',
                onPressed: _isVerifying ? null : () => _verifyAllContacts(snapshot.data!.docs),
              );
            },
          ),
        ],
      ),
      body: userId == null
          ? const Center(
        child: Text(
          'Please log in',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').doc(userId).collection('contacts').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return _buildContactCountIndicator(snapshot.data!.docs.length);
            },
          ),
          if (_isVerifying)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Verifying contacts... $_verificationProgress of $_verificationTotal',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _verificationTotal > 0 ? _verificationProgress / _verificationTotal : 0,
                    backgroundColor: Colors.white10,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ..._groups.map((group) {
                  final isSelected = _selectedGroup == group && _selectedCustomGroupId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _groupIcons[group],
                            size: 18,
                            color: isSelected ? Colors.white : _groupColors[group],
                          ),
                          const SizedBox(width: 6),
                          Text(group),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedGroup = group;
                          _selectedCustomGroupId = null;
                        });
                      },
                      backgroundColor: const Color(0xFF1E2740),
                      selectedColor: _groupColors[group],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
                ..._customGroups.map((group) {
                  final isSelected = _selectedCustomGroupId == group.id;
                  final color = _getColorFromString(group.color);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Text(
                        group.icon,
                        style: const TextStyle(fontSize: 16),
                      ),
                      label: Text(group.name),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCustomGroupId = group.id;
                            _selectedGroup = 'All';
                          } else {
                            _selectedCustomGroupId = null;
                          }
                        });
                      },
                      backgroundColor: const Color(0xFF1E2740),
                      selectedColor: color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .collection('contacts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading contacts',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00BFA5),
                    ),
                  );
                }

                var contacts = snapshot.data?.docs ?? [];

                if (_selectedGroup != 'All' && _selectedCustomGroupId == null) {
                  contacts = contacts.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['group'] == _selectedGroup;
                  }).toList();
                }

                if (_selectedCustomGroupId != null) {
                  final selectedGroup = _customGroups.firstWhere((g) => g.id == _selectedCustomGroupId);
                  contacts = contacts.where((doc) {
                    return selectedGroup.contactIds.contains(doc.id);
                  }).toList();
                }

                contacts.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final priorityA = dataA['priority'] ?? 2;
                  final priorityB = dataB['priority'] ?? 2;
                  return priorityA.compareTo(priorityB);
                });

                if (contacts.isEmpty) {
                  String emptyMessage;
                  IconData emptyIcon;

                  if (_selectedCustomGroupId != null) {
                    final selectedGroup = _customGroups.firstWhere((g) => g.id == _selectedCustomGroupId);
                    emptyMessage = 'No contacts in ${selectedGroup.name}';
                    emptyIcon = Icons.group;
                  } else if (_selectedGroup == 'All') {
                    emptyMessage = 'No Emergency Contacts';
                    emptyIcon = Icons.contacts_outlined;
                  } else {
                    emptyMessage = 'No $_selectedGroup Contacts';
                    emptyIcon = _groupIcons[_selectedGroup]!;
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          emptyIcon,
                          size: 80,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          emptyMessage,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _selectedGroup == 'All'
                              ? 'Add your first contact\nto get started'
                              : 'Add contacts to this group',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () => _handleAddNewContact(userId),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final doc = contacts[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final contactId = doc.id;
                    final group = data['group'] ?? 'Family';
                    final priority = data['priority'] ?? 2;
                    final priorityColor = ContactPriority.fromValue(priority).color;
                    final priorityIcon = ContactPriority.fromValue(priority).icon;
                    final name = data['name'] ?? 'Unknown';
                    final phone = data['phone'] ?? '';
                    final verified = data['verified'] ?? false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xFF1E2740),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(priorityIcon, color: priorityColor),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (verified)
                              const Icon(
                                Icons.verified,
                                color: Colors.green,
                                size: 20,
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phone,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_groupColors[group] ?? const Color(0xFF00BFA5)).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    group,
                                    style: TextStyle(
                                      color: _groupColors[group] ?? const Color(0xFF00BFA5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PriorityBadge(priority: priority, compact: true),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            switch (value) {
                              case 'verify':
                                await _verifySingleContact(
                                  contactId,
                                  name,
                                  phone,
                                );
                                break;
                              case 'edit':
                                _showContactDialog(
                                  contactId: contactId,
                                  existingName: name,
                                  existingPhone: phone,
                                  existingEmail: data['email'],
                                  existingGroup: group,
                                  existingPriority: priority,
                                );
                                break;
                              case 'delete':
                                _deleteContact(contactId, name);
                                break;
                            }
                          },
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                          color: const Color(0xFF1E2740),
                          itemBuilder: (context) => [
                            if (!verified)
                              const PopupMenuItem(
                                value: 'verify',
                                child: Row(
                                  children: [
                                    Icon(Icons.verified, size: 20, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text(
                                      'Verify Contact',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Color(0xFF00BFA5),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 20, color: Colors.red),
                                  SizedBox(width: 12),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => userId != null ? _handleAddNewContact(userId) : null,
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.add),
        label: const Text('Add Contact'),
      ),
    );
  }
}