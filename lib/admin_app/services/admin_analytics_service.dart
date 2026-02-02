import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Analytics Service
/// Provides analytics data for the admin dashboard
class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream real-time analytics summary
  Stream<AnalyticsSummary> streamAnalyticsSummary() {
    return Stream.periodic(const Duration(seconds: 30)).asyncMap((_) async {
      return await _computeSummary();
    });
  }

  /// Compute analytics summary from Firestore
  Future<AnalyticsSummary> _computeSummary() async {
    try {
      // Total users
      final usersSnapshot = await _firestore.collection('users').count().get();
      final totalUsers = usersSnapshot.count ?? 0;

      // Daily active (last 24 hours)
      final dayAgo = DateTime.now().subtract(const Duration(days: 1));
      final dauSnapshot = await _firestore
          .collection('users')
          .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(dayAgo))
          .count()
          .get();
      final dailyActiveUsers = dauSnapshot.count ?? 0;

      // Weekly active (last 7 days)
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final wauSnapshot = await _firestore
          .collection('users')
          .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .count()
          .get();
      final weeklyActiveUsers = wauSnapshot.count ?? 0;

      // Total matches
      final matchesSnapshot =
          await _firestore.collection('matches').count().get();
      final totalMatches = matchesSnapshot.count ?? 0;

      // Matches this week
      final weekMatchesSnapshot = await _firestore
          .collection('matches')
          .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
          .count()
          .get();
      final matchesThisWeek = weekMatchesSnapshot.count ?? 0;

      // Acceptance rate (matches / total likes)
      final acceptanceRate = await _computeAcceptanceRate();

      return AnalyticsSummary(
        totalUsers: totalUsers,
        dailyActiveUsers: dailyActiveUsers,
        weeklyActiveUsers: weeklyActiveUsers,
        totalMatches: totalMatches,
        matchesThisWeek: matchesThisWeek,
        acceptanceRate: acceptanceRate,
      );
    } catch (e) {
      print('Error computing analytics: $e');
      return AnalyticsSummary.empty();
    }
  }

  /// Compute match acceptance rate
  Future<double> _computeAcceptanceRate() async {
    try {
      // Count total likes
      final swipesSnapshot = await _firestore
          .collectionGroup('swipes')
          .where('direction', isEqualTo: 'like')
          .count()
          .get();
      final totalLikes = swipesSnapshot.count ?? 0;

      // Count total matches
      final matchesSnapshot =
          await _firestore.collection('matches').count().get();
      final totalMatches = matchesSnapshot.count ?? 1; // Avoid division by zero

      // Each match represents 2 likes (mutual), so multiply matches by 2
      final mutualLikes = totalMatches * 2;

      if (totalLikes == 0) return 0.0;

      return (mutualLikes / totalLikes) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Stream matches over time for chart
  Stream<List<TimeSeriesData>> streamMatchesOverTime({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('matches')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      // Group by day
      final Map<DateTime, int> dailyCounts = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['createdAt'] as Timestamp?;
        if (timestamp != null) {
          final date = DateTime(
            timestamp.toDate().year,
            timestamp.toDate().month,
            timestamp.toDate().day,
          );
          dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
        }
      }

      // Fill in missing days with 0
      final List<TimeSeriesData> result = [];
      var current = startDate;
      while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
        final date = DateTime(current.year, current.month, current.day);
        result.add(TimeSeriesData(
          date: date,
          value: dailyCounts[date] ?? 0,
        ));
        current = current.add(const Duration(days: 1));
      }

      return result;
    });
  }

  /// Stream top subjects by student interest
  Stream<List<SubjectStats>> streamTopSubjects({int limit = 10}) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      // Count subject occurrences
      final Map<String, int> subjectCounts = {};
      int totalStudents = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final subjects = data['subjectsInterested'] as List<dynamic>? ?? [];
        if (subjects.isNotEmpty) {
          totalStudents++;
          for (final subject in subjects) {
            if (subject is String) {
              subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
            }
          }
        }
      }

      // Convert to list and sort
      final sortedSubjects = subjectCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Take top N with percentages
      return sortedSubjects.take(limit).map((entry) {
        final percentage =
            totalStudents > 0 ? (entry.value / totalStudents) * 100 : 0.0;
        return SubjectStats(
          name: entry.key,
          studentCount: entry.value,
          percentage: percentage,
        );
      }).toList();
    });
  }
}

// Data classes
class AnalyticsSummary {
  final int totalUsers;
  final int dailyActiveUsers;
  final int weeklyActiveUsers;
  final int totalMatches;
  final int matchesThisWeek;
  final double acceptanceRate;

  AnalyticsSummary({
    required this.totalUsers,
    required this.dailyActiveUsers,
    required this.weeklyActiveUsers,
    required this.totalMatches,
    required this.matchesThisWeek,
    required this.acceptanceRate,
  });

  factory AnalyticsSummary.empty() => AnalyticsSummary(
        totalUsers: 0,
        dailyActiveUsers: 0,
        weeklyActiveUsers: 0,
        totalMatches: 0,
        matchesThisWeek: 0,
        acceptanceRate: 0,
      );
}

class TimeSeriesData {
  final DateTime date;
  final int value;

  TimeSeriesData({required this.date, required this.value});
}

class SubjectStats {
  final String name;
  final int studentCount;
  final double percentage;

  SubjectStats({
    required this.name,
    required this.studentCount,
    required this.percentage,
  });
}
