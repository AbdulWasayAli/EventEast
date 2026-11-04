import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../about_us_screen.dart';
import '../contact_us_screen.dart';
import 'profile_screen.dart';
import '../../widgets/premium_ui.dart';

class UnifiedSettingsScreen extends StatefulWidget {
  final String userRole;

  const UnifiedSettingsScreen({
    super.key,
    this.userRole = 'User',
  });

  @override
  State<UnifiedSettingsScreen> createState() => _UnifiedSettingsScreenState();
}

class _UnifiedSettingsScreenState extends State<UnifiedSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Color _primary = Color(0xFF007E7B);
  static const Color _primaryDark = Color(0xFF00524F);
  static const Color _accent = Color(0xFF00A896);
  static const Color _bg = Color(0xFFF6FAF9);


  bool _isLoading = false;

  String _userName = 'User';
  String _userEmail = 'No email available';
  String _userRole = 'User';
  String _profileImageUrl = '';

  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    // Immediately populate available details so the screen never gets stuck in a blank state
    final User? user = _auth.currentUser;
    if (user != null) {
      _userName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'User';
      _userEmail = user.email?.trim().isNotEmpty == true
          ? user.email!.trim()
          : 'No email available';
      _profileImageUrl = user.photoURL?.trim() ?? '';
      _userRole = widget.userRole.trim().isNotEmpty ? widget.userRole.trim() : 'User';
    }
    _loadUserProfile();
  }

  
  Future<void> _loadUserProfile() async {
    try {
      final User? user = _auth.currentUser;

      if (user == null) {
        _setFallbackProfile(null);
        return;
      }

      String name = user.displayName?.trim() ?? '';
      String email = user.email?.trim() ?? '';

      String role = widget.userRole.trim().isNotEmpty
          ? widget.userRole.trim()
          : 'User';

      String profileImage = user.photoURL?.trim() ?? '';
      bool pushNotifications = _pushNotifications;

      // Wrap Firestore calls with a timeout so network delays don't freeze the screen
      final DocumentSnapshot<Map<String, dynamic>> preferencesSnapshot =
          await _firestore.collection('Users').doc(user.uid).get().timeout(
                const Duration(seconds: 4),
                onTimeout: () => throw Exception('Preferences timeout'),
              ).catchError((_) => _firestore.collection('users').doc(user.uid).get());
      if (preferencesSnapshot.data()?['PushNotifications'] is bool) {
        pushNotifications =
            preferencesSnapshot.data()!['PushNotifications'] as bool;
      }

      // Check both 'Users' and 'users' collections
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('Users').doc(user.uid).get().timeout(
                const Duration(seconds: 4),
                onTimeout: () => throw Exception('User doc timeout'),
              ).catchError((_) => _firestore.collection('users').doc(user.uid).get());

      if (!snapshot.exists) {
        snapshot = await _firestore.collection('users').doc(user.uid).get().catchError((_) => snapshot);
      }

      if (!snapshot.exists) {
        final QuerySnapshot<Map<String, dynamic>> result = await _firestore
            .collection('Users')
            .where('UserId', isEqualTo: user.uid)
            .limit(1)
            .get()
            .catchError((_) => _firestore.collection('users').where('UserId', isEqualTo: user.uid).limit(1).get());

        if (result.docs.isNotEmpty) {
          snapshot = result.docs.first;
        }
      }

      if (!snapshot.exists) {
        final QuerySnapshot<Map<String, dynamic>> result = await _firestore
            .collection('users')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get()
            .catchError((_) => _firestore.collection('Users').where('userId', isEqualTo: user.uid).limit(1).get());

        if (result.docs.isNotEmpty) {
          snapshot = result.docs.first;
        }
      }

      if (!snapshot.exists && email.isNotEmpty) {
        final QuerySnapshot<Map<String, dynamic>> result = await _firestore
            .collection('Users')
            .where('Email', isEqualTo: email)
            .limit(1)
            .get()
            .catchError((_) => _firestore.collection('users').where('Email', isEqualTo: email).limit(1).get());

        if (result.docs.isNotEmpty) {
          snapshot = result.docs.first;
        }
      }

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        name = _firstNonEmpty([
          data['Name'], data['name'],
          data['FullName'], data['fullName'],
          data['DisplayName'], data['displayName'],
          data['username'], data['userName'],
        ]);

        final String firestoreEmail = _firstNonEmpty([
          data['Email'], data['email'],
        ]);
        if (firestoreEmail.isNotEmpty) email = firestoreEmail;

        final String firestoreRole = _firstNonEmpty([
          data['Role'], data['role'],
          data['UserRole'], data['userRole'],
        ]);
        if (firestoreRole.isNotEmpty) role = firestoreRole;

        final String firestoreImage = _firstNonEmpty([
          data['ProfileImage'], data['profileImage'],
          data['ProfileImageUrl'], data['profileImageUrl'],
          data['PhotoURL'], data['photoURL'],
          data['PhotoUrl'], data['photoUrl'],
          data['Image'], data['image'],
        ]);
        if (firestoreImage.isNotEmpty) profileImage = firestoreImage;

       
        if (!preferencesSnapshot.exists && data['PushNotifications'] is bool) {
          pushNotifications = data['PushNotifications'] as bool;
        }

      }

      if (name.isEmpty) name = user.displayName?.trim() ?? '';
      if (name.isEmpty) name = 'User';
      if (email.isEmpty) email = user.email?.trim() ?? '';
      if (email.isEmpty) email = 'No email available';
      if (role.trim().isEmpty) {
        role = widget.userRole.trim().isNotEmpty
            ? widget.userRole.trim()
            : 'User';
      }

      if (!mounted) return;

      setState(() {
        _userName = name;
        _userEmail = email;
        _userRole = role;
        _profileImageUrl = profileImage;
        _pushNotifications = pushNotifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SETTINGS PROFILE LOAD ERROR: $e');
      if (!mounted) return;
      _setFallbackProfile(_auth.currentUser);
    }
  }

  void _setFallbackProfile(User? user) {
    String name = user?.displayName?.trim() ?? '';
    String email = user?.email?.trim() ?? '';

    if (name.isEmpty) name = 'User';
    if (email.isEmpty) email = 'No email available';

    final String role = widget.userRole.trim().isNotEmpty
        ? widget.userRole.trim()
        : 'User';

    if (!mounted) return;

    setState(() {
      _userName = name;
      _userEmail = email;
      _userRole = role;
      _profileImageUrl = user?.photoURL?.trim() ?? '';
      _isLoading = false;
    });
  }

  

  String _firstNonEmpty(List<dynamic> values) {
    for (final dynamic value in values) {
      if (value == null) continue;
      final String text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String get _initial {
    final String name = _userName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Color _roleColor() {
    switch (_userRole.trim().toLowerCase()) {
      case 'admin':
      case 'super admin':
        return const Color(0xFF7C3AED);
      case 'organizer':
        return const Color(0xFF028090);
      default:
        return _accent;
    }
  }

  
  Future<void> _openProfile(BuildContext context) async {
    final Widget profileScreen = UnifiedProfileScreen(
      userRole: _userRole,
      userName: _userName,
      userEmail: _userEmail,
    );

    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => profileScreen),
    );

    if (changed == true) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });
      await _loadUserProfile();
    }
  }

  
  Future<void> _saveNotificationPreferences() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('Users').doc(user.uid).set(
        {
          'PushNotifications': _pushNotifications,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF007E7B),
          ),
        );
      }
    } catch (e) {
      debugPrint('SAVE NOTIFICATIONS ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save notification preferences.'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  
  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirm Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out of your account?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
            ),
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(80, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    foregroundColor: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey.shade600,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    try {
                      await _auth.signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    } catch (e) {
                      debugPrint('LOGOUT ERROR: $e');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(100, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  
  Widget _buildProfileAvatar() {
    final avatarInner = _profileImageUrl.isEmpty
        ? CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Text(
              _initial,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          )
        : CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: Image.network(
                _profileImageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_accent, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: avatarInner,
    );
  }

  BoxDecoration _cardDecoration() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE9EFEF),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF00524F).withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldBg = isDark ? const Color(0xFF0F172A) : _bg;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    final Color roleColor = _roleColor();
    final Color primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadUserProfile,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: SettingsStyleAppBar(
                title: 'Settings',
                showBackArrow: false,
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern Hero Profile Card
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            _buildProfileAvatar(),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _userEmail,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: roleColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: roleColor.withValues(alpha: 0.22),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      _userRole.toUpperCase(),
                                      style: TextStyle(
                                        color: roleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF0FDF9),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : _primary.withValues(alpha: 0.2),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : _primary.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  color: isDark
                                      ? const Color(0xFF5EEAD4)
                                      : _primary,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- APPEARANCE & THEME SECTION ---
                    _sectionLabel('Appearance'),

                          Container(
                            decoration: _cardDecoration(),
                            padding: const EdgeInsets.all(12),
                            child: Consumer<ThemeProvider>(
                              builder: (context, themeProvider, _) {
                                final currentMode = themeProvider.themeMode;
                                return Row(
                                  children: [
                                    _buildThemeOption(
                                      context: context,
                                      title: 'System',
                                      icon: Icons.brightness_auto_rounded,
                                      isSelected: currentMode == ThemeMode.system,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        themeProvider.setThemeMode(ThemeMode.system);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildThemeOption(
                                      context: context,
                                      title: 'Light',
                                      icon: Icons.light_mode_rounded,
                                      isSelected: currentMode == ThemeMode.light,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        themeProvider.setThemeMode(ThemeMode.light);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildThemeOption(
                                      context: context,
                                      title: 'Dark',
                                      icon: Icons.dark_mode_rounded,
                                      isSelected: currentMode == ThemeMode.dark,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        themeProvider.setThemeMode(ThemeMode.dark);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 28),

                          _sectionLabel('Account & Application'),

                          Container(
                            decoration: _cardDecoration(),
                            child: Column(
                              children: [
                                _buildSettingTile(
                                  icon: Icons.person_outline_rounded,
                                  title: 'My Profile',
                                  subtitle: 'Edit name, phone & account details',
                                  onTap: () => _openProfile(context),
                                ),
                                _buildDivider(),
                                _buildSwitchTile(
                                  icon: Icons.notifications_active_outlined,
                                  title: 'Push Notifications',
                                  subtitle: 'Receive instant app updates',
                                  value: _pushNotifications,
                                  onChanged: (val) {
                                    setState(() => _pushNotifications = val);
                                    _saveNotificationPreferences();
                                  },
                                ),
                                _buildDivider(),
                                _buildSettingTile(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'Contact Us',
                                  subtitle: 'Send feedback, queries & support requests',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ContactUsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(),
                                _buildSettingTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'About Us',
                                  subtitle: 'Learn about EventEase & development team',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const AboutUsScreen(),
                                      ),
                                    );
                                  },
                                  isLast: true,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          _sectionLabel('Session'),

                          Container(
                            decoration: _cardDecoration(),
                            child: _buildSettingTile(
                              icon: Icons.logout_rounded,
                              iconColor: Colors.redAccent,
                              title: 'Log Out',
                              titleColor: Colors.redAccent,
                              subtitle: 'Sign out of your EventEase account',
                              onTap: () => _confirmLogout(context),
                              isLast: true,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // --- MODERN BRAND FOOTER ---
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.asset(
                                          'assets/images/logo.jpg',
                                          height: 20,
                                          width: 20,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.celebration_rounded,
                                            size: 18,
                                            color: _primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'EventEase',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'v1.0.0',
                                          style: TextStyle(
                                            color: _primary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Secure Event Experience',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildDivider() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 66, right: 16),
      child: Container(
        height: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    Color iconColor = _primary,
    required String title,
    Color? titleColor,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color defaultSubColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.vertical(
        bottom: isLast ? const Radius.circular(22) : Radius.zero,
        top: Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          bottom: isLast ? const Radius.circular(22) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? defaultTitleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: defaultSubColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    Color iconColor = _primary,
    required String title,
    Color? titleColor,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultTitleColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color defaultSubColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? defaultTitleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: defaultSubColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: _primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color unselectedBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final Color unselectedBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color inactiveIconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color inactiveTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [_primary, _accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : unselectedBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF2DD4BF) : unselectedBorder,
                width: isSelected ? 1.6 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _primary.withValues(alpha: isDark ? 0.45 : 0.32),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.18)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          boxShadow: isSelected
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: isSelected ? Colors.white : inactiveIconColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : inactiveTextColor,
                          letterSpacing: isSelected ? 0.2 : 0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
