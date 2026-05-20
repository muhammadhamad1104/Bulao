import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/confirmed_booking_model.dart';

/// Card displaying the detailed booking receipt.
class BookingReceiptCard extends StatelessWidget {
  final ConfirmedBookingModel booking;

  const BookingReceiptCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8), // White/cream fill
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD9C9A8), // Thin gold border
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Receipt',
                    style: GoogleFonts.ibmPlexSansCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D0D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Small underline under title
                  Container(
                    height: 2,
                    width: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC9A84C), // Gold
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  booking.bookingId,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFFB8952A), // Gold text
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Receipt Rows ────────────────────────────────────────────────
          _ReceiptRow(label: 'Service', value: booking.service),
          _divider(),
          _ReceiptRow(
            label: 'Provider',
            valueWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  booking.providerName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded, size: 14, color: Color(0xFFC9A84C)),
                const SizedBox(width: 2),
                Text(
                  booking.providerRating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          _ReceiptRow(label: 'Time', value: booking.time),
          _divider(),
          _ReceiptRow(label: 'Location', value: booking.location),
          _divider(),
          
          // ── Total Row ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6B6B),
                ),
              ),
              Text(
                booking.total,
                style: GoogleFonts.ibmPlexSansCondensed(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB8952A), // Gold text
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        height: 1,
        color: const Color(0xFFE8DCC8), // Light gold/cream divider
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _ReceiptRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6B6B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: valueWidget ??
                (value != null
                    ? Text(
                        value!,
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF0D0D0D),
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
        ),
      ],
    );
  }
}
