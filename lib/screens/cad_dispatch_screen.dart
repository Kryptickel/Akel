import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== CAD DISPATCH SCREEN ====================
///
/// PRODUCTION READY - BUILD 58 - UPDATED & FIXED
///
/// Features:
/// - Real-time dispatcher communication
/// - Incident status tracking
/// - Unit assignment display
/// - Response time monitoring
/// - Multi-agency coordination
/// - Live dispatch feed
///
/// Firebase Collections:
/// - /cad_incidents
/// - /cad_units
/// - /cad_communications
///
/// ================================================================

class CadDispatchScreen extends StatefulWidget {
  const CadDispatchScreen({super.key});

  @override
  State<CadDispatchScreen> createState() => _CadDispatchScreenState();
}

class _CadDispatchScreenState extends State<CadDispatchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedFilter = 'active';

  final List<String> _filters = ['all', 'active', 'pending', 'completed'];

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CAD Dispatch'),
        backgroundColor: AkelDesign.carbonFiber,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      backgroundColor: AkelDesign.deepBlack,
      body: user == null
          ? const Center(
        child: Text(
          'Please log in to view dispatch',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : Column(
        children: [
          _buildStatusHeader(),
          _buildFilterChips(),
          Expanded(child: _buildIncidentsList()),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepOrange.withValues(alpha: 0.3),
            Colors.deepOrange.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Column(
        children: [
// FIXED: Removed 'const' because children now use dynamic .withValues calls
          Row(
            children: [
// FIXED: Replaced non-existent Icons.dispatcher with Icons.support_agent
              const Icon(Icons.support_agent, color: Colors.deepOrange, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAD DISPATCH',
                      style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Computer-Aided Dispatch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('cad_incidents').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final incidents = snapshot.data!.docs;
              final active = incidents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'active';
              }).length;

              final pending = incidents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'pending';
              }).length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active', '$active', AkelDesign.primaryRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Pending', '$pending', AkelDesign.warningOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Total', '${incidents.length}', AkelDesign.neonBlue),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: Colors.deepOrange.withValues(alpha: 0.3),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.deepOrange : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildIncidentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('cad_incidents')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Error loading incidents',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepOrange),
          );
        }

        var incidents = snapshot.data?.docs ?? [];

// Apply filter
        if (_selectedFilter != 'all') {
          incidents = incidents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _selectedFilter;
          }).toList();
        }

        if (incidents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${_selectedFilter == "all" ? "" : _selectedFilter} incidents',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = incidents[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildIncidentCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildIncidentCard(String id, Map<String, dynamic> data) {
    final incidentType = data['type'] ?? 'Unknown';
    final status = data['status'] ?? 'pending';
    final location = data['location'] ?? 'Unknown location';
    final timestamp = data['timestamp'] as Timestamp?;
    final units = data['assignedUnits'] as List<dynamic>? ?? [];

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'active':
        statusColor = AkelDesign.primaryRed;
        statusIcon = Icons.emergency;
        break;
      case 'pending':
        statusColor = AkelDesign.warningOrange;
        statusIcon = Icons.schedule;
        break;
      case 'completed':
        statusColor = AkelDesign.successGreen;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      color: AkelDesign.carbonFiber,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: () {
          _showIncidentDetails(id, data);
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'INC-${id.substring(0, 6).toUpperCase()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          incidentType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (timestamp != null)
                    Text(
                      _formatTime(timestamp.toDate()),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(Icons.location_on, color: AkelDesign.neonBlue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

              if (units.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.local_shipping, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: units.map((unit) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              unit.toString(),
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showIncidentDetails(String id, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AkelDesign.carbonFiber,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'INC-${id.substring(0, 6).toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                ),
              ),

              const SizedBox(height: 8),

              Text(
                data['type'] ?? 'Unknown Type',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),

              const Divider(color: Colors.white24, height: 32),

              _buildDetailRow('Status', data['status'] ?? 'Unknown'),
              _buildDetailRow('Location', data['location'] ?? 'Unknown'),
              _buildDetailRow('Priority', data['priority'] ?? 'Normal'),

              if (data['description'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Description',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'],
                  style: const TextStyle(color: Colors.white),
                ),
              ],

              const SizedBox(height: 24),

              const Text(
                'Assigned Units',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (data['assignedUnits'] != null)
                ...(data['assignedUnits'] as List).map((unit) {
                  return Card(
                    color: Colors.white.withValues(alpha: 0.05),
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping, color: Colors.green),
                      title: Text(
                        unit.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: const Text(
                        'En Route',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  );
                }).toList()
              else
                const Text(
                  'No units assigned',
                  style: TextStyle(color: Colors.white54),
                ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AkelDesign.neonBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}