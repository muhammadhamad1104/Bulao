import 'dart:math';
import 'package:flutter/material.dart';

/// Animated audio waveform widget matching the Bulao Processing Loading screen.
///
/// Renders a row of rounded-capsule bars that animate up/down continuously,
/// simulating audio amplitude. Color zones follow the reference:
///   Left side  → deep navy (#1E3A72)
///   Center     → silver/white
///   Right side → gold/amber (#C9A84C)
///
/// Backend-ready API:
///   Pass [amplitudes] as a List<double> (values 0.0–1.0) to drive each bar.
///   When real microphone data is available, replace [_mockAmplitudes] with
///   a Stream<List<double>> and rebuild via setState or StreamBuilder.
///
///   Example future integration:
///     AnimatedAudioWaveform(amplitudes: micAmplitudeStream.latest)
class AnimatedAudioWaveform extends StatefulWidget {
  /// Optional external amplitudes (0.0 – 1.0 per bar).
  /// When null, the widget uses internal mock animation.
  final List<double>? amplitudes;

  /// Total number of bars to render.
  final int barCount;

  /// Maximum height of the tallest bar in logical pixels.
  final double maxBarHeight;

  /// Width of each individual bar.
  final double barWidth;

  /// Gap between adjacent bars.
  final double barSpacing;

  const AnimatedAudioWaveform({
    super.key,
    this.amplitudes,
    this.barCount = 19,
    this.maxBarHeight = 140,
    this.barWidth = 8,
    this.barSpacing = 5,
  });

  @override
  State<AnimatedAudioWaveform> createState() => _AnimatedAudioWaveformState();
}

class _AnimatedAudioWaveformState extends State<AnimatedAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // ── Static mock amplitude envelope ────────────────────────────────────────
  // This is the "resting" bell-curve shape. Each value is a normalized
  // height (0.0–1.0). The animation adds a phase-shifted sine wave on top.
  // Replace this with real mic amplitude data during backend integration.
  static const List<double> _mockEnvelope = [
    0.10, 0.15, 0.25, 0.38, 0.52, // left — short, rising
    0.65, 0.75, 0.85, 0.95, 1.00, // center-left — tall peak
    0.95, 0.85, 0.75,              // center — descending
    0.88, 0.95, 0.80, 0.60, 0.35, // right gold section
    0.15,                          // rightmost tiny dot
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Color for each bar based on position ──────────────────────────────────
  // Mirrors the reference: navy left → silver center → gold right
  Color _barColor(int index, int total) {
    final t = index / (total - 1); // 0.0 → 1.0 left to right

    if (t < 0.42) {
      // Navy zone
      return Color.lerp(
        const Color(0xFF1E3A72),
        const Color(0xFF8AAAD4),
        t / 0.42,
      )!;
    } else if (t < 0.55) {
      // Silver/white center peak
      return Color.lerp(
        const Color(0xFF8AAAD4),
        const Color(0xFFEEF2F8),
        (t - 0.42) / 0.13,
      )!;
    } else {
      // Gold zone
      return Color.lerp(
        const Color(0xFFD4B060),
        const Color(0xFFC9A84C),
        (t - 0.55) / 0.45,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0.0 → 1.0 looping

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Waveform bars ──────────────────────────────────────────────
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(widget.barCount, (i) {
                // External amplitudes override mock if provided
                final baseHeight = widget.amplitudes != null
                    ? (widget.amplitudes![i % widget.amplitudes!.length]
                        .clamp(0.0, 1.0))
                    : _mockEnvelope[i % _mockEnvelope.length];

                // Phase-shifted sine animation per bar for ripple effect
                final phase = (i / widget.barCount) * 2 * pi;
                final wave = sin(2 * pi * t + phase) * 0.22;
                final animatedHeight =
                    ((baseHeight + wave).clamp(0.08, 1.0)) *
                        widget.maxBarHeight;

                final color = _barColor(i, widget.barCount);

                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: widget.barSpacing / 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    width: widget.barWidth,
                    height: animatedHeight,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(widget.barWidth / 2),
                      // Glass-like gradient on each bar: lighter top → richer bottom
                      gradient: LinearGradient(
                        colors: [
                          Color.lerp(color, Colors.white, 0.35)!,
                          color,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // ── Soft elliptical shadow under the waveform ─────────────────
            Container(
              width: widget.barCount * (widget.barWidth + widget.barSpacing) *
                  0.85,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFB0B8CC).withValues(alpha: 0.30),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
