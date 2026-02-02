import 'package:flutter/material.dart';
import '../../services/admin_analytics_service.dart';
import 'analytics_drilldown_screen.dart';

/// Analytics Dashboard Screen
/// Shows high-level metrics: registered users, DAU/WAU, matches per day, subjects, acceptance rate
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AdminAnalyticsService _analyticsService = AdminAnalyticsService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildChartsSection(),
          const SizedBox(height: 24),
          _buildTopSubjectsSection(),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.date_range, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date Range', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    '${_formatDate(_dateRange.start)} - ${_formatDate(_dateRange.end)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.edit),
              label: const Text('Change'),
            ),
          ],
        ),
      ),
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
              value: data.dailyActiveUsers.toString(),
              icon: Icons.today,
              color: Colors.green,
              subtitle: 'Active in last 24h',
              onTap: () => _navigateToDrilldown('dau'),
            ),
            _StatCard(
              title: 'Weekly Active',
              value: data.weeklyActiveUsers.toString(),
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
              value: data.matchesThisWeek.toString(),
              icon: Icons.trending_up,
              color: Colors.purple,
              subtitle: 'New matches created',
              onTap: () => _navigateToDrilldown('recent_matches'),
            ),
            _StatCard(
              title: 'Acceptance Rate',
              value: '${data.acceptanceRate.toStringAsFixed(1)}%',
              icon: Icons.check_circle,
              color: Colors.teal,
              subtitle: 'Like → Match conversion',
              onTap: () => _navigateToDrilldown('acceptance'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Matches Over Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _navigateToDrilldown('matches_trend'),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<TimeSeriesData>>(
                stream: _analyticsService.streamMatchesOverTime(
                  startDate: _dateRange.start,
                  endDate: _dateRange.end,
                ),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const Center(child: Text('No data available for selected period'));
                  }
                  return _MatchesBarChart(data: data);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Most Requested Subjects', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => _navigateToDrilldown('subjects'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<SubjectStats>>(
              stream: _analyticsService.streamTopSubjects(limit: 10),
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
                    return _SubjectListItem(rank: entry.key + 1, subject: entry.value);
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
        builder: (context) => AnalyticsDrilldownScreen(metric: metric, dateRange: _dateRange),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 3;
    if (width >= 800) return 2;
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3 ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Theme.of(context).colorScheme.primary : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('${subject.studentCount} students interested', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
            child: Text(
              '${subject.percentage.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesBarChart extends StatelessWidget {
  final List<TimeSeriesData> data;
  const _MatchesBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((point) {
        final height = maxValue > 0 ? (point.value / maxValue) * 150 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (point.value > 0) Text('${point.value}', style: const TextStyle(fontSize: 10)),
                const SizedBox(height: 4),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${point.date.day}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
