import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        elevation: 0,
        backgroundColor: const Color(0xFF00BFA5),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildHeaderCard(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 24),

          // FAQs Section
          _buildSectionHeader('Frequently Asked Questions', Icons.quiz),
          const SizedBox(height: 12),
          _buildFAQItem(
            'How do I add emergency contacts?',
            'Go to Emergency Contacts from the main menu, tap the + button, '
                'and enter their details. You can add up to 5 contacts with names, '
                'phone numbers, and relationships.',
            Icons.contact_phone,
          ),
          _buildFAQItem(
            'How does the panic button work?',
            'Simply tap the large red panic button on the home screen. It will '
                'immediately send your GPS location and alert message to all your '
                'emergency contacts via SMS. They\'ll receive a text with your exact '
                'coordinates and a Google Maps link.',
            Icons.emergency,
          ),
          _buildFAQItem(
            'What is silent activation?',
            'Long-press (hold) the panic button for 3 seconds to trigger a '
                'silent alert without sound or vibration. This is useful when you\'re '
                'in a dangerous situation and need to call for help discreetly.',
            Icons.volume_off,
          ),
          _buildFAQItem(
            'Can I cancel a panic alert?',
            'Yes! If the countdown feature is enabled in settings, you have 10 '
                'seconds to cancel before the alert is sent. Otherwise, alerts are '
                'sent immediately when you tap the button.',
            Icons.cancel,
          ),
          _buildFAQItem(
            'Does it work without internet?',
            'Yes! The app uses SMS which only requires cellular network (not WiFi). '
                'Your GPS location works offline too and will be embedded in the text '
                'message sent to your contacts.',
            Icons.signal_cellular_alt,
          ),
          _buildFAQItem(
            'How accurate is the GPS location?',
            'GPS is typically accurate within 5-50 meters depending on your device, '
                'weather conditions, and environment. It works best outdoors with a '
                'clear view of the sky. Indoor accuracy may be lower.',
            Icons.location_on,
          ),
          _buildFAQItem(
            'Can I customize the alert message?',
            'Yes! Go to Settings > Message Templates to customize your emergency '
                'message. You can create multiple templates for different situations.',
            Icons.message,
          ),
          _buildFAQItem(
            'What happens if my phone battery dies?',
            'Make sure to keep your phone charged at all times. Consider carrying '
                'a power bank. The app has battery optimization features, but it cannot '
                'work if the phone is completely dead.',
            Icons.battery_alert,
          ),

          const SizedBox(height: 32),

          // Emergency Safety Tips
          _buildSectionHeader('Emergency Safety Tips', Icons.shield),
          const SizedBox(height: 12),
          _buildTipCard(
            ' Test Regularly',
            'Test your panic button monthly! Send a test alert to your contacts '
                'to ensure they receive messages and the GPS location is accurate. '
                'Let them know it\'s just a test.',
            Colors.orange,
          ),
          _buildTipCard(
            ' Keep Battery Charged',
            'Always keep your phone charged above 20%. Enable battery saver mode '
                'if needed, and consider carrying a portable power bank for emergencies.',
            Colors.green,
          ),
          _buildTipCard(
            ' Update Contacts',
            'Regularly verify your emergency contacts. Make sure phone numbers '
                'are current and contacts are reachable. Remove contacts who are no '
                'longer available.',
            Colors.blue,
          ),
          _buildTipCard(
            ' Enable Biometric Lock',
            'Protect your app with fingerprint or face unlock to prevent '
                'unauthorized access to your emergency contacts and alert history.',
            Colors.purple,
          ),
          _buildTipCard(
            ' Enable Location Always',
            'For best results, allow location access "Always" in phone settings '
                'so GPS works even when the app is in the background or closed.',
            Colors.red,
          ),
          _buildTipCard(
            ' Disable Do Not Disturb',
            'Make sure "Do Not Disturb" is off or configure it to allow alerts '
                'from your emergency contacts so you can receive their responses.',
            Colors.teal,
          ),

          const SizedBox(height: 32),

          // Quick Feature Guide
          _buildSectionHeader('Quick Feature Guide', Icons.apps),
          const SizedBox(height: 12),
          _buildFeatureGuideCard(
            Icons.touch_app,
            'Panic Button',
            [
              'Single tap: Instant alert with countdown',
              'Long press (3s): Silent alert, no sound',
              'With countdown: 10 seconds to cancel',
              'Without countdown: Immediate alert',
            ],
            Colors.red,
          ),
          _buildFeatureGuideCard(
            Icons.contacts,
            'Emergency Contacts',
            [
              'Add up to 5 trusted contacts',
              'Organize into groups (Family, Friends, etc.)',
              'Set priority levels for each contact',
              'Verify phone numbers are correct',
            ],
            Colors.blue,
          ),
          _buildFeatureGuideCard(
            Icons.location_searching,
            'Location Sharing',
            [
              'Automatically sends GPS coordinates',
              'Includes Google Maps link in SMS',
              'Works offline with cellular network',
              'Typical accuracy: 5-50 meters',
            ],
            Colors.green,
          ),
          _buildFeatureGuideCard(
            Icons.history,
            'Panic History',
            [
              'View all past panic alerts',
              'See when and where alerts were sent',
              'Export event data for records',
              'Delete old alerts when needed',
            ],
            Colors.orange,
          ),
          _buildFeatureGuideCard(
            Icons.settings,
            'Settings & Customization',
            [
              'Customize alert messages',
              'Toggle countdown timer on/off',
              'Enable/disable haptic feedback',
              'Configure sound and vibration',
            ],
            Colors.purple,
          ),

          const SizedBox(height: 32),

          // Troubleshooting Section
          _buildSectionHeader('Troubleshooting', Icons.build),
          const SizedBox(height: 12),
          _buildTroubleshootingCard(
            ' SMS Not Sending',
            [
              'Check cellular network signal strength',
              'Verify SMS permission is granted in settings',
              'Ensure contact phone numbers are valid',
              'Check if you have active cellular service',
              'Try restarting the app and phone',
              'Verify SIM card is properly inserted',
            ],
          ),
          _buildTroubleshootingCard(
            ' Location Not Working',
            [
              'Enable Location Services in phone settings',
              'Grant location permission to app (Always)',
              'Ensure GPS is turned on',
              'Move to an open area with clear sky view',
              'Wait 30-60 seconds for GPS to acquire signal',
              'Check if airplane mode is off',
            ],
          ),
          _buildTroubleshootingCard(
            ' Notifications Not Showing',
            [
              'Check notification permissions are granted',
              'Disable battery optimization for this app',
              'Ensure "Do Not Disturb" is off',
              'Check notification settings for the app',
              'Restart your device',
              'Clear app cache and data (last resort)',
            ],
          ),
          _buildTroubleshootingCard(
            ' App Crashing or Freezing',
            [
              'Update to the latest app version',
              'Clear app cache in phone settings',
              'Restart your phone',
              'Reinstall the app (backup data first)',
              'Check if phone storage is full',
              'Contact support if problem persists',
            ],
          ),

          const SizedBox(height: 32),

          // Contact Support Section
          _buildSectionHeader('Need More Help?', Icons.support_agent),
          const SizedBox(height: 12),
          _buildContactCard(
            Icons.email,
            'Email Support',
            'support@akel.app',
            'Get help via email (24-48 hour response)',
            'mailto:support@akel.app',
          ),
          _buildContactCard(
            Icons.phone,
            'Emergency Hotline',
            '+1-800-AKEL-911',
            'Call for urgent support',
            'tel:+18002535911',
          ),
          _buildContactCard(
            Icons.language,
            'Visit Website',
            'www.akel.app',
            'Access online help center and documentation',
            'https://akel.app',
          ),
          _buildContactCard(
            Icons.video_library,
            'Video Tutorials',
            'YouTube Channel',
            'Watch step-by-step how-to videos',
            'https://youtube.com/@akelapp',
          ),
          _buildContactCard(
            Icons.chat,
            'Community Forum',
            'forum.akel.app',
            'Connect with other users and get tips',
            'https://forum.akel.app',
          ),

          const SizedBox(height: 32),

          // App Information
          _buildAppInfoCard(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(Icons.help_outline, size: 56, color: Colors.white),
          SizedBox(height: 16),
          Text(
            'How can we help you?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find answers, tips, and support',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            context,
            Icons.contact_support,
            'Contact Us',
            Colors.blue,
                () => _launchURL('mailto:support@akel.app'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            context,
            Icons.play_circle_outline,
            'Tutorials',
            Colors.red,
                () => _launchURL('https://youtube.com/@akelapp'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
            child: Icon(icon, color: const Color(0xFF00BFA5), size: 22),
          ),
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.6,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(String title, String description, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGuideCard(
      IconData icon,
      String title,
      List<String> points,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  radius: 24,
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...points.map((point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard(String problem, List<String> solutions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFF3E0),
            child: Icon(Icons.error_outline, color: Colors.orange),
          ),
          title: Text(
            problem,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Solutions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...solutions.map((solution) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓ ',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            solution,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
      IconData icon,
      String title,
      String subtitle,
      String description,
      String url,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00BFA5).withOpacity(0.1),
          radius: 28,
          child: Icon(icon, color: const Color(0xFF00BFA5), size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF00BFA5),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () => _launchURL(url),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield,
                size: 48,
                color: Color(0xFF00BFA5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AKEL Panic Button',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0 (MVP)',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'IMPORTANT DISCLAIMER',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This app is a safety enhancement tool, NOT a substitute for '
                        'official emergency services. Always contact local authorities '
                        '(911, 112, etc.) in critical situations.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 Kryptickel. All rights reserved.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}