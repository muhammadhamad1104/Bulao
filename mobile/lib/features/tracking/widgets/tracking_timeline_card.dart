import 'package:flutter/material.dart';
import '../models/tracking_models.dart';
import 'timeline_step_item.dart';

/// Card containing the vertical timeline lifecycle of the booking.
class TrackingTimelineCard extends StatelessWidget {
  final TrackingModel model;

  const TrackingTimelineCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9C9A8), width: 1.0), // Thin gold border
      ),
      child: Column(
        children: List.generate(model.timelineSteps.length, (index) {
          final step = model.timelineSteps[index];
          final isLast = index == model.timelineSteps.length - 1;
          
          return TimelineStepItem(
            step: step,
            isLast: isLast,
          );
        }),
      ),
    );
  }
}
