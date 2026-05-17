import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/confirmed_booking_model.dart';
import 'widgets/confirmation_message_bubble.dart';
import 'widgets/booking_receipt_card.dart';
import 'widgets/booking_action_button.dart';
import '../tracking/tracking_screen.dart';

/// Confirmed Booking Screen
///
/// Displays the confirmation message, receipt, and action buttons.
/// Data is driven by [ConfirmedBookingModel].
class ConfirmedBookingScreen extends StatelessWidget {
  const ConfirmedBookingScreen({super.key});

  void _goBack(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToTracking(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const TrackingScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = ConfirmedBookingModel.mockData;

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
                ConfirmationMessageBubble(message: booking.confirmationMessage),

                const SizedBox(height: 24),

                // ── Booking Receipt Card ─────────────────────────────────────
                BookingReceiptCard(booking: booking),

                const SizedBox(height: 32),

                // ── Action Buttons (Calendar & WhatsApp) ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BookingActionButton(
                      icon: Icons.calendar_month_outlined,
                      label: 'Calendar',
                      onTap: () => _showComingSoon(
                          context, 'Calendar integration will be connected later'),
                    ),
                    const SizedBox(width: 16),
                    BookingActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      onTap: () => _showComingSoon(
                          context, 'WhatsApp sharing will be connected later'),
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
