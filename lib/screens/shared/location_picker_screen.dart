import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;


class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  late LatLng _currentCenter;
  bool _isLoadingAddress = false;
  bool _isFetchingGps = false;
  bool _isInitialLoading = true;
  String _address = "Move map to select location";

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<dynamic> _suggestions = [];
  bool _isLoadingSuggestions = false;
  Timer? _debounce;

  // Karachi bounding box - search results ko is area ke ird gird priority milegi
  static const String _karachiViewbox = '66.5,25.15,67.5,24.7';

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialLocation ?? const LatLng(24.8607, 67.0011);
    if (widget.initialLocation == null) {
      _getCurrentLocation();
    } else {
      _reverseGeocode(_currentCenter);
    }

    _searchFocusNode.addListener(() {
      // Turant rebuild karo taake ellipsis-overlay <-> TextField switch
      // sahi waqt par ho (focus milte / jaate hi).
      if (mounted) setState(() {});

      if (!_searchFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _suggestions = []);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // GPS - CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Please turn on device GPS/Location services');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Location permission denied');
        if (mounted) setState(() => _isInitialLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permission permanently denied. Enable it from app settings.');
      if (mounted) setState(() => _isInitialLoading = false);
      return;
    }

    try {
      setState(() => _isFetchingGps = true);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_currentCenter, 15.0);
        await _reverseGeocode(_currentCenter);
      }
    } catch (e) {
      _showSnack('Could not get location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingGps = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  // ============================================================
  // REVERSE GEOCODE (map center -> address)
  // ============================================================

  Future<void> _reverseGeocode(LatLng location) async {
    setState(() => _isLoadingAddress = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=${location.latitude}&lon=${location.longitude}'
        '&zoom=18&addressdetails=1&accept-language=en',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'EventEaseFlutterApp/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _address = data['display_name'] ?? "Unknown location";
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _address =
                "Location selected: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address =
              "Location selected: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  // ============================================================
  // DYNAMIC SEARCH SUGGESTIONS (Pakistan-only, Karachi-biased)
  // ============================================================

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    setState(() {}); // clear-icon show/hide ke liye rebuild

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(trimmed);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isLoadingSuggestions = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json'
        '&q=${Uri.encodeComponent(query)}'
        '&limit=6&addressdetails=1&accept-language=en'
        '&countrycodes=pk'
        '&viewbox=$_karachiViewbox&bounded=0',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'EventEaseFlutterApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (mounted) {
          setState(() => _suggestions = data);
        }
      } else if (mounted) {
        _showSnack('Suggestions failed (${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Suggestion error: check internet connection');
      }
    } finally {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  void _selectSuggestion(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final newLoc = LatLng(lat, lon);

    _mapController.move(newLoc, 15.0);
    _searchFocusNode.unfocus();

    setState(() {
      _currentCenter = newLoc;
      _address = place['display_name'] ?? '';
      _suggestions = [];
      _searchController.text = place['display_name'] ?? '';
    });
  }

  Future<void> _searchPlace(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _searchFocusNode.unfocus();
    setState(() {
      _isLoadingAddress = true;
      _suggestions = [];
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json'
        '&q=${Uri.encodeComponent(trimmed)}&limit=1&accept-language=en'
        '&countrycodes=pk'
        '&viewbox=$_karachiViewbox&bounded=0',
      );

      final response = await http
          .get(url, headers: {'User-Agent': 'EventEaseFlutterApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLoc = LatLng(lat, lon);

          _mapController.move(newLoc, 15.0);

          if (mounted) {
            setState(() {
              _currentCenter = newLoc;
              _address = data[0]['display_name'] ?? trimmed;
            });
          }
        } else {
          _showSnack('Not found. Try a nearby area or road name, then drag the pin.');
        }
      } else {
        _showSnack('Search failed (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error searching place: check internet connection');
    } finally {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topOffset = MediaQuery.of(context).padding.top + 12;

    return Scaffold(
      body: GestureDetector(
        onTap: () => _searchFocusNode.unfocus(),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentCenter,
                initialZoom: 14.0,
                onPositionChanged: (position, hasGesture) {
                  if (position.center != null) {
                    _currentCenter = position.center!;
                  }
                },
                onMapEvent: (event) {
                  if (event is MapEventMoveEnd) {
                    _reverseGeocode(_currentCenter);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.eventease.app',
                ),
              ],
            ),

            // Center Pin (Fixed in middle of screen)
            IgnorePointer(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: const Color(0xFF007E7B),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // Top row: Back button + Search bar — ek hi Row mein, hamesha aligned
            Positioned(
              top: topOffset,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button
                      Material(
                        color: Theme.of(context).cardColor,
                        shape: const CircleBorder(),
                        elevation: 3,
                        shadowColor: Colors.black26,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.titleLarge?.color, size: 22),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Search bar
                      Expanded(
                        child: Material(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 3,
                          shadowColor: Colors.black26,
                          child: SizedBox(
                            height: 48,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _searchPlace(_searchController.text),
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(Icons.search, color: Color(0xFF007E7B), size: 20),
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.centerLeft,
                                    children: [
                                      TextField(
                                        controller: _searchController,
                                        focusNode: _searchFocusNode,
                                        textInputAction: TextInputAction.search,
                                        onSubmitted: _searchPlace,
                                        onChanged: _onSearchChanged,
                                        textAlignVertical: TextAlignVertical.center,
                                        style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.titleLarge?.color),
                                        decoration: InputDecoration(
                                          isCollapsed: true,
                                          hintText: 'Search area, road, or landmark...',
                                          hintStyle: TextStyle(fontSize: 13.5, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                        ),
                                      ),
                                      // Jab field focused nahi aur text lamba ho, to ellipsis ke sath
                                      // dikhaen — takay hard-cut ki bajaye "..." nazar aaye.
                                      if (!_searchFocusNode.hasFocus && _searchController.text.isNotEmpty)
                                        Positioned.fill(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _searchFocusNode.requestFocus(),
                                            child: Container(
                                              color: Theme.of(context).cardColor,
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                _searchController.text,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 15, color: Theme.of(context).textTheme.titleLarge?.color),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_isLoadingSuggestions)
                                  const Padding(
                                    padding: EdgeInsets.all(13),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                else if (_searchController.text.isNotEmpty)
                                  InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () {
                                      _searchController.clear();
                                      setState(() => _suggestions = []);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(13),
                                      child: Icon(Icons.close, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4), size: 18),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Dynamic suggestions list — search bar ke bilkul neeche, back-button width ke barabar indent
                  if (_suggestions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 54),
                      child: Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxHeight: 260),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _suggestions.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, index) {
                            final place = _suggestions[index];
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.location_on_outlined, color: Color(0xFF007E7B)),
                              title: Text(
                                place['display_name'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                              ),
                              onTap: () => _selectSuggestion(place),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // GPS Button - bada, teal background, prominent
            Positioned(
              bottom: 230,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'gps_btn',
                backgroundColor: const Color(0xFF007E7B),
                foregroundColor: Colors.white,
                elevation: 4,
                onPressed: _isFetchingGps ? null : _getCurrentLocation,
                child: _isFetchingGps
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Icon(Icons.my_location_rounded, size: 26),
              ),
            ),

            // Bottom Sheet
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF007E7B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _isLoadingAddress
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF007E7B)),
                                )
                              : const Icon(Icons.location_city_rounded, color: Color(0xFF007E7B)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selected Location',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _address,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.titleLarge?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress
                            ? null
                            : () {
                                Navigator.pop(context, {
                                  'latLng': _currentCenter,
                                  'address': _address,
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007E7B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Confirm Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Initial loading overlay - GPS fetch / reverse geocode hone tak dikhta hai
            if (_isInitialLoading)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: _isInitialLoading ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(
                      child: CircularProgressIndicator(),
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