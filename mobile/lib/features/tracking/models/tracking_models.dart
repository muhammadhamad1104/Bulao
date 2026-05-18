/// Enum representing the state of a tracking timeline step.
enum TrackingStepStatus {
  completed,
  active,
  pending,
}

/// Model for a single step in the tracking timeline.
class TrackingStepModel {
  final String title;
  final String subtitle;
  final TrackingStepStatus status;

  const TrackingStepModel({
    required this.title,
    required this.subtitle,
    required this.status,
  });
}

/// Main data model for the Tracking Screen.
/// 
/// Backend integration:
/// This model should be populated via a real-time stream (e.g. Firebase/WebSocket)
/// to keep the tracking UI updated as the provider moves.
class TrackingModel {
  final String providerName;
  final String providerInitials;
  final String statusText;
  final String phoneNumber;
  final List<TrackingStepModel> timelineSteps;

  const TrackingModel({
    required this.providerName,
    required this.providerInitials,
    required this.statusText,
    required this.phoneNumber,
    required this.timelineSteps,
  });

  // Centralized mock data matching the reference UI exactly.
  static const TrackingModel mockData = TrackingModel(
    providerName: 'Ahmed Khan',
    providerInitials: 'AK',
    statusText: 'En Route . 3.2km away',
    phoneNumber: '+92000000000',
    timelineSteps: [
      TrackingStepModel(
        title: 'Booking Confirmed',
        subtitle: 'Yesterday . 10:32 AM',
        status: TrackingStepStatus.completed,
      ),
      TrackingStepModel(
        title: 'Ahmed is on his way',
        subtitle: 'Left 9:44 AM    ETA 10:02 AM',
        status: TrackingStepStatus.active,
      ),
      TrackingStepModel(
        title: 'Service In Progress',
        subtitle: 'Pending',
        status: TrackingStepStatus.pending,
      ),
      TrackingStepModel(
        title: 'Completed',
        subtitle: 'Pending',
        status: TrackingStepStatus.pending,
      ),
    ],
  );
}
