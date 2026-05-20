import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/orchestrate_models.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// BACKEND URL CONFIGURATION
///
/// Change [_backendBaseUrl] to your Cloud Run URL when deploying.
/// Examples:
///   Local Android emulator : 'http://10.0.2.2:8000'
///   Local iOS simulator    : 'http://localhost:8000'
///   Cloud Run              : 'https://bulao-backend-<hash>-as.a.run.app'
/// ─────────────────────────────────────────────────────────────────────────────
const String _backendBaseUrl = 'https://bulou-ex8jo.ondigitalocean.app';

/// Timeout for the /orchestrate pipeline (local LLM on dedicated CPU can be slow).
const Duration _orchestrateTimeout = Duration(seconds: 90);

/// HTTP client for all Bulao backend API calls.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _client = http.Client();

  // ── POST /orchestrate ──────────────────────────────────────────────────────

  /// Sends a user request to the 6-agent pipeline and returns the full result.
  ///
  /// Throws [ApiException] on network errors, timeouts, or non-2xx responses.
  Future<OrchestrateResponse> orchestrate({
    required String text,
    required String userId,
    List<double>? userLocation,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/orchestrate');
    final body = OrchestrateRequest(
      text: text,
      userId: userId,
      userLocation: userLocation,
    ).toJson();

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return OrchestrateResponse.fromJson(json);
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  // ── POST /book ─────────────────────────────────────────────────────────────

  /// Finalizes a booking with the selected provider and quote.
  Future<Booking> book({
    required String quoteId,
    required String userId,
    String? userName,
    required Intent intent,
    required String providerId,
    required PriceQuote acceptedQuote,
    ProviderCandidate? provider,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/book');
    final body = {
      'quote_id': quoteId,
      'user_id': userId,
      if (userName != null) 'user_name': userName,
      'intent': {
        'service_type': intent.serviceType,
        'location': intent.location,
        'city': intent.city,
        'time_window': intent.timeWindow,
        'urgency': intent.urgency,
        'job_complexity': intent.jobComplexity,
        'confidence': intent.confidence,
      },
      'provider_id': providerId,
      'accepted_quote': acceptedQuote.toJson(),
      if (provider != null) 'provider': provider.toJson(),
    };

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Booking.fromJson(json);
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  // ── GET /booking/{booking_id}/lifecycle ───────────────────────────────────

  /// Polls the lifecycle status of a booking.
  Future<Map<String, dynamic>> getLifecycle(String bookingId) async {
    final uri = Uri.parse('$_backendBaseUrl/booking/$bookingId/lifecycle');
    
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  // ── POST /rating ───────────────────────────────────────────────────────────

  /// Submits a rating for a completed booking.
  Future<Map<String, dynamic>> submitRating({
    required String bookingId,
    required int rating,
  }) async {
    final uri = Uri.parse('$_backendBaseUrl/rating');
    final body = {
      'booking_id': bookingId,
      'rating': rating,
    };

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  // ── GET /services ──────────────────────────────────────────────────────────

  /// Fetches the list of available services.
  Future<List<String>> getServices() async {
    final uri = Uri.parse('$_backendBaseUrl/services');
    
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final list = json['services'] as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  // ── GET /user/{user_id}/bookings ───────────────────────────────────────────

  /// Fetches the booking history for the current user.
  Future<List<Booking>> getBookings(String userId) async {
    final uri = Uri.parse('$_backendBaseUrl/user/$userId/bookings');
    
    late http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
            },
          )
          .timeout(_orchestrateTimeout);
    } on Exception catch (e) {
      throw ApiException(
        message: 'Network error: ${e.toString()}',
        statusCode: null,
      );
    }

    if (response.statusCode == 200) {
      try {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        throw ApiException(
          message: 'Failed to parse backend response: $e',
          statusCode: response.statusCode,
        );
      }
    } else {
      String errorMsg = 'Backend error (${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        errorMsg = errJson['detail'] as String? ?? errorMsg;
      } catch (_) {}
      throw ApiException(message: errorMsg, statusCode: response.statusCode);
    }
  }

  void dispose() => _client.close();
}

/// Structured error thrown by [ApiService] on any failure.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';

  /// Human-readable message suitable for showing to the user.
  String get userFriendlyMessage {
    if (statusCode == null) {
      return 'Backend se connect nahi ho pa raha. Internet check karein.';
    }
    if (statusCode == 503 || statusCode == 504) {
      return 'Server thodi der ke liye busy hai. Dobara try karein.';
    }
    return 'Kuch masla aa gaya. Dobara try karein.';
  }
}
