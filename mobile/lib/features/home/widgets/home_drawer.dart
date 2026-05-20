import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/widgets/bulao_toast.dart';
import '../../tracking/tracking_screen.dart';
import '../../auth/auth_gate.dart';
import '../../booking/my_bookings_screen.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/local_booking_store.dart';
import '../../../core/models/orchestrate_models.dart';

/// Side drawer for the HomeScreen.
/// Provides navigation to Live Tracking, My Bookings, and Logout.
class HomeDrawer extends StatelessWidget {
  final String userName;
  
  // Backend-ready flag: controls tracking navigation logic.
  // Defaults to true for UI demonstration purposes.
  final bool hasActiveBooking;

  const HomeDrawer({
    super.key,
    required this.userName,
    this.hasActiveBooking = true, 
  });

  void _showComingSoon(BuildContext context, String message) {
    BulaoToast.show(context, message: message, type: ToastType.info);
  }

  void _navigateToTracking(BuildContext context) async {
    // Show a small loader in a dialog
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
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';

      // First check in-memory local store (instant, works even offline)
      Booking? activeBooking = LocalBookingStore.instance.firstActive;

      // Then try the backend (may have more bookings from previous sessions)
      if (activeBooking == null) {
        try {
          final bookings = await ApiService.instance.getBookings(userId);
          for (var b in bookings) {
            final status = b.status.toLowerCase();
            if (status == 'confirmed' || status == 'en_route' || status == 'arrived' || status == 'in_progress') {
              activeBooking = b;
              break;
            }
          }
        } catch (_) {
          // Backend unavailable — local store already checked above
        }
      }
      
      // Pop loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        if (activeBooking != null) {
          Navigator.of(context).pop(); // Close drawer
          final providerName = activeBooking.providerName ?? 
              (activeBooking.acceptedQuote.lineItems.isNotEmpty
                  ? activeBooking.acceptedQuote.lineItems[0].labelEnglish.split(' booked')[0]
                  : 'Provider');
          final initials = providerName.isNotEmpty
              ? providerName.split(' ').map((e) => e[0]).join().toUpperCase()
              : 'P';
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TrackingScreen(
                booking: activeBooking!,
                providerName: providerName,
                providerInitials: initials,
              ),
            ),
          );
        } else {
          Navigator.of(context).pop(); // Close drawer
          _showComingSoon(context, 'Live Tracking is available after booking');
        }
      }
    } catch (e) {
      // Pop loading dialog
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        Navigator.of(context).pop(); // Close drawer
        _showComingSoon(context, 'Masla aa gaya: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFAFAF7), // Unified Bulao background
      child: Column(
        children: [
          // ── Drawer Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFEBE3D0).withValues(alpha: 0.6),
                  const Color(0xFFFAFAF7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bulao',
                  style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2D4E), // Navy
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'bolo, aur kaam ho jaye',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFB8952A), // Gold
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Hey $userName,',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
              ],
            ),
          ),
          
          // ── Divider ─────────────────────────────────────────────────────
          Divider(
            color: const Color(0xFFD9C9A8).withValues(alpha: 0.5),
            height: 1,
            thickness: 1,
            indent: 24,
            endIndent: 24,
          ),

          const SizedBox(height: 16),

          // ── Menu Items ──────────────────────────────────────────────────
          _DrawerItem(
            icon: Icons.location_on_outlined,
            title: 'Live Tracking',
            onTap: () => _navigateToTracking(context),
          ),
          
          _DrawerItem(
            icon: Icons.receipt_long_rounded,
            title: 'My Bookings',
            onTap: () {
              Navigator.of(context).pop(); // Close drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),

          const Spacer(),

          // ── Logout ──────────────────────────────────────────────────────
          Divider(
            color: const Color(0xFFD9C9A8).withValues(alpha: 0.5),
            height: 1,
            thickness: 1,
          ),
          _DrawerItem(
            icon: Icons.logout_rounded,
            title: 'Logout',
            textColor: const Color(0xFFD32F2F),
            iconColor: const Color(0xFFD32F2F),
            onTap: () async {
              Navigator.of(context).pop();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                BulaoToast.show(context, message: 'You are logged out successfully', type: ToastType.success);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(
        icon,
        size: 26,
        color: iconColor ?? const Color(0xFF1E2D4E),
      ),
      title: Text(
        title,
        style: GoogleFonts.ibmPlexSans(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: textColor ?? const Color(0xFF0D0D0D),
        ),
      ),
      onTap: onTap,
      splashColor: const Color(0xFFC9A84C).withValues(alpha: 0.1),
    );
  }
}
