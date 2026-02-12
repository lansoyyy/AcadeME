import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Analytics Service
/// Provides analytics data for admin dashboard
class AdminAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream real-time analytics summary
  /// Combines multiple Firestore streams into a single analytics summary
  Stream<AnalyticsSummary> streamAnalyticsSummary() {
    // Combine streams for total users, matches, and other stats
    return Rx.combineLatest4(
      _streamTotalUsers(),
      _streamTotalMatches(),
      _streamPendingRegistrations(),
      _streamActiveStudySessions(),
      (totalUsers, totalMatches, pendingRegistrations, activeSessions) {
        return AnalyticsSummary(
          totalUsers: totalUsers,
          totalMatches: totalMatches,
          pendingRegistrations: pendingRegistrations,
          activeStudySessions: activeSessions,
        );
      },
    );
  }

  /// Stream total users count
  Stream<int> _streamTotalUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream total matches count
  Stream<int> _streamTotalMatches() {
    return _firestore
        .collection('matches')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream pending registrations count
  Stream<int> _streamPendingRegistrations() {
    return _firestore
        .collection('users')
        .where('accountStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream active study sessions count
  Stream<int> _streamActiveStudySessions() {
    return _firestore
        .collection('studySessions')
        .where('status', isEqualTo: 'scheduled')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get daily active users (last 24 hours)
  Future<int> getDailyActiveUsers() async {
    final dayAgo = DateTime.now().subtract(const Duration(days: 1));
    final snapshot = await _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(dayAgo))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get weekly active users (last 7 days)
  Future<int> getWeeklyActiveUsers() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _firestore
        .collection('users')
        .where('lastActiveAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get matches in the last week
  Future<int> getMatchesThisWeek() async {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _firestore
        .collection('matches')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(weekAgo))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Get acceptance rate (matches / total likes)
  Future<double> getAcceptanceRate() async {
    try {
      // Count total likes
      final swipesSnapshot = await _firestore
          .collectionGroup('swipes')
          .where('direction', isEqualTo: 'like')
          .count()
          .get();
      final totalLikes = swipesSnapshot.count ?? 0;

      // Count total matches
      final matchesSnapshot = await _firestore
          .collection('matches')
          .count()
          .get();
      final totalMatches = matchesSnapshot.count ?? 1;

      // Each match represents 2 likes (mutual), so multiply matches by 2
      final mutualLikes = totalMatches * 2;

      if (totalLikes == 0) return 0.0;

      return (mutualLikes / totalLikes) * 100;
    } catch (e) {
      return 0.0;
    }
  }

  /// Get total forum posts
  Future<int> getTotalForumPosts() async {
    final snapshot = await _firestore.collection('forumPosts').count().get();
    return snapshot.count ?? 0;
  }

  /// Get total reports
  Future<int> getTotalReports() async {
    final snapshot = await _firestore.collection('reports').count().get();
    return snapshot.count ?? 0;
  }

  /// Stream user growth over time (registrations per day)
  Stream<List<TimeSeriesData>> streamUserGrowth({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('users')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
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
          while (current.isBefore(endDate) ||
              current.isAtSameMomentAs(endDate)) {
            final date = DateTime(current.year, current.month, current.day);
            result.add(
              TimeSeriesData(date: date, value: dailyCounts[date] ?? 0),
            );
            current = current.add(const Duration(days: 1));
          }

          return result;
        });
  }

  /// Stream matches over time for chart
  Stream<List<TimeSeriesData>> streamMatchesOverTime({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('matches')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
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
          while (current.isBefore(endDate) ||
              current.isAtSameMomentAs(endDate)) {
            final date = DateTime(current.year, current.month, current.day);
            result.add(
              TimeSeriesData(date: date, value: dailyCounts[date] ?? 0),
            );
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
        final percentage = totalStudents > 0
            ? (entry.value / totalStudents) * 100
            : 0.0;
        return SubjectStats(
          name: entry.key,
          studentCount: entry.value,
          percentage: percentage,
        );
      }).toList();
    });
  }

  /// Stream user distribution by track
  Stream<List<TrackStats>> streamTrackDistribution() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final Map<String, int> trackCounts = {};
      int totalUsers = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final track = data['track'] as String? ?? 'Unknown';
        trackCounts[track] = (trackCounts[track] ?? 0) + 1;
        totalUsers++;
      }

      return trackCounts.entries.map((entry) {
        final percentage = totalUsers > 0
            ? (entry.value / totalUsers) * 100
            : 0.0;
        return TrackStats(
          name: entry.key,
          userCount: entry.value,
          percentage: percentage,
        );
      }).toList();
    });
  }

  /// Stream recent activity (last 10 actions)
  Stream<List<ActivityItem>> streamRecentActivity() {
    return _firestore
        .collection('adminActions')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return ActivityItem(
              id: doc.id,
              action: data['action'] as String? ?? 'Unknown',
              adminEmail: data['adminEmail'] as String? ?? 'Unknown',
              timestamp:
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
              details: data['details'] as String? ?? '',
            );
          }).toList();
        });
  }
}

// Helper class for combining streams
class Rx {
  static Stream<T> combineLatest4<A, B, C, D, T>(
    Stream<A> streamA,
    Stream<B> streamB,
    Stream<C> streamC,
    Stream<D> streamD,
    T Function(A, B, C, D) combiner,
  ) async* {
    A? latestA;
    B? latestB;
    C? latestC;
    D? latestD;

    await for (final value in streamA) {
      latestA = value;
      if (latestB != null && latestC != null && latestD != null) {
        yield combiner(latestA!, latestB!, latestC!, latestD!);
      }
    }
    await for (final value in streamB) {
      latestB = value;
      if (latestA != null && latestC != null && latestD != null) {
        yield combiner(latestA!, latestB!, latestC!, latestD!);
      }
    }
    await for (final value in streamC) {
      latestC = value;
      if (latestA != null && latestB != null && latestD != null) {
        yield combiner(latestA!, latestB!, latestC!, latestD!);
      }
    }
    await for (final value in streamD) {
      latestD = value;
      if (latestA != null && latestB != null && latestC != null) {
        yield combiner(latestA!, latestB!, latestC!, latestD!);
      }
    }
  }
}

// Data classes
class AnalyticsSummary {
  final int totalUsers;
  final int totalMatches;
  final int pendingRegistrations;
  final int activeStudySessions;

  AnalyticsSummary({
    required this.totalUsers,
    required this.totalMatches,
    required this.pendingRegistrations,
    required this.activeStudySessions,
  });

  factory AnalyticsSummary.empty() => AnalyticsSummary(
    totalUsers: 0,
    totalMatches: 0,
    pendingRegistrations: 0,
    activeStudySessions: 0,
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

class TrackStats {
  final String name;
  final int userCount;
  final double percentage;

  TrackStats({
    required this.name,
    required this.userCount,
    required this.percentage,
  });
}

class ActivityItem {
  final String id;
  final String action;
  final String adminEmail;
  final DateTime timestamp;
  final String details;

  ActivityItem({
    required this.id,
    required this.action,
    required this.adminEmail,
    required this.timestamp,
    required this.details,
  });
}
