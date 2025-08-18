import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile header
              _buildProfileHeader(),
              const SizedBox(height: 24),
              
              // Profile sections
              _buildProfileSection(),
              const SizedBox(height: 24),
              
              _buildMedicalSection(),
              const SizedBox(height: 24),
              
              _buildSettingsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'John Doe',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Profile created on Dec 15, 2024',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusChip('Active', Colors.green, true),
                _buildStatusChip('2 Devices', Theme.of(context).colorScheme.primary, false),
                _buildStatusChip('5 Contacts', Theme.of(context).colorScheme.secondary, false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          if (isActive) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildProfileItem(Icons.person, 'Name', 'John Doe'),
          _buildProfileItem(Icons.calendar_today, 'Age', '28 years old'),
          _buildProfileItem(Icons.person_outline, 'Sex', 'Male'),
          _buildProfileItem(Icons.location_on, 'Address', '123 Main St, City, State 12345'),
        ],
      ),
    );
  }

  Widget _buildMedicalSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Medical Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.medical_information,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildProfileItem(Icons.bloodtype, 'Blood Type', 'O+'),
          _buildProfileItem(Icons.warning, 'Allergies', 'Peanuts, Shellfish'),
          _buildProfileItem(Icons.medication, 'Medications', 'None'),
          _buildProfileItem(Icons.health_and_safety, 'Medical Conditions', 'None'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _editMedicalInfo,
              icon: const Icon(Icons.edit),
              label: const Text('Update Medical Information'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Settings & Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          _buildSettingItem(
            Icons.devices,
            'Linked Devices',
            'Manage connected devices',
            () => _showComingSoon('Device Management'),
          ),
          _buildSettingItem(
            Icons.notifications,
            'Notifications',
            'Emergency alert settings',
            () => _showComingSoon('Notification Settings'),
          ),
          _buildSettingItem(
            Icons.privacy_tip,
            'Privacy',
            'Data and privacy controls',
            () => _showComingSoon('Privacy Settings'),
          ),
          _buildSettingItem(
            Icons.security,
            'Security',
            'Authentication and security',
            () => _showComingSoon('Security Settings'),
          ),
          _buildSettingItem(
            Icons.backup,
            'Backup & Sync',
            'Cloud storage and sync',
            () => _showComingSoon('Backup Settings'),
          ),
          _buildSettingItem(
            Icons.help,
            'Help & Support',
            'Get help and contact support',
            () => _showHelpDialog(),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _exportData,
                    icon: const Icon(Icons.download),
                    label: const Text('Export My Data'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _editProfile() {
    _showComingSoon('Profile Editing');
  }

  void _editMedicalInfo() {
    _showComingSoon('Medical Information Editor');
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text(
            'Export all your profile data, emergency contacts, and settings to a secure file?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export will be available soon'),
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Emergency Hotlines:'),
              const SizedBox(height: 8),
              const Text('• Emergency: 911'),
              const Text('• Crisis Text Line: Text HOME to 741741'),
              const Text('• National Suicide Prevention: 988'),
              const SizedBox(height: 16),
              const Text('App Support:'),
              const SizedBox(height: 8),
              const Text('• Version: 1.0.0'),
              const Text('• Contact: support@akel.app'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
      ),
    );
  }
}