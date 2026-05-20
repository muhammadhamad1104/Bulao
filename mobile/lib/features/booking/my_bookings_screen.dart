import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/orchestrate_models.dart';
import '../../core/services/api_service.dart';
import '../tracking/tracking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool _isLoading = true;
  List<Booking> _bookings = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final list = await ApiService.instance.getBookings(userId);
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _openWhatsApp(Booking booking) async {
    final url = booking.whatsappUrl ?? 
        'https://wa.me/?text=Assalam%20o%20Alaikum%2C%20I%20booked%20a%20${booking.serviceType}%20service%20via%20Bulao';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callProvider(Booking booking) async {
    final phone = booking.providerPhone ?? '03001234567';
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFD32F2F);
      case 'en_route':
      case 'arrived':
      case 'in_progress':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF1E2D4E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAF7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2D4E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Bookings',
          style: GoogleFonts.ibmPlexSansCondensed(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E2D4E),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        color: const Color(0xFFC9A84C),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC9A84C)),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFD32F2F)),
                          const SizedBox(height: 16),
                          Text(
                            'Bookings load nahi ho sakeen',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E2D4E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _fetchBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try Again'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2D4E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFD9C9A8)),
                            const SizedBox(height: 16),
                            Text(
                              'Abhi tak koi booking nahi hai',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E2D4E),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Apni pehli service abhi order karein!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          final providerName = booking.providerName ?? 
                              (booking.acceptedQuote.lineItems.isNotEmpty
                                  ? booking.acceptedQuote.lineItems[0].labelEnglish.split(' booked')[0]
                                  : 'Provider');

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF5EDD8), Color(0xFFEDE0C4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFD9C9A8), width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        booking.bookingId,
                                        style: GoogleFonts.ibmPlexSansCondensed(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1E2D4E),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          booking.status.toUpperCase().replaceAll('_', ' '),
                                          style: GoogleFonts.ibmPlexSansCondensed(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: _getStatusColor(booking.status),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    booking.serviceType.toUpperCase().replaceAll('_', ' '),
                                    style: GoogleFonts.ibmPlexSansCondensed(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0D0D0D),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    providerName,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E2D4E),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Location: ${booking.location}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF4A4A4A),
                                    ),
                                  ),
                                  Text(
                                    'Scheduled: ${booking.scheduledTime.contains('T') ? booking.scheduledTime.split('T')[0] : booking.scheduledTime}',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF6B6B6B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total Estimate:',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B6B6B),
                                        ),
                                      ),
                                      Text(
                                        'PKR ${booking.acceptedQuote.estimatedTotalPkr}',
                                        style: GoogleFonts.ibmPlexSansCondensed(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0D0D0D),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 1,
                                    color: const Color(0xFFD9C9A8).withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (booking.status.toLowerCase() != 'completed' &&
                                          booking.status.toLowerCase() != 'cancelled') ...[
                                        IconButton(
                                          icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF4CAF50)),
                                          onPressed: () => _callProvider(booking),
                                          tooltip: 'Call Provider',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF1E2D4E)),
                                          onPressed: () => _openWhatsApp(booking),
                                          tooltip: 'WhatsApp',
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) => TrackingScreen(
                                                  booking: booking,
                                                  providerName: providerName,
                                                  providerInitials: providerName.isNotEmpty
                                                      ? providerName.split(' ').map((e) => e[0]).join().toUpperCase()
                                                      : 'P',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.location_on_outlined, size: 16),
                                          label: const Text('Track'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E2D4E),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          'Booking Closed',
                                          style: GoogleFonts.ibmPlexSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
