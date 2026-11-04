import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen>
    with SingleTickerProviderStateMixin {
  
  static const Color _teal900 = Color(0xFF04342C);
  static const Color _teal700 = Color(0xFF0A5744);
  static const Color _teal600 = Color(0xFF0F6E56);
  static const Color _teal400 = Color(0xFF1D9E75);
  static const Color _teal100 = Color(0xFF9FE1CB);
  static const Color _teal50 = Color(0xFFE1F5EE);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _canvas = Color(0xFFF4FAF8);
  static const Color _ink = Color(0xFF1E293B);
  static const Color _inkMuted = Color(0xFF64748B);

  static const double _radiusMd = 18;
  static const double _radiusXl = 28;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _subjectFocus = FocusNode();
  final _messageFocus = FocusNode();

  String _selectedTopic = 'General';
  static const List<Map<String, dynamic>> _topics = [
    {'name': 'General', 'icon': Icons.chat_bubble_outline_rounded},
    {'name': 'Booking', 'icon': Icons.confirmation_number_outlined},
    {'name': 'Organizer', 'icon': Icons.campaign_outlined},
    {'name': 'Tech Help', 'icon': Icons.build_circle_outlined},
  ];

  bool _isSending = false;
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Widget _reveal({
    required double start,
    required double end,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fade(start, end),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
        child: child,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('ContactMessages').add({
        'UserId': user?.uid,
        'Name': _nameController.text.trim(),
        'Email': _emailController.text.trim(),
        'Subject': _subjectController.text.trim(),
        'Message': _messageController.text.trim(),
        'Topic': _selectedTopic,
        'Status': 'New',
        'SubmittedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message could not be sent. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSending = false);

    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color dialogBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color titleColor = isDark ? const Color(0xFFF8FAFC) : _ink;
    final Color descColor = isDark ? const Color(0xFF94A3B8) : _inkMuted;
    final Color borderColor = isDark ? const Color(0xFF334155) : Colors.transparent;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(_radiusXl),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.4) : _teal900.withOpacity(0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_teal400, _teal600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _teal600.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                Text(
                  'Message Sent!',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Thank you for reaching out. Our team will get back to you within 24 hours.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: descColor, fontSize: 14, height: 1.55),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_radiusMd),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color canvasColor = isDark ? const Color(0xFF0F172A) : _canvas;
    final Color inkColor = isDark ? const Color(0xFFF8FAFC) : _ink;
    final Color inkMutedColor = isDark ? const Color(0xFF94A3B8) : _inkMuted;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: canvasColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(isDark, inkColor, inkMutedColor, canvasColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(start: 0, end: .4, child: _buildIntroCard(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                  const SizedBox(height: 16),
                  _reveal(start: .1, end: .55, child: _buildContactInfoRow(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                  const SizedBox(height: 24),
                  _reveal(start: .2, end: .6, child: _buildTrustStrip(isDark)),
                  const SizedBox(height: 32),
                  _reveal(start: .25, end: .6, child: _buildSectionHeader(inkColor, inkMutedColor)),
                  const SizedBox(height: 20),
                  _reveal(start: .3, end: .95, child: _buildFormCard(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildHeader(bool isDark, Color inkColor, Color inkMutedColor, Color canvasColor) {
    final Color headerBg = isDark ? const Color(0xFF162235) : _teal50;
    return SliverAppBar(
      backgroundColor: headerBg,
      elevation: 0,
      pinned: true,
      stretch: true,
      expandedHeight: 250,
      iconTheme: IconThemeData(color: inkColor),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [headerBg, canvasColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_teal400.withOpacity(isDark ? 0.20 : 0.28), _teal400.withOpacity(0)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _gold.withOpacity(isDark ? 0.05 : 0.08),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_teal400, _teal600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _teal600.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : _teal100,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Support Active',
                                style: TextStyle(
                                  color: inkMutedColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF5EEAD4), Color(0xFF14B8A6)]
                            : const [_teal700, _teal400],
                      ).createShader(rect),
                      child: const Text(
                        'Contact Us',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get in touch with the EventEase team',
                      style: TextStyle(
                        color: inkMutedColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Intro card ----------------
  Widget _buildIntroCard(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_teal50, Colors.white],
              ),
        borderRadius: BorderRadius.circular(_radiusXl),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : _teal600.withOpacity(0.05),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal400, _teal600],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _teal400.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.forum_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'How can we help?',
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Send us your question, feedback, or event inquiry. Our team will respond as soon as possible.',
            style: TextStyle(color: inkMutedColor, fontSize: 14, height: 1.65),
          ),
        ],
      ),
    );
  }

  // ---------------- Contact info ----------------
  Widget _buildContactInfoRow(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildContactInfoCard(
                Icons.email_rounded,
                'Email',
                'support@eventease.com',
                isDark: isDark,
                cardBg: cardBg,
                cardBorder: cardBorder,
                inkColor: inkColor,
                inkMutedColor: inkMutedColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactInfoCard(
                Icons.call_rounded,
                'Phone',
                '+92 300 1234567',
                isDark: isDark,
                cardBg: cardBg,
                cardBorder: cardBorder,
                inkColor: inkColor,
                inkMutedColor: inkMutedColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildContactInfoCard(
          Icons.location_on_rounded,
          'Office Location',
          'Karachi, Pakistan',
          fullWidth: true,
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          inkColor: inkColor,
          inkMutedColor: inkMutedColor,
        ),
      ],
    );
  }

  Widget _buildContactInfoCard(
    IconData icon,
    String title,
    String value, {
    bool fullWidth = false,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color inkColor,
    required Color inkMutedColor,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(_radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radiusMd),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radiusMd),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : _ink.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: fullWidth
              ? Row(
                  children: [
                    _infoIcon(icon, isDark),
                    const SizedBox(width: 12),
                    Expanded(child: _infoText(title, value, inkColor, inkMutedColor)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoIcon(icon, isDark),
                    const SizedBox(height: 12),
                    _infoText(title, value, inkColor, inkMutedColor),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _infoIcon(IconData icon, bool isDark) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2E26) : _teal50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _teal400, size: 20),
      );

  Widget _infoText(String title, String value, Color inkColor, Color inkMutedColor) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: inkMutedColor.withOpacity(0.85),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: inkColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );

  // ---------------- Trust strip ----------------
  Widget _buildTrustStrip(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF032620), Color(0xFF063E32)]
              : const [_teal900, _teal700],
        ),
        borderRadius: BorderRadius.circular(_radiusXl),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : _teal900.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(child: _StatItem(value: '<2h', label: 'First Reply')),
          _StatDivider(),
          Expanded(child: _StatItem(value: '24/7', label: 'Support Team')),
          _StatDivider(),
          Expanded(child: _StatItem(value: '98%', label: 'Satisfaction')),
        ],
      ),
    );
  }

  // ---------------- Form ----------------
  Widget _buildSectionHeader(Color inkColor, Color inkMutedColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: _teal400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send us a Message',
              style: TextStyle(
                color: inkColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'We typically respond within a few hours.',
              style: TextStyle(
                color: inkMutedColor.withValues(alpha: 0.85),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Form(
      key: _formKey,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(_radiusXl),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0x080F172A),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category/Topic selector
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Text(
                    'INQUIRY TOPIC',
                    style: TextStyle(
                      color: inkMutedColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _teal400.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        color: _teal600,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _topics.map((t) {
                  final String name = t['name'] as String;
                  final IconData icon = t['icon'] as IconData;
                  final bool isSelected = _selectedTopic == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 2),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTopic = name);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? _teal600 : _teal700)
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? _teal400
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.3 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _teal400.withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                size: 14,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            _buildFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              nextFocus: _emailFocus,
              label: 'FULL NAME',
              hint: 'e.g. Ali Ahmad',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocus: _subjectFocus,
              label: 'EMAIL ADDRESS',
              hint: 'e.g. ali@example.com',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              isDark: isDark,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Please enter your email';
                final regex = RegExp(r'^[\w.\-]+@([\w-]+\.)+[\w-]{2,}$');
                if (!regex.hasMatch(value)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _subjectController,
              focusNode: _subjectFocus,
              nextFocus: _messageFocus,
              label: 'SUBJECT',
              hint: 'e.g. Partnership or query details',
              icon: Icons.title_rounded,
              isDark: isDark,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a subject' : null,
            ),
            const SizedBox(height: 12),
            _buildFormField(
              controller: _messageController,
              focusNode: _messageFocus,
              label: 'MESSAGE',
              hint: 'Type your message or inquiry here...',
              icon: Icons.chat_outlined,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              isDark: isDark,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter your message'
                  : null,
            ),
            const SizedBox(height: 18),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [_teal400, _teal600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _teal600.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isSending ? null : _submitForm,
          child: Center(
            child: _isSending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Send Message',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color inkColor,
    required Color inkMutedColor,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    final Color inputFill = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color inputBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: inkMutedColor,
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
              letterSpacing: 0.7,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction ??
              (nextFocus != null ? TextInputAction.next : TextInputAction.done),
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          cursorColor: _teal400,
          validator: validator,
          style: TextStyle(
            color: inkColor,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: inkMutedColor.withValues(alpha: 0.55),
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                bottom: maxLines > 1 ? 42 : 0,
              ),
              child: Icon(
                icon,
                color: inkMutedColor.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
            filled: true,
            fillColor: inputFill,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor, width: 1.1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _teal400, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// One number in the dark trust strip. Identical pattern to the About
/// screen's stats strip so both pages share the same visual language.
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Thin vertical divider between stat items.
class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withOpacity(0.15),
    );
  }
}