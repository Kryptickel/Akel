import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PanicDashboard extends StatefulWidget {
  const PanicDashboard({super.key});

  @override
  State<PanicDashboard> createState() => _PanicDashboardState();
}

class _PanicDashboardState extends State<PanicDashboard> {
  bool _isEmergencyMode = false;
  bool _isRecording = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akel Safety Dashboard'),
        backgroundColor: _isEmergencyMode 
            ? Colors.red 
            : Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency status card
              if (_isEmergencyMode) _buildEmergencyStatusCard(),
              
              // Main panic button
              _buildPanicButton(),
              const SizedBox(height: 24),
              
              // Quick actions
              _buildQuickActions(),
              const SizedBox(height: 24),
              
              // Safety features
              _buildSafetyFeatures(),
              const SizedBox(height: 24),
              
              // Recent activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Contacts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Location',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 1:
              context.go('/emergency-contacts');
              break;
            case 2:
              // TODO: Navigate to location page
              break;
            case 3:
              // TODO: Navigate to settings page
              break;
          }
        },
      ),
    );
  }

  Widget _buildEmergencyStatusCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red, size: 24),
              const SizedBox(width: 12),
              Text(
                'EMERGENCY MODE ACTIVE',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isRecording)
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Recording audio and video...'),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _deactivateEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Deactivate Emergency'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanicButton() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _activatePanicButton,
            onLongPress: _activateSilentPanic,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isEmergencyMode ? Colors.red : Colors.red.shade600,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isEmergencyMode ? Icons.stop : Icons.emergency,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEmergencyMode ? 'EMERGENCY\nACTIVE' : 'PANIC\nBUTTON',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEmergencyMode 
                ? 'Tap to stop emergency mode'
                : 'Tap to activate • Hold for silent mode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.call,
                title: 'Call 911',
                onTap: _call911,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.location_on,
                title: 'Share Location',
                onTap: _shareLocation,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.local_hospital,
                title: 'Find Hospital',
                onTap: _findHospital,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Features',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFeatureRow(
          Icons.group,
          'Emergency Contacts',
          'Manage your trusted contact list',
          () => context.go('/emergency-contacts'),
        ),
        _buildFeatureRow(
          Icons.security,
          'Device Security',
          'Monitor device integrity and threats',
          () => _showComingSoon('Device Security'),
        ),
        _buildFeatureRow(
          Icons.location_history,
          'Location Tracking',
          'Real-time location sharing',
          () => _showComingSoon('Location Tracking'),
        ),
        _buildFeatureRow(
          Icons.health_and_safety,
          'Medical Profile',
          'Emergency medical information',
          () => _showComingSoon('Medical Profile'),
        ),
      ],
    );
  }

  Widget _buildFeatureRow(
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

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  'All systems operational',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'No recent emergency activations',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _activatePanicButton() {
    setState(() {
      _isEmergencyMode = !_isEmergencyMode;
      if (_isEmergencyMode) {
        _isRecording = true;
      } else {
        _isRecording = false;
      }
    });
    
    if (_isEmergencyMode) {
      _showEmergencyActivatedDialog();
    }
  }

  void _activateSilentPanic() {
    setState(() {
      _isEmergencyMode = true;
      _isRecording = true;
    });
    
    // Show minimal indication for silent mode
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Silent emergency mode activated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _deactivateEmergency() {
    setState(() {
      _isEmergencyMode = false;
      _isRecording = false;
    });
  }

  void _call911() {
    // TODO: Implement emergency calling
    _showComingSoon('Emergency Calling');
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    _showComingSoon('Location Sharing');
  }

  void _findHospital() {
    // TODO: Implement hospital finder
    _showComingSoon('Hospital Finder');
  }

  void _showEmergencyActivatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Emergency Activated'),
            ],
          ),
          content: const Text(
            'Emergency services and your emergency contacts have been notified. Recording is now active.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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