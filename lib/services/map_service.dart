import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/map_models.dart';
import 'storage_service.dart';

class MapService {
  static const String baseUrl = 'https://sih-backend-uy9n.onrender.com/api/v1/maps';
  static const Duration timeoutDuration = Duration(seconds: 45);

  final http.Client _client;
  final StorageService _storageService;

  MapService({
    required StorageService storageService,
    http.Client? client,
  })  : _storageService = storageService,
        _client = client ?? http.Client();

  Map<String, String> _getHeaders() {
    final token = _storageService.getAccessToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GET /api/v1/maps/regions/
  /// Returns all offline map regions and their nested blackout zones.
  Future<List<MapRegion>> getMapRegions() async {
    final uri = Uri.parse('$baseUrl/regions/');

    try {
      final response = await _client
          .get(uri, headers: _getHeaders())
          .timeout(timeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((item) => MapRegion.fromJson(item))
              .toList();
        } else if (decoded is Map<String, dynamic>) {
          final results = decoded['results'] ?? decoded['regions'] ?? decoded['data'];
          if (results is List) {
            return results
                .whereType<Map<String, dynamic>>()
                .map((item) => MapRegion.fromJson(item))
                .toList();
          }
        }
        return [];
      } else {
        throw HttpException(
          'Failed to load regions (Status ${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Connection timed out while fetching map regions.');
    } on SocketException {
      throw Exception('No network connection available.');
    } catch (e) {
      throw Exception('Error loading map regions: $e');
    }
  }

  /// GET /api/v1/maps/regions/check-location/?lat=lat&lon=lon
  /// Checks if a single coordinate point is currently inside a map region or a blackout zone.
  Future<LocationCheckResult> checkLocation({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$baseUrl/regions/check-location/?lat=$lat&lon=$lon');

    try {
      final response = await _client
          .get(uri, headers: _getHeaders())
          .timeout(timeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return LocationCheckResult.fromJson(decoded);
        }
        throw const FormatException('Invalid response format for check-location');
      } else {
        throw HttpException(
          'Failed to check location (Status ${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Connection timed out while checking location.');
    } on SocketException {
      throw Exception('No network connection available.');
    } catch (e) {
      throw Exception('Error checking location: $e');
    }
  }

  /// POST /api/v1/maps/regions/calculate-route/
  /// Fetches route geometry and checks for dead zone intersections with known IMU blackout regions.
  Future<RouteCalculationResult> calculateRoute({
    required double originLat,
    required double originLon,
    required double destLat,
    required double destLon,
  }) async {
    final uri = Uri.parse('$baseUrl/regions/calculate-route/');
    final body = jsonEncode({
      'origin_lat': originLat,
      'origin_lon': originLon,
      'dest_lat': destLat,
      'dest_lon': destLon,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: _getHeaders(),
            body: body,
          )
          .timeout(timeoutDuration);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return RouteCalculationResult.fromJson(decoded);
        }
        throw const FormatException('Invalid route calculation response structure');
      } else {
        throw HttpException(
          'Failed to calculate route (Status ${response.statusCode}): ${response.body}',
        );
      }
    } on TimeoutException {
      throw Exception('Connection timed out while calculating route.');
    } on SocketException {
      throw Exception('No network connection available.');
    } catch (e) {
      throw Exception('Error calculating route: $e');
    }
  }
}
