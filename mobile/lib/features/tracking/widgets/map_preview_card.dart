import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Google Maps card for the Tracking Screen.
/// Shows a styled status overlay until the map renders real tiles.
/// If tiles never appear (API key not configured), the overlay stays visible.
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
  // Overlay is shown until map reports camera idle after our initial animation
  bool _showOverlay = true;
  Timer? _fallbackTimer;

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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      };

  String get _statusLabel {
    switch (widget.status) {
      case 'en_route':  return 'Provider is on the way';
      case 'arrived':   return 'Provider has arrived';
      case 'in_progress': return 'Service in progress';
      case 'completed': return 'Service completed';
      default:          return 'Tracking your booking';
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    // Animate to show both markers. onCameraIdle fires AFTER this animation
    // settles — only then do we reveal the map (hiding the overlay).
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
  }

  // onCameraIdle fires after EVERY animation settles — both our programmatic
  // animateCamera AND tile-loading-triggered redraws. By the time idle fires
  // after our initial animation, tiles should be rendering (or not).
  void _onCameraIdle() {
    if (_showOverlay && mounted) {
      setState(() => _showOverlay = false);
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
            // ── Real Google Map (always in tree so it initializes) ──────────
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _mapCenter, zoom: 13.5),
              markers: _markers,
              onMapCreated: _onMapCreated,
              onCameraIdle: _onCameraIdle,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),

            // ── Status overlay — hides after camera settles ─────────────────
            if (_showOverlay)
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
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFC9A84C)),
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
}
