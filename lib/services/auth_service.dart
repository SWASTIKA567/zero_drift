import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';

class AuthService {
  static const String baseUrl = 'https://sih-backend-uy9n.onrender.com/api/auth';
  static const Duration timeoutDuration = Duration(seconds: 45);

  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  /// Logs in using either username or email as the `login` parameter
  Future<AuthResponse> login({
    required String login,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/login/');
    final body = jsonEncode({
      'login': login.trim(),
      'password': password,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeoutDuration);

      return _processResponse(response);
    } on TimeoutException {
      return AuthResponse.failure(
        'Connection timed out. The server may be waking up from sleep. Please try again in a few moments.',
      );
    } on SocketException {
      return AuthResponse.failure(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } catch (e) {
      return AuthResponse.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Signs up a new user with username, email, and password
  Future<AuthResponse> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/signup/');
    final body = jsonEncode({
      'username': username.trim(),
      'email': email.trim(),
      'password': password,
    });

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeoutDuration);

      return _processResponse(response);
    } on TimeoutException {
      return AuthResponse.failure(
        'Connection timed out. The server may be waking up from sleep. Please try again in a few moments.',
      );
    } on SocketException {
      return AuthResponse.failure(
        'Unable to connect to the server. Please check your internet connection.',
      );
    } catch (e) {
      return AuthResponse.failure(
        'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  AuthResponse _processResponse(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return AuthResponse.fromApiResponse(decoded);
        }
        return AuthResponse.success();
      }

      // Handle failure responses (e.g. 400 Bad Request)
      if (decoded is Map<String, dynamic>) {
        final Map<String, List<String>> fieldErrors = {};
        final List<String> generalMessages = [];

        decoded.forEach((key, value) {
          if (value is List) {
            final list = value.map((e) => e.toString()).toList();
            fieldErrors[key] = list;
            generalMessages.addAll(list);
          } else if (value is String) {
            fieldErrors[key] = [value];
            generalMessages.add(value);
          }
        });

        final primaryMessage = generalMessages.isNotEmpty
            ? generalMessages.first
            : 'Authentication failed (Status ${response.statusCode})';

        return AuthResponse.failure(primaryMessage, fieldErrors: fieldErrors);
      }

      return AuthResponse.failure(
        'Server returned error: ${response.statusCode}',
      );
    } catch (_) {
      return AuthResponse.failure(
        'Server response could not be parsed. (Status ${response.statusCode})',
      );
    }
  }
}
