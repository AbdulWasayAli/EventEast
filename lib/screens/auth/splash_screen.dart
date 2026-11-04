import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import '../attendee/home_dashboard_screen.dart';
import '../organizer/organizer_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/notification_service.dart';
import '../../services/page_transitions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Entrance Animation (Slide up & Fade in)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _slideAnimation = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic)),
    );

    // Continuous Pulse Animation for the background glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _entranceController.forward();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Give the animation minimum 3 seconds to play so it looks premium
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    debugPrint('=== SPLASH INITIALIZE DEBUG ===');
    debugPrint('onboardingCompleted in prefs: $onboardingCompleted');
    debugPrint('================================');

    // 2. Check if user is logged in
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!onboardingCompleted) {
        debugPrint('>>> Navigating to OnboardingScreen');
        Navigator.of(context).pushReplacement(
          FadePageRoute(page: const OnboardingScreen()),
        );
      } else {
        debugPrint('>>> Navigating to LoginScreen because onboardingCompleted is true');
        Navigator.of(context).pushReplacement(
          FadePageRoute(page: const LoginScreen()),
        );
      }
      return;
    }

    
    try {
      
      var doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.serverAndCache));
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

      bool hasRole(Map<String, dynamic>? d) {
        if (d == null) return false;
        return d.containsKey('Role') || d.containsKey('role') || d.containsKey('UserRole') || d.containsKey('userRole');
      }

      if (!doc.exists || !hasRole(data)) {
        final altDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.serverAndCache));
        if (altDoc.exists && hasRole(altDoc.data() as Map<String, dynamic>?)) {
          doc = altDoc;
          data = altDoc.data() as Map<String, dynamic>?;
        } else if (altDoc.exists && !doc.exists) {
          doc = altDoc;
          data = altDoc.data() as Map<String, dynamic>?;
        }
      }

      if (!mounted) return;

      if (doc.exists) {
        NotificationService.saveDeviceToken();
        data = doc.data() as Map<String, dynamic>?;
        final role = (data?['Role'] ?? data?['role'] ?? data?['UserRole'] ?? data?['userRole'] ?? 'attendee').toString().trim().toLowerCase();
        await prefs.setString('last_session_uid', user.uid);
        await prefs.setString('last_session_role', role);

        // DEBUG: Log role value for troubleshooting
        debugPrint('=== SPLASH ROLE DEBUG ===');
        debugPrint('UID: ${user.uid}');
        debugPrint('Raw data keys: ${data?.keys.toList()}');
        debugPrint('Role field value: ${data?["Role"]}');
        debugPrint('Resolved role: $role');
        debugPrint('========================');

        Widget nextScreen;
        if (role == 'admin') {
          debugPrint('>>> SPLASH: Navigating to ADMIN Dashboard');
          nextScreen = const AdminDashboardScreen();
        } else if (role == 'organizer') {
          debugPrint('>>> SPLASH: Navigating to ORGANIZER Dashboard');
          nextScreen = const OrganizerDashboard();
        } else {
          debugPrint('>>> SPLASH: Navigating to ATTENDEE Dashboard (role was: $role)');
          nextScreen = const HomeDashboardScreen();
        }

        Navigator.of(context).pushReplacement(FadePageRoute(page: nextScreen));
      } else {
        Navigator.of(context).pushReplacement(FadePageRoute(page: const HomeDashboardScreen()));
      }
    } catch (e) {
      if (!mounted) return;
      final String? cachedUid = prefs.getString('last_session_uid');
      final String? cachedRole = prefs.getString('last_session_role');
      if (cachedUid == user.uid && cachedRole != null) {
        final Widget dashboard = cachedRole == 'admin'
            ? const AdminDashboardScreen()
            : cachedRole == 'organizer'
                ? const OrganizerDashboard()
                : const HomeDashboardScreen();
        Navigator.of(context).pushReplacement(FadePageRoute(page: dashboard));
        return;
      }
      Navigator.of(context).pushReplacement(FadePageRoute(page: const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
           
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A896).withOpacity(0.08),
                          blurRadius: 120,
                          spreadRadius: 60,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Main Content
            AnimatedBuilder(
              animation: _entranceController,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Box
                      Container(
                        width: 125,
                        height: 125,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007E7B).withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(35),
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            width: 125,
                            height: 125,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      
                      // EventEase Text
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                          ),
                          children: [
                            TextSpan(text: 'Event', style: TextStyle(color: const Color(0xFF1E293B))),
                            TextSpan(text: 'Ease', style: TextStyle(color: Color(0xFF007E7B))),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Premium Tagline
                      Text(
                        'Your premium event companion',
                        style: TextStyle(
                          color: Colors.blueGrey.shade400,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
