import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/auth_models.dart';
import '../models/map_models.dart';
import '../services/map_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final UserModel currentUser;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.currentUser,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MapService _mapService;
  final MapController _mapController = MapController();

  // Location & Map states
  LatLng _currentLocation = const LatLng(28.6129, 77.2295); // Default to Delhi Central
  bool _isLoadingLocation = true;
  String? _locationStatusMessage;

  // Live Location Check result
  LocationCheckResult? _locationCheckResult;
  bool _isCheckingLocation = false;

  // Offline Regions & Blackout Zones
  List<MapRegion> _regions = [];
  bool _isLoadingRegions = false;
  bool _showRegionsLayer = true;

  // Route Planning states
  RouteCalculationResult? _routeResult;
  bool _isCalculatingRoute = false;
  LatLng _origin = const LatLng(28.6129, 77.2295);
  LatLng _destination = const LatLng(28.6280, 77.2450);

  @override
  void initState() {
    super.initState();
    _mapService = MapService(storageService: widget.storageService);
    _initLocationFlow();
  }

  /// Flow: Ask Location Permission -> Get Location (Lat, Lon) -> Center Map -> Marker -> Check Location
  Future<void> _initLocationFlow() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatusMessage = 'Requesting location permission...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatusMessage = 'Location services disabled. Using default coordinate.';
        });
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationStatusMessage = 'Permission denied. Showing default area.';
        });
      } else {
        // Permission granted, fetch current position
        setState(() {
          _locationStatusMessage = 'Fetching current GPS position...';
        });

        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );

        final newLocation = LatLng(position.latitude, position.longitude);
        _currentLocation = newLocation;
        _origin = newLocation; // sync default route origin
        _mapController.move(newLocation, 15.0);
      }
    } catch (e) {
      // Fallback coordinate gracefully if emulator or hardware GPS unavailable
      _locationStatusMessage = 'GPS unavailable: using default coordinates';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        // Call check-location and fetch offline regions
        _checkLiveLocation(_currentLocation.latitude, _currentLocation.longitude);
        _fetchMapRegions();
      }
    }
  }

  /// Check live location against map regions & blackout zones
  Future<void> _checkLiveLocation(double lat, double lon) async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final result = await _mapService.checkLocation(lat: lat, lon: lon);
      if (mounted) {
        setState(() {
          _locationCheckResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check location status: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingLocation = false;
        });
      }
    }
  }

  /// Fetch offline map regions and their nested blackout zones
  Future<void> _fetchMapRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });

    try {
      final regions = await _mapService.getMapRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
        });
      }
    } catch (e) {
      // Quiet fail or log - map still works
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRegions = false;
        });
      }
    }
  }

  /// Calculate Route & Check Dead Zones
  Future<void> _calculateRoute({
    required LatLng origin,
    required LatLng dest,
  }) async {
    setState(() {
      _isCalculatingRoute = true;
    });

    try {
      final result = await _mapService.calculateRoute(
        originLat: origin.latitude,
        originLon: origin.longitude,
        destLat: dest.latitude,
        destLon: dest.longitude,
      );

      if (mounted) {
        setState(() {
          _routeResult = result;
          _origin = origin;
          _destination = dest;
        });

        // Fit bounds to route
        if (result.routeGeometry.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints(result.routeGeometry);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50),
            ),
          );
        }

        // Show bottom modal with route summary
        _showRouteSummaryModal(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Route calculation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingRoute = false;
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of your Zero Drift session?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 40),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.storageService.clearAuthSession();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LoginScreen(storageService: widget.storageService),
          ),
        );
      }
    }
  }

  void _openRoutePlannerModal() {
    final originLatCtrl = TextEditingController(text: _origin.latitude.toStringAsFixed(5));
    final originLonCtrl = TextEditingController(text: _origin.longitude.toStringAsFixed(5));
    final destLatCtrl = TextEditingController(text: _destination.latitude.toStringAsFixed(5));
    final destLonCtrl = TextEditingController(text: _destination.longitude.toStringAsFixed(5));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Calculate Route & Dead Zones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Detects route geometry and IMU blackout dead zones along the path.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Origin
              Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  const Text('Origin (Current / Custom)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        originLatCtrl.text = _currentLocation.latitude.toStringAsFixed(5);
                        originLonCtrl.text = _currentLocation.longitude.toStringAsFixed(5);
                      });
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Use Current', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: originLatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Origin Lat',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: originLonCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Origin Lon',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Destination
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 6),
                  const Text('Destination',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        originLatCtrl.text = '28.6129';
                        originLonCtrl.text = '77.2295';
                        destLatCtrl.text = '28.6280';
                        destLonCtrl.text = '77.2450';
                      });
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Preset Test Route', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: destLatCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Dest Lat',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: destLonCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Dest Lon',
                        isDense: true,
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final oLat = double.tryParse(originLatCtrl.text);
                    final oLon = double.tryParse(originLonCtrl.text);
                    final dLat = double.tryParse(destLatCtrl.text);
                    final dLon = double.tryParse(destLonCtrl.text);

                    if (oLat != null && oLon != null && dLat != null && dLon != null) {
                      Navigator.of(ctx).pop();
                      _calculateRoute(
                        origin: LatLng(oLat, oLon),
                        dest: LatLng(dLat, dLon),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid coordinates')),
                      );
                    }
                  },
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text(
                    'Calculate Route',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRouteSummaryModal(RouteCalculationResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.route_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Route Calculated',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Distance & Duration cards
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DISTANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          result.totalDistanceMeters >= 1000
                              ? '${(result.totalDistanceMeters / 1000).toStringAsFixed(2)} km'
                              : '${result.totalDistanceMeters.toStringAsFixed(0)} m',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DURATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            )),
                        const SizedBox(height: 4),
                        Text(
                          result.totalDurationSeconds >= 60
                              ? '${(result.totalDurationSeconds / 60).toStringAsFixed(1)} min'
                              : '${result.totalDurationSeconds.toStringAsFixed(0)} sec',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Blackout dead zones banner
            if (result.hasBlackoutZones && result.intersectingBlackoutZones.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${result.intersectingBlackoutZones.length} Dead Zone Intersections Detected',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.intersectingBlackoutZones.map((zone) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${zone.name} (${zone.zoneType}, ~${zone.approxLengthMeters.toStringAsFixed(0)}m)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Clear Route: No blackout dead zones detected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build polygon overlays from regions and intersecting route blackout zones
    final polygons = <Polygon>[];

    // Intersecting blackout zones from calculated route
    if (_routeResult != null) {
      for (final zone in _routeResult!.intersectingBlackoutZones) {
        if (zone.geometry.length >= 3) {
          polygons.add(
            Polygon(
              points: zone.geometry,
              color: AppColors.error.withValues(alpha: 0.35),
              borderColor: AppColors.error,
              borderStrokeWidth: 2.5,
              isFilled: true,
            ),
          );
        }
      }
    }

    // Offline regions & nested blackout zones
    if (_showRegionsLayer) {
      for (final region in _regions) {
        if (region.bounds.length >= 3) {
          polygons.add(
            Polygon(
              points: region.bounds,
              color: AppColors.primary.withValues(alpha: 0.1),
              borderColor: AppColors.primary.withValues(alpha: 0.6),
              borderStrokeWidth: 1.5,
              isFilled: true,
            ),
          );
        }
        for (final zone in region.blackoutZones) {
          if (zone.geometry.length >= 3) {
            polygons.add(
              Polygon(
                points: zone.geometry,
                color: AppColors.warning.withValues(alpha: 0.3),
                borderColor: AppColors.warning,
                borderStrokeWidth: 2.0,
                isFilled: true,
              ),
            );
          }
        }
      }
    }

    // Build polylines for calculated route
    final polylines = <Polyline>[];
    if (_routeResult != null && _routeResult!.routeGeometry.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _routeResult!.routeGeometry,
          color: AppColors.primary,
          strokeWidth: 4.5,
        ),
      );
    }

    // Build markers
    final markers = <Marker>[
      // User current location marker 📍
      Marker(
        point: _currentLocation,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    // Origin marker if route is active
    if (_routeResult != null) {
      markers.add(
        Marker(
          point: _origin,
          width: 36,
          height: 36,
          child: const Icon(Icons.trip_origin_rounded, color: AppColors.success, size: 28),
        ),
      );

      // Destination marker
      markers.add(
        Marker(
          point: _destination,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on_rounded, color: AppColors.error, size: 36),
        ),
      );

      // Entry & Exit points for blackout dead zones
      for (final zone in _routeResult!.intersectingBlackoutZones) {
        if (zone.entryPoint != null) {
          markers.add(
            Marker(
              point: zone.entryPoint!,
              width: 28,
              height: 28,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.warning,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
              ),
            ),
          );
        }
        if (zone.exitPoint != null) {
          markers.add(
            Marker(
              point: zone.exitPoint!,
              width: 28,
              height: 28,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, size: 16, color: Colors.white),
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        title: Row(
          children: [
            const Text(
              'zerodrift',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'OSM MAPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 14.5,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.zerodrift.mapping_showcase',
              ),
              if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),

          // Floating Top Status Card: Location & Blackout Zone
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.my_location_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentLocation.latitude.toStringAsFixed(4)}°, ${_currentLocation.longitude.toStringAsFixed(4)}°',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_isCheckingLocation || _isLoadingLocation)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        InkWell(
                          onTap: () => _checkLiveLocation(
                            _currentLocation.latitude,
                            _currentLocation.longitude,
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 2),
                              Text(
                                'Check',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Location check result display
                  if (_locationCheckResult != null) ...[
                    Row(
                      children: [
                        // Region tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _locationCheckResult!.isInRegion
                                ? AppColors.successLight
                                : AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _locationCheckResult!.isInRegion
                                    ? Icons.location_city_rounded
                                    : Icons.public_off_rounded,
                                size: 12,
                                color: _locationCheckResult!.isInRegion
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _locationCheckResult!.isInRegion
                                    ? (_locationCheckResult!.regionName ?? 'Inside Map Region')
                                    : 'Outside Defined Region',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _locationCheckResult!.isInRegion
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Blackout dead zone tag
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _locationCheckResult!.inBlackoutZone
                                  ? AppColors.errorLight
                                  : AppColors.successLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _locationCheckResult!.inBlackoutZone
                                      ? Icons.signal_cellular_connected_no_internet_4_bar_rounded
                                      : Icons.satellite_alt_rounded,
                                  size: 12,
                                  color: _locationCheckResult!.inBlackoutZone
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _locationCheckResult!.inBlackoutZone
                                        ? (_locationCheckResult!.currentBlackoutZone?.name ??
                                            'Dead Zone Alert')
                                        : 'GNSS Active',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _locationCheckResult!.inBlackoutZone
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _locationStatusMessage ?? 'Ready',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Floating Action Buttons (Right side)
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Toggle Regions overlay
                FloatingActionButton.small(
                  heroTag: 'toggle_regions',
                  backgroundColor: AppColors.surface,
                  foregroundColor:
                      _showRegionsLayer ? AppColors.primary : AppColors.textSecondary,
                  tooltip: 'Toggle Offline Regions',
                  onPressed: () {
                    setState(() {
                      _showRegionsLayer = !_showRegionsLayer;
                    });
                  },
                  child: const Icon(Icons.layers_rounded),
                ),
                const SizedBox(height: 10),

                // Recenter to user position
                FloatingActionButton.small(
                  heroTag: 'recenter_gps',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  tooltip: 'Recenter GPS',
                  onPressed: () {
                    _mapController.move(_currentLocation, 15.0);
                  },
                  child: const Icon(Icons.gps_fixed_rounded),
                ),
                const SizedBox(height: 10),

                // Route Planner Button
                FloatingActionButton.extended(
                  heroTag: 'route_planner',
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  icon: _isCalculatingRoute
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.alt_route_rounded),
                  label: const Text(
                    'Route & Blackouts',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _openRoutePlannerModal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
