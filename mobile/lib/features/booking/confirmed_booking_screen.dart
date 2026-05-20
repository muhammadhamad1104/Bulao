import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/confirmed_booking_model.dart';
import 'widgets/confirmation_message_bubble.dart';
import 'widgets/booking_receipt_card.dart';
import 'widgets/booking_action_button.dart';
import '../tracking/tracking_screen.dart';
import '../../core/models/orchestrate_models.dart';

/// Confirmed Booking Screen
///
/// Displays the confirmation message, receipt, and action buttons.
/// Data is driven by [ConfirmedBookingModel].
class ConfirmedBookingScreen extends StatelessWidget {
  final Booking booking;
  final String providerName;
  final double providerRating;

  const ConfirmedBookingScreen({
    super.key,
    required this.booking,
    required this.providerName,
    required this.providerRating,
  });

  void _goBack(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openWhatsApp(BuildContext context) async {
    // Use backend-generated pre-filled WhatsApp URL if available
    final url = booking.whatsappUrl ?? 
        'https://wa.me/?text=Assalam%20o%20Alaikum%2C%20I%20booked%20a%20${booking.serviceType}%20service%20via%20Bulao';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp nahi mila. Please manually contact provider.',
                style: GoogleFonts.ibmPlexSans(color: Colors.white)),
            backgroundColor: const Color(0xFF2A3A5E),
          ),
        );
      }
    }
  }

  void _callProvider(BuildContext context) async {
    final phone = booking.providerPhone ?? '03001234567';
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _navigateToTracking(BuildContext context) {
    String initials(String name) => name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('').toUpperCase();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => TrackingScreen(
          booking: booking,
          providerName: providerName,
          providerInitials: initials(providerName),
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    String humanize(String s) => s.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    String formatPkr(int pkr) => pkr.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
    String humanizeTime(String time) {
      if (!time.contains('T')) return time;
      try {
        final dt = DateTime.parse(time);
        return '${dt.day}/${dt.month} · ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return time;
      }
    }

    final uiBooking = ConfirmedBookingModel(
      bookingId: booking.bookingId,
      shortBookingId: booking.bookingId.length > 7
          ? booking.bookingId.substring(booking.bookingId.length - 7)
          : booking.bookingId,
      providerName: providerName,
      providerRating: providerRating,
      service: humanize(booking.serviceType),
      time: humanizeTime(booking.scheduledTime),
      location: booking.location,
      total: 'PKR ${formatPkr(booking.acceptedQuote.estimatedTotalPkr)}',
      confirmationMessage: booking.confirmationMessageUrdu.isNotEmpty
          ? booking.confirmationMessageUrdu
          : booking.confirmationMessageEnglish,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // Bulao unified background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Bar: Back Arrow ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => _goBack(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.70),
                        border: Border.all(
                          color: const Color(0xFFD8D8D8),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF3A3A3A),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Confirmation Logo ────────────────────────────────────────
                Center(
                  child: Image.asset(
                    'assets/images/confirm_book_logo.png',
                    width: 140, // Match reference size
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                // ── Heading ──────────────────────────────────────────────────
                Center(
                  child: Text(
                    'Booking Confirmed !',
                    style: GoogleFonts.ibmPlexSansCondensed(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D0D),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Confirmation Message Bubble ──────────────────────────────
                ConfirmationMessageBubble(message: uiBooking.confirmationMessage),

                const SizedBox(height: 24),

                // ── Booking Receipt Card ─────────────────────────────────────
                BookingReceiptCard(booking: uiBooking),

                const SizedBox(height: 32),

                // ── Action Buttons (Call, WhatsApp, Track) ──────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BookingActionButton(
                      icon: Icons.call_rounded,
                      label: 'Call',
                      onTap: () => _callProvider(context),
                    ),
                    const SizedBox(width: 16),
                    BookingActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      onTap: () => _openWhatsApp(context),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Track Button (Centered below) ───────────────────────────
                Center(
                  child: BookingActionButton(
                    icon: Icons.location_on_outlined,
                    label: 'Track',
                    onTap: () => _navigateToTracking(context),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
