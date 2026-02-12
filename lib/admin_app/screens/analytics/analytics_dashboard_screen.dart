import 'package:flutter/material.dart';
import '../../services/admin_analytics_service.dart';
import 'analytics_drilldown_screen.dart';

/// Analytics Dashboard Screen
/// Shows real-time metrics from Firestore
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  // Cached values for async computations
  int _dailyActiveUsers = 0;
  int _weeklyActiveUsers = 0;
  int _matchesThisWeek = 0;
  double _acceptanceRate = 0.0;
  int _totalForumPosts = 0;
  int _totalReports = 0;
  bool _isLoadingAsync = true;

  @override
  void initState() {
    super.initState();
    _loadAsyncData();
  }

  Future<void> _loadAsyncData() async {
    setState(() => _isLoadingAsync = true);
    try {
      final results = await Future.wait([
        _analyticsService.getDailyActiveUsers(),
        _analyticsService.getWeeklyActiveUsers(),
        _analyticsService.getMatchesThisWeek(),
        _analyticsService.getAcceptanceRate(),
        _analyticsService.getTotalForumPosts(),
        _analyticsService.getTotalReports(),
      ]);
      if (mounted) {
        setState(() {
          _dailyActiveUsers = results[0] as int;
          _weeklyActiveUsers = results[1] as int;
          _matchesThisWeek = results[2] as int;
          _acceptanceRate = results[3] as double;
          _totalForumPosts = results[4] as int;
          _totalReports = results[5] as int;
          _isLoadingAsync = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAsync = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAsyncData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildChartsSection(),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopSubjectsSection()),
                const SizedBox(width: 16),
                Expanded(child: _buildTrackDistributionSection()),
              ],
            ),
            const SizedBox(height: 24),
            _buildRecentActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time analytics from Firestore',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 200,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 65,
                    child: Text(
                      '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _selectDateRange,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Icon(Icons.edit, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<AnalyticsSummary>(
      stream: _analyticsService.streamAnalyticsSummary(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data ?? AnalyticsSummary.empty();
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: _getCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _StatCard(
              title: 'Total Users',
              value: data.totalUsers.toString(),
              icon: Icons.people,
              color: Colors.blue,
              subtitle: 'Registered students',
              onTap: () => _navigateToDrilldown('users'),
            ),
            _StatCard(
              title: 'Daily Active',
              value: _isLoadingAsync ? '...' : _dailyActiveUsers.toString(),
              icon: Icons.today,
              color: Colors.green,
              subtitle: 'Active in last 24h',
              onTap: () => _navigateToDrilldown('dau'),
            ),
            _StatCard(
              title: 'Weekly Active',
              value: _isLoadingAsync ? '...' : _weeklyActiveUsers.toString(),
              icon: Icons.calendar_view_week,
              color: Colors.orange,
              subtitle: 'Active in last 7 days',
              onTap: () => _navigateToDrilldown('wau'),
            ),
            _StatCard(
              title: 'Total Matches',
              value: data.totalMatches.toString(),
              icon: Icons.favorite,
              color: Colors.red,
              subtitle: 'Successful matches',
              onTap: () => _navigateToDrilldown('matches'),
            ),
            _StatCard(
              title: 'Matches This Week',
              value: _isLoadingAsync ? '...' : _matchesThisWeek.toString(),
              icon: Icons.trending_up,
              color: Colors.purple,
              subtitle: 'New matches created',
              onTap: () => _navigateToDrilldown('recent_matches'),
            ),
            _StatCard(
              title: 'Acceptance Rate',
              value: _isLoadingAsync
                  ? '...'
                  : '${_acceptanceRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.teal,
              subtitle: 'Like → Match conversion',
              onTap: () => _navigateToDrilldown('acceptance'),
            ),
            _StatCard(
              title: 'Pending Approvals',
              value: data.pendingRegistrations.toString(),
              icon: Icons.how_to_reg,
              color: Colors.amber,
              subtitle: 'Awaiting review',
              onTap: () => _navigateToDrilldown('pending'),
            ),
            _StatCard(
              title: 'Active Sessions',
              value: data.activeStudySessions.toString(),
              icon: Icons.event,
              color: Colors.indigo,
              subtitle: 'Scheduled sessions',
              onTap: () => _navigateToDrilldown('sessions'),
            ),
            _StatCard(
              title: 'Forum Posts',
              value: _isLoadingAsync ? '...' : _totalForumPosts.toString(),
              icon: Icons.forum,
              color: Colors.cyan,
              subtitle: 'Total discussions',
              onTap: () => _navigateToDrilldown('forum'),
            ),
            _StatCard(
              title: 'Reports',
              value: _isLoadingAsync ? '...' : _totalReports.toString(),
              icon: Icons.report,
              color: Colors.redAccent,
              subtitle: 'User reports',
              onTap: () => _navigateToDrilldown('reports'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'User Growth Over Time',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateToDrilldown('user_growth'),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<TimeSeriesData>>(
                stream: _analyticsService.streamUserGrowth(
                  startDate: _dateRange.start,
                  endDate: _dateRange.end,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const Center(
                      child: Text('No data available for selected period'),
                    );
                  }
                  return _GrowthLineChart(data: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSubjectsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Subjects',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            StreamBuilder<List<SubjectStats>>(
              stream: _analyticsService.streamTopSubjects(limit: 8),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final subjects = snapshot.data!;
                if (subjects.isEmpty) {
                  return const Center(child: Text('No subject data available'));
                }
                return Column(
                  children: subjects.asMap().entries.map((entry) {
                    return _SubjectListItem(
                      rank: entry.key + 1,
                      subject: entry.value,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackDistributionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Track Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<TrackStats>>(
              stream: _analyticsService.streamTrackDistribution(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tracks = snapshot.data!;
                if (tracks.isEmpty) {
                  return const Center(child: Text('No track data available'));
                }
                return Column(
                  children: tracks.map((track) {
                    return _TrackDistributionItem(track: track);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Admin Activity',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<ActivityItem>>(
              stream: _analyticsService.streamRecentActivity(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final activities = snapshot.data!;
                if (activities.isEmpty) {
                  return const Center(child: Text('No recent activity'));
                }
                return Column(
                  children: activities.map((activity) {
                    return _ActivityListItem(activity: activity);
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _navigateToDrilldown(String metric) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AnalyticsDrilldownScreen(metric: metric, dateRange: _dateRange),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final VoidCallback onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        // onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectListItem extends StatelessWidget {
  final int rank;
  final SubjectStats subject;

  const _SubjectListItem({required this.rank, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${subject.studentCount} students',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${subject.percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackDistributionItem extends StatelessWidget {
  final TrackStats track;

  const _TrackDistributionItem({required this.track});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                track.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                '${track.userCount} (${track.percentage.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: track.percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              size: 20,
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (activity.details.isNotEmpty)
                  Text(
                    activity.details,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(activity.timestamp),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              Text(
                activity.adminEmail.split('@')[0],
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${timestamp.month}/${timestamp.day}';
  }
}

class _GrowthLineChart extends StatelessWidget {
  final List<TimeSeriesData> data;

  const _GrowthLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minValue = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: _LineChartPainter(
        data: data,
        maxValue: maxValue,
        minValue: minValue,
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<TimeSeriesData> data;
  final int maxValue;
  final int minValue;

  _LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final range = maxValue - minValue == 0 ? 1 : maxValue - minValue;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = padding + (chartHeight / 4) * i;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line
    final linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + (chartWidth / (data.length - 1)) * i;
      final normalizedValue = (data[i].value - minValue) / range;
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Draw line segments
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Draw gradient fill below line
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.blue.withOpacity(0.3), Colors.blue.withOpacity(0.05)],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(padding, padding, chartWidth, chartHeight),
      );

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.lineTo(points.last.dx, size.height - padding);
    path.lineTo(points.first.dx, size.height - padding);
    path.close();

    canvas.drawPath(path, fillPaint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in points) {
      canvas.drawCircle(point, 5, pointPaint);
      canvas.drawCircle(point, 5, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue;
  }
}
