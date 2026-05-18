import 'package:flutter/material.dart';
import 'models/provider_models.dart';
import 'widgets/provider_header.dart';
import 'widgets/best_match_badge.dart';
import 'widgets/provider_card.dart';
import '../../core/models/orchestrate_models.dart';

/// Provider Screen — displays ranked providers returned by the Ranking Agent.
///
/// Backend wiring:
///   Receives [OrchestrateResponse] from [ProcessingScreen].
///   Maps [DiscoveryResult.candidates] + [RankingResult] to [ProviderModel].
///   All child widgets (ProviderCard, BestMatchBadge) need zero changes.
class ProviderScreen extends StatelessWidget {
  final OrchestrateResponse response;

  const ProviderScreen({super.key, required this.response});

  // ── Map backend candidates → UI ProviderModel list ──────────────────────

  List<ProviderModel> _buildProviders() {
    final discovery = response.discovery;
    final ranking = response.ranking;
    final pricing = response.pricing;

    if (discovery == null || discovery.candidates.isEmpty) {
      return _fallbackProviders();
    }

    // Build ordered list: recommended first, then rest by ranking order
    final candidates = List<ProviderCandidate>.from(discovery.candidates);
    final recommendedId = ranking?.recommendedId;
    final topThree = ranking?.topThreeIds ?? [];

    // Sort: recommended → top-three order → rest
    candidates.sort((a, b) {
      if (a.id == recommendedId) return -1;
      if (b.id == recommendedId) return 1;
      final aIdx = topThree.indexOf(a.id);
      final bIdx = topThree.indexOf(b.id);
      if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
      if (aIdx != -1) return -1;
      if (bIdx != -1) return 1;
      return b.rating.compareTo(a.rating);
    });

    return candidates.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final c = entry.value;
      final isRecommended = c.id == recommendedId;

      // Build factor scores from ranking result
      final factorScores = ranking?.factorScores[c.id];
      final factors = factorScores != null
          ? _buildFactorsFromScores(factorScores, c)
          : _buildFactorsFromProvider(c);

      // Price: use pricing agent total for recommended; estimate others
      final priceStr = isRecommended && pricing != null
          ? 'PKR ${_formatPkr(pricing.estimatedTotalPkr)}'
          : 'PKR ${_formatPkr(c.baseVisitFeePkr + c.ratePerHourPkr)}';

      // Initials from name
      final initials = _initials(c.name);

      return ProviderModel(
        id: c.id,
        rank: rank,
        initials: initials,
        name: c.name,
        serviceTitle: _humanize(c.serviceCategories.isNotEmpty
            ? c.serviceCategories.first
            : 'Service'),
        experience: '${c.yearsExperience} yrs exp',
        rating: c.rating,
        price: priceStr,
        isBestMatch: isRecommended,
        factors: factors,
      );
    }).toList();
  }

  // ── Factor score helpers ─────────────────────────────────────────────────

  List<RankingFactorModel> _buildFactorsFromScores(
      FactorScores s, ProviderCandidate c) {
    return [
      RankingFactorModel(
          label: 'Distance',
          valueString: '${c.distanceKm.toStringAsFixed(1)} km',
          progress: s.distance.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Rating',
          valueString: c.rating.toStringAsFixed(1),
          progress: s.rating.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'On-time',
          valueString: '${(c.onTimeScore * 100).toStringAsFixed(0)}%',
          progress: s.onTime.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Specialization',
          valueString: c.specializations.isNotEmpty
              ? _humanize(c.specializations.first)
              : 'General',
          progress: s.specialization.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Availability',
          valueString: _humanizeAvailability(c.availabilityStatus),
          progress: s.availability.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Risk',
          valueString:
              c.cancellationRate == 0 ? '0%' : '${(c.cancellationRate * 100).toStringAsFixed(0)}%',
          progress: (1 - s.risk).clamp(0.0, 1.0)),
    ];
  }

  List<RankingFactorModel> _buildFactorsFromProvider(ProviderCandidate c) {
    final maxDist = 10.0;
    return [
      RankingFactorModel(
          label: 'Distance',
          valueString: '${c.distanceKm.toStringAsFixed(1)} km',
          progress: (1 - (c.distanceKm / maxDist)).clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Rating',
          valueString: c.rating.toStringAsFixed(1),
          progress: (c.rating / 5.0).clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'On-time',
          valueString: '${(c.onTimeScore * 100).toStringAsFixed(0)}%',
          progress: c.onTimeScore.clamp(0.0, 1.0)),
      RankingFactorModel(
          label: 'Specialization',
          valueString: c.specializations.isNotEmpty
              ? _humanize(c.specializations.first)
              : 'General',
          progress: c.specializations.isNotEmpty ? 0.85 : 0.5),
      RankingFactorModel(
          label: 'Availability',
          valueString: _humanizeAvailability(c.availabilityStatus),
          progress: c.availabilityStatus == 'available_now' ? 1.0 : 0.6),
      RankingFactorModel(
          label: 'Cancellation',
          valueString:
              c.cancellationRate == 0 ? '0%' : '${(c.cancellationRate * 100).toStringAsFixed(0)}%',
          progress: (1 - c.cancellationRate).clamp(0.0, 1.0)),
    ];
  }

  // ── String helpers ───────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }

  static String _humanize(String s) =>
      s.replaceAll('_', ' ').split(' ').map((w) {
        if (w.isEmpty) return '';
        return '${w[0].toUpperCase()}${w.substring(1)}';
      }).join(' ');

  static String _formatPkr(int pkr) {
    return pkr.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]},',
        );
  }

  static String _humanizeAvailability(String status) {
    switch (status) {
      case 'available_now': return 'Open Now';
      case 'next_slot_within_2h': return 'In 2 hrs';
      case 'next_slot_today': return 'Today';
      case 'tomorrow_or_later': return 'Tomorrow';
      default: return 'Available';
    }
  }

  // ── Fallback mock data (used only if backend returns no providers) ────────

  static const List<RankingFactorModel> _demoFactors = [
    RankingFactorModel(label: 'Distance',     valueString: '3.2 km', progress: 0.82),
    RankingFactorModel(label: 'Rating',       valueString: '4.8',    progress: 0.78),
    RankingFactorModel(label: 'On-time',      valueString: '94%',    progress: 0.90),
    RankingFactorModel(label: 'Specialization', valueString: 'AC',   progress: 0.98),
    RankingFactorModel(label: 'Cancellation', valueString: '0%',     progress: 0.88),
    RankingFactorModel(label: 'Availability', valueString: 'Open',   progress: 0.84),
  ];

  List<ProviderModel> _fallbackProviders() => const [
    ProviderModel(
      id: 'prov_001',
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
      id: 'prov_002',
      rank: 2,
      initials: 'MF',
      name: 'M . Faisal',
      serviceTitle: 'AC & Geyser',
      experience: '8 yrs exp',
      rating: 4.5,
      price: 'PKR 2,400',
      factors: _demoFactors,
    ),
  ];

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goBack(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final providers = _buildProviders();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),

            // ── Header ──────────────────────────────────────────────────────
            ProviderHeader(
              onBack: () => _goBack(context),
              providerCount: providers.length,
            ),

            const SizedBox(height: 12),

            // ── Best Match badge ─────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 20),
              child: BestMatchBadge(),
            ),

            const SizedBox(height: 8),

            // ── Provider list ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 28),
                itemCount: providers.length,
                itemBuilder: (context, index) =>
                    ProviderCard(
                      provider: providers[index],
                      response: response,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
