import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real interactive Google Map showing provider and user locations.
/// Shows a styled placeholder if the map is blank (API key not enabled).
class MapPreviewCard extends StatefulWidget {
  final String status;
  final double? providerLat;
  final double? providerLng;
  final double? userLat;
  final double? userLng;

  const MapPreviewCard({
    super.key,
    required this.status,
    this.providerLat,
    this.providerLng,
    this.userLat,
    this.userLng,
  });

  @override
  State<MapPreviewCard> createState() => _MapPreviewCardState();
}

class _MapPreviewCardState extends State<MapPreviewCard> {
  GoogleMapController? _controller;
  // Start with fallback visible; hide it once map renders tiles
  bool _showFallback = true;

  static const LatLng _defaultCenter = LatLng(33.595, 73.048);

  LatLng get _providerPos =>
      widget.providerLat != null && widget.providerLng != null
          ? LatLng(widget.providerLat!, widget.providerLng!)
          : const LatLng(33.601, 73.055);

  LatLng get _userPos =>
      widget.userLat != null && widget.userLng != null
          ? LatLng(widget.userLat!, widget.userLng!)
          : _defaultCenter;

  LatLng get _mapCenter => LatLng(
        (_providerPos.latitude + _userPos.latitude) / 2,
        (_providerPos.longitude + _userPos.longitude) / 2,
      );

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('user'),
          position: _userPos,
          infoWindow: const InfoWindow(title: 'You'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
        Marker(
          markerId: const MarkerId('provider'),
          position: _providerPos,
          infoWindow: const InfoWindow(title: 'Provider'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };

  String get _statusLabel {
    switch (widget.status) {
      case 'en_route':
        return 'Provider is on the way';
      case 'arrived':
        return 'Provider has arrived';
      case 'in_progress':
        return 'Service in progress';
      case 'completed':
        return 'Service completed';
      default:
        return 'Tracking your booking';
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
            // ── Real Google Map ─────────────────────────────────────────────
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _mapCenter, zoom: 13.5),
              markers: _markers,
              onMapCreated: (controller) {
                _controller = controller;
                _controller?.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    LatLngBounds(
                      southwest: LatLng(
                        _providerPos.latitude < _userPos.latitude
                            ? _providerPos.latitude
                            : _userPos.latitude,
                        _providerPos.longitude < _userPos.longitude
                            ? _providerPos.longitude
                            : _userPos.longitude,
                      ),
                      northeast: LatLng(
                        _providerPos.latitude > _userPos.latitude
                            ? _providerPos.latitude
                            : _userPos.latitude,
                        _providerPos.longitude > _userPos.longitude
                            ? _providerPos.longitude
                            : _userPos.longitude,
                      ),
                    ),
                    60.0,
                  ),
                );
              },
              // When the camera moves, tiles have loaded — hide fallback
              onCameraMove: (_) {
                if (_showFallback && mounted) {
                  setState(() => _showFallback = false);
                }
              },
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // ── Fallback overlay — shown until real tiles appear ─────────────
            if (_showFallback)
              Container(
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
                    const SizedBox(height: 12),
                    Text(
                      _statusLabel,
                      style: GoogleFonts.ibmPlexSansCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Islamabad / Rawalpindi',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legend(const Color(0xFF64B5F6), 'You'),
                        const SizedBox(width: 24),
                        _legend(const Color(0xFFC9A84C), 'Provider'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Loading map...',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
        ],
      );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
