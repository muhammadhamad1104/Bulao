import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/orchestrate_models.dart';

/// Persistent booking store — saves bookings to device storage via SharedPreferences.
/// This ensures Sidebar Live Tracking and My Bookings work even after app restarts,
/// without needing cloud_firestore on the Flutter side.
class LocalBookingStore {
  LocalBookingStore._();
  static final LocalBookingStore instance = LocalBookingStore._();

  static const _key = 'bulao_bookings_v1';

  final List<Booking> _bookings = [];
  bool _loaded = false;

  /// Load persisted bookings from device storage. Call once at startup.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        _bookings.clear();
        for (final item in list) {
          try {
            _bookings.add(Booking.fromJson(item as Map<String, dynamic>));
          } catch (_) {}
        }
      }
    } catch (e) {
      // Storage unavailable — fall back to in-memory only
    }
  }

  /// Save a booking (called right after /book succeeds).
  Future<void> save(Booking booking) async {
    // Remove any previous entry with the same ID to avoid duplicates.
    _bookings.removeWhere((b) => b.bookingId == booking.bookingId);
    _bookings.insert(0, booking); // most-recent first
    await _persist();
  }

  /// All locally cached bookings (most-recent first).
  List<Booking> get all => List.unmodifiable(_bookings);

  /// The first active (confirmed / en_route / arrived / in_progress) booking.
  Booking? get firstActive {
    const activeStatuses = {'confirmed', 'en_route', 'arrived', 'in_progress'};
    for (final b in _bookings) {
      if (activeStatuses.contains(b.status.toLowerCase())) return b;
    }
    return null;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only keep the last 20 bookings to avoid storage bloat
      final toStore = _bookings.take(20).toList();
      final encoded = jsonEncode(toStore.map(_bookingToJson).toList());
      await prefs.setString(_key, encoded);
    } catch (_) {}
  }

  Map<String, dynamic> _bookingToJson(Booking b) => {
        'booking_id': b.bookingId,
        'user_id': b.userId,
        'provider_id': b.providerId,
        'service_type': b.serviceType,
        'location': b.location,
        'city': b.city,
        'scheduled_time': b.scheduledTime,
        'status': b.status,
        'lifecycle': {
          'confirmed_at': b.lifecycle.confirmedAt,
          'en_route_at': b.lifecycle.enRouteAt,
          'arrived_at': b.lifecycle.arrivedAt,
          'in_progress_at': b.lifecycle.inProgressAt,
          'completed_at': b.lifecycle.completedAt,
          'cancelled_at': b.lifecycle.cancelledAt,
        },
        'accepted_quote': b.acceptedQuote.toJson(),
        'intent_snapshot': {
          'service_type': b.intentSnapshot.serviceType,
          'location': b.intentSnapshot.location,
          'city': b.intentSnapshot.city,
          'time_window': b.intentSnapshot.timeWindow,
          'urgency': b.intentSnapshot.urgency,
          'job_complexity': b.intentSnapshot.jobComplexity,
          'confidence': b.intentSnapshot.confidence,
          'needs_clarification': b.intentSnapshot.needsClarification,
        },
        'confirmation_message_english': b.confirmationMessageEnglish,
        'confirmation_message_urdu': b.confirmationMessageUrdu,
        'provider_name': b.providerName,
        'provider_lat': b.providerLat,
        'provider_lng': b.providerLng,
        'user_lat': b.userLat,
        'user_lng': b.userLng,
        'eta_minutes': b.etaMinutes,
        'provider_phone': b.providerPhone,
        'whatsapp_url': b.whatsappUrl,
      };
}
