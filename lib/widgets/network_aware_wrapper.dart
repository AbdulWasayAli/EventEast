import 'dart:async';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// A global wrapper widget that listens for real-time network connectivity changes
/// and displays a modern, glassmorphic floating capsule / pill at the top of the screen.
class NetworkAwareWrapper extends StatefulWidget {
  final Widget child;

  const NetworkAwareWrapper({super.key, required this.child});

  @override
  State<NetworkAwareWrapper> createState() => _NetworkAwareWrapperState();
}

class _NetworkAwareWrapperState extends State<NetworkAwareWrapper>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _subscription;
  bool _isOffline = false;
  bool _showBackOnline = false;
  bool _manuallyDismissed = false;
  Timer? _backOnlineDismissTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();

    // In connectivity_plus: ^6.0.0+, onConnectivityChanged yields List<ConnectivityResult>
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      _handleConnectivityResults(results);
    });
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityResults(results, isInitial: true);
    } catch (_) {
      // Gracefully handle any platform exception
    }
  }

  void _handleConnectivityResults(
    List<ConnectivityResult> results, {
    bool isInitial = false,
  }) {
    // Offline if result list has none, or is completely empty
    final bool offline =
        results.contains(ConnectivityResult.none) || results.isEmpty;

    if (!mounted) return;

    if (_isOffline && !offline) {
      // Transition from Offline -> Online
      _backOnlineDismissTimer?.cancel();
      setState(() {
        _isOffline = false;
        _showBackOnline = true;
        _manuallyDismissed = false;
      });

      // Auto dismiss "Back Online" badge after 2.5 seconds
      _backOnlineDismissTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          setState(() {
            _showBackOnline = false;
          });
        }
      });
    } else if (offline != _isOffline) {
      // Transition from Online -> Offline or initial state setup
      _backOnlineDismissTimer?.cancel();
      setState(() {
        _isOffline = offline;
        _showBackOnline = false;
        // If offline state changed, reset manual dismissal so user gets notified
        _manuallyDismissed = false;
      });
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _backOnlineDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldShow = (_isOffline || _showBackOnline) && !_manuallyDismissed;

    return Stack(
      children: [
        // The underlying application UI (all pages & routes)
        widget.child,

        // Top Floating Modern Capsule Popup
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSlide(
            offset: shouldShow ? Offset.zero : const Offset(0, -1.3),
            duration: const Duration(milliseconds: 400),
            curve: shouldShow ? Curves.easeOutBack : Curves.easeInOutCubic,
            child: AnimatedOpacity(
              opacity: shouldShow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Center(
                    child: _buildFloatingIsland(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingIsland(BuildContext context) {
    final bool isOffline = _isOffline;
    final Color accentColor =
        isOffline ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final Color badgeGlow =
        isOffline ? const Color(0xFFDC2626) : const Color(0xFF059669);

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        // Swipe up to dismiss
        if (details.primaryDelta != null && details.primaryDelta! < -4) {
          setState(() => _manuallyDismissed = true);
        }
      },
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(89),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: accentColor.withAlpha(64),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xE00F172A),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: accentColor.withAlpha(89),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Status Icon Avatar
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: badgeGlow.withAlpha(46),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withAlpha(102),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          isOffline
                              ? Icons.wifi_off_rounded
                              : Icons.wifi_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title and subtitle
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isOffline
                                ? 'No Internet Connection'
                                : 'Back Online',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            isOffline
                                ? 'Please check your Wi-Fi or mobile data'
                                : 'Connection restored successfully',
                            style: TextStyle(
                              color: Colors.white.withAlpha(184),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quick close button
                    GestureDetector(
                      onTap: () {
                        setState(() => _manuallyDismissed = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white.withAlpha(153),
                          size: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
