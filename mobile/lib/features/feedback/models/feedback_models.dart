/// Represents the booking details shown on the feedback screen.
class FeedbackBookingModel {
  final String bookingId;
  final String providerId;
  final String providerInitials;
  final String providerName;
  final String descriptionLabel;

  const FeedbackBookingModel({
    required this.bookingId,
    required this.providerId,
    required this.providerInitials,
    required this.providerName,
    required this.descriptionLabel,
  });

  // Mock data matching the reference UI exactly.
  static const FeedbackBookingModel mockData = FeedbackBookingModel(
    bookingId: 'BL-2024-7823',
    providerId: 'provider-123',
    providerInitials: 'AK',
    providerName: 'Ahmed Khan',
    descriptionLabel: 'AC Repair . G-13/4 . Today',
  );
}

/// Represents the data the user submits as feedback.
class FeedbackSubmissionModel {
  final String bookingId;
  final String providerId;
  final int rating;
  final List<String> selectedTags;
  final String comment;

  const FeedbackSubmissionModel({
    required this.bookingId,
    required this.providerId,
    required this.rating,
    required this.selectedTags,
    required this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'providerId': providerId,
      'rating': rating,
      'selectedTags': selectedTags,
      'comment': comment,
    };
  }
}
