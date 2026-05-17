import 'package:flutter/material.dart';

import 'models/tracking_models.dart';
import 'widgets/tracking_header.dart';
import 'widgets/map_preview_card.dart';
import 'widgets/provider_tracking_card.dart';
import 'widgets/tracking_timeline_card.dart';

import '../feedback/feedback_screen.dart';

/// Real Tracking Screen matching the UI reference.
/// Currently powered by mock data but structured to accept backend state.
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  void _debugCompleteBooking(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const FeedbackScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Backend integration: Replace with state stream / provider data later.
    final trackingData = TrackingModel.mockData;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // Unified Bulao background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header (Back arrow, Title, Logo) ─────────────────────────
                const TrackingHeader(),

                const SizedBox(height: 24),

                // ── Map Mock Card ────────────────────────────────────────────
                const MapPreviewCard(),

                const SizedBox(height: 20),

                // ── Provider Tracking Info (AK, Ahmed Khan, En Route) ────────
                ProviderTrackingCard(model: trackingData),

                const SizedBox(height: 16),

                // ── Timeline Card ────────────────────────────────────────────
                TrackingTimelineCard(model: trackingData),

                const SizedBox(height: 32),
                
                // ── Temporary Testing Button ─────────────────────────────────
                // Will be removed when backend lifecycle states trigger FeedbackScreen
                Center(
                  child: TextButton.icon(
                    onPressed: () => _debugCompleteBooking(context),
                    icon: const Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50)),
                    label: const Text(
                      'Mark Completed (Demo)',
                      style: TextStyle(color: Color(0xFF4CAF50)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
