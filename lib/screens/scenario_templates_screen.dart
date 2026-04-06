import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/scenario_template_service.dart';
import '../services/vibration_service.dart';

class ScenarioTemplatesScreen extends StatefulWidget {
  const ScenarioTemplatesScreen({super.key});

  @override
  State<ScenarioTemplatesScreen> createState() => _ScenarioTemplatesScreenState();
}

class _ScenarioTemplatesScreenState extends State<ScenarioTemplatesScreen> {
  final ScenarioTemplateService _templateService = ScenarioTemplateService();
  final VibrationService _vibrationService = VibrationService();

  List<ScenarioTemplate> _templates = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
    _loadStatistics();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final templates = _showFavoritesOnly
            ? await _templateService.getFavoriteTemplates(userId)
            : await _templateService.getTemplates(userId);

        if (mounted) {
          setState(() {
            _templates = templates;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint(' Load templates error: $e');
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
        final stats = await _templateService.getTemplateStatistics(userId);

        if (mounted) {
          setState(() {
            _statistics = stats;
          });
        }
      } catch (e) {
        debugPrint(' Load statistics error: $e');
      }
    }
  }

  Future<void> _createDefaultTemplates() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    await _vibrationService.light();

    setState(() => _isLoading = true);

    await _templateService.createDefaultTemplates(userId);

    setState(() => _isLoading = false);

    if (mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Default templates created'),
          backgroundColor: Colors.green,
        ),
      );

      _loadTemplates();
      _loadStatistics();
    }
  }

  Future<void> _activateTemplate(ScenarioTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ScenarioTemplateService.getTypeIcon(template.type)} Activate Scenario?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              template.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Message:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(template.message),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...{
              if (template.actions.startLocationTracking) ' Start Location Tracking',
              if (template.actions.startAudioRecording) ' Start Audio Recording',
              if (template.actions.startVideoRecording) ' Start Video Recording',
              if (template.actions.sendBroadcast) ' Send Broadcast',
              if (template.actions.callEmergencyServices) ' Call Emergency Services',
              if (template.actions.activateSiren) ' Activate Siren',
              if (template.actions.shareLocationLive) ' Share Live Location',
            }.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $action', style: const TextStyle(fontSize: 12)),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Activate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _vibrationService.success();
      await _templateService.recordUsage(template.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' ${template.name} activated!'),
            backgroundColor: Colors.red,
          ),
        );

        _loadTemplates();
        _loadStatistics();
      }

      // In production, this would trigger the actual emergency actions
      debugPrint(' Scenario activated: ${template.name}');
    }
  }

  Future<void> _toggleFavorite(ScenarioTemplate template) async {
    await _vibrationService.light();

    final success = await _templateService.updateTemplate(
      templateId: template.id,
      isFavorite: !template.isFavorite,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            template.isFavorite
                ? ' Removed from favorites'
                : ' Added to favorites',
          ),
          duration: const Duration(seconds: 1),
        ),
      );

      _loadTemplates();
    }
  }

  Future<void> _duplicateTemplate(ScenarioTemplate template) async {
    await _vibrationService.light();

    setState(() => _isLoading = true);

    final duplicate = await _templateService.duplicateTemplate(template.id);

    setState(() => _isLoading = false);

    if (duplicate != null && mounted) {
      await _vibrationService.success();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(' Template duplicated'),
          backgroundColor: Colors.green,
        ),
      );

      _loadTemplates();
      _loadStatistics();
    }
  }

  Future<void> _deleteTemplate(ScenarioTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template?'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
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
      final success = await _templateService.deleteTemplate(template.id);

      if (success && mounted) {
        await _vibrationService.success();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(' Template deleted'),
            backgroundColor: Colors.green,
          ),
        );

        _loadTemplates();
        _loadStatistics();
      }
    }
  }

  void _showTemplateDetails(ScenarioTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${ScenarioTemplateService.getTypeIcon(template.type)} ${template.name}',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', ScenarioTemplateService.getTypeLabel(template.type)),
              _buildDetailRow('Usage Count', '${template.usageCount}'),
              if (template.lastUsed != null)
                _buildDetailRow(
                  'Last Used',
                  DateFormat('MMM dd, yyyy hh:mm a').format(template.lastUsed!),
                ),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Text(template.message),
              ),
              const SizedBox(height: 16),
              const Text(
                'Contact Groups:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: template.contactGroups
                    .map((group) => Chip(
                  label: Text(group),
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Auto Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...{
                if (template.actions.startLocationTracking) ' Location Tracking',
                if (template.actions.startAudioRecording) ' Audio Recording',
                if (template.actions.startVideoRecording) ' Video Recording',
                if (template.actions.sendBroadcast) ' Broadcast',
                if (template.actions.callEmergencyServices) ' Call 911',
                if (template.actions.activateSiren) ' Siren',
                if (template.actions.shareLocationLive) ' Live Location',
              }.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(action),
                  ],
                ),
              )),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Templates'),
        actions: [
          IconButton(
            icon: Icon(_showFavoritesOnly ? Icons.star : Icons.star_border),
            tooltip: _showFavoritesOnly ? 'Show All' : 'Show Favorites',
            onPressed: () {
              _vibrationService.light();
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
              _loadTemplates();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _vibrationService.light();
              _loadTemplates();
              _loadStatistics();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          if (_statistics != null) _buildStatisticsCard(),

          // Info Card
          _buildInfoCard(),

          // Templates List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _templates.isEmpty
                ? _buildEmptyState()
                : _buildTemplatesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createDefaultTemplates,
        icon: const Icon(Icons.add),
        label: const Text('Create Defaults'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final total = _statistics!['totalTemplates'] as int;
    final favorites = _statistics!['favoriteTemplates'] as int;
    final usage = _statistics!['totalUsage'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue,
            Colors.blue.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Templates', '$total', Icons.description),
          _buildStatItem('Favorites', '$favorites', Icons.star),
          _buildStatItem('Used', '$usage', Icons.trending_up),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  'Emergency Scenarios',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pre-configured templates for quick emergency response.',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Templates Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create default templates to get started',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createDefaultTemplates,
            icon: const Icon(Icons.add),
            label: const Text('Create Default Templates'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(ScenarioTemplate template) {
    final typeColor = _hexToColor(ScenarioTemplateService.getTypeColor(template.type));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () {
          _vibrationService.light();
          _showTemplateDetails(template);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        ScenarioTemplateService.getTypeIcon(template.type),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                template.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                template.isFavorite ? Icons.star : Icons.star_border,
                                color: template.isFavorite ? Colors.amber : Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => _toggleFavorite(template),
                            ),
                          ],
                        ),
                        Text(
                          ScenarioTemplateService.getTypeLabel(template.type),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                template.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${template.contactGroups.length} group(s)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.touch_app, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Used ${template.usageCount}x',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateTemplate(template),
                      icon: const Icon(Icons.emergency, size: 16),
                      label: const Text('Activate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _duplicateTemplate(template),
                    tooltip: 'Duplicate',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteTemplate(template),
                    tooltip: 'Delete',
                  ),
                ],
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