import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  int _totalPanics = 0;
  String _mostContactedName = 'None';
  int _mostContactedCount = 0;
  int _thisMonth = 0;
  int _lastMonth = 0;
  Map<String, int> _last7Days = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
// Get all panic events
      final panicSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('panic_events')
          .orderBy('timestamp', descending: true)
          .get();

      final events = panicSnapshot.docs;
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

// Count totals
      int thisMonthCount = 0;
      int lastMonthCount = 0;
      Map<String, int> contactCounts = {};
      Map<String, int> dailyCounts = {};

// Initialize last 7 days
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final key = '${day.month}/${day.day}';
        dailyCounts[key] = 0;
      }

      for (var doc in events) {
        final data = doc.data();
        final timestamp = DateTime.parse(data['timestamp']);
        final contacts = data['contacts_notified'] as List<dynamic>? ?? [];

// This month count
        if (timestamp.isAfter(thisMonthStart)) {
          thisMonthCount++;
        }

// Last month count
        if (timestamp.isAfter(lastMonthStart) && timestamp.isBefore(thisMonthStart)) {
          lastMonthCount++;
        }

// Last 7 days
        if (timestamp.isAfter(sevenDaysAgo)) {
          final key = '${timestamp.month}/${timestamp.day}';
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        }

// Count contacts
        for (var contact in contacts) {
          if (contact is Map && contact['name'] != null) {
            final name = contact['name'] as String;
            contactCounts[name] = (contactCounts[name] ?? 0) + 1;
          }
        }
      }

// Find most contacted
      String mostContacted = 'None';
      int maxCount = 0;
      contactCounts.forEach((name, count) {
        if (count > maxCount) {
          maxCount = count;
          mostContacted = name;
        }
      });

      setState(() {
        _totalPanics = events.length;
        _thisMonth = thisMonthCount;
        _lastMonth = lastMonthCount;
        _mostContactedName = mostContacted;
        _mostContactedCount = maxCount;
        _last7Days = dailyCounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading statistics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Usage Statistics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadStatistics();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        color: const Color(0xFF00BFA5),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
// Header
            const Text(
              'Your Emergency Alert Activity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track your panic button usage and patterns',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),

// Total Panics Card
            _buildStatCard(
              icon: Icons.warning_rounded,
              iconColor: Colors.red,
              title: 'Total Panic Events',
              value: '$_totalPanics',
              subtitle: 'All time',
            ),
            const SizedBox(height: 16),

// Most Contacted Card
            _buildStatCard(
              icon: Icons.person,
              iconColor: const Color(0xFF00BFA5),
              title: 'Most Contacted',
              value: _mostContactedName,
              subtitle: _mostContactedCount > 0
                  ? '$_mostContactedCount alert${_mostContactedCount == 1 ? '' : 's'}'
                  : 'No contacts alerted yet',
            ),
            const SizedBox(height: 16),

// This Month vs Last Month
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.calendar_today,
                    iconColor: Colors.blue,
                    title: 'This Month',
                    value: '$_thisMonth',
                    subtitle: 'Alerts',
                    compact: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.history,
                    iconColor: Colors.orange,
                    title: 'Last Month',
                    value: '$_lastMonth',
                    subtitle: 'Alerts',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

// Last 7 Days Section
            const Text(
              'LAST 7 DAYS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

// Activity Chart
            Card(
              color: const Color(0xFF1E2740),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Activity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActivityChart(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

// Insights Section
            const Text(
              'INSIGHTS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00BFA5),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 16),

// Insights Card
            Card(
              color: const Color(0xFF1E2740),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.yellow[700],
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Quick Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInsightRow(
                      'Average per month',
                      '${((_thisMonth + _lastMonth) / 2).toStringAsFixed(1)} alerts',
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      'Peak activity',
                      _getPeakDay(),
                    ),
                    const SizedBox(height: 12),
                    _buildInsightRow(
                      'Status',
                      _totalPanics == 0
                          ? 'No emergencies yet'
                          : _totalPanics < 5
                          ? 'Low usage'
                          : 'Active user',
                    ),
                  ],
                ),
              ),
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
                  const Expanded(
                    child: Text(
                      'Statistics are updated in real-time and help you understand your emergency alert patterns.',
                      style: TextStyle(
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
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    bool compact = false,
  }) {
    return Card(
      color: const Color(0xFF1E2740),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: compact ? 40 : 50,
                  height: compact ? 40 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.2),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: compact ? 20 : 28,
                  ),
                ),
                if (!compact) const Spacer(),
              ],
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 12 : 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 24 : 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white54,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final maxValue = _last7Days.values.isEmpty
        ? 1
        : _last7Days.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _last7Days.entries.map((entry) {
          final height = maxValue > 0
              ? (entry.value / maxValue) * 120
              : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (entry.value > 0)
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: height > 0 ? height : 8,
                    decoration: BoxDecoration(
                      color: entry.value > 0
                          ? const Color(0xFF00BFA5)
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getPeakDay() {
    if (_last7Days.isEmpty || _last7Days.values.every((v) => v == 0)) {
      return 'No activity';
    }

    String peakDay = '';
    int maxCount = 0;

    _last7Days.forEach((day, count) {
      if (count > maxCount) {
        maxCount = count;
        peakDay = day;
      }
    });

    return maxCount > 0 ? '$peakDay ($maxCount alerts)' : 'No activity';
  }
}