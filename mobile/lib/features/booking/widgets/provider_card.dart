import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provider_models.dart';
import 'ranking_factors_panel.dart';
import 'star_rating_display.dart';
import '../confirmed_booking_screen.dart';
import '../../../core/models/orchestrate_models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_booking_store.dart';

/// Expandable provider card — data driven by [ProviderModel].
///
/// Layout decisions (crash-safe):
///   • Gold left accent uses Stack + Positioned (no Row stretch, no non-uniform border).
///   • Main card Container uses uniform border only — Flutter requires this with borderRadius.
///   • AnimatedSize wraps the ranking panel only — never the full card.
///   • All Row children use Expanded or fixed widths — no unconstrained text.
class ProviderCard extends StatefulWidget {
  final ProviderModel provider;
  final OrchestrateResponse response;
  const ProviderCard({
    super.key,
    required this.provider,
    required this.response,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.provider.isBestMatch;
  }

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  Future<void> _confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? 'anonymous';
    final userName = user?.displayName ?? 'User';

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
        ),
      ),
    );

    try {
      ProviderCandidate? selectedCandidate;
      final candidates = widget.response.discovery?.candidates ?? [];
      final alternates = widget.response.discovery?.alternates ?? [];
      for (var c in candidates) {
        if (c.id == widget.provider.id) {
          selectedCandidate = c;
          break;
        }
      }
      if (selectedCandidate == null) {
        for (var c in alternates) {
          if (c.id == widget.provider.id) {
            selectedCandidate = c;
            break;
          }
        }
      }

      final booking = await ApiService.instance.book(
        quoteId: widget.response.pricing?.quoteId ?? 'quote_001',
        userId: userId,
        userName: userName,
        intent: widget.response.intent,
        providerId: widget.provider.id,
        provider: selectedCandidate,
        acceptedQuote: widget.response.pricing ?? PriceQuote(
          quoteId: 'quote_001',
          subtotalPkr: 0,
          estimatedTotalPkr: 0,
          explanationEnglish: '',
          explanationUrdu: '',
          fairnessNote: '',
          expiresAt: DateTime.now().toIso8601String(),
        ),
      );

      // ── Save to local store so drawer tracking works immediately ─────────
      await LocalBookingStore.instance.save(booking);

      // Pop loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, a, __) => ConfirmedBookingScreen(
              booking: booking,
              providerName: widget.provider.name,
              providerRating: widget.provider.rating,
            ),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }

    } catch (e) {
      // Pop loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking fail ho gayi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final p = widget.provider;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Summary card ────────────────────────────────────────────────────
          Stack(
            children: [
              // Main rounded card — uniform border required by Flutter with borderRadius
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5EDD8), Color(0xFFEDE0C4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD9C9A8), // uniform — same color all sides
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  // Left padding larger to clear the gold accent bar
                  padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Provider info row ──────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Gold rank badge
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9A84C),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Center(
                              child: Text(
                                '${p.rank}',
                                style: GoogleFonts.ibmPlexSansCondensed(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Navy initials circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E2D4E),
                            ),
                            child: Center(
                              child: Text(
                                p.initials,
                                style: GoogleFonts.ibmPlexSansCondensed(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Name + subtitle — Expanded prevents horizontal overflow
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexSansCondensed(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0D0D0D),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${p.serviceTitle} . ${p.experience}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B6B6B),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Price — always on right, not in Expanded
                          Text(
                            p.price,
                            style: GoogleFonts.ibmPlexSansCondensed(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0D0D0D),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Stars — indented to align under name
                      Padding(
                        padding: const EdgeInsets.only(left: 54),
                        child: StarRatingDisplay(rating: p.rating),
                      ),

                      const SizedBox(height: 12),

                      // Thin divider
                      Container(
                        height: 1,
                        color: const Color(0xFFD4C4A0).withValues(alpha: 0.6),
                      ),

                      const SizedBox(height: 8),

                      // Tap To Expand / Collapse toggle
                      GestureDetector(
                        onTap: _toggle,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tap To Expand',
                              style: GoogleFonts.ibmPlexSansCondensed(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFB8952A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFFB8952A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gold left accent bar — Stack/Positioned avoids Row-stretch AND
              // avoids non-uniform border. Both previous crash causes eliminated.
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC9A84C), Color(0xFFE0BB6A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          // ── Ranking factors panel (animated, separate white card) ──────────
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                      border: Border.all(
                        color: const Color(0xFFD9C9A8), // uniform — same color all sides
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RankingFactorsPanel(factors: p.factors),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _confirmBooking,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF8A9BB5).withValues(alpha: 0.90),
                                    const Color(0xFF6B7E9A).withValues(alpha: 0.95),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6B7E9A)
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Confirm Booking',
                                style: GoogleFonts.ibmPlexSansCondensed(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
