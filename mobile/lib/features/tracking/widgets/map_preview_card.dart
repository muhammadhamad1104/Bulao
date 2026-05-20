import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Static Map Card using Google Maps Static API.
///
/// Shows a real satellite/road map image with:
///  - Blue marker  → user's location
///  - Red marker   → provider's shop location
///  - A dashed path between them
///  - ETA badge overlaid on top
///
/// Tapping the card opens Google Maps directions.
/// No Maps SDK for Android required — just the Static Maps API (billing enabled).
class MapPreviewCard extends StatefulWidget {
  final String status;
  final double? providerLat;
  final double? providerLng;
  final double? userLat;
  final double? userLng;
  final int? etaMinutes;

  const MapPreviewCard({
    super.key,
    required this.status,
    this.providerLat,
    this.providerLng,
    this.userLat,
    this.userLng,
    this.etaMinutes,
  });

  @override
  State<MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends State<MapPreviewCard> {
  static const _apiKey = 'AIzaSyBBFw3aCdVP1L7hfWfOZxTnRlyWv28w7oo';

  // Default: Islamabad centre
  static const _defLat = 33.595;
  static const _defLng = 73.048;

  double get _pLat => widget.providerLat ?? (_defLat + 0.006);
  double get _pLng => widget.providerLng ?? (_defLng + 0.007);
  double get _uLat => widget.userLat ?? _defLat;
  double get _uLng => widget.userLng ?? _defLng;

  double get _centerLat => (_pLat + _uLat) / 2;
  double get _centerLng => (_pLng + _uLng) / 2;

  String get _statusLabel {
    switch (widget.status) {
      case 'en_route':    return 'Provider on the way';
      case 'arrived':     return 'Provider has arrived';
      case 'in_progress': return 'Service in progress';
      case 'completed':   return 'Completed';
      default:            return 'Booking confirmed';
    }
  }

  /// Google Static Maps URL — returns a PNG image showing both locations.
  String get _staticMapUrl {
    final userMarker   = 'color:blue|label:U|$_uLat,$_uLng';
    final provMarker   = 'color:red|label:P|$_pLat,$_pLng';
    final path         = 'color:0x1E2D4EBB|weight:3|$_uLat,$_uLng|$_pLat,$_pLng';
    final params = {
      'center':    '$_centerLat,$_centerLng',
      'zoom':      '13',
      'size':      '640x320',
      'scale':     '2',
      'maptype':   'roadmap',
      'markers':   userMarker,        // first markers param
      'path':      path,
      'key':       _apiKey,
    };

    final base = 'https://maps.googleapis.com/maps/api/staticmap';
    // Build manually to allow duplicate 'markers' key
    final query = [
      'center=${Uri.encodeComponent('$_centerLat,$_centerLng')}',
      'zoom=13',
      'size=640x320',
      'scale=2',
      'maptype=roadmap',
      'markers=${Uri.encodeComponent('color:blue|label:U|$_uLat,$_uLng')}',
      'markers=${Uri.encodeComponent('color:red|label:P|$_pLat,$_pLng')}',
      'path=${Uri.encodeComponent('color:0x1E2D4ECC|weight:4|geodesic:true|$_uLat,$_uLng|$_pLat,$_pLng')}',
      'key=$_apiKey',
    ].join('&');

    return '$base?$query';
  }

  void _openDirections() async {
    final url =
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$_uLat,$_uLng'
        '&destination=$_pLat,$_pLng'
        '&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDirections,
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 4.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Real map image from Static Maps API ──────────────────────
              Image.network(
                _staticMapUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return _buildLoading();
                },
                errorBuilder: (ctx, err, st) => _buildFallback(),
              ),

              // ── Top: status pill ─────────────────────────────────────────
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D4E).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radio_button_checked,
                          size: 10, color: Color(0xFFC9A84C)),
                      const SizedBox(width: 6),
                      Text(
                        _statusLabel,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom: ETA badge ─────────────────────────────────────────
              if (widget.etaMinutes != null && widget.etaMinutes! > 0)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 16, color: Color(0xFF1E2D4E)),
                        const SizedBox(width: 5),
                        Text(
                          'ETA ~${widget.etaMinutes} min',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E2D4E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Bottom-left: legend ───────────────────────────────────────
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D4E).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _dot(Colors.blue, 'You'),
                      const SizedBox(width: 10),
                      _dot(Colors.red, 'Provider'),
                    ],
                  ),
                ),
              ),

              // ── Tap hint ─────────────────────────────────────────────────
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_new_rounded,
                      size: 16, color: Color(0xFF1E2D4E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildLoading() => Container(
        color: const Color(0xFF1E2D4E),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
          ),
        ),
      );

  Widget _buildFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E2D4E), Color(0xFF2A3A5E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded,
                size: 48, color: Color(0xFFC9A84C)),
            const SizedBox(height: 10),
            Text(_statusLabel,
                style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text('Islamabad / Rawalpindi',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.65))),
            if (widget.etaMinutes != null && widget.etaMinutes! > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('ETA ~${widget.etaMinutes} min',
                    style: GoogleFonts.ibmPlexSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2D4E))),
              ),
            ],
          ],
        ),
      );
}
