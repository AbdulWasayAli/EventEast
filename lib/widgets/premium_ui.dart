import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/event_model.dart';

class PremiumNavItem {
  const PremiumNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class PremiumBottomNav extends StatelessWidget {
  const PremiumBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<PremiumNavItem> items;
  final ValueChanged<int> onTap;

  static const Color _primary = Color(0xFF007E7B);
  static const Color _primaryLight = Color(0xFF10B981);
  static const Color _idle = Color(0xFF8A9AA5);

  static const double _barHPad = 6;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 32, 16, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth =
              (constraints.maxWidth - _barHPad * 2) / items.length;
          final iconSize = math.max(38.0, math.min(56.0, tabWidth - 8));
          final knobSize = iconSize + 10;
          final knobLeft =
              _barHPad + tabWidth * currentIndex + (tabWidth - knobSize) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              _buildBar(context),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 480),
                curve: Curves.easeOutBack,
                left: knobLeft,
                top: -knobSize * 0.36,
                child: _buildKnob(context, iconSize, knobSize),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark ? const Color(0xFF94A3B8) : _idle;
    final selectedLabelColor =
        isDark ? const Color(0xFF5EEAD4) : _primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A))
                .withOpacity(isDark ? 0.38 : 0.09),
            blurRadius: isDark ? 18 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF111827)
                  : Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : Colors.white.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: _barHPad, vertical: 7),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = currentIndex == index;
            final item = items[index];
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: item.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () => onTap(index),
                  child: SizedBox(
                    height: 58,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: selected ? 0 : 1,
                          child: Icon(item.icon, size: 22, color: idleColor),
                        ),
                        const SizedBox(height: 3),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 280),
                          opacity: selected ? 1 : 0,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: selectedLabelColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
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
          }),
        ),
      ),
    ))));
  }

  Widget _buildKnob(
    BuildContext context,
    double iconSize,
    double cursorSize,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: cursorSize,
      height: cursorSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: Colors.white,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.38 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isDark ? const Color(0xFF14B8A6) : _primary)
                .withOpacity(isDark ? 0.30 : 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_primaryLight, _primary],
            ),
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                items[currentIndex].icon,
                key: ValueKey<int>(currentIndex),
                size: iconSize * 0.45,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumDrawerItem {
  const PremiumDrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool selected;
}

class PremiumDrawerSection {
  const PremiumDrawerSection({required this.label, required this.items});

  final String label;
  final List<PremiumDrawerItem> items;
}
class PremiumDrawer extends StatelessWidget {
  const PremiumDrawer({
    super.key,
    required this.name,
    required this.email,
    required this.roleLabel,
    required this.sections,
    required this.onLogout,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String roleLabel;
  final List<PremiumDrawerSection> sections;
  final VoidCallback onLogout;
  final String? photoUrl;

  static const Color _teal = Color(0xFF007E7B);
  static const Color _tealLight = Color(0xFF008E89);
  static const double _overlap = 22;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final drawerBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Drawer(
      backgroundColor: drawerBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: Column(
        children: [
          _buildHero(context),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -_overlap),
              child: _buildSheet(context),
            ),
          ),
          _buildLogout(),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 18,
          20,
          _overlap + 24,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_tealLight, _teal],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -96, right: -64, child: _orb(172, 0.10)),
            Positioned(bottom: -34, right: 28, child: _orb(82, 0.07)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVENTEASE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFE0F7F5),
                        backgroundImage:
                            hasPhoto ? NetworkImage(photoUrl!) : null,
                        child: hasPhoto
                            ? null
                            : Text(
                                name.trim().isNotEmpty
                                    ? name.trim()[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: _teal,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withOpacity(0.78),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 7),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              roleLabel,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _orb(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _buildSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF334155) : const Color(0xFFEEF3F2);

    final children = <Widget>[
      Center(
        child: Container(
          width: 34,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ];

    for (var i = 0; i < sections.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            height: 1,
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            color: dividerColor,
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Text(
            sections[i].label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      );
      children.addAll(sections[i].items.map((item) => _buildTile(context, item)));
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 12),
        children: children,
      ),
    );
  }

  Widget _buildTile(BuildContext context, PremiumDrawerItem item) {
    final selected = item.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = selected
        ? Colors.white
        : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: selected ? _teal : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: item.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(item.icon,
                    size: 19, color: selected ? Colors.white : _teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Material(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          onTap: onLogout,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 19, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
class PremiumScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PremiumScreenAppBar({
    super.key,
    required this.title,
    this.eyebrow,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.showBackArrow = true,
  });

  final String title;
  final String? eyebrow;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackArrow;

  @override
  Size get preferredSize => Size.fromHeight(eyebrow != null ? 96 : 88);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool canPop = Navigator.of(context).canPop();

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        width: double.infinity,
        height: preferredSize.height + topPadding,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D4A), Color(0xFF007E7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Ambient subtle glow orb for modern depth
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 14),
                      ] else if (showBackArrow && canPop) ...[
                        _PremiumBackButton(onPressed: () => Navigator.of(context).pop()),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (eyebrow != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: Colors.white.withOpacity(0.15), width: 0.8),
                                ),
                                child: Text(
                                  eyebrow!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            _ModernTitleText(title: title),
                          ],
                        ),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsStyleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackArrow;
  
  const SettingsStyleAppBar({
    super.key, 
    required this.title,
    this.actions,
    this.leading,
    this.showBackArrow = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(88);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool canPop = Navigator.of(context).canPop();
    
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        width: double.infinity,
        height: preferredSize.height + topPadding,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D4A), Color(0xFF007E7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Ambient subtle glow orb for modern depth
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        const SizedBox(width: 14),
                      ] else if (showBackArrow && canPop) ...[
                        _PremiumBackButton(onPressed: () => Navigator.of(context).pop()),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: _ModernTitleText(title: title),
                      ),
                      if (actions != null) ...actions!,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings-style header with an optional tab strip for primary tab screens.
class SettingsStyleTabAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsStyleTabAppBar({
    super.key,
    required this.title,
    required this.tabBar,
    this.showBackArrow = true,
  });

  final String title;
  final TabBar tabBar;
  final bool showBackArrow;

  @override
  Size get preferredSize => const Size.fromHeight(120);

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool canPop = Navigator.of(context).canPop();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        height: preferredSize.height + topPadding,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D4A), Color(0xFF007E7B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (showBackArrow && canPop) ...[
                          _PremiumBackButton(onPressed: () => Navigator.of(context).pop()),
                          const SizedBox(width: 14),
                        ],
                        Expanded(
                          child: _ModernTitleText(title: title),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: tabBar,
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
}

/// Ultra-modern dual-tone gradient title with soft shadow
class _ModernTitleText extends StatelessWidget {
  const _ModernTitleText({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFFF0FDFA), // Soft ice-teal tint
            Color(0xFFCCFBF1), // Premium mint highlight
          ],
          stops: [0.0, 0.65, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.22,
          shadows: [
            Shadow(
              color: Color(0x38000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern frosted glass back button for premium AppBars.
class _PremiumBackButton extends StatelessWidget {
  const _PremiumBackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}


class _HeaderOrb extends StatelessWidget {
  const _HeaderOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );
}

class PremiumEventCard extends StatelessWidget {
  const PremiumEventCard({super.key, required this.event, required this.onTap});

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFull = event.availableSeats <= 0;
    const primary = Color(0xFF007E7B);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'event_image_${event.id}',
                      child: event.imageUrl.isEmpty
                          ? const ColoredBox(
                              color: Color(0xFFE6F2F1),
                              child: Icon(Icons.event_rounded,
                                  size: 48, color: primary),
                            )
                          : Image.network(event.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                    color: Color(0xFFE6F2F1),
                                    child: Icon(Icons.event_rounded,
                                        size: 48, color: primary),
                                  )),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0xA8001F1E)],
                          stops: [0.35, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: _Pill(
                        label: '${event.date.day} ${_month(event.date.month)}',
                        foreground: primary,
                        background: Theme.of(context).cardColor,
                      ),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: _Pill(
                        label: event.price == 0
                            ? 'Free'
                            : 'Rs. ${event.price.toStringAsFixed(0)}',
                        foreground: Colors.white,
                        background: const Color(0xDD102A2A),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Text(event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.35)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 15, 18, 17),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(spacing: 12, runSpacing: 6, children: [
                        _Meta(icon: Icons.location_on_outlined,
                            label: event.location.isEmpty ? 'Location TBA' : event.location),
                        _Meta(icon: Icons.schedule_rounded,
                            label: event.startTime.isEmpty ? 'Time TBA' : event.startTime),
                      ]),
                    ),
                    _Pill(
                      label: isFull ? 'Sold out' : '${event.availableSeats} left',
                      foreground: isFull ? const Color(0xFFB42318) : primary,
                      background: isFull ? const Color(0xFFFFE9E7) : const Color(0xFFE4F5F2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _month(int month) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month - 1];
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.foreground, required this.background});
  final String label;
  final Color foreground;
  final Color background;
  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w800)),
        ),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 15, color: const Color(0xFF7A8994)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF60717D), fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]);
}
