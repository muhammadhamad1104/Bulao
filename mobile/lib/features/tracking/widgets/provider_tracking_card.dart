import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/tracking_models.dart';

/// Card showing the provider's current status and a contact button.
class ProviderTrackingCard extends StatelessWidget {
  final TrackingModel model;

  const ProviderTrackingCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9C9A8), width: 1.0), // Thin gold
      ),
      child: Row(
        children: [
          // Navy initials circle
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E2D4E),
            ),
            child: Center(
              child: Text(
                model.providerInitials,
                style: GoogleFonts.ibmPlexSansCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Name & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model.providerName,
                  style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  model.statusText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF4CAF50), // Green en-route text
                  ),
                ),
              ],
            ),
          ),
          
          // Green Phone Button
          GestureDetector(
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: model.phoneNumber);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Call function not supported on this device'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFDDE3CE), // Light green circle
              ),
              child: const Icon(
                Icons.phone_in_talk,
                color: Color(0xFF4CAF50), // Green icon
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
