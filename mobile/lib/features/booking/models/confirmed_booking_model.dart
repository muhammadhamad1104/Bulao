/// Data model for the Confirmed Booking Screen.
///
/// Backend integration:
///   When the backend confirms a booking, deserialize the response into this
///   model and pass it to ConfirmedBookingScreen.
class ConfirmedBookingModel {
  final String bookingId;
  final String shortBookingId;
  final String providerName;
  final double providerRating;
  final String service;
  final String time;
  final String location;
  final String total;
  final String confirmationMessage;

  const ConfirmedBookingModel({
    required this.bookingId,
    required this.shortBookingId,
    required this.providerName,
    required this.providerRating,
    required this.service,
    required this.time,
    required this.location,
    required this.total,
    required this.confirmationMessage,
  });

  // Centralized mock data for UI building
  static const ConfirmedBookingModel mockData = ConfirmedBookingModel(
    bookingId: 'BL-2024-7823',
    shortBookingId: 'BL-7823',
    providerName: 'Ahmed Khan',
    providerRating: 4.8,
    service: 'AC Repair (Complex)',
    time: 'Tomorrow · 10:00 AM',
    location: 'G-13/4, Islamabad',
    total: 'PKR 2,760',
    confirmationMessage: 'Aapki booking confirm ho gayi!\nAhmed Khan kal 10:00 AM ko\nG-13/4 aayenge. Booking ID:\nBL-7823',
  );
}
