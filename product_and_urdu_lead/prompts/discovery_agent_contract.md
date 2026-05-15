# Discovery Agent — behavior contract (no LLM)

The Discovery Agent does NOT use an LLM. It is plain Python — a filter, scorer, and scheduler over the provider database.

## INPUT
- intent: validated Intent (incl. job_complexity, specialization_hint, gender_preference)
- user_location: optional LatLng {"lat": float, "lng": float}

## ALGORITHM

1. **SERVICE FILTER**: Keep providers where intent.service_type is in provider.service_categories.

2. **LOCATION FILTER**: If intent.location is set, keep providers in that neighborhood OR within 5km of the geocoded neighborhood center. If no location, use Islamabad center.

3. **GENDER FILTER**: If intent.gender_preference is "female" or "male" (not "any"), filter accordingly.

4. **COMPLEXITY FILTER**:
   - "complex": require provider.years_experience >= 5 AND intent.specialization_hint in provider.specializations (if hint set).
   - "intermediate": require provider.years_experience >= 2.
   - "basic": no filter.

5. **RISK FILTER**: Drop providers with risk_score > 0.7 OR strikes >= 3 OR cancellation_rate > 0.25.

6. **DISTANCE**: Compute distance_km using haversine from user_location or neighborhood center.

7. **AVAILABILITY**: Compute availability_status with 30-min travel buffer:
   - "available_now": next slot within 60 minutes
   - "next_slot_within_2h": next slot within 2 hours
   - "next_slot_today": next slot within 12 hours
   - "tomorrow_or_later": otherwise

8. **SCHEDULING INTELLIGENCE**: If fewer than 3 candidates within user's time_window, switch into alternate_slot_mode — return up to 8 with their NEAREST available slot.

9. **SORT**: by (distance_km asc, availability_status priority, rating desc). Return top 8.

## OUTPUT
```json
{
  "candidates": [...],
  "alternates": [...],
  "alternate_slot_mode": false,
  "no_match_reason": null
}
```

## PHONE MASKING
Only last 4 digits visible (e.g. "+92 XXX-XXX-1234"). Full phone revealed only after booking confirmation.

## NO-MATCH REASONS
- "no_provider_in_neighborhood"
- "no_provider_for_complexity"
- "all_providers_high_risk"
- "no_availability_in_window"

No-match reason MUST include Urdu translation:
- "Filhal aapke ilaake mein koi provider available nahi hai."
- "Is waqt required experience level ka koi provider nahi mila."
