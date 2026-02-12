import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../screens/admin_login_screen.dart';
import '../screens/user_management/users_list_screen.dart';
import '../screens/profile_monitoring/profile_audit_screen.dart';
import '../screens/forum_moderation/forum_overview_screen.dart';
import '../screens/match_monitoring/matches_overview_screen.dart';
import '../screens/reports_blacklist/reports_list_screen.dart';
import '../screens/analytics/analytics_dashboard_screen.dart';
import '../screens/feedback_ratings/ratings_overview_screen.dart';
import '../screens/academic_structure/subjects_screen.dart';
import '../screens/registration_approval/registration_approval_screen.dart';

/// AdminShell - Main navigation container for admin interface
/// Provides NavigationRail (desktop/tablet) or Drawer (mobile)
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<_NavigationItem> _navItems = [
    _NavigationItem(
      index: 0,
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      screen: const AnalyticsDashboardScreen(),
    ),
    _NavigationItem(
      index: 1,
      label: 'Users',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      screen: const UsersListScreen(),
    ),
    _NavigationItem(
      index: 2,
      label: 'Profiles',
      icon: Icons.person_search_outlined,
      selectedIcon: Icons.person_search,
      screen: const ProfileAuditScreen(),
    ),
    _NavigationItem(
      index: 3,
      label: 'Matches',
      icon: Icons.favorite_outline,
      selectedIcon: Icons.favorite,
      screen: const MatchesOverviewScreen(),
    ),
    _NavigationItem(
      index: 4,
      label: 'Reports',
      icon: Icons.report_outlined,
      selectedIcon: Icons.report,
      screen: const ReportsListScreen(),
    ),
    _NavigationItem(
      index: 5,
      label: 'Forum',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum,
      screen: const ForumOverviewScreen(),
    ),
    _NavigationItem(
      index: 6,
      label: 'Ratings',
      icon: Icons.star_outline,
      selectedIcon: Icons.star,
      screen: const RatingsOverviewScreen(),
    ),

    _NavigationItem(
      index: 7,
      label: 'Registrations',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      screen: const RegistrationApprovalScreen(),
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdminAuthService().logout();
      if (mounted) {
        // Navigate to login screen and clear all routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation rail or drawer
          if (isWideScreen)
            NavigationRail(
              extended: true,
              minExtendedWidth: 200,
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _navItems
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            )
          else
            const SizedBox.shrink(),
          // Content
          Expanded(child: _navItems[_selectedIndex].screen),
        ],
      ),
      drawer: !isWideScreen
          ? Drawer(
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'AcadeME Admin',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                AdminAuthService().adminUsername,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final isSelected = index == _selectedIndex;
                        return ListTile(
                          leading: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          title: Text(item.label),
                          selected: isSelected,
                          onTap: () {
                            _onDestinationSelected(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: _logout,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _NavigationItem {
  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;

  _NavigationItem({
    required this.index,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });
}
