import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/event_provider.dart';
import '../../models/event_model.dart';

import 'event_details_screen.dart';
import 'search_filter_screen.dart';
import '../common/notifications_screen.dart';
import 'gallery_view_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../widgets/premium_ui.dart';

class DiscoverEventsScreen extends StatefulWidget {
  const DiscoverEventsScreen({super.key});

  @override
  State<DiscoverEventsScreen> createState() => _DiscoverEventsScreenState();
}

class _DiscoverEventsScreenState extends State<DiscoverEventsScreen> {
  String _selectedCategory = 'All';
  String _userName = 'User';
  bool _isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventProvider>(context, listen: false).fetchEvents();
    });
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('UserId', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data();
          final nameVal = data['Name'] ?? data['name'];
          if (nameVal != null && nameVal.toString().trim().isNotEmpty) {
            setState(() {
              _userName = nameVal.toString().trim();
              _isLoadingName = false;
            });
            return;
          }
        }

        if (user.email != null) {
          final emailQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

          if (emailQuery.docs.isNotEmpty) {
            final data = emailQuery.docs.first.data();
            final nameVal = data['Name'] ?? data['name'];
            if (nameVal != null && nameVal.toString().trim().isNotEmpty) {
              setState(() {
                _userName = nameVal.toString().trim();
                _isLoadingName = false;
              });
              return;
            }
          }
        }

        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          setState(() {
            _userName = user.displayName!.trim();
            _isLoadingName = false;
          });
          return;
        }

        setState(() {
          _userName = user.email != null ? user.email!.split('@').first : 'User';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingName = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);

    var events = provider.events;
    if (_selectedCategory != 'All') {
      events = events.where((e) {
        final cat = e.category.toLowerCase();
        final selected = _selectedCategory.toLowerCase();
        return cat == selected || cat.contains(selected) || selected.contains(cat);
      }).toList();
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        color: const Color(0xFF007E7B),
        onRefresh: () => provider.refreshEvents(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  _buildSearchBar(context, events),
                  SizedBox(height: 24),
                  _buildAnimatedStatsRow(context, provider),
                  SizedBox(height: 24),
                  if (events.isNotEmpty) ...[
                    _buildSectionHeader('Featured Events'),
                    SizedBox(height: 12),
                    _buildFeaturedCarousel(context, events),
                    SizedBox(height: 28),
                  ],
                  _buildSectionHeader('Categories'),
                  _buildCategories(),
                  SizedBox(height: 28),
                  _buildSectionHeader(_selectedCategory == 'All' ? 'Explore Events' : '$_selectedCategory Events'),
                  SizedBox(height: 12),
                ],
              ),
            ),
            if (provider.isLoading && events.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.errorMessage != null && events.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 60, color: Theme.of(context).dividerColor),
                      const SizedBox(height: 12),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12),
                      TextButton(
                        onPressed: () => provider.fetchEvents(),
                        child: Text('Retry', style: TextStyle(color: Color(0xFF007E7B), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              )
            else if (events.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 60, color: Theme.of(context).dividerColor),
                        const SizedBox(height: 12),
                        Text(
                          'No events found in $_selectedCategory',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        return _buildEventCard(context, events[index]);
                      },
                      childCount: events.length,
                    ),
                  ),
                ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String avatarInitial = _isLoadingName || _userName.trim().isEmpty
        ? 'A'
        : _userName.trim()[0].toUpperCase();
    return SliverAppBar(
      automaticallyImplyLeading: false,
      pinned: true,
      stretch: true,
      expandedHeight: 154,
      toolbarHeight: 60,
      elevation: 0,
      backgroundColor: const Color(0xFF007E7B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF005E5C), Color(0xFF007E7B), Color(0xFF00A39E)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: _headerOrb(140, 0.08),
                ),
                Positioned(
                  right: 50,
                  top: 40,
                  child: _headerOrb(60, 0.06),
                ),
                Positioned(
                  left: -20,
                  bottom: -40,
                  child: _headerOrb(120, 0.05),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoadingName
                            ? 'WELCOME BACK'
                            : 'WELCOME BACK, ${_userName.toUpperCase()}',
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
                        'Attendee Dashboard',
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
                backgroundImage: user?.photoURL?.isNotEmpty == true
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: user?.photoURL?.isNotEmpty == true
                    ? null
                    : Text(
                        avatarInitial,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: StreamBuilder<List<NotificationModel>>(
            stream: NotificationService.getUserNotificationsStream(),
            builder: (context, snapshot) {
              final int unreadCount =
                  snapshot.data?.where((notification) => !notification.isRead).length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Material(
                    color: Colors.white.withOpacity(0.16),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 1,
                      top: 3,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF007E7B),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      pinned: true,
      toolbarHeight: 65.0,
      leading: Builder(
        builder: (ctx) {
          final user = FirebaseAuth.instance.currentUser;
          return IconButton(
            tooltip: 'Open Menu',
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF007E7B).withOpacity(0.4), width: 1.5),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF007E7B).withOpacity(0.1),
                backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                    ? Icon(Icons.person_rounded, size: 16, color: Color(0xFF007E7B))
                    : null,
              ),
            ),
          );
        },
      ),
      titleSpacing: 12,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            _isLoadingName ? 'Welcome 👋' : '$_userName 👋',
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: StreamBuilder<List<NotificationModel>>(
            stream: NotificationService.getUserNotificationsStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded, color: Theme.of(context).iconTheme.color),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
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
    );
  }

  Widget _headerOrb(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAnimatedStatsRow(BuildContext context, EventProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Near You',
              provider.events.length,
              Icons.near_me_rounded,
              const Color(0xFF007E7B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Registered',
              provider.registeredEvents.length,
              Icons.confirmation_number_rounded,
              const Color(0xFF5B5CE2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Favorites',
              provider.favoriteEvents.length,
              Icons.favorite_rounded,
              const Color(0xFFE84A72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 146),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 17),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: count),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: theme.textTheme.titleLarge?.color,
                  height: 1,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, List<EventModel> events) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Autocomplete<EventModel>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<EventModel>.empty();
          }
          return events.where((EventModel event) {
            return event.title.toLowerCase().contains(textEditingValue.text.toLowerCase()) || 
                   event.category.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        displayStringForOption: (EventModel option) => option.title,
        onSelected: (EventModel selection) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: selection.id)),
          );
        },
        fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
          return TextField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            decoration: InputDecoration(
              hintText: 'Search for events...',
              prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
              suffixIcon: IconButton(
                icon: Icon(Icons.filter_list_rounded, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                  );
                },
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          );
        },
        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<EventModel> onSelected, Iterable<EventModel> options) {
          final theme = Theme.of(context);
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final EventModel option = options.elementAt(index);
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          option.imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: theme.dividerColor, child: Icon(Icons.image, color: theme.iconTheme.color)),
                        ),
                      ),
                      title: Text(option.title, style: TextStyle(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.bold)),
                      subtitle: Text(option.category, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      onTap: () {
                        onSelected(option);
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  Widget _buildFeaturedCarousel(BuildContext context, List<EventModel> events) {
    final featuredList = events.take(5).toList();

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.88),
        itemCount: featuredList.length,
        itemBuilder: (context, index) {
          final event = featuredList[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF007E7B).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Theme.of(context).dividerColor),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007E7B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.category.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            event.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'All', 'icon': Icons.stars_rounded},
      {'name': 'Technology', 'icon': Icons.laptop_mac_rounded},
      {'name': 'Music', 'icon': Icons.music_note_rounded},
      {'name': 'Art', 'icon': Icons.palette_rounded},
      {'name': 'Business', 'icon': Icons.business_center_rounded},
      {'name': 'Sports', 'icon': Icons.sports_soccer_rounded},
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 14.0),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final catName = cat['name'] as String;
            final catIcon = cat['icon'] as IconData;
            final isSelected = _selectedCategory == catName;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Material(
                color: isSelected ? const Color(0xFF007E7B) : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(22),
                elevation: isSelected ? 4 : 0,
                shadowColor: const Color(0xFF007E7B).withOpacity(0.4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    setState(() {
                      _selectedCategory = catName;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          catIcon,
                          size: 18,
                          color: isSelected ? Colors.white : Theme.of(context).iconTheme.color?.withOpacity(0.5),
                        ),
                        SizedBox(width: 8),
                        Text(
                          catName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
    return PremiumEventCard(
      event: event,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailsScreen(eventId: event.id)),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return (month >= 1 && month <= 12) ? months[month - 1] : 'JAN';
  }
}
