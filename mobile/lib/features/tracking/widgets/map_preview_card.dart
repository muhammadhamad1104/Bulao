import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Interactive map card using flutter_map + OpenStreetMap tiles.
///
/// - FREE — no API key, no billing
/// - Real interactive map with pan/zoom
/// - Blue marker  → user's location
/// - Red marker   → provider's shop
/// - Route line between them
/// - ETA badge overlay
/// - Tap card to open Google Maps directions
class MapPreviewCard extends StatelessWidget {
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

  // Default: Islamabad centre
  static const _defLat = 33.595;
  static const _defLng = 73.048;

  LatLng get _providerPos => LatLng(
        providerLat ?? (_defLat + 0.006),
        providerLng ?? (_defLng + 0.007),
      );

  LatLng get _userPos => LatLng(userLat ?? _defLat, userLng ?? _defLng);

  LatLng get _center => LatLng(
        (_providerPos.latitude + _userPos.latitude) / 2,
        (_providerPos.longitude + _userPos.longitude) / 2,
      );

  String get _statusLabel {
    switch (status) {
      case 'en_route':    return 'Provider on the way';
      case 'arrived':     return 'Provider has arrived';
      case 'in_progress': return 'Service in progress';
      case 'completed':   return 'Completed';
      default:            return 'Booking confirmed';
    }
  }

  void _openDirections() async {
    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${_userPos.latitude},${_userPos.longitude}'
        '&destination=${_providerPos.latitude},${_providerPos.longitude}'
        '&travelmode=driving';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          children: [
            // ── Real interactive map (OpenStreetMap tiles, free) ──────────
            FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 13.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.drag,
                ),
              ),
              children: [
                // OSM tile layer — no API key, completely free
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bulao.mobile',
                  maxZoom: 19,
                ),

                // Route line between user and provider
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userPos, _providerPos],
                      strokeWidth: 4.0,
                      color: const Color(0xFF1E2D4E),
                    ),
                  ],
                ),

                // Markers
                MarkerLayer(
                  markers: [
                    // User marker (blue)
                    Marker(
                      point: _userPos,
                      width: 40,
                      height: 50,
                      child: Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.person,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('You',
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),

                    // Provider marker (red/gold)
                    Marker(
                      point: _providerPos,
                      width: 50,
                      height: 58,
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A84C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.home_repair_service,
                                size: 16, color: Color(0xFF1E2D4E)),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A84C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Provider',
                                style: GoogleFonts.inter(
                                    fontSize: 8,
                                    color: const Color(0xFF1E2D4E),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // ── Top-left: Status pill ─────────────────────────────────────
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2D4E).withValues(alpha: 0.90),
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

            // ── Top-right: Open full maps button ─────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _openDirections,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions,
                          size: 14, color: Color(0xFF1976D2)),
                      const SizedBox(width: 4),
                      Text(
                        'Directions',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom-right: ETA badge ───────────────────────────────────
            if (etaMinutes != null && etaMinutes! > 0)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC9A84C),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: Color(0xFF1E2D4E)),
                      const SizedBox(width: 5),
                      Text(
                        'ETA ~$etaMinutes min',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E2D4E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
