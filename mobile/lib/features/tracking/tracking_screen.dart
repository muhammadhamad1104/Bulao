import 'dart:async';
import 'package:flutter/material.dart';

import 'models/tracking_models.dart';
import 'widgets/tracking_header.dart';
import 'widgets/map_preview_card.dart';
import 'widgets/provider_tracking_card.dart';
import 'widgets/tracking_timeline_card.dart';

import '../feedback/feedback_screen.dart';
import '../../core/models/orchestrate_models.dart';
import '../../core/services/api_service.dart';

/// Real Tracking Screen matching the UI reference.
/// Powered by periodic polling of the backend lifecycle endpoint.
class TrackingScreen extends StatefulWidget {
  final Booking booking;
  final String providerName;
  final String providerInitials;

  const TrackingScreen({
    super.key,
    required this.booking,
    required this.providerName,
    required this.providerInitials,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  Timer? _timer;
  Map<String, dynamic>? _lifecycleData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    // Poll every 10 seconds for demo purposes
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchStatus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await ApiService.instance.getLifecycle(widget.booking.bookingId);
      if (mounted) {
        setState(() {
          _lifecycleData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Keep showing old data or initial data on error
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _debugCompleteBooking(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => FeedbackScreen(
          bookingId: widget.booking.bookingId,
          providerName: widget.providerName,
          providerInitials: widget.providerInitials,
          descriptionLabel: '${widget.booking.serviceType} . ${widget.booking.location}',
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
    } catch (_) {
      return '9:44 AM'; // Fallback
    }
  }

  String _humanizeTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return 'Today . ${_formatTime(isoTime)}';
    } catch (_) {
      return 'Today';
    }
  }

  TrackingStepStatus _getStepStatus(String currentStatus, String step) {
    if (currentStatus == 'completed') return TrackingStepStatus.completed;
    
    if (step == 'confirmed') {
      return (currentStatus == 'confirmed') ? TrackingStepStatus.active : TrackingStepStatus.completed;
    }
    if (step == 'en_route') {
      if (currentStatus == 'confirmed') return TrackingStepStatus.pending;
      return (currentStatus == 'en_route') ? TrackingStepStatus.active : TrackingStepStatus.completed;
    }
    if (step == 'in_progress') {
      if (currentStatus == 'confirmed' || currentStatus == 'en_route') return TrackingStepStatus.pending;
      return (currentStatus == 'arrived' || currentStatus == 'in_progress') ? TrackingStepStatus.active : TrackingStepStatus.completed;
    }
    if (step == 'completed') {
      return (currentStatus == 'completed') ? TrackingStepStatus.active : TrackingStepStatus.pending;
    }
    return TrackingStepStatus.pending;
  }

  @override
  Widget build(BuildContext context) {
    final status = _lifecycleData?['status'] as String? ?? widget.booking.status;
    final eta = _lifecycleData?['eta_minutes'] as int? ?? 15;
    
    // Map status to text
    String statusText = 'Confirmed';
    if (status == 'en_route') statusText = 'En Route . $eta min away';
    if (status == 'arrived') statusText = 'Arrived';
    if (status == 'in_progress') statusText = 'Service In Progress';
    if (status == 'completed') statusText = 'Completed';

    // Map lifecycle dates
    final lifecycle = _lifecycleData?['lifecycle'] as Map<String, dynamic>? ?? {};
    final confirmedAt = lifecycle['confirmed_at'] as String? ?? widget.booking.lifecycle.confirmedAt;
    final enRouteAt = lifecycle['en_route_at'] as String? ?? widget.booking.lifecycle.enRouteAt;
    final arrivedAt = lifecycle['arrived_at'] as String? ?? widget.booking.lifecycle.arrivedAt;
    final inProgressAt = lifecycle['in_progress_at'] as String? ?? widget.booking.lifecycle.inProgressAt;
    final completedAt = lifecycle['completed_at'] as String? ?? widget.booking.lifecycle.completedAt;

    final trackingData = TrackingModel(
      providerName: widget.providerName,
      providerInitials: widget.providerInitials,
      statusText: statusText,
      phoneNumber: '+92000000000',
      timelineSteps: [
        TrackingStepModel(
          title: 'Booking Confirmed',
          subtitle: confirmedAt != null ? _humanizeTime(confirmedAt) : 'Pending',
          status: _getStepStatus(status, 'confirmed'),
        ),
        TrackingStepModel(
          title: '${widget.providerName} is on his way',
          subtitle: enRouteAt != null ? 'Left ${_formatTime(enRouteAt)}' : 'Pending',
          status: _getStepStatus(status, 'en_route'),
        ),
        TrackingStepModel(
          title: 'Service In Progress',
          subtitle: inProgressAt != null ? _humanizeTime(inProgressAt) : 'Pending',
          status: _getStepStatus(status, 'in_progress'),
        ),
        TrackingStepModel(
          title: 'Completed',
          subtitle: completedAt != null ? _humanizeTime(completedAt) : 'Pending',
          status: _getStepStatus(status, 'completed'),
        ),
      ],
    );

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
                MapPreviewCard(status: status),

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
