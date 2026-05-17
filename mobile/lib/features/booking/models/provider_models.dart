// Data models for the ProviderScreen.
//
// Backend integration:
//   When backend is ready, deserialize the ranked providers API response into
//   a List of ProviderModel and pass it to ProviderScreen. No widget changes needed.

/// Represents a single scoring factor used by the Ranking Agent.
class RankingFactorModel {
  final String label;       // e.g. "Distance"
  final String valueString; // e.g. "3.2 km"
  final double progress;    // 0.0 → 1.0 for the horizontal bar

  const RankingFactorModel({
    required this.label,
    required this.valueString,
    required this.progress,
  });
}

/// Represents a single ranked provider returned by the backend.
class ProviderModel {
  final int rank;
  final String initials;      // e.g. "AK"
  final String name;          // e.g. "Ahmed Khan"
  final String serviceTitle;  // e.g. "AC Technician"
  final String experience;    // e.g. "12 yrs exp"
  final double rating;        // e.g. 4.8
  final String price;         // e.g. "PKR 2,750"
  final bool isBestMatch;     // First/top provider flag
  final List<RankingFactorModel> factors;

  const ProviderModel({
    required this.rank,
    required this.initials,
    required this.name,
    required this.serviceTitle,
    required this.experience,
    required this.rating,
    required this.price,
    this.isBestMatch = false,
    required this.factors,
  });
}
