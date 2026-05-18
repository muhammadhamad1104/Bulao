/// Dart models that mirror the FastAPI Pydantic schemas in backend/app/models.py
/// Field names match the backend JSON exactly so fromJson is straightforward.
/// Schema version: 1.0 — keep in sync with backend/app/models.py

// ── Request ─────────────────────────────────────────────────────────────────

class OrchestrateRequest {
  final String text;
  final String userId;
  final List<double>? userLocation; // [lat, lng]

  const OrchestrateRequest({
    required this.text,
    required this.userId,
    this.userLocation,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'user_id': userId,
        if (userLocation != null) 'user_location': userLocation,
      };
}

// ── Intent ──────────────────────────────────────────────────────────────────

class Intent {
  final String serviceType;
  final String? location;
  final String city;
  final String timeWindow;
  final String urgency;
  final String jobComplexity;
  final String? specializationHint;
  final String genderPreference;
  final String? rawNotes;
  final double confidence;
  final bool needsClarification;
  final String? clarificationQuestion;

  const Intent({
    required this.serviceType,
    this.location,
    this.city = 'Islamabad',
    required this.timeWindow,
    required this.urgency,
    required this.jobComplexity,
    this.specializationHint,
    this.genderPreference = 'any',
    this.rawNotes,
    required this.confidence,
    this.needsClarification = false,
    this.clarificationQuestion,
  });

  factory Intent.fromJson(Map<String, dynamic> json) => Intent(
        serviceType: json['service_type'] as String? ?? 'plumber',
        location: json['location'] as String?,
        city: json['city'] as String? ?? 'Islamabad',
        timeWindow: json['time_window'] as String? ?? 'flexible',
        urgency: json['urgency'] as String? ?? 'normal',
        jobComplexity: json['job_complexity'] as String? ?? 'basic',
        specializationHint: json['specialization_hint'] as String?,
        genderPreference: json['gender_preference'] as String? ?? 'any',
        rawNotes: json['raw_notes'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.5,
        needsClarification: json['needs_clarification'] as bool? ?? false,
        clarificationQuestion: json['clarification_question'] as String?,
      );
}

// ── Provider Candidate ───────────────────────────────────────────────────────

class ProviderCandidate {
  final String id;
  final String name;
  final List<String> serviceCategories;
  final List<String> specializations;
  final double distanceKm;
  final String neighborhood;
  final double rating;
  final int completedJobsInArea;
  final double onTimeScore;
  final double cancellationRate;
  final int reviewRecencyDays;
  final double riskScore;
  final double currentWorkload;
  final String availabilityStatus;
  final String nextSlot;
  final int baseVisitFeePkr;
  final int ratePerHourPkr;
  final String gender;
  final int yearsExperience;
  final List<String> languages;
  final bool verified;
  final String phoneMasked;
  final String? alternateSlotReason;

  const ProviderCandidate({
    required this.id,
    required this.name,
    required this.serviceCategories,
    this.specializations = const [],
    required this.distanceKm,
    required this.neighborhood,
    required this.rating,
    required this.completedJobsInArea,
    required this.onTimeScore,
    required this.cancellationRate,
    required this.reviewRecencyDays,
    required this.riskScore,
    required this.currentWorkload,
    required this.availabilityStatus,
    required this.nextSlot,
    required this.baseVisitFeePkr,
    required this.ratePerHourPkr,
    required this.gender,
    required this.yearsExperience,
    this.languages = const [],
    this.verified = true,
    required this.phoneMasked,
    this.alternateSlotReason,
  });

  factory ProviderCandidate.fromJson(Map<String, dynamic> json) =>
      ProviderCandidate(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Unknown',
        serviceCategories: List<String>.from(json['service_categories'] as List? ?? []),
        specializations: List<String>.from(json['specializations'] as List? ?? []),
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
        neighborhood: json['neighborhood'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        completedJobsInArea: json['completed_jobs_in_area'] as int? ?? 0,
        onTimeScore: (json['on_time_score'] as num?)?.toDouble() ?? 0.0,
        cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0.0,
        reviewRecencyDays: json['review_recency_days'] as int? ?? 0,
        riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
        currentWorkload: (json['current_workload'] as num?)?.toDouble() ?? 0.0,
        availabilityStatus: json['availability_status'] as String? ?? 'available_now',
        nextSlot: json['next_slot'] as String? ?? '',
        baseVisitFeePkr: json['base_visit_fee_pkr'] as int? ?? 0,
        ratePerHourPkr: json['rate_per_hour_pkr'] as int? ?? 0,
        gender: json['gender'] as String? ?? 'male',
        yearsExperience: json['years_experience'] as int? ?? 0,
        languages: List<String>.from(json['languages'] as List? ?? []),
        verified: json['verified'] as bool? ?? true,
        phoneMasked: json['phone_masked'] as String? ?? '**********',
        alternateSlotReason: json['alternate_slot_reason'] as String?,
      );
}

// ── Discovery Result ─────────────────────────────────────────────────────────

class DiscoveryResult {
  final List<ProviderCandidate> candidates;
  final List<ProviderCandidate> alternates;
  final String? noMatchReason;

  const DiscoveryResult({
    this.candidates = const [],
    this.alternates = const [],
    this.noMatchReason,
  });

  factory DiscoveryResult.fromJson(Map<String, dynamic> json) => DiscoveryResult(
        candidates: (json['candidates'] as List? ?? [])
            .map((e) => ProviderCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        alternates: (json['alternates'] as List? ?? [])
            .map((e) => ProviderCandidate.fromJson(e as Map<String, dynamic>))
            .toList(),
        noMatchReason: json['no_match_reason'] as String?,
      );
}

// ── Ranking Result ───────────────────────────────────────────────────────────

class FactorScores {
  final double distance;
  final double availability;
  final double rating;
  final double onTime;
  final double specialization;
  final double risk;
  final double total;

  const FactorScores({
    required this.distance,
    required this.availability,
    required this.rating,
    required this.onTime,
    required this.specialization,
    required this.risk,
    required this.total,
  });

  factory FactorScores.fromJson(Map<String, dynamic> json) => FactorScores(
        distance: (json['distance'] as num?)?.toDouble() ?? 0,
        availability: (json['availability'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        onTime: (json['on_time'] as num?)?.toDouble() ?? 0,
        specialization: (json['specialization'] as num?)?.toDouble() ?? 0,
        risk: (json['risk'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );
}

class RankingResult {
  final String? recommendedId;
  final List<String> topThreeIds;
  final Map<String, FactorScores> factorScores;
  final String reasoningEnglish;
  final String reasoningUrdu;
  final String tradeoffs;
  final String confidence;

  const RankingResult({
    this.recommendedId,
    this.topThreeIds = const [],
    this.factorScores = const {},
    this.reasoningEnglish = '',
    this.reasoningUrdu = '',
    this.tradeoffs = '',
    this.confidence = 'medium',
  });

  factory RankingResult.fromJson(Map<String, dynamic> json) => RankingResult(
        recommendedId: json['recommended_id'] as String?,
        topThreeIds: List<String>.from(json['top_three_ids'] as List? ?? []),
        factorScores: (json['factor_scores'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, FactorScores.fromJson(v as Map<String, dynamic>)),
        ),
        reasoningEnglish: json['reasoning_english'] as String? ?? '',
        reasoningUrdu: json['reasoning_urdu'] as String? ?? '',
        tradeoffs: json['tradeoffs'] as String? ?? '',
        confidence: json['confidence'] as String? ?? 'medium',
      );
}

// ── Price Quote ──────────────────────────────────────────────────────────────

class PriceLineItem {
  final String labelEnglish;
  final String labelUrdu;
  final int amountPkr;
  final String kind;

  const PriceLineItem({
    required this.labelEnglish,
    required this.labelUrdu,
    required this.amountPkr,
    required this.kind,
  });

  factory PriceLineItem.fromJson(Map<String, dynamic> json) => PriceLineItem(
        labelEnglish: json['label_english'] as String? ?? '',
        labelUrdu: json['label_urdu'] as String? ?? '',
        amountPkr: json['amount_pkr'] as int? ?? 0,
        kind: json['kind'] as String? ?? 'base',
      );
}

class PriceQuote {
  final String quoteId;
  final List<PriceLineItem> lineItems;
  final int subtotalPkr;
  final int estimatedTotalPkr;
  final List<int> estimatedRangePkr;
  final String explanationEnglish;
  final String explanationUrdu;
  final String fairnessNote;
  final String expiresAt;

  const PriceQuote({
    required this.quoteId,
    this.lineItems = const [],
    required this.subtotalPkr,
    required this.estimatedTotalPkr,
    this.estimatedRangePkr = const [0, 0],
    required this.explanationEnglish,
    required this.explanationUrdu,
    required this.fairnessNote,
    required this.expiresAt,
  });

  factory PriceQuote.fromJson(Map<String, dynamic> json) => PriceQuote(
        quoteId: json['quote_id'] as String? ?? '',
        lineItems: (json['line_items'] as List? ?? [])
            .map((e) => PriceLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotalPkr: json['subtotal_pkr'] as int? ?? 0,
        estimatedTotalPkr: json['estimated_total_pkr'] as int? ?? 0,
        estimatedRangePkr: (json['estimated_range_pkr'] as List? ?? [0, 0])
            .map((e) => e as int)
            .toList(),
        explanationEnglish: json['explanation_english'] as String? ?? '',
        explanationUrdu: json['explanation_urdu'] as String? ?? '',
        fairnessNote: json['fairness_note'] as String? ?? '',
        expiresAt: json['expires_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'quote_id': quoteId,
        'line_items': lineItems
            .map((e) => {
                  'label_english': e.labelEnglish,
                  'label_urdu': e.labelUrdu,
                  'amount_pkr': e.amountPkr,
                  'kind': e.kind,
                })
            .toList(),
        'subtotal_pkr': subtotalPkr,
        'estimated_total_pkr': estimatedTotalPkr,
        'estimated_range_pkr': estimatedRangePkr,
        'explanation_english': explanationEnglish,
        'explanation_urdu': explanationUrdu,
        'fairness_note': fairnessNote,
        'expires_at': expiresAt,
      };
}

// ── Orchestrate Response ─────────────────────────────────────────────────────

class OrchestrateResponse {
  final Intent intent;
  final DiscoveryResult? discovery;
  final RankingResult? ranking;
  final PriceQuote? pricing;
  final Map<String, dynamic>? bookingPreview;
  final Map<String, dynamic>? followupPlanned;
  final bool needsClarification;
  final String? clarificationQuestion;
  final String? userMessageUrdu;
  final String? userMessageEnglish;

  const OrchestrateResponse({
    required this.intent,
    this.discovery,
    this.ranking,
    this.pricing,
    this.bookingPreview,
    this.followupPlanned,
    this.needsClarification = false,
    this.clarificationQuestion,
    this.userMessageUrdu,
    this.userMessageEnglish,
  });

  factory OrchestrateResponse.fromJson(Map<String, dynamic> json) =>
      OrchestrateResponse(
        intent: Intent.fromJson(json['intent'] as Map<String, dynamic>),
        discovery: json['discovery'] != null
            ? DiscoveryResult.fromJson(json['discovery'] as Map<String, dynamic>)
            : null,
        ranking: json['ranking'] != null
            ? RankingResult.fromJson(json['ranking'] as Map<String, dynamic>)
            : null,
        pricing: json['pricing'] != null
            ? PriceQuote.fromJson(json['pricing'] as Map<String, dynamic>)
            : null,
        bookingPreview: json['booking_preview'] as Map<String, dynamic>?,
        followupPlanned: json['followup_planned'] as Map<String, dynamic>?,
        needsClarification: json['needs_clarification'] as bool? ?? false,
        clarificationQuestion: json['clarification_question'] as String?,
        userMessageUrdu: json['user_message_urdu'] as String?,
        userMessageEnglish: json['user_message_english'] as String?,
      );
}

// ── Booking Lifecycle ────────────────────────────────────────────────────────

class BookingLifecycle {
  final String? confirmedAt;
  final String? enRouteAt;
  final String? arrivedAt;
  final String? inProgressAt;
  final String? completedAt;
  final String? cancelledAt;

  const BookingLifecycle({
    this.confirmedAt,
    this.enRouteAt,
    this.arrivedAt,
    this.inProgressAt,
    this.completedAt,
    this.cancelledAt,
  });

  factory BookingLifecycle.fromJson(Map<String, dynamic> json) => BookingLifecycle(
        confirmedAt: json['confirmed_at'] as String?,
        enRouteAt: json['en_route_at'] as String?,
        arrivedAt: json['arrived_at'] as String?,
        inProgressAt: json['in_progress_at'] as String?,
        completedAt: json['completed_at'] as String?,
        cancelledAt: json['cancelled_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'confirmed_at': confirmedAt,
        'en_route_at': enRouteAt,
        'arrived_at': arrivedAt,
        'in_progress_at': inProgressAt,
        'completed_at': completedAt,
        'cancelled_at': cancelledAt,
      };
}

// ── Booking ──────────────────────────────────────────────────────────────────

class Booking {
  final String bookingId;
  final String userId;
  final String providerId;
  final String serviceType;
  final String location;
  final String city;
  final String scheduledTime;
  final String status;
  final BookingLifecycle lifecycle;
  final PriceQuote acceptedQuote;
  final Intent intentSnapshot;
  final RankingResult? rankingSnapshot;
  final String? receiptUrl;
  final String confirmationMessageEnglish;
  final String confirmationMessageUrdu;

  const Booking({
    required this.bookingId,
    required this.userId,
    required this.providerId,
    required this.serviceType,
    required this.location,
    required this.city,
    required this.scheduledTime,
    required this.status,
    required this.lifecycle,
    required this.acceptedQuote,
    required this.intentSnapshot,
    this.rankingSnapshot,
    this.receiptUrl,
    this.confirmationMessageEnglish = '',
    this.confirmationMessageUrdu = '',
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        bookingId: json['booking_id'] as String? ?? '',
        userId: json['user_id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? '',
        serviceType: json['service_type'] as String? ?? '',
        location: json['location'] as String? ?? '',
        city: json['city'] as String? ?? '',
        scheduledTime: json['scheduled_time'] as String? ?? '',
        status: json['status'] as String? ?? 'confirmed',
        lifecycle: BookingLifecycle.fromJson(json['lifecycle'] as Map<String, dynamic>? ?? {}),
        acceptedQuote: PriceQuote.fromJson(json['accepted_quote'] as Map<String, dynamic>? ?? {}),
        intentSnapshot: Intent.fromJson(json['intent_snapshot'] as Map<String, dynamic>? ?? {}),
        rankingSnapshot: json['ranking_snapshot'] != null
            ? RankingResult.fromJson(json['ranking_snapshot'] as Map<String, dynamic>)
            : null,
        receiptUrl: json['receipt_url'] as String?,
        confirmationMessageEnglish: json['confirmation_message_english'] as String? ?? '',
        confirmationMessageUrdu: json['confirmation_message_urdu'] as String? ?? '',
      );
}

