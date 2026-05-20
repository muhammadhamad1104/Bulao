import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Real interactive Google Map showing provider and user locations.
/// Falls back to a styled placeholder if lat/lng not available.
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

  // Default center: Saddar Rawalpindi
  static const LatLng _defaultCenter = LatLng(33.595, 73.048);

  LatLng get _providerPos => widget.providerLat != null && widget.providerLng != null
      ? LatLng(widget.providerLat!, widget.providerLng!)
      : const LatLng(33.601, 73.055); // slightly offset as placeholder

  LatLng get _userPos => widget.userLat != null && widget.userLng != null
      ? LatLng(widget.userLat!, widget.userLng!)
      : _defaultCenter;

  LatLng get _mapCenter {
    // Center between provider and user
    return LatLng(
      (_providerPos.latitude + _userPos.latitude) / 2,
      (_providerPos.longitude + _userPos.longitude) / 2,
    );
  }

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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _mapCenter,
            zoom: 13.5,
          ),
          markers: _markers,
          onMapCreated: (controller) {
            _controller = controller;
            // Auto-fit bounds to show both markers
            _controller?.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    _providerPos.latitude < _userPos.latitude ? _providerPos.latitude : _userPos.latitude,
                    _providerPos.longitude < _userPos.longitude ? _providerPos.longitude : _userPos.longitude,
                  ),
                  northeast: LatLng(
                    _providerPos.latitude > _userPos.latitude ? _providerPos.latitude : _userPos.latitude,
                    _providerPos.longitude > _userPos.longitude ? _providerPos.longitude : _userPos.longitude,
                  ),
                ),
                60.0, // padding in pixels
              ),
            );
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
