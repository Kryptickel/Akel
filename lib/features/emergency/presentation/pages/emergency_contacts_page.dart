import 'package:flutter/material.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final List<EmergencyContact> _contacts = [
    EmergencyContact(
      name: 'Mom',
      phone: '+1 (555) 123-4567',
      relationship: 'Mother',
      isPrimary: true,
    ),
    EmergencyContact(
      name: 'John Smith',
      phone: '+1 (555) 987-6543',
      relationship: 'Spouse',
      isPrimary: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addContact,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Emergency Contacts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These contacts will be automatically notified when you activate the panic button. Make sure to inform them about this app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            // Contacts list
            Expanded(
              child: _contacts.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        return _buildContactCard(_contacts[index], index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.contacts,
            size: 80,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Emergency Contacts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add trusted contacts who will be notified during emergencies',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addContact,
            icon: const Icon(Icons.add),
            label: const Text('Add First Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: contact.isPrimary 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          child: Text(
            contact.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              contact.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (contact.isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PRIMARY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(contact.phone),
            Text(contact.relationship),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editContact(index);
                break;
              case 'delete':
                _deleteContact(index);
                break;
              case 'primary':
                _makePrimary(index);
                break;
              case 'test':
                _testContact(contact);
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!contact.isPrimary)
              const PopupMenuItem(
                value: 'primary',
                child: Row(
                  children: [
                    Icon(Icons.star),
                    SizedBox(width: 8),
                    Text('Make Primary'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'test',
              child: Row(
                children: [
                  Icon(Icons.message),
                  SizedBox(width: 8),
                  Text('Send Test Alert'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addContact() {
    _showContactDialog();
  }

  void _editContact(int index) {
    _showContactDialog(contact: _contacts[index], index: index);
  }

  void _deleteContact(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to remove ${_contacts[index].name} from your emergency contacts?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _contacts.removeAt(index);
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact removed')),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _makePrimary(int index) {
    setState(() {
      // Remove primary status from all contacts
      for (var contact in _contacts) {
        contact.isPrimary = false;
      }
      // Make selected contact primary
      _contacts[index].isPrimary = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_contacts[index].name} is now primary contact')),
    );
  }

  void _testContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Send Test Alert'),
          content: Text(
            'Send a test emergency alert to ${contact.name}?\n\nThis will help verify that your emergency contact system is working.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement actual test message sending
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Test alert sent to ${contact.name}')),
                );
              },
              child: const Text('Send Test'),
            ),
          ],
        );
      },
    );
  }

  void _showContactDialog({EmergencyContact? contact, int? index}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final relationshipController = TextEditingController(text: contact?.relationship ?? '');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(contact == null ? 'Add Emergency Contact' : 'Edit Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.family_restroom),
                    hintText: 'e.g., Mother, Friend, Spouse',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  final newContact = EmergencyContact(
                    name: nameController.text,
                    phone: phoneController.text,
                    relationship: relationshipController.text.isNotEmpty 
                        ? relationshipController.text 
                        : 'Contact',
                    isPrimary: contact?.isPrimary ?? (_contacts.isEmpty),
                  );
                  
                  setState(() {
                    if (index != null) {
                      _contacts[index] = newContact;
                    } else {
                      _contacts.add(newContact);
                    }
                  });
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        contact == null ? 'Contact added' : 'Contact updated',
                      ),
                    ),
                  );
                }
              },
              child: Text(contact == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }
}

class EmergencyContact {
  String name;
  String phone;
  String relationship;
  bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.relationship,
    required this.isPrimary,
  });
}