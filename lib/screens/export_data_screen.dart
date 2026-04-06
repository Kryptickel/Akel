import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../services/export_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final ExportService _exportService = ExportService();
  bool _isExporting = false;

  Future<void> _exportContacts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isExporting = true);

    try {
      final csvData = await _exportService.exportContactsToCSV(userId);
      final fileName = _exportService.getContactsFileName();

      await _saveAndShare(csvData, fileName, 'Contacts exported successfully!');
    } catch (e) {
      _showError('Failed to export contacts: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPanicHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isExporting = true);

    try {
      final jsonData = await _exportService.exportPanicHistoryToJSON(userId);
      final fileName = _exportService.getPanicHistoryFileName();

      await _saveAndShare(jsonData, fileName, 'Panic history exported successfully!');
    } catch (e) {
      _showError('Failed to export panic history: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isExporting = true);

    try {
      final jsonData = await _exportService.exportUserProfile(userId);
      final fileName = _exportService.getProfileFileName();

      await _saveAndShare(jsonData, fileName, 'Profile exported successfully!');
    } catch (e) {
      _showError('Failed to export profile: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportFullBackup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    setState(() => _isExporting = true);

    try {
      final jsonData = await _exportService.exportFullBackup(userId);
      final fileName = _exportService.getFullBackupFileName();

      await _saveAndShare(jsonData, fileName, 'Full backup created successfully!');
    } catch (e) {
      _showError('Failed to create backup: $e');
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _saveAndShare(String data, String fileName, String successMessage) async {
    try {
      // For web, use download
      if (kIsWeb) {
        // Create blob and download link
        final bytes = utf8.encode(data);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // For mobile, use file system and share
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(data);

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'AKEL Data Export - $fileName',
          text: 'Here is your exported AKEL data.',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to save and share file: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isExporting
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00BFA5)),
            SizedBox(height: 20),
            Text(
              'Preparing export...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          const Text(
            'Export Your Data',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            kIsWeb
                ? 'Download your AKEL data to your computer'
                : 'Download your AKEL data for backup or transfer',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 32),

          // Export Contacts Card
          _buildExportCard(
            icon: Icons.contacts,
            iconColor: const Color(0xFF00BFA5),
            title: 'Export Contacts',
            subtitle: 'Download all emergency contacts as CSV',
            buttonText: 'Export CSV',
            onTap: _exportContacts,
          ),
          const SizedBox(height: 16),

          // Export Panic History Card
          _buildExportCard(
            icon: Icons.history,
            iconColor: Colors.orange,
            title: 'Export Panic History',
            subtitle: 'Download all panic events as JSON',
            buttonText: 'Export JSON',
            onTap: _exportPanicHistory,
          ),
          const SizedBox(height: 16),

          // Export Profile Card
          _buildExportCard(
            icon: Icons.person,
            iconColor: Colors.blue,
            title: 'Export Profile',
            subtitle: 'Download your profile information',
            buttonText: 'Export JSON',
            onTap: _exportProfile,
          ),
          const SizedBox(height: 16),

          // Full Backup Card
          _buildExportCard(
            icon: Icons.backup,
            iconColor: Colors.purple,
            title: 'Full Backup',
            subtitle: 'Export everything (profile, contacts, history)',
            buttonText: 'Create Backup',
            onTap: _exportFullBackup,
            highlight: true,
          ),
          const SizedBox(height: 32),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[300],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'Files will be downloaded to your Downloads folder. You can then upload them to cloud storage or email them.'
                        : 'Exported files can be shared via email, saved to cloud storage, or transferred to another device.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildExportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Card(
      color: highlight
          ? const Color(0xFF2A3555)
          : const Color(0xFF1E2740),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.2),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.file_download, size: 20),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: highlight
                      ? Colors.purple
                      : iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}