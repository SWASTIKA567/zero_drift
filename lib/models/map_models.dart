import 'package:latlong2/latlong.dart';

/// Response model for check-location endpoint:
/// GET /api/v1/maps/regions/check-location/?lat=lat&lon=lon
class LocationCheckResult {
  final double latitude;
  final double longitude;
  final bool isInRegion;
  final String? regionName;
  final bool inBlackoutZone;
  final CurrentBlackoutZone? currentBlackoutZone;

  LocationCheckResult({
    required this.latitude,
    required this.longitude,
    required this.isInRegion,
    this.regionName,
    required this.inBlackoutZone,
    this.currentBlackoutZone,
  });

  factory LocationCheckResult.fromJson(Map<String, dynamic> json) {
    return LocationCheckResult(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isInRegion: json['is_in_region'] == true,
      regionName: json['region_name'] as String?,
      inBlackoutZone: json['in_blackout_zone'] == true,
      currentBlackoutZone: json['current_blackout_zone'] != null
          ? CurrentBlackoutZone.fromJson(
              json['current_blackout_zone'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'is_in_region': isInRegion,
        'region_name': regionName,
        'in_blackout_zone': inBlackoutZone,
        'current_blackout_zone': currentBlackoutZone?.toJson(),
      };
}

class CurrentBlackoutZone {
  final int id;
  final String name;
  final String zoneType;
  final double approxLengthMeters;

  CurrentBlackoutZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.approxLengthMeters,
  });

  factory CurrentBlackoutZone.fromJson(Map<String, dynamic> json) {
    return CurrentBlackoutZone(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Unknown Zone',
      zoneType: json['zone_type'] as String? ?? 'tunnel',
      approxLengthMeters: (json['approx_length_meters'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'zone_type': zoneType,
        'approx_length_meters': approxLengthMeters,
      };
}

/// Request model for route calculation
class RouteRequest {
  final double originLat;
  final double originLon;
  final double destLat;
  final double destLon;

  RouteRequest({
    required this.originLat,
    required this.originLon,
    required this.destLat,
    required this.destLon,
  });

  Map<String, dynamic> toJson() => {
        'origin_lat': originLat,
        'origin_lon': originLon,
        'dest_lat': destLat,
        'dest_lon': destLon,
      };
}

/// Response model for route calculation:
/// POST /api/v1/maps/regions/calculate-route/
class RouteCalculationResult {
  final List<LatLng> routeGeometry;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final bool hasBlackoutZones;
  final List<IntersectingBlackoutZone> intersectingBlackoutZones;

  RouteCalculationResult({
    required this.routeGeometry,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.hasBlackoutZones,
    required this.intersectingBlackoutZones,
  });

  factory RouteCalculationResult.fromJson(Map<String, dynamic> json) {
    List<LatLng> coords = [];
    if (json['route_geometry'] is List) {
      for (final item in json['route_geometry'] as List) {
        if (item is List && item.length >= 2) {
          final lat = (item[0] as num?)?.toDouble();
          final lon = (item[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            coords.add(LatLng(lat, lon));
          }
        }
      }
    }

    List<IntersectingBlackoutZone> zones = [];
    if (json['intersecting_blackout_zones'] is List) {
      zones = (json['intersecting_blackout_zones'] as List)
          .map((z) => IntersectingBlackoutZone.fromJson(z as Map<String, dynamic>))
          .toList();
    }

    return RouteCalculationResult(
      routeGeometry: coords,
      totalDistanceMeters: (json['total_distance_meters'] as num?)?.toDouble() ?? 0.0,
      totalDurationSeconds: (json['total_duration_seconds'] as num?)?.toDouble() ?? 0.0,
      hasBlackoutZones: json['has_blackout_zones'] == true,
      intersectingBlackoutZones: zones,
    );
  }
}

class IntersectingBlackoutZone {
  final int id;
  final String name;
  final String zoneType;
  final double approxLengthMeters;
  final List<LatLng> geometry;
  final LatLng? entryPoint;
  final LatLng? exitPoint;

  IntersectingBlackoutZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.approxLengthMeters,
    required this.geometry,
    this.entryPoint,
    this.exitPoint,
  });

  factory IntersectingBlackoutZone.fromJson(Map<String, dynamic> json) {
    List<LatLng> polygonCoords = [];
    if (json['geometry'] is List) {
      for (final pt in json['geometry'] as List) {
        if (pt is List && pt.length >= 2) {
          final lat = (pt[0] as num?)?.toDouble();
          final lon = (pt[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            polygonCoords.add(LatLng(lat, lon));
          }
        }
      }
    }

    LatLng? parsePt(dynamic raw) {
      if (raw is List && raw.length >= 2) {
        final lat = (raw[0] as num?)?.toDouble();
        final lon = (raw[1] as num?)?.toDouble();
        if (lat != null && lon != null) return LatLng(lat, lon);
      }
      return null;
    }

    return IntersectingBlackoutZone(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] as String? ?? 'Dead Zone',
      zoneType: json['zone_type'] as String? ?? 'tunnel',
      approxLengthMeters: (json['approx_length_meters'] as num?)?.toDouble() ?? 0.0,
      geometry: polygonCoords,
      entryPoint: parsePt(json['entry_point']),
      exitPoint: parsePt(json['exit_point']),
    );
  }
}

/// Offline map region model:
/// GET /api/v1/maps/regions/
class MapRegion {
  final dynamic id;
  final String name;
  final String? description;
  final List<LatLng> bounds;
  final List<RegionBlackoutZone> blackoutZones;

  MapRegion({
    required this.id,
    required this.name,
    this.description,
    required this.bounds,
    required this.blackoutZones,
  });

  factory MapRegion.fromJson(Map<String, dynamic> json) {
    List<LatLng> parsedBounds = [];
    final rawBounds = json['bounds'] ?? json['geometry'] ?? json['coordinates'];
    if (rawBounds is List) {
      for (final pt in rawBounds) {
        if (pt is List && pt.length >= 2) {
          final lat = (pt[0] as num?)?.toDouble();
          final lon = (pt[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            parsedBounds.add(LatLng(lat, lon));
          }
        }
      }
    }

    List<RegionBlackoutZone> zones = [];
    final rawZones = json['blackout_zones'] ?? json['zones'] ?? json['nested_blackout_zones'];
    if (rawZones is List) {
      zones = rawZones
          .whereType<Map<String, dynamic>>()
          .map((z) => RegionBlackoutZone.fromJson(z))
          .toList();
    }

    return MapRegion(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? 'Unnamed Region',
      description: json['description'] as String?,
      bounds: parsedBounds,
      blackoutZones: zones,
    );
  }
}

class RegionBlackoutZone {
  final dynamic id;
  final String name;
  final String zoneType;
  final double approxLengthMeters;
  final List<LatLng> geometry;

  RegionBlackoutZone({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.approxLengthMeters,
    required this.geometry,
  });

  factory RegionBlackoutZone.fromJson(Map<String, dynamic> json) {
    List<LatLng> polygonCoords = [];
    final rawGeom = json['geometry'] ?? json['coordinates'] ?? json['polygon'];
    if (rawGeom is List) {
      for (final pt in rawGeom) {
        if (pt is List && pt.length >= 2) {
          final lat = (pt[0] as num?)?.toDouble();
          final lon = (pt[1] as num?)?.toDouble();
          if (lat != null && lon != null) {
            polygonCoords.add(LatLng(lat, lon));
          }
        }
      }
    }

    return RegionBlackoutZone(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? 'Dead Zone',
      zoneType: json['zone_type'] as String? ?? 'tunnel',
      approxLengthMeters: (json['approx_length_meters'] as num?)?.toDouble() ?? 0.0,
      geometry: polygonCoords,
    );
  }
}
