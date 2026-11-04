import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/page_transitions.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  double _pageOffset = 0;
  int _currentPage = 0;
  late final AnimationController _contentAnimController;
  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _iconFadeAnim;
  late final Animation<Offset> _titleSlideAnim;
  late final Animation<double> _titleFadeAnim;
  late final Animation<Offset> _subtitleSlideAnim;
  late final Animation<double> _subtitleFadeAnim;
  late final AnimationController _bgAnimController;
  late final AnimationController _ringAnimController;

  bool _buttonPressed = false;

  // EventEase brand palette (teal + ivory)
  static const Color _teal900 = Color(0xFF04342C);
  static const Color _teal700 = Color(0xFF0A5744);
  static const Color _teal600 = Color(0xFF0F6E56);
  static const Color _teal400 = Color(0xFF1D9E75);
  static const Color _teal200 = Color(0xFFBFEBD9);
  static const Color _teal100 = Color(0xFF9FE1CB);
  static const Color _teal50 = Color(0xFFE1F5EE);

  final List<_OnboardData> _onboardingData = const [
    _OnboardData(
      title: "Discover every event",
      subtitle:
          "Search and filter events by category, date, and location — tech, music, sports, workshops and more, all in one place.",
      icon: Icons.explore_rounded,
    ),
    _OnboardData(
      title: "Register in a tap",
      subtitle:
          "Reserve your seat instantly and get a digital QR pass — your ticket for fast, contactless event check-in.",
      icon: Icons.qr_code_2_rounded,
    ),
    _OnboardData(
      title: "Never miss an update",
      subtitle:
          "Get reminders before an event starts, plus instant alerts for schedule changes and organizer announcements.",
      icon: Icons.notifications_active_rounded,
    ),
    _OnboardData(
      title: "One app, every role",
      subtitle:
          "Attendees discover and register, organizers create and manage events, admins oversee it all — each with their own dashboard.",
      icon: Icons.groups_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _ringAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _contentAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconScaleAnim = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack),
    );
    _iconFadeAnim = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _titleFadeAnim = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _titleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    ));

    _subtitleFadeAnim = CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _subtitleSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentAnimController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));

    _contentAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentAnimController.dispose();
    _bgAnimController.dispose();
    _ringAnimController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
    _contentAnimController
      ..reset()
      ..forward();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      FadePageRoute(page: const LoginScreen()),
    );
  }

  bool get _isLastPage => _currentPage == _onboardingData.length - 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_teal50.withOpacity(0.9), Colors.white],
                ),
              ),
            ),
          ),
          _buildAnimatedBackground(size),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) => _buildPage(index, theme),
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: Listenable.merge([_bgAnimController, _pageController]),
      builder: (context, _) {
        final breathe = Curves.easeInOut.transform(_bgAnimController.value);
        final parallax = _pageOffset * 30;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -size.width * 0.32 + breathe * 16,
                right: -size.width * 0.3 - parallax,
                child: _glow(size.width * 0.85, _teal400.withOpacity(0.28)),
              ),
              Positioned(
                bottom: -size.width * 0.34 - breathe * 12,
                left: -size.width * 0.34 + parallax,
                child: _glow(size.width * 0.7, _teal200.withOpacity(0.35)),
              ),
              Positioned(
                top: size.height * 0.32 + breathe * 10,
                left: -size.width * 0.2 - parallax * 0.6,
                child: _glow(size.width * 0.4, _teal100.withOpacity(0.3)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glow(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              '0${_currentPage + 1} / 0${_onboardingData.length}',
              key: ValueKey(_currentPage),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: _teal600.withOpacity(0.6),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: _isLastPage ? 0 : 1,
            child: TextButton(
              onPressed: _isLastPage ? null : _completeOnboarding,
              style: TextButton.styleFrom(foregroundColor: _teal600),
              child: const Text(
                "Skip",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index, ThemeData theme) {
    final data = _onboardingData[index];
    final t = (index - _pageOffset).clamp(-1.0, 1.0);
    final scale = 1 - (t.abs() * 0.12);
    final fade = 1 - (t.abs() * 0.55);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: fade.clamp(0.0, 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _iconFadeAnim,
                child: ScaleTransition(
                  scale: _iconScaleAnim,
                  child: _buildIcon(data.icon),
                ),
              ),
              const SizedBox(height: 44),
              FadeTransition(
                opacity: _titleFadeAnim,
                child: SlideTransition(
                  position: _titleSlideAnim,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [_teal700, _teal400],
                    ).createShader(rect),
                    child: Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeTransition(
                opacity: _subtitleFadeAnim,
                child: SlideTransition(
                  position: _subtitleSlideAnim,
                  child: Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.65) ??
                          Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildIcon(IconData icon) {
    return SizedBox(
      width: 232,
      height: 232,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 232,
                height: 232,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // Continuously rotating gradient ring
          AnimatedBuilder(
            animation: _ringAnimController,
            builder: (context, _) {
              return Transform.rotate(
                angle: _ringAnimController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(216, 216),
                  painter: _RingPainter(colorA: _teal400, colorB: _teal600),
                ),
              );
            },
          ),
          Container(
            width: 146,
            height: 146,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_teal400, _teal600],
              ),
              boxShadow: [
                BoxShadow(
                  color: _teal400.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Icon(icon, size: 62, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 28.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWormIndicator(),
          _buildGlassButton(),
        ],
      ),
    );
  }
  Widget _buildWormIndicator() {
    return Row(
      children: List.generate(_onboardingData.length, (index) {
        final distance = (index - _pageOffset).abs().clamp(0.0, 1.0);
        final amount = 1 - distance;
        final width = 8 + (18 * amount);
        final color = Color.lerp(_teal100, _teal400, amount)!;

        return Container(
          margin: const EdgeInsets.only(right: 8),
          height: 8,
          width: width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: amount > 0.5
                ? [
                    BoxShadow(
                      color: _teal400.withOpacity(0.35 * amount),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildGlassButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _buttonPressed = true),
      onTapUp: (_) => setState(() => _buttonPressed = false),
      onTapCancel: () => setState(() => _buttonPressed = false),
      child: AnimatedScale(
        scale: _buttonPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          height: 56,
          width: _isLastPage ? 172 : 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_teal400, _teal700],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
            boxShadow: [
              BoxShadow(
                color: _teal600.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                if (_isLastPage) {
                  _completeOnboarding();
                } else {
                  HapticFeedback.lightImpact();
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeInOutCubic,
                  );
                }
              },
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: _isLastPage
                      ? const Text(
                          "Get started",
                          key: ValueKey('label'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_forward_rounded,
                          key: ValueKey('arrow'),
                          size: 22,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _RingPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;

  const _RingPainter({required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          colorA.withOpacity(0),
          colorA.withOpacity(0.9),
          colorB.withOpacity(0.9),
          colorB.withOpacity(0),
        ],
        stops: const [0.0, 0.18, 0.5, 0.68],
      ).createShader(rect);

    canvas.drawArc(
      rect.deflate(paint.strokeWidth),
      0,
      2 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

class _OnboardData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}