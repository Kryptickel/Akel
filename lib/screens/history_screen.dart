import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

import '../providers/auth_provider.dart';
import '../services/panic_service_v2.dart';
import '../widgets/futuristic_widgets.dart';
import '../widgets/glossy_3d_widgets.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== HISTORY SCREEN ====================
///
/// AKEL PANIC BUTTON - PANIC HISTORY
///
/// Displays all past panic alerts with:
/// - Timeline view
/// - Location maps
/// - Contact notifications
/// - Filter by date
/// - Export capability
///
/// =====================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  final PanicServiceV2 _panicService = PanicServiceV2();

  String _selectedFilter = 'all'; // all, today, week, month
  bool _isLoading = true;

  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  DateTime? _getFilterDate() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return DateTime(now.year, now.month, now.day);
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return now.subtract(const Duration(days: 30));
      default:
        return null;
    }
  }

  Stream<QuerySnapshot> _getPanicHistoryStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('panic_history')
        .orderBy('timestamp', descending: true);

    final filterDate = _getFilterDate();
    if (filterDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: filterDate);
    }

    return query.limit(50).snapshots();
  }

  Future<void> _openLocation(double lat, double lng) async {
    final url = 'https://maps.google.com/?q=$lat,$lng';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open maps'),
            backgroundColor: AkelDesign.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteAlert(String userId, String alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
          side: BorderSide(
            color: AkelDesign.errorRed.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AkelDesign.errorRed, size: 32),
            const SizedBox(width: 12),
            Text('Delete Alert?', style: AkelDesign.h3.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          'This action cannot be undone.\n\nAre you sure you want to delete this panic alert record?',
          style: AkelDesign.body,
        ),
        actions: [
          FuturisticButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            isOutlined: true,
            isSmall: true,
          ),
          const SizedBox(width: 8),
          FuturisticButton(
            text: 'Delete',
            icon: Icons.delete,
            onPressed: () => Navigator.pop(context, true),
            color: AkelDesign.errorRed,
            isSmall: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('panic_history')
            .doc(alertId)
            .delete();

        if (mounted) {
          _panicService.triggerHapticFeedback(type: HapticType.success);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert deleted'),
              backgroundColor: AkelDesign.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AkelDesign.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllHistory(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AkelDesign.darkPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
          side: BorderSide(
            color: AkelDesign.errorRed.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning, color: AkelDesign.warningOrange, size: 32),
            const SizedBox(width: 12),
            Text('Clear All History?', style: AkelDesign.h3.copyWith(fontSize: 18)),
          ],
        ),
        content: Text(
          'WARNING: This will permanently delete ALL panic alert records.\n\nThis action CANNOT be undone!\n\nAre you absolutely sure?',
          style: AkelDesign.body,
        ),
        actions: [
          FuturisticButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(context, false),
            isOutlined: true,
            isSmall: true,
          ),
          const SizedBox(width: 8),
          FuturisticButton(
            text: 'Delete All',
            icon: Icons.delete_sweep,
            onPressed: () => Navigator.pop(context, true),
            color: AkelDesign.errorRed,
            isSmall: true,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('panic_history')
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          _panicService.triggerHapticFeedback(type: HapticType.success);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${snapshot.docs.length} alerts'),
              backgroundColor: AkelDesign.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AkelDesign.errorRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _panicService.triggerHapticFeedback(type: HapticType.light);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [
              AkelDesign.neonBlue.withValues(alpha: 0.3),
              AkelDesign.neonBlue.withValues(alpha: 0.1),
            ],
          )
              : LinearGradient(
            colors: [
              AkelDesign.carbonFiber.withValues(alpha: 0.5),
              AkelDesign.deepBlack.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
          border: Border.all(
            color: isSelected
                ? AkelDesign.neonBlue
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AkelDesign.neonBlue.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AkelDesign.neonBlue : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AkelDesign.neonBlue : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, String alertId, String userId) {
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final location = data['location'] as Map<String, dynamic>?;
    final contactsNotified = data['contacts_notified'] ?? 0;
    final totalContacts = data['total_contacts'] ?? 0;
    final silent = data['silent'] ?? false;
    final message = data['message'] as String?;

    final hasLocation = location != null &&
        location['latitude'] != null &&
        location['longitude'] != null;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.3),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  AkelDesign.carbonFiber.withValues(alpha: 0.8),
                  AkelDesign.deepBlack.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(AkelDesign.radiusLg),
              border: Border.all(
                color: AkelDesign.primaryRed.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AkelDesign.primaryRed.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Glossy overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AkelDesign.radiusLg),
                        topRight: Radius.circular(AkelDesign.radiusLg),
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  AkelDesign.primaryRed.withValues(alpha: 0.3),
                                  AkelDesign.primaryRed.withValues(alpha: 0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AkelDesign.primaryRed.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: const Icon(
                                    Icons.warning_rounded,
                                    color: AkelDesign.primaryRed,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'EMERGENCY ALERT',
                                      style: AkelDesign.h3.copyWith(
                                        fontSize: 16,
                                        color: AkelDesign.primaryRed,
                                      ),
                                    ),
                                    if (silent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.volume_off,
                                              size: 10,
                                              color: Colors.orange,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Silent',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timestamp != null
                                      ? DateFormat('MMM dd, yyyy • h:mm a').format(timestamp)
                                      : 'Unknown time',
                                  style: AkelDesign.caption.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AkelDesign.errorRed),
                            onPressed: () => _deleteAlert(userId, alertId),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AkelDesign.deepBlack.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AkelDesign.radiusMd),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                Icons.people,
                                'Contacts',
                                '$contactsNotified/$totalContacts',
                                AkelDesign.neonBlue,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 30,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                hasLocation ? Icons.location_on : Icons.location_off,
                                'Location',
                                hasLocation ? 'Available' : 'Unavailable',
                                hasLocation ? AkelDesign.successGreen : AkelDesign.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Location button
                      if (hasLocation)
                        FuturisticButton(
                          text: 'VIEW LOCATION',
                          icon: Icons.map,
                          onPressed: () => _openLocation(
                            location['latitude'],
                            location['longitude'],
                          ),
                          color: AkelDesign.successGreen,
                          isOutlined: true,
                          isSmall: true,
                          isFullWidth: true,
                        ),

                      // Message (if exists)
                      if (message != null && message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ExpansionTile(
                          title: Text(
                            'Message',
                            style: AkelDesign.caption.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(top: 8),
                          iconColor: AkelDesign.neonBlue,
                          collapsedIconColor: Colors.white70,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AkelDesign.deepBlack.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(AkelDesign.radiusSm),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                message,
                                style: AkelDesign.caption.copyWith(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: AkelDesign.caption.copyWith(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AkelDesign.neonBlue.withValues(alpha: 0.2),
                        AkelDesign.neonBlue.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.history,
                    size: 80,
                    color: AkelDesign.neonBlue,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'No Panic Alerts',
            style: AkelDesign.h2.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedFilter == 'all'
                ? 'You haven\'t triggered any panic alerts yet.\nStay safe!'
                : 'No alerts found for this time period.\nTry a different filter.',
            textAlign: TextAlign.center,
            style: AkelDesign.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: AkelDesign.deepBlack,
        appBar: AppBar(
          backgroundColor: AkelDesign.carbonFiber,
          title: Text('History', style: AkelDesign.h3.copyWith(fontSize: 18)),
        ),
        body: const Center(
          child: Text('Please sign in to view history'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AkelDesign.deepBlack,
      appBar: AppBar(
        backgroundColor: AkelDesign.carbonFiber,
        elevation: 0,
        leading: FuturisticIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.pop(context),
          size: 40,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Panic History', style: AkelDesign.h3.copyWith(fontSize: 18)),
            Text('All Emergency Alerts', style: AkelDesign.caption.copyWith(fontSize: 10)),
          ],
        ),
        actions: [
          FuturisticIconButton(
            icon: Icons.delete_sweep,
            onPressed: () => _clearAllHistory(userId),
            color: AkelDesign.errorRed,
            size: 40,
            tooltip: 'Clear All',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AkelDesign.carbonFiber.withValues(alpha: 0.8),
                  AkelDesign.deepBlack,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FILTER BY',
                  style: AkelDesign.caption.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Time', 'all', Icons.all_inclusive),
                      const SizedBox(width: 8),
                      _buildFilterChip('Today', 'today', Icons.today),
                      const SizedBox(width: 8),
                      _buildFilterChip('This Week', 'week', Icons.date_range),
                      const SizedBox(width: 8),
                      _buildFilterChip('This Month', 'month', Icons.calendar_month),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPanicHistoryStream(userId),
              builder: (context, snapshot) {
                if (_isLoading || snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: FuturisticLoadingIndicator(
                      size: 60,
                      color: AkelDesign.neonBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AkelDesign.errorRed, size: 64),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: AkelDesign.body),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return _buildHistoryCard(data, doc.id, userId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}