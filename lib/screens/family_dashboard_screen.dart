import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/family_dashboard_service.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  final FamilyDashboardService _dashboardService = FamilyDashboardService();
  bool _isLoading = true;

  static const List<String> _relationships = [
    'child', 'son', 'daughter',
    'parent', 'mother', 'father',
    'spouse', 'partner',
    'sibling', 'brother', 'sister',
    'grandparent', 'grandmother', 'grandfather',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _dashboardService.initialize();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0E27),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFA5)),
        ),
      );
    }

    final members = _dashboardService.getAllMembers();
    final stats = _dashboardService.getStatistics();
    final pendingCheckIns = _dashboardService.getPendingCheckIns();
    final activities = _dashboardService.getRecentActivities(limit: 10);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Family Safety'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: () => _showSettings(),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatisticsCard(stats),
            const SizedBox(height: 16),
            if (pendingCheckIns.isNotEmpty) ...[
              _buildSectionHeader('Pending Check-Ins', Icons.notifications_active),
              const SizedBox(height: 12),
              ...pendingCheckIns.map((c) => _buildCheckInCard(c)),
              const SizedBox(height: 16),
            ],
            _buildSectionHeader('Family Members', Icons.people),
            const SizedBox(height: 12),
            if (members.isEmpty)
              _buildEmptyState()
            else
              ...members.map((m) => _buildMemberCard(m)),
            const SizedBox(height: 16),
            _buildSectionHeader('Recent Activity', Icons.history),
            const SizedBox(height: 12),
            if (activities.isEmpty)
              _buildNoActivityState()
            else
              ...activities.take(5).map((a) => _buildActivityCard(a)),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFamilyMember(),
        backgroundColor: const Color(0xFF00BFA5),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BFA5), Color(0xFF1DE9B6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.family_restroom, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text(
                'Family Overview',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem('Total Members', '${stats['totalMembers']}', Icons.people)),
              Expanded(child: _buildStatItem('Active', '${stats['activeMembers']}', Icons.check_circle)),
              Expanded(child: _buildStatItem('Check-Ins', '${stats['pendingCheckIns']}', Icons.notifications)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildMemberCard(FamilyMember member) {
    final hasLocation = member.lastKnownLocation != null;
    final locationAge = hasLocation
        ? DateTime.now().difference(member.lastKnownLocation!.timestamp)
        : null;
    final isLocationRecent = locationAge != null && locationAge.inHours < 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2740),
        borderRadius: BorderRadius.circular(16),
        border: member.isPrimaryContact
            ? Border.all(color: const Color(0xFF00BFA5), width: 2)
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _dashboardService.getRelationshipColor(member.relationship).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: member.photoUrl != null
                      ? ClipOval(
                    child: Image.network(
                      member.photoUrl!,
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _dashboardService.getRelationshipIcon(member.relationship),
                        color: _dashboardService.getRelationshipColor(member.relationship),
                        size: 30,
                      ),
                    ),
                  )
                      : Icon(
                    _dashboardService.getRelationshipIcon(member.relationship),
                    color: _dashboardService.getRelationshipColor(member.relationship),
                    size: 30,
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
                          child: Text(member.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        if (member.isPrimaryContact)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BFA5).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('PRIMARY',
                                style: TextStyle(color: Color(0xFF00BFA5), fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_dashboardService.getRelationshipIcon(member.relationship),
                            color: _dashboardService.getRelationshipColor(member.relationship), size: 14),
                        const SizedBox(width: 4),
                        Text(member.relationship.toUpperCase(),
                            style: TextStyle(
                                color: _dashboardService.getRelationshipColor(member.relationship),
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        if (member.age > 0) ...[
                          const SizedBox(width: 8),
                          Text('${member.age} years old',
                              style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ],
                    ),
                    if (member.phoneNumber != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.phone, color: Colors.white38, size: 12),
                          const SizedBox(width: 4),
                          Text(member.phoneNumber!,
                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ],
                    if (hasLocation) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              color: isLocationRecent ? Colors.green : Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(_getLocationAge(member.lastKnownLocation!),
                                style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton(
                color: const Color(0xFF1E2740),
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _callMember(member),
                    child: const Row(children: [
                      Icon(Icons.phone, color: Color(0xFF00BFA5), size: 20),
                      SizedBox(width: 12),
                      Text('Call', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () => _requestCheckIn(member),
                    child: const Row(children: [
                      Icon(Icons.check_circle, color: Color(0xFF00BFA5), size: 20),
                      SizedBox(width: 12),
                      Text('Request Check-In', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () => _viewLocation(member),
                    child: const Row(children: [
                      Icon(Icons.location_on, color: Color(0xFF00BFA5), size: 20),
                      SizedBox(width: 12),
                      Text('View Location', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () => _editMember(member),
                    child: const Row(children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Text('Edit', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                  PopupMenuItem(
                    onTap: () => _removeMember(member),
                    child: const Row(children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Remove', style: TextStyle(color: Colors.white)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
          if (member.healthStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: member.healthStatus!.getStatusColor().withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: member.healthStatus!.getStatusColor().withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.favorite, color: member.healthStatus!.getStatusColor(), size: 18),
                  const SizedBox(width: 8),
                  if (member.healthStatus!.heartRate != null)
                    Text('${member.healthStatus!.heartRate} BPM',
                        style: TextStyle(
                            color: member.healthStatus!.getStatusColor(),
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 16),
                  if (member.healthStatus!.steps != null)
                    Row(
                      children: [
                        Icon(Icons.directions_walk,
                            color: member.healthStatus!.getStatusColor(), size: 18),
                        const SizedBox(width: 4),
                        Text('${member.healthStatus!.steps} steps',
                            style: TextStyle(
                                color: member.healthStatus!.getStatusColor(), fontSize: 13)),
                      ],
                    ),
                ],
              ),
            ),
          ],
          // Quick action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickAction(Icons.phone, 'Call', const Color(0xFF00BFA5), () => _callMember(member)),
              const SizedBox(width: 8),
              _buildQuickAction(Icons.check_circle, 'Check-In', Colors.orange, () => _requestCheckIn(member)),
              const SizedBox(width: 8),
              _buildQuickAction(Icons.location_on, 'Location', Colors.blue, () => _viewLocation(member)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInCard(CheckInRequest checkIn) {
    final member = _dashboardService.getMemberById(checkIn.memberId);
    if (member == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(checkIn.message,
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await _dashboardService.completeCheckIn(checkIn.id);
                    setState(() {});
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${member.name} checked in'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  },
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  child: const Text('Mark Complete'),
                ),
              ),
              if (member.phoneNumber != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _callMember(member),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call Now'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(FamilyActivity activity) {
    final member = _dashboardService.getMemberById(activity.memberId);
    if (member == null) return const SizedBox();

    IconData icon;
    Color color;
    switch (activity.activityType) {
      case 'check-in-completed':
        icon = Icons.check_circle; color = Colors.green; break;
      case 'check-in-requested':
        icon = Icons.pending_actions; color = Colors.orange; break;
      case 'location-updated':
        icon = Icons.location_on; color = Colors.blue; break;
      case 'member-added':
        icon = Icons.person_add; color = const Color(0xFF00BFA5); break;
      default:
        icon = Icons.info; color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1E2740), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.description,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text(_formatTimeAgo(activity.timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00BFA5), size: 24),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('No family members yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Tap the button below to add your first family member',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildNoActivityState() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text('No recent activity',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
      ),
    );
  }

  void _addFamilyMember() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRelationship = 'child';
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text('Add Family Member', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Full Name *', nameController, Icons.person),
                const SizedBox(height: 14),
                _dialogField('Phone Number', phoneController, Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 14),
                _dialogField('Email', emailController, Icons.email, type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  dropdownColor: const Color(0xFF1E2740),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedRelationship = val ?? selectedRelationship),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Primary Contact',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('First notified in emergencies',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: isPrimary,
                  activeColor: const Color(0xFF00BFA5),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPrimary = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name'), backgroundColor: Colors.red));
                  return;
                }
                final member = FamilyMember(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  relationship: selectedRelationship,
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  isPrimaryContact: isPrimary,
                  addedDate: DateTime.now(),
                );
                await _dashboardService.addMember(member);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${member.name} added to family'), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editMember(FamilyMember member) {
    final nameController = TextEditingController(text: member.name);
    final phoneController = TextEditingController(text: member.phoneNumber ?? '');
    final emailController = TextEditingController(text: member.email ?? '');
    String selectedRelationship =
    _relationships.contains(member.relationship) ? member.relationship : 'other';
    bool isPrimary = member.isPrimaryContact;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: Text('Edit ${member.name}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Full Name *', nameController, Icons.person),
                const SizedBox(height: 14),
                _dialogField('Phone Number', phoneController, Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 14),
                _dialogField('Email', emailController, Icons.email, type: TextInputType.emailAddress),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: selectedRelationship,
                  dropdownColor: const Color(0xFF1E2740),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1))))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedRelationship = val ?? selectedRelationship),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  title: const Text('Primary Contact',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('First notified in emergencies',
                      style: TextStyle(color: Colors.white54, fontSize: 11)),
                  value: isPrimary,
                  activeColor: const Color(0xFF00BFA5),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) => setDialogState(() => isPrimary = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final updated = FamilyMember(
                  id: member.id,
                  name: nameController.text.trim(),
                  relationship: selectedRelationship,
                  photoUrl: member.photoUrl,
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                  birthday: member.birthday,
                  lastKnownLocation: member.lastKnownLocation,
                  healthStatus: member.healthStatus,
                  isPrimaryContact: isPrimary,
                  addedDate: member.addedDate,
                );
                await _dashboardService.updateMember(updated);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${updated.name} updated'), backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeMember(FamilyMember member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: const Text('Remove Family Member', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${member.name} from your family?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _dashboardService.removeMember(member.id);
              if (mounted) {
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Member removed'), backgroundColor: Colors.green));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _callMember(FamilyMember member) async {
    if (member.phoneNumber == null || member.phoneNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No phone number saved for ${member.name}'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: Text('Call ${member.name}?', style: const TextStyle(color: Colors.white)),
        content: Text(member.phoneNumber!,
            style: const TextStyle(color: Color(0xFF00BFA5), fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            child: const Text('CALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri.parse('tel:${member.phoneNumber}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch dialer'), backgroundColor: Colors.red));
      }
    }
  }

  void _requestCheckIn(FamilyMember member) async {
    await _dashboardService.requestCheckIn(
        member.id, 'Please check in to let us know you\'re safe');
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Check-in requested from ${member.name}'),
          backgroundColor: Colors.green));
    }
  }

  void _viewLocation(FamilyMember member) {
    if (member.lastKnownLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No location available'), backgroundColor: Colors.orange));
      return;
    }

    final loc = member.lastKnownLocation!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2740),
        title: Text('${member.name}\'s Location', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFF00BFA5), size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(loc.address, style: const TextStyle(color: Colors.white))),
              ],
            ),
            const SizedBox(height: 8),
            Text('${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 6),
            Text('Updated: ${_getLocationAge(loc)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (loc.batteryLevel != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    loc.batteryLevel! > 20 ? Icons.battery_std : Icons.battery_alert,
                    color: loc.batteryLevel! > 20 ? Colors.green : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text('Battery: ${loc.batteryLevel!.toStringAsFixed(0)}%',
                      style: TextStyle(
                          color: loc.batteryLevel! > 20 ? Colors.green : Colors.red,
                          fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Open Maps'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(
                  'https://maps.google.com/?q=${loc.latitude},${loc.longitude}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open Maps'), backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    int interval = _dashboardService.getCheckInInterval();
    bool wanderingAlert = _dashboardService.isAutoCheckInEnabled();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E2740),
          title: const Text('Family Dashboard Settings', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Auto Check-Ins', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Request periodic check-ins',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  value: _dashboardService.isAutoCheckInEnabled(),
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    _dashboardService.updateSettings(autoCheckIn: value);
                    setDialogState(() {}); setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Location Sharing', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Share locations with family',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  value: _dashboardService.isLocationSharingEnabled(),
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    _dashboardService.updateSettings(locationSharing: value);
                    setDialogState(() {}); setState(() {});
                  },
                ),
                SwitchListTile(
                  title: const Text('Health Monitoring', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Track health from wearables',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  value: _dashboardService.isHealthMonitoringEnabled(),
                  activeColor: const Color(0xFF00BFA5),
                  onChanged: (value) {
                    _dashboardService.updateSettings(healthMonitoring: value);
                    setDialogState(() {}); setState(() {});
                  },
                ),
                const Divider(color: Colors.white12, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Check-In Every',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                    Text('$interval hrs',
                        style: const TextStyle(
                            color: Color(0xFF00BFA5), fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: interval.toDouble(),
                  min: 1, max: 48, divisions: 47,
                  activeColor: const Color(0xFF00BFA5),
                  label: '${interval}h',
                  onChanged: (val) {
                    setDialogState(() => interval = val.toInt());
                    _dashboardService.updateSettings(checkInInterval: val.toInt());
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1h', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    Text('48h', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ELDER CARE',
                      style: TextStyle(
                          color: Color(0xFF00BFA5), fontSize: 11,
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.elderly, color: Colors.orange, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Wandering Alerts',
                                style: TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Alert when senior leaves safe zone',
                                style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: wanderingAlert,
                        activeColor: Colors.orange,
                        onChanged: (val) {
                          setDialogState(() => wanderingAlert = val);
                          _dashboardService.updateSettings(autoCheckIn: val);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  TextField _dialogField(String label, TextEditingController controller, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00BFA5))),
      ),
    );
  }

  String _getLocationAge(LocationInfo location) {
    final age = DateTime.now().difference(location.timestamp);
    if (age.inMinutes < 1) return 'Just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dateTime);
  }
}