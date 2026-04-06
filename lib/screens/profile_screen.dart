import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/vibration_service.dart';
import '../services/sound_service.dart';
import 'panic_history_screen.dart';
import 'statistics_screen.dart';

/// ==================== PROFILE SCREEN ====================
///
/// AKEL PANIC BUTTON - USER PROFILE
///
/// BUILD 58 - FIXED VERSION
/// - Fixed medicalInfo type error (String → Map)
/// - Proper null safety
/// - Enhanced UI
///
/// =====================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final vibrationService = VibrationService();
    final soundService = SoundService();
    final userProfile = authProvider.userProfile;

    final name = userProfile?['name'] as String? ?? 'User';
    final email = authProvider.user?.email ?? 'No email';
    final phone = userProfile?['phone'] as String? ?? 'Not set';
    final address = userProfile?['address'] as String? ?? 'Not set';

// FIX: Handle medicalInfo as Map or String
    final medicalInfoData = userProfile?['medicalInfo'];
    String medicalInfo;
    if (medicalInfoData is Map) {
// If it's a Map, convert to readable string
      medicalInfo = _formatMedicalInfo(medicalInfoData);
    } else if (medicalInfoData is String) {
      medicalInfo = medicalInfoData;
    } else {
      medicalInfo = 'None';
    }

    final emergencyMessage = userProfile?['emergencyMessage'] as String? ??
        userProfile?['emergency_message'] as String? ??
        'Default message';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () async {
              await vibrationService.light();
              await soundService.playClick();
              if (context.mounted) {
                _showEditProfileDialog(context, authProvider);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
// Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

// Quick Actions
            _buildSectionHeader(context, 'QUICK ACTIONS'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.history,
                    label: 'Panic History',
                    color: Colors.orange,
                    onTap: () async {
                      await vibrationService.light();
                      await soundService.playClick();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PanicHistoryScreen()),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    context: context,
                    icon: Icons.bar_chart,
                    label: 'Statistics',
                    color: Colors.blue,
                    onTap: () async {
                      await vibrationService.light();
                      await soundService.playClick();
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

// Personal Information
            _buildSectionHeader(context, 'PERSONAL INFORMATION'),
            const SizedBox(height: 12),

            _buildInfoCard(
              context: context,
              icon: Icons.phone,
              label: 'Phone',
              value: phone,
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              context: context,
              icon: Icons.location_on,
              label: 'Address',
              value: address,
            ),

            const SizedBox(height: 24),

// Medical Information
            _buildSectionHeader(context, 'MEDICAL INFORMATION'),
            const SizedBox(height: 12),

            _buildInfoCard(
              context: context,
              icon: Icons.medical_services,
              label: 'Medical Info',
              value: medicalInfo,
            ),

            const SizedBox(height: 24),

// Emergency Settings
            _buildSectionHeader(context, 'EMERGENCY SETTINGS'),
            const SizedBox(height: 12),

            _buildInfoCard(
              context: context,
              icon: Icons.message,
              label: 'Emergency Message',
              value: emergencyMessage,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

// Helper method to format medical info Map to String
  static String _formatMedicalInfo(Map<dynamic, dynamic> medicalData) {
    final buffer = StringBuffer();

    if (medicalData['bloodType'] != null) {
      buffer.write('Blood Type: ${medicalData['bloodType']}');
    }

    if (medicalData['allergies'] != null && medicalData['allergies'].toString().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Allergies: ${medicalData['allergies']}');
    }

    if (medicalData['medications'] != null && medicalData['medications'].toString().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Medications: ${medicalData['medications']}');
    }

    if (medicalData['conditions'] != null && medicalData['conditions'].toString().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write('\n');
      buffer.write('Conditions: ${medicalData['conditions']}');
    }

    return buffer.isEmpty ? 'None' : buffer.toString();
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.2),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AuthProvider authProvider) {
    final nameController = TextEditingController(text: authProvider.userProfile?['name']);
    final phoneController = TextEditingController(text: authProvider.userProfile?['phone']);
    final addressController = TextEditingController(text: authProvider.userProfile?['address']);

// FIX: Handle medicalInfo properly
    String initialMedicalInfo = '';
    final medicalData = authProvider.userProfile?['medicalInfo'];
    if (medicalData is Map) {
      initialMedicalInfo = _formatMedicalInfo(medicalData);
    } else if (medicalData is String) {
      initialMedicalInfo = medicalData;
    }
    final medicalController = TextEditingController(text: initialMedicalInfo);

    final messageController = TextEditingController(
        text: authProvider.userProfile?['emergencyMessage'] ??
            authProvider.userProfile?['emergency_message']
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Theme.of(context).textTheme.headlineMedium?.color),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  prefixIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  prefixIcon: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: medicalController,
                decoration: InputDecoration(
                  labelText: 'Medical Info',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  prefixIcon: Icon(Icons.medical_services, color: Theme.of(context).primaryColor),
                  hintText: 'e.g., Blood Type: O+, Allergies: None',
                  hintStyle: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Emergency Message',
                  labelStyle: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  prefixIcon: Icon(Icons.message, color: Theme.of(context).primaryColor),
                ),
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = authProvider.user?.uid;
              if (userId != null) {
// FIX: Convert medical info string to Map
                final medicalInfoMap = _parseMedicalInfo(medicalController.text);

                await authProvider.updateUserProfile(
                  userId: userId,
                  name: nameController.text,
                  phone: phoneController.text,
                  address: addressController.text,
                  medicalInfo: medicalInfoMap, // Now passing Map instead of String
                  emergencyMessage: messageController.text,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

// FIX: Helper method to parse medical info string to Map
  static Map<String, dynamic> _parseMedicalInfo(String medicalText) {
    if (medicalText.isEmpty || medicalText == 'None') {
      return {};
    }

    final medicalMap = <String, dynamic>{
      'bloodType': '',
      'allergies': '',
      'medications': '',
      'conditions': '',
      'notes': medicalText, // Store original text as notes
    };

// Try to parse structured data
    final lines = medicalText.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.toLowerCase().startsWith('blood type:')) {
        medicalMap['bloodType'] = trimmed.substring(11).trim();
      } else if (trimmed.toLowerCase().startsWith('allergies:')) {
        medicalMap['allergies'] = trimmed.substring(10).trim();
      } else if (trimmed.toLowerCase().startsWith('medications:')) {
        medicalMap['medications'] = trimmed.substring(12).trim();
      } else if (trimmed.toLowerCase().startsWith('conditions:')) {
        medicalMap['conditions'] = trimmed.substring(11).trim();
      }
    }

    return medicalMap;
  }
}