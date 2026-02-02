import 'package:flutter/material.dart';

/// Analytics Drilldown Screen
/// Shows detailed view of specific metrics
class AnalyticsDrilldownScreen extends StatelessWidget {
  final String metric;
  final DateTimeRange dateRange;

  const AnalyticsDrilldownScreen({
    super.key,
    required this.metric,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Detailed view for: $_getTitle()',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Date range: ${_formatDate(dateRange.start)} - ${_formatDate(dateRange.end)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            const Text('Detailed analytics implementation coming soon...'),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (metric) {
      case 'users':
        return 'Registered Users';
      case 'dau':
        return 'Daily Active Users';
      case 'wau':
        return 'Weekly Active Users';
      case 'matches':
        return 'All Matches';
      case 'recent_matches':
        return 'Recent Matches';
      case 'acceptance':
        return 'Match Acceptance Rate';
      case 'matches_trend':
        return 'Match Trends';
      case 'subjects':
        return 'Subject Analytics';
      default:
        return 'Analytics Detail';
    }
  }

  IconData _getIcon() {
    switch (metric) {
      case 'users':
      case 'dau':
      case 'wau':
        return Icons.people;
      case 'matches':
      case 'recent_matches':
      case 'matches_trend':
        return Icons.favorite;
      case 'acceptance':
        return Icons.check_circle;
      case 'subjects':
        return Icons.school;
      default:
        return Icons.analytics;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
