import '../models/orchestrate_models.dart';

/// In-memory store that caches the most recent bookings made during this
/// app session. This ensures the Sidebar Live Tracking and My Bookings
/// buttons can always find bookings even if Firestore is unreachable or
/// the backend getBookings call fails.
class LocalBookingStore {
  LocalBookingStore._();
  static final LocalBookingStore instance = LocalBookingStore._();

  final List<Booking> _bookings = [];

  /// Save a booking (called right after /book succeeds).
  void save(Booking booking) {
    // Remove any previous entry with the same ID to avoid duplicates.
    _bookings.removeWhere((b) => b.bookingId == booking.bookingId);
    _bookings.insert(0, booking); // most-recent first
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
}
