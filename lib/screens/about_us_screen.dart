import 'package:flutter/material.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

 
  static const Color _teal900 = Color(0xFF04342C);
  static const Color _teal700 = Color(0xFF0A5744);
  static const Color _teal600 = Color(0xFF0F6E56);
  static const Color _teal400 = Color(0xFF1D9E75);
  static const Color _teal200 = Color(0xFFBFEBD9);
  static const Color _teal100 = Color(0xFF9FE1CB);
  static const Color _teal50 = Color(0xFFE1F5EE);
  static const Color _gold = Color(0xFFC9A227);
  static const Color _canvas = Color(0xFFF4FAF8); 
  static const Color _ink = Color(0xFF1E293B);
  static const Color _inkMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _fade(double start, double end) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slide(double start, double end) => Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ));

  Widget _reveal({
    required double start,
    required double end,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fade(start, end),
      child: SlideTransition(position: _slide(start, end), child: child),
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
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(start: 0.05, end: 0.45, child: _buildPurposeCard(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                  const SizedBox(height: 14),
                  _reveal(
                    start: 0.10,
                    end: 0.50,
                    child: _buildMissionVisionRow(isDark, cardBg, cardBorder, inkColor, inkMutedColor),
                  ),
                  const SizedBox(height: 28),
                  _reveal(
                    start: 0.15,
                    end: 0.55,
                    child: _buildFeaturesSection(isDark, cardBg, cardBorder, inkColor, inkMutedColor),
                  ),
                  const SizedBox(height: 28),
                  _reveal(start: 0.25, end: 0.65, child: _buildStatsRow(isDark)),
                  const SizedBox(height: 28),
                  _reveal(start: 0.30, end: 0.70, child: _buildTeamSection(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                  const SizedBox(height: 28),
                  _reveal(
                    start: 0.35,
                    end: 0.75,
                    child: _buildOrganizationSection(isDark, cardBg, cardBorder, inkColor, inkMutedColor),
                  ),
                  const SizedBox(height: 28),
                  _reveal(
                    start: 0.40,
                    end: 0.80,
                    child: _buildLegalSection(context, isDark, cardBg, cardBorder, inkColor, inkMutedColor),
                  ),
                  const SizedBox(height: 36),
                  _reveal(start: 0.45, end: 0.85, child: _buildFooter(isDark, cardBg, cardBorder, inkColor, inkMutedColor)),
                  const SizedBox(height: 24),
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
      expandedHeight: 258,
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
                    colors: [
                      _teal400.withOpacity(isDark ? 0.20 : 0.28),
                      _teal400.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_teal400, _teal600],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _teal400.withOpacity(0.35),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.event_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? const Color(0xFF334155) : _teal100),
                          ),
                          child: const Icon(
                            Icons.info_rounded,
                            color: _teal400,
                            size: 20,
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
                        'About Us',
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
                      'Smart Event Discovery & Management',
                      style: TextStyle(
                        color: inkMutedColor,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _RoleBadge(
                          label: 'Attendee',
                          icon: Icons.person_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _RoleBadge(
                          label: 'Organizer',
                          icon: Icons.storefront_rounded,
                          isDark: isDark,
                        ),
                        const SizedBox(width: 8),
                        _RoleBadge(
                          label: 'Admin',
                          icon: Icons.admin_panel_settings_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildPurposeCard(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        gradient: isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_teal50, Colors.white],
              ),
        borderRadius: BorderRadius.circular(28),
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
                child: const Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'What is EventEase?',
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
          const SizedBox(height: 18),
          Text(
            'EventEase is a comprehensive event management platform designed to simplify the way people discover, organize, and attend events.',
            style: TextStyle(color: inkMutedColor, fontSize: 14, height: 1.7),
          ),
          const SizedBox(height: 14),
          Text(
            'Our platform connects three key roles — Attendees who want seamless event experiences, Organizers who need powerful management tools, and Administrators who oversee the entire ecosystem.',
            style: TextStyle(color: inkMutedColor, fontSize: 14, height: 1.7),
          ),
        ],
      ),
    );
  }

 
  Widget _buildMissionVisionRow(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatementTile(
              icon: Icons.flag_rounded,
              title: 'Our Mission',
              body: 'Make discovering and running great events effortless.',
              accent: _teal400,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatementTile(
              icon: Icons.visibility_rounded,
              title: 'Our Vision',
              body: 'A single trusted home for every event, everywhere.',
              accent: _gold,
              isDark: isDark,
              cardBg: cardBg,
              cardBorder: cardBorder,
              inkColor: inkColor,
              inkMutedColor: inkMutedColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Key Features — a 2x2 bento grid
  // ---------------------------------------------------------------------
  Widget _buildFeaturesSection(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: 'Key Features', icon: Icons.grid_view_rounded, isDark: isDark, inkColor: inkColor),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureTile(
                  icon: Icons.search_rounded,
                  title: 'Smart Discovery',
                  description:
                      'Tailored search and filters to find events that match your interests.',
                  accent: _teal400,
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureTile(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Digital Tickets',
                  description:
                      'Secure QR-based passes for seamless event check-ins.',
                  accent: const Color(0xFF3B82F6),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _FeatureTile(
                  icon: Icons.analytics_rounded,
                  title: 'Analytics Dashboard',
                  description:
                      'Real-time insights for organizers to track attendance.',
                  accent: const Color(0xFFF59E0B),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureTile(
                  icon: Icons.campaign_rounded,
                  title: 'Instant Notifications',
                  description:
                      'Live announcements and reminders for every event.',
                  accent: const Color(0xFF8B5CF6),
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

 
  Widget _buildStatsRow(bool isDark) {
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
        borderRadius: BorderRadius.circular(28),
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
          Expanded(child: _StatItem(value: '3', label: 'User Roles')),
          _StatDivider(),
          Expanded(child: _StatItem(value: '4', label: 'Core Modules')),
          _StatDivider(),
          Expanded(child: _StatItem(value: '2026', label: 'Founded')),
        ],
      ),
    );
  }

 
  Widget _buildTeamSection(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.25) : _ink.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(title: 'Our Team', icon: Icons.groups_rounded, isDark: isDark, inkColor: inkColor),
          const SizedBox(height: 12),
          Text(
            'Built by a dedicated team passionate about crafting seamless and unforgettable event experiences.',
            style: TextStyle(color: inkMutedColor, fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _TeamMemberCard(
                  name: 'Abdul Wasay',
                  accentIndex: 0,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeamMemberCard(
                  name: 'Mudabbir Ali',
                  accentIndex: 1,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TeamMemberCard(
                  name: 'Laiba Sabir',
                  accentIndex: 2,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TeamMemberCard(
                  name: 'Abdul Raheem',
                  accentIndex: 3,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  
  Widget _buildOrganizationSection(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          title: 'Organization',
          icon: Icons.business_rounded,
          isDark: isDark,
          inkColor: inkColor,
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.apartment_rounded,
                  label: 'Organization',
                  value: 'EventEase Technologies',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.location_on_rounded,
                  label: 'Headquarters',
                  value: 'Karachi, Pakistan',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.calendar_month_rounded,
                  label: 'Founded',
                  value: '2026',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  icon: Icons.language_rounded,
                  label: 'Website',
                  value: 'www.eventease.com',
                  isDark: isDark,
                  cardBg: cardBg,
                  cardBorder: cardBorder,
                  inkColor: inkColor,
                  inkMutedColor: inkMutedColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.email_rounded,
          label: 'Email',
          value: 'eventease@gmail.com',
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

  Widget _buildLegalSection(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color inkColor,
    Color inkMutedColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(
          title: 'Legal & Policies',
          icon: Icons.verified_user_rounded,
          isDark: isDark,
          inkColor: inkColor,
        ),
        const SizedBox(height: 14),
        _buildLegalTile(
          context: context,
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'How we collect, protect and process your personal data',
          badgeText: 'Updated 2026',
          accentColor: _teal400,
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          inkColor: inkColor,
          inkMutedColor: inkMutedColor,
          onTap: () => _showPolicyModal(
            context: context,
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_rounded,
            sections: const [
              MapEntry('1. Data We Collect', 'When you create an account, register for events, or contact organizers, we collect personal information such as your name, email address, role, profile details, and event participation data.'),
              MapEntry('2. How We Use Your Data', 'Your information is used to facilitate event discovery, ticket generation, QR code verification, sending important event reminders, and ensuring system security across attendees and organizers.'),
              MapEntry('3. Payment & Ticket Safety', 'Ticket transactions and passes are encrypted and securely authenticated via Firebase Authentication. We never store raw payment credentials on our servers.'),
              MapEntry('4. Information Sharing', 'We never sell your personal data to third parties. Event organizers can only view attendee registration details required for event entry and capacity management.'),
              MapEntry('5. Your Rights & Data Deletion', 'You have the right to review, update, or request permanent deletion of your profile and event history at any time through the app settings or by contacting our support team at eventease@gmail.com.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildLegalTile(
          context: context,
          icon: Icons.gavel_rounded,
          title: 'Terms of Service',
          subtitle: 'Rules, user guidelines and platform responsibilities',
          badgeText: 'Version 1.0',
          accentColor: _gold,
          isDark: isDark,
          cardBg: cardBg,
          cardBorder: cardBorder,
          inkColor: inkColor,
          inkMutedColor: inkMutedColor,
          onTap: () => _showPolicyModal(
            context: context,
            title: 'Terms of Service',
            icon: Icons.gavel_rounded,
            sections: const [
              MapEntry('1. Acceptance of Terms', 'By using EventEase, whether as an Attendee, Organizer, or Administrator, you agree to comply with these terms, community standards, and applicable local regulations.'),
              MapEntry('2. Organizer Responsibilities', 'Organizers must provide accurate, verified information regarding event dates, locations, schedules, and ticketing. Misleading listings or fraudulent events will result in immediate suspension.'),
              MapEntry('3. Attendee Conduct', 'Attendees agree to respect event venue rules, use valid digital QR passes issued under their account, and avoid unauthorized ticket transfers or disruptions.'),
              MapEntry('4. Intellectual Property', 'All logos, software design, interface elements, and brand assets of EventEase remain the exclusive property of EventEase Technologies.'),
              MapEntry('5. Termination & Liability', 'We reserve the right to suspend accounts violating safety, community standards, or fraud policies. EventEase serves as a management facilitator and is not directly liable for independent third-party venue policies.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color accentColor,
    required bool isDark,
    required Color cardBg,
    required Color cardBorder,
    required Color inkColor,
    required Color inkMutedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: accentColor.withOpacity(0.12),
        highlightColor: accentColor.withOpacity(0.06),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : _ink.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: accentColor.withOpacity(isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: inkColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: inkMutedColor,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: inkMutedColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPolicyModal({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<MapEntry<String, String>> sections,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color modalBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color inkColor = isDark ? const Color(0xFFF8FAFC) : _ink;
    final Color inkMutedColor = isDark ? const Color(0xFF94A3B8) : _inkMuted;
    final Color cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_teal400, _teal600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: inkColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'EventEase Legal & Compliance',
                            style: TextStyle(
                              color: inkMutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: inkMutedColor),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: cardBorder),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 32),
                  itemCount: sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final item = sections[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FBFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.key,
                            style: TextStyle(
                              color: _teal400,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.value,
                            style: TextStyle(
                              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark, Color cardBg, Color cardBorder, Color inkColor, Color inkMutedColor) {
    return Column(
      children: [
        // Elegant decorative divider with center diamond dot
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardBorder.withOpacity(0.0),
                      cardBorder,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _teal400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _teal400.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardBorder,
                      cardBorder.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        // Modern branded card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : _ink.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Logo badge with glowing gradient ring
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_teal400, _teal600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _teal400.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.event_rounded, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'EventEase',
                style: TextStyle(
                  color: inkColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              // Modern pill badge for version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _teal400.withOpacity(isDark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _teal400.withOpacity(isDark ? 0.35 : 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _teal400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'v1.0.0 (Build 2026)',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F6E56),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Crafted with passion for the ultimate event experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inkMutedColor,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '© 2026 EventEase Technologies. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: inkMutedColor.withOpacity(0.6),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Small pill used in the header to show the three EventEase roles.
class _RoleBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;

  const _RoleBadge({
    required this.label,
    required this.icon,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF9FE1CB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF1D9E75)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F6E56),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small heading used above each page section, paired with an icon chip.
class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final Color inkColor;

  const _SectionLabel({
    required this.title,
    required this.icon,
    this.isDark = false,
    this.inkColor = const Color(0xFF1E293B),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F2E26) : const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF1D9E75)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: inkColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// A compact Mission/Vision statement tile.
class _StatementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color inkColor;
  final Color inkMutedColor;

  const _StatementTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.inkColor,
    required this.inkMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? cardBorder : accent.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: inkColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            body,
            style: TextStyle(
              color: inkMutedColor.withOpacity(0.9),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// One number in the dark stats strip.
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

/// One tile in the Key Features bento grid.
class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color inkColor;
  final Color inkMutedColor;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.inkColor,
    required this.inkMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: inkColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(
              color: inkMutedColor.withOpacity(0.9),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// A team contact card
class _TeamMemberCard extends StatefulWidget {
  final String name;
  final int accentIndex;
  final bool isDark;

  const _TeamMemberCard({
    required this.name,
    required this.accentIndex,
    this.isDark = false,
  });

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  static const List<List<Color>> _accents = [
    [Color(0xFF1D9E75), Color(0xFF0F6E56)], // teal / emerald
    [Color(0xFF60A5FA), Color(0xFF2563EB)], // royal blue
    [Color(0xFFF59E0B), Color(0xFFD97706)], // warm amber
    [Color(0xFFA855F7), Color(0xFF7E22CE)], // electric purple
  ];

  bool _pressed = false;

  String get _initials {
    final parts = widget.name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _accents[widget.accentIndex % _accents.length];
    final bool isDark = widget.isDark;
    final Color cardBg = isDark ? const Color(0xFF131D31) : const Color(0xFFF8FAFC);
    final Color borderColor = isDark ? const Color(0xFF2E3D56) : const Color(0xFFE2E8F0);
    final Color nameColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors[0].withOpacity(0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.name,
                style: TextStyle(
                  color: nameColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An Organization info tile — icon, muted label, bold value.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final bool isDark;
  final Color cardBg;
  final Color cardBorder;
  final Color inkColor;
  final Color inkMutedColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    required this.isDark,
    required this.cardBg,
    required this.cardBorder,
    required this.inkColor,
    required this.inkMutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2E26) : const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1D9E75), size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: inkMutedColor.withOpacity(0.75),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: inkColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}