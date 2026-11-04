import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../widgets/premium_ui.dart';
import '../../providers/event_provider.dart';
import 'event_details_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'All';
  DateTime? _selectedDate;
  bool _onlyAvailable = false;
  double _maxPrice = 500.0;
  final List<String> _categories = [
    'All',
    'Technology',
    'Education',
    'Sports',
    'Music',
    'Business',
    'Workshop',
    'Conference',
    'Community'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Clear all filters method (SRS Requirement)
  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _locationController.clear();
      _selectedCategory = 'All';
      _selectedDate = null;
      _onlyAvailable = false;
      _maxPrice = 500.0;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Color(0xFF007E7B),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFFF8FAFC),
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF007E7B),
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF1E293B),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EventProvider>(context);

    List<EventModel> filteredEvents = provider.events;

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filteredEvents = filteredEvents.where((event) {
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.location.toLowerCase().contains(query) ||
            event.organizer.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      filteredEvents = filteredEvents.where((event) {
        final cat = event.category.trim().toLowerCase();
        final selected = _selectedCategory.trim().toLowerCase();
        return cat == selected || cat.contains(selected) || selected.contains(cat);
      }).toList();
    }

    // 4. Date Filter (SRS 1.6.4 Requirement)
    if (_selectedDate != null) {
      filteredEvents = filteredEvents.where((event) {
        return event.date.year == _selectedDate!.year &&
            event.date.month == _selectedDate!.month &&
            event.date.day == _selectedDate!.day;
      }).toList();
    }

    final locationQuery = _locationController.text.trim().toLowerCase();
    if (locationQuery.isNotEmpty) {
      filteredEvents = filteredEvents.where((event) {
        return event.location.toLowerCase().contains(locationQuery);
      }).toList();
    }

    if (_onlyAvailable) {
      filteredEvents = filteredEvents.where((event) {
        return event.availableSeats > 0;
      }).toList();
    }

    filteredEvents = filteredEvents.where((event) {
      return event.price <= _maxPrice;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PremiumScreenAppBar(
        eyebrow: 'Explore smarter',
        title: 'Search events',
        actions: [
          // Clear All Filters Button (SRS Requirement)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search events, title, organizer...',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4), fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).dividerColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: _locationController,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Filter by location / venue...',
                    hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4), fontSize: 14),
                    prefixIcon: Icon(Icons.location_on_outlined, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                    suffixIcon: _locationController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).dividerColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Category',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.titleLarge?.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            selectedColor: const Color(0xFF007E7B),
                            backgroundColor: Theme.of(context).dividerColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF007E7B)),
                        label: Text(
                          _selectedDate == null
                              ? 'Select Date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                                : Theme.of(context).textTheme.titleLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () => setState(() => _selectedDate = null),
                        tooltip: 'Clear Date',
                      ),
                    ],
                    SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          'Available Only',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.titleLarge?.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Switch(
                          value: _onlyAvailable,
                          activeColor: const Color(0xFF007E7B),
                          onChanged: (val) {
                            setState(() {
                              _onlyAvailable = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 60, color: Theme.of(context).dividerColor),
                  SizedBox(height: 12),
                  Text(
                    'No events match your filters',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredEvents.length,
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventDetailsScreen(eventId: event.id),
                        ),
                      );
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Theme.of(context).dividerColor,
                          child: Icon(Icons.broken_image, size: 20, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    title: Text(
                      event.title,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          '${event.date.day}/${event.date.month}/${event.date.year} • ${event.location}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF007E7B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.category,
                                style: TextStyle(
                                  color: Color(0xFF007E7B),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (event.availableSeats <= 0) ...[
                              SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FULL',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: Text(
                      event.price == 0
                          ? 'FREE'
                          : 'Rs. ${event.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
