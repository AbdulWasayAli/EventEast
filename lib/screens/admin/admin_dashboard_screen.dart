import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/event_provider.dart';
import 'manage_users_screen.dart';
import 'manage_events_screen.dart';
import 'reports_screen.dart';
import 'approvals_screen.dart';
import 'content_moderation_screen.dart';
import '../common/settings_screen.dart';
import '../common/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

import '../../widgets/premium_ui.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  bool _isLoading = true;
  String? _error;
  String _profileImageUrl = '';
  String _adminName = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadAdminProfile();
    _loadDashboard();
  }

  Future<void> _loadAdminProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String name = user.displayName?.trim() ?? '';
    String photo = user.photoURL?.trim() ?? '';

    try {
      final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final firestoreImage = (data['ProfileImage'] ?? data['profileImage'] ?? data['PhotoUrl'] ?? data['photoUrl'] ?? data['avatarUrl'] ?? '') as String;
        if (firestoreImage.trim().isNotEmpty) {
          photo = firestoreImage.trim();
        }
        final firestoreName = (data['Name'] ?? data['name'] ?? data['FullName'] ?? data['fullName'] ?? data['DisplayName'] ?? data['displayName'] ?? '') as String;
        if (firestoreName.trim().isNotEmpty) {
          name = firestoreName.trim();
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _profileImageUrl = photo;
        _adminName = name.isNotEmpty ? name : 'Admin';
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _loadAdminProfile();
      await context.read<AdminProvider>().loadDashboardData();

      if (!mounted) return;

      await context.read<EventProvider>().fetchManageEvents();
    } catch (e) {
      debugPrint('Dashboard loading error: $e');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
          ),
          title: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              color: isDark ? const Color(0xFFCBD5E1) : Colors.blueGrey.shade700,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildOverview(),
      const ManageUsersScreen(),
      const ManageEventsScreen(),
      const ReportsScreen(),
      const UnifiedSettingsScreen(
        userRole: 'Super Admin',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildNavigationDrawer(context),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildOverview() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return _buildErrorView();
    }

    return RefreshIndicator(
      color: const Color(0xFF007E7B),
      onRefresh: _loadDashboard,
      child: _AdminDashboardHome(
        photoUrl: _profileImageUrl,
        adminName: _adminName,
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 45,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Unable to load dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFF8FAFC)
                    : const Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007E7B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return PremiumBottomNav(
      currentIndex: _currentIndex,
      items: const [
        PremiumNavItem(icon: Icons.dashboard_rounded, label: 'Overview'),
        PremiumNavItem(icon: Icons.people_rounded, label: 'Users'),
        PremiumNavItem(icon: Icons.event_note_rounded, label: 'Events'),
        PremiumNavItem(icon: Icons.insert_chart_rounded, label: 'Reports'),
        PremiumNavItem(icon: Icons.settings_rounded, label: 'Settings'),
      ],
      onTap: (index) => _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String displayName = _adminName.isNotEmpty
        ? _adminName
        : ((user?.displayName?.isNotEmpty == true) ? user!.displayName! : 'Admin');
    final String? photo = _profileImageUrl.isNotEmpty
        ? _profileImageUrl
        : user?.photoURL;

    void openPage(int index) {
      Navigator.pop(context);
      _pageController.jumpToPage(index);
    }

    void openScreen(Widget screen) {
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }

    return PremiumDrawer(
      name: displayName,
      email: user?.email ?? 'admin@eventease.com',
      photoUrl: photo,
      roleLabel: 'ADMINISTRATOR',
      onLogout: () {
        Navigator.pop(context);
        _logout();
      },
      sections: [
        PremiumDrawerSection(
          label: 'MAIN MENU',
          items: [
            PremiumDrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Overview',
              selected: _currentIndex == 0,
              onTap: () => openPage(0),
            ),
            PremiumDrawerItem(
              icon: Icons.people_rounded,
              title: 'Manage Users',
              selected: _currentIndex == 1,
              onTap: () => openPage(1),
            ),
            PremiumDrawerItem(
              icon: Icons.event_note_rounded,
              title: 'Manage Events',
              selected: _currentIndex == 2,
              onTap: () => openPage(2),
            ),
            PremiumDrawerItem(
              icon: Icons.insert_chart_rounded,
              title: 'Reports & Analytics',
              selected: _currentIndex == 3,
              onTap: () => openPage(3),
            ),
            PremiumDrawerItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              selected: _currentIndex == 4,
              onTap: () => openPage(4),
            ),
          ],
        ),
        PremiumDrawerSection(
          label: 'ADMIN ACTIONS',
          items: [
            PremiumDrawerItem(
              icon: Icons.verified_user_rounded,
              title: 'Approvals & Requests',
              onTap: () => openScreen(const ApprovalsScreen()),
            ),
            PremiumDrawerItem(
              icon: Icons.shield_rounded,
              title: 'Content Moderation',
              onTap: () => openScreen(const ContentModerationScreen()),
            ),
            PremiumDrawerItem(
              icon: Icons.notifications_rounded,
              title: 'Alerts & Notifications',
              onTap: () => openScreen(const NotificationsScreen()),
            ),
          ],
        ),
      ],
    );
  }

}

class _AdminDashboardHome extends StatelessWidget {
  final String photoUrl;
  final String adminName;

  const _AdminDashboardHome({
    this.photoUrl = '',
    this.adminName = '',
  });

  static const Color _teal = Color(0xFF007E7B);
  static const Color _tealDark = Color(0xFF005E5C);
  static const Color _tealLight = Color(0xFF008E89);
  static const Color _ink = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFEEF2F1);
    final primaryText = isDark ? const Color(0xFFF8FAFC) : _ink;
    final secondaryText = isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600;
    final dividerColor = isDark ? const Color(0xFF334155) : Colors.blueGrey.shade50;
    final adminProvider = context.watch<AdminProvider>();
    final eventProvider = context.watch<EventProvider>();

    final int totalUsers = adminProvider.totalUsersCount;
    final int activeEvents = eventProvider.events.length;
    final int pendingApprovals = adminProvider.pendingApprovalsCount;
    final int flaggedItems = adminProvider.flaggedItemsCount;
    final logs = adminProvider.systemLogs;

    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String displayName = adminName.isNotEmpty
        ? adminName
        : ((currentUser?.displayName?.isNotEmpty == true)
            ? currentUser!.displayName!
            : 'Admin');
    final String initial =
        displayName.trim().isNotEmpty ? displayName.trim()[0].toUpperCase() : 'A';
    final String effectivePhoto = photoUrl.isNotEmpty
        ? photoUrl
        : (currentUser?.photoURL?.trim() ?? '');
    final bool hasPhoto = effectivePhoto.isNotEmpty;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _teal,
          elevation: 0,
          pinned: true,
          expandedHeight: 154.0,
          toolbarHeight: 60,
          leading: Builder(
            builder: (ctx) => Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.white.withOpacity(0.16),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    backgroundImage: hasPhoto
                        ? NetworkImage(effectivePhoto)
                        : null,
                    child: hasPhoto
                        ? null
                        : Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_tealDark, _tealLight],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 40,
                      top: 30,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK, ${displayName.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Admin Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: StreamBuilder<List<NotificationModel>>(
                stream: NotificationService.getUserNotificationsStream(),
                builder: (context, snapshot) {
                  final unreadCount =
                      snapshot.data?.where((n) => !n.isRead).length ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.14),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white, size: 24),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              border: Border.all(color: _tealDark, width: 1.5),
                            ),
                            constraints:
                                const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('Quick Actions', primaryText),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Approvals',
                        '$pendingApprovals Pending',
                        Icons.verified_user_rounded,
                        const Color(0xFF00A896),
                        const ApprovalsScreen(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Moderation',
                        '$flaggedItems Flagged',
                        Icons.warning_rounded,
                        const Color(0xFFEA8C00),
                        const ContentModerationScreen(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _sectionHeader('Platform Metrics', primaryText),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow(Icons.groups_rounded, 'Total Users',
                          '$totalUsers', '+12%', true, primaryText, secondaryText),
                      _divider(dividerColor),
                      _buildMetricRow(Icons.event_available_rounded,
                          'Active Events', '$activeEvents', '+5%', true, primaryText, secondaryText),
                      _divider(dividerColor),
                      _buildMetricRow(Icons.pending_actions_rounded,
                          'Pending Approvals', '$pendingApprovals', '', false, primaryText, secondaryText),
                      _divider(dividerColor),
                      _buildMetricRow(Icons.flag_rounded, 'Flagged Content',
                          '$flaggedItems', '', false, primaryText, secondaryText),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _sectionHeader('Recent Activity', primaryText),
                const SizedBox(height: 14),
                if (logs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.history_rounded,
                            color: isDark ? const Color(0xFF64748B) : Colors.blueGrey.shade200, size: 32),
                        const SizedBox(height: 10),
                        Text(
                          'No recent system activity.',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    child: Column(
                      children: [
                        for (int i = 0; i < logs.length; i++) ...[
                          _buildActivityTile(
                            context,
                            logs[i]['title']?.toString() ?? '',
                            logs[i]['subtitle']?.toString() ?? '',
                            logs[i]['time']?.toString() ?? '',
                            _activityIcon(logs[i]['type']?.toString() ?? ''),
                            _activityColor(logs[i]['type']?.toString() ?? ''),
                          ),
                          if (i != logs.length - 1) _divider(dividerColor),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: _teal,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _divider(Color color) => Divider(
        height: 1,
        thickness: 1,
        color: color,
      );

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget targetScreen,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetScreen),
        ),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF334155)
                  : const Color(0xFFEEF2F1),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.16), color.withOpacity(0.08)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFF8FAFC)
                      : _ink,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 10, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    IconData icon,
    String title,
    String value,
    String change,
    bool isPositive,
    Color primaryText,
    Color secondaryText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: _teal),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (change.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: isPositive
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        change,
                        style: TextStyle(
                          color: isPositive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFF8FAFC)
                        : _ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF94A3B8)
                          : Colors.blueGrey.shade500,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              time,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF64748B)
                    : Colors.blueGrey.shade300,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _activityIcon(String type) {
    switch (type) {
      case 'approval':
        return Icons.verified_user_rounded;
      case 'moderation':
        return Icons.flag_rounded;
      case 'user':
        return Icons.person_rounded;
      case 'event':
        return Icons.event_rounded;
      case 'login':
        return Icons.login_rounded;
      case 'delete':
        return Icons.delete_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  static Color _activityColor(String type) {
    switch (type) {
      case 'approval':
        return const Color(0xFF00A896);
      case 'moderation':
        return Colors.orange;
      case 'user':
        return Colors.blue;
      case 'event':
        return Colors.purple;
      case 'login':
        return Colors.green;
      case 'delete':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }
}
