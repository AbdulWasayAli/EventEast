import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../models/event_model.dart';

class EventMapScreen extends StatefulWidget {
  final EventModel event;

  const EventMapScreen({super.key, required this.event});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;
  bool _isLoadingRoute = false;

  List<LatLng> _fullRoutePoints = [];

  
  List<LatLng> _displayRoutePoints = [];

  
  bool _isNavigating = false;

  
  double _heading = 0;

 
  static const double _arrivalThresholdMeters = 30;

  late final LatLng _eventLocation;

  @override
  void initState() {
    super.initState();
   
    _eventLocation = LatLng(
      widget.event.latitude ?? 24.8607,
      widget.event.longitude ?? 67.0011,
    );
    _checkPermissionsAndTrack();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissionsAndTrack() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled. Please enable them in settings.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // Pehli dafa current location lay lo
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        
        _fetchRoute();
      }
    } catch (e) {
      debugPrint("Error getting initial location: $e");
    }

 
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1,
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        if (!mounted) return;

        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
         
          if (position.heading >= 0) {
            _heading = position.heading;
          }
        });

        // Agar actively track kar raha hai toh map ko user ke sath move karo
        if (_isTracking) {
          _mapController.move(_userLocation!, _mapController.camera.zoom);
        }

        if (_isNavigating) {
          _updateNavigationProgress();
        }
      },
      onError: (e) {
        debugPrint('Position stream error: $e');
      },
    );
  }

 
  Future<void> _fetchRoute() async {
    if (_userLocation == null) return;

    setState(() => _isLoadingRoute = true);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${_userLocation!.longitude},${_userLocation!.latitude};'
        '${_eventLocation.longitude},${_eventLocation.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();

          if (mounted) {
            setState(() {
              _fullRoutePoints = points;
              _displayRoutePoints = points;
            });
          }
        }
      } else {
        debugPrint('OSRM error: ${response.statusCode}');
        _fallbackToStraightLine();
      }
    } catch (e) {
      debugPrint('Route fetch failed: $e');
      _fallbackToStraightLine();
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  
  void _fallbackToStraightLine() {
    if (_userLocation == null) return;
    if (mounted) {
      setState(() {
        _fullRoutePoints = [_userLocation!, _eventLocation];
        _displayRoutePoints = [_userLocation!, _eventLocation];
      });
    }
  }


  Future<void> _startNavigation() async {
    if (_userLocation == null) {
      _showError('Your location has not been found yet, please wait a moment.');
      return;
    }

    // Agar route abhi tak nahi mila to pehle fetch kar lein
    if (_fullRoutePoints.isEmpty) {
      await _fetchRoute();
    }

    if (!mounted) return;

    setState(() {
      _isNavigating = true;
      _isTracking = true;
    });

    // Navigation start hote hi camera ko zoom karke user pe center karo
    _mapController.move(_userLocation!, 17.0);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigation started — keep going straight ahead.'),
        backgroundColor: Color(0xFF007E7B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
      _isTracking = false;
      
      _displayRoutePoints = _fullRoutePoints;
    });
  }

  void _updateNavigationProgress() {
    if (_fullRoutePoints.isEmpty || _userLocation == null) return;

    int nearestIndex = 0;
    double nearestDist = double.infinity;

    for (int i = 0; i < _fullRoutePoints.length; i++) {
      final d = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        _fullRoutePoints[i].latitude,
        _fullRoutePoints[i].longitude,
      );
      if (d < nearestDist) {
        nearestDist = d;
        nearestIndex = i;
      }
    }

    setState(() {
      _displayRoutePoints = [_userLocation!, ..._fullRoutePoints.sublist(nearestIndex)];
    });

    // Arrival check — agar destination ke bohot qareeb pohanch gaye
    final double distanceToDestination = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _eventLocation.latitude,
      _eventLocation.longitude,
    );

    if (distanceToDestination <= _arrivalThresholdMeters) {
      _stopNavigation();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 You have arrived at your destination!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      setState(() => _isTracking = true);
      _mapController.move(_userLocation!, 15.0);
    } else {
      _checkPermissionsAndTrack(); // Wapas try karo agar permission nahi thi
    }
  }

  void _centerOnEvent() {
    setState(() => _isTracking = false);
    _mapController.move(_eventLocation, 15.0);
  }

  Future<void> _openInGoogleMaps() async {
    final lat = _eventLocation.latitude;
    final lng = _eventLocation.longitude;

    // google.navigation url se direct navigation start ho jati hai
    final Uri googleMapsAppUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri googleMapsWebUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    try {
      if (await canLaunchUrl(googleMapsAppUrl)) {
        await launchUrl(googleMapsAppUrl);
      } else {
        await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showError('Could not open Google Maps');
    }
  }

  String _calculateDistance() {
    if (_userLocation == null) return 'Calculating...';

    final double distanceInMeters = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      _eventLocation.latitude,
      _eventLocation.longitude,
    );

    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km away';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Device ke bottom safe area (gesture bar / nav bar) ka extra padding —
    // isse card aur buttons screen ke bilkul niche chipakte nahi.
    final double bottomSafePadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _eventLocation,
              initialZoom: 14.0,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture && _isTracking) {
                 
                  setState(() => _isTracking = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.eventease.app',
              ),
            
              if (_displayRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _displayRoutePoints,
                      color: const Color(0xFF007E7B),
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Event Marker — standard teardrop-shaped map pin
                  Marker(
                    point: _eventLocation,
                    width: 44,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF007E7B),
                      size: 52,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 44,
                      height: 44,
                      child: _isNavigating
                          ? Transform.rotate(
                              angle: _heading * (math.pi / 180),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF007E7B),
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.blueAccent,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),

          // Route load ho rahi hai to chota loading indicator
          if (_isLoadingRoute)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading route...', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Navigation mode ka top banner — "End Route" button ke sath
          if (_isNavigating)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007E7B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.navigation, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _calculateDistance(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _stopNavigation,
                      style: TextButton.styleFrom(backgroundColor: Colors.white24),
                      child: const Text('End', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),

         
          Positioned(
            right: 16,
            bottom: (_isNavigating ? 24 : 210) + bottomSafePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            
                if (_isNavigating) ...[
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'btnEvent',
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: _centerOnEvent,
                        child: const Icon(Icons.location_on, color: Color(0xFF007E7B)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                          ],
                        ),
                        child: const Text(
                          'Event',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
             
                Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'btnGPS',
                      backgroundColor: const Color(0xFF007E7B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: _centerOnUser,
                      child: const Icon(Icons.gps_fixed, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
                        ],
                      ),
                      child: const Text(
                        'My Location',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          
          if (!_isNavigating)
            Positioned(
              bottom: 24 + bottomSafePadding,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                          child: const Icon(Icons.location_on_rounded, color: Color(0xFF007E7B)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.event.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.event.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _calculateDistance(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                   
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _startNavigation,
                              icon: const Icon(Icons.navigation_rounded),
                              label: const Text(
                                'Start Route',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF007E7B),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                       
                        Column(
                          children: [
                            SizedBox(
                              height: 54,
                              width: 54,
                              child: OutlinedButton(
                                onPressed: _openInGoogleMaps,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF007E7B),
                                  side: const BorderSide(color: Color(0xFF007E7B)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Icon(Icons.map_outlined),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Google Maps',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}