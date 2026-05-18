import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tracking_models.dart';

/// Renders a single step in the tracking timeline.
class TimelineStepItem extends StatelessWidget {
  final TrackingStepModel step;
  final bool isLast;

  const TimelineStepItem({
    super.key,
    required this.step,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Node & Vertical Line Column ──────────────────────────────────
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _buildNodeIcon(),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0xFFE8DCC8), // Timeline line color
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // ── Text Column ──────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 4), // Align text with node icon center roughly
                  Text(
                    step.title,
                    style: GoogleFonts.ibmPlexSansCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _getTitleColor(),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _getSubtitleColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeIcon() {
    switch (step.status) {
      case TrackingStepStatus.completed:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF70B758), // Green
          ),
          child: const Icon(
            Icons.check,
            color: Colors.white,
            size: 20,
          ),
        );
      case TrackingStepStatus.active:
        return Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFC9A84C), // Gold
          ),
          child: const Icon(
            Icons.hourglass_bottom_rounded,
            color: Colors.white,
            size: 18,
          ),
        );
      case TrackingStepStatus.pending:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEFEFEF), // Light grey background
            border: Border.all(color: const Color(0xFFD8D8D8)),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            color: Color(0xFFB5B5B5),
            size: 18,
          ),
        );
    }
  }

  Color _getTitleColor() {
    switch (step.status) {
      case TrackingStepStatus.completed:
      case TrackingStepStatus.active:
        return const Color(0xFF0D0D0D); // Black
      case TrackingStepStatus.pending:
        return const Color(0xFFB5B5B5); // Light grey
    }
  }

  Color _getSubtitleColor() {
    switch (step.status) {
      case TrackingStepStatus.completed:
        return const Color(0xFFB8952A); // Gold
      case TrackingStepStatus.active:
        return const Color(0xFF8A95A8); // Standard subtitle grey
      case TrackingStepStatus.pending:
        return const Color(0xFFB5B5B5); // Light grey
    }
  }
}
