import 'package:flutter/material.dart';
import 'models/provider_models.dart';
import 'widgets/provider_header.dart';
import 'widgets/best_match_badge.dart';
import 'widgets/provider_card.dart';

/// Provider Screen — displays ranked providers returned by the Ranking Agent.
///
/// Backend integration:
///   1. Replace [_mockProviders] with the deserialized API response
///      (a List of ProviderModel) from your state manager / API call.
///   2. All child widgets consume ProviderModel through constructors — zero
///      widget changes are needed when the real backend is connected.
class ProviderScreen extends StatelessWidget {
  const ProviderScreen({super.key});

  // ── Shared ranking factors mock data ────────────────────────────────────
  // Backend will return per-provider factors; for now all share this demo set.
  static const List<RankingFactorModel> _demoFactors = [
    RankingFactorModel(label: 'Distance',       valueString: '3.2 km', progress: 0.82),
    RankingFactorModel(label: 'Rating',         valueString: '4.8',    progress: 0.78),
    RankingFactorModel(label: 'On-time',        valueString: '94%',    progress: 0.90),
    RankingFactorModel(label: 'Speciliazation', valueString: 'AC',     progress: 0.98),
    RankingFactorModel(label: 'Cancellation',   valueString: '0%',     progress: 0.88),
    RankingFactorModel(label: 'Availability',   valueString: 'Open',   progress: 0.84),
  ];

  // ── MOCK DATA — single source of truth ──────────────────────────────────
  // Replace with real ranked provider list from backend when integrating.
  static const List<ProviderModel> _mockProviders = [
    ProviderModel(
      rank: 1,
      initials: 'AK',
      name: 'Ahmed Khan',
      serviceTitle: 'AC Technician',
      experience: '12 yrs exp',
      rating: 4.8,
      price: 'PKR 2,750',
      isBestMatch: true,
      factors: _demoFactors,
    ),
    ProviderModel(
      rank: 2,
      initials: 'MF',
      name: 'M . Faisal',
      serviceTitle: 'AC & Geyser',
      experience: '8 yrs exp',
      rating: 4.5,
      price: 'PKR 2,400',
      factors: _demoFactors,
    ),
    ProviderModel(
      rank: 3,
      initials: 'ZA',
      name: 'Zain Ali',
      serviceTitle: 'AC Repair',
      experience: '4 yrs exp',
      rating: 4.0,
      price: 'PKR 2,000',
      factors: _demoFactors,
    ),
    ProviderModel(
      rank: 4,
      initials: 'BA',
      name: 'Bilal Ahmed',
      serviceTitle: 'HVAC Specialist',
      experience: '10 yrs exp',
      rating: 4.7,
      price: 'PKR 2,900',
      factors: _demoFactors,
    ),
    ProviderModel(
      rank: 5,
      initials: 'UR',
      name: 'Usman Raza',
      serviceTitle: 'Appliance Repair',
      experience: '6 yrs exp',
      rating: 4.3,
      price: 'PKR 2,200',
      factors: _demoFactors,
    ),
  ];

  void _goBack(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // ── Header ───────────────────────────────────────────────────────
            ProviderHeader(
              onBack: () => _goBack(context),
              providerCount: _mockProviders.length,
            ),

            const SizedBox(height: 12),

            // ── Best Match badge — above the first card, outside it ──────────
            // Matches Provider.png: badge floats above the first provider card.
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: BestMatchBadge(),
            ),

            const SizedBox(height: 8),

            // ── Scrollable provider list ──────────────────────────────────────
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 28),
                itemCount: _mockProviders.length,
                itemBuilder: (context, index) =>
                    ProviderCard(provider: _mockProviders[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
