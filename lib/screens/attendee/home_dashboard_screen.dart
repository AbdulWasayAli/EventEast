import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'discover_events_screen.dart';
import 'my_events_screen.dart';
import 'favorites_screen.dart';
import '../common/settings_screen.dart';
import '../common/notifications_screen.dart';
import 'gallery_view_screen.dart';
import '../about_us_screen.dart';
import '../contact_us_screen.dart';
import '../../widgets/premium_ui.dart';

class HomeDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const HomeDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  late int _currentIndex;
  late PageController _pageController;

  final List<Widget> _screens = const [
    DiscoverEventsScreen(),
    MyEventsScreen(),
    GalleryViewScreen(),
    FavoritesScreen(),
    UnifiedSettingsScreen(userRole: 'Attendee'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent),
              const SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
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
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    elevation: 0,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildNavigationDrawer(context),
      body: PageView(
        clipBehavior: Clip.none,
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentIndex,
        items: const [
          PremiumNavItem(icon: Icons.explore_rounded, label: 'Discover'),
          PremiumNavItem(icon: Icons.local_activity_rounded, label: 'My Events'),
          PremiumNavItem(icon: Icons.photo_library_rounded, label: 'Gallery'),
          PremiumNavItem(icon: Icons.favorite_rounded, label: 'Favorites'),
          PremiumNavItem(icon: Icons.settings_rounded, label: 'Settings'),
        ],
        onTap: (index) => _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('Users').doc(user.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        String name = user?.displayName ?? 'Attendee User';
        String email = user?.email ?? 'user@eventease.com';
        String? photoUrl = user?.photoURL;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          name = data?['Name'] ?? data?['name'] ?? name;
          email = data?['Email'] ?? data?['email'] ?? email;
          photoUrl = data?['ProfileImage'] ?? photoUrl;
        }

        void openPage(int index) {
          Navigator.pop(context);
          _pageController.jumpToPage(index);
        }

        void openScreen(Widget screen) {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }

        return PremiumDrawer(
          name: name,
          email: email,
          photoUrl: photoUrl,
          roleLabel: 'ATTENDEE',
          onLogout: () {
            Navigator.pop(context);
            _logout();
          },
          sections: [
            PremiumDrawerSection(
              label: 'MAIN MENU',
              items: [
                PremiumDrawerItem(
                  icon: Icons.explore_rounded,
                  title: 'Discover Events',
                  selected: _currentIndex == 0,
                  onTap: () => openPage(0),
                ),
                PremiumDrawerItem(
                  icon: Icons.local_activity_rounded,
                  title: 'My Registered Events',
                  selected: _currentIndex == 1,
                  onTap: () => openPage(1),
                ),
                PremiumDrawerItem(
                  icon: Icons.favorite_rounded,
                  title: 'Saved Favorites',
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
              label: 'MORE',
              items: [
                PremiumDrawerItem(
                  icon: Icons.notifications_rounded,
                  title: 'Alerts & Notifications',
                  onTap: () => openScreen(const NotificationsScreen()),
                ),
                PremiumDrawerItem(
                  icon: Icons.photo_library_rounded,
                  title: 'Event Gallery',
                  selected: _currentIndex == 2,
                  onTap: () => openPage(2),
                ),
                PremiumDrawerItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Contact Us',
                  onTap: () => openScreen(const ContactUsScreen()),
                ),
                PremiumDrawerItem(
                  icon: Icons.info_rounded,
                  title: 'About Us',
                  onTap: () => openScreen(const AboutUsScreen()),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

}
