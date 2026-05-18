import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/feedback_models.dart';
import 'widgets/rating_stars.dart';
import 'widgets/feedback_chip.dart';
import 'widgets/comment_box.dart';
import 'widgets/feedback_send_button.dart';
import '../../core/services/api_service.dart';

/// Screen allowing users to rate and review their completed service.
class FeedbackScreen extends StatefulWidget {
  final String bookingId;
  final String providerName;
  final String providerInitials;
  final String descriptionLabel;

  const FeedbackScreen({
    super.key,
    required this.bookingId,
    required this.providerName,
    required this.providerInitials,
    required this.descriptionLabel,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  
  // State for user input
  int _selectedRating = 0;
  final Set<String> _selectedTags = {};

  final List<String> _availableTags = [
    'On Time',
    'Professional',
    'Fair Price',
    'Friendly',
    'Clean Work',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitFeedback() async {
    // Hide keyboard
    FocusScope.of(context).unfocus();

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating before sending.')),
      );
      return;
    }

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
      final response = await ApiService.instance.submitRating(
        bookingId: widget.bookingId,
        rating: _selectedRating,
      );

      // Pop loading dialog
      if (mounted) Navigator.of(context).pop();

      final msg = response['message_urdu'] as String? ?? 'Feedback submitted. Thank you!';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );

        // Safely return to Home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Pop loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fail ho gaya: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // Unified background
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Bar: Back Arrow ────────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _goHome,
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

                const SizedBox(height: 16),

                // ── Header & Logo Row ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Rate Your\nExperience',
                      style: GoogleFonts.ibmPlexSansCondensed(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0D0D0D),
                        height: 1.15,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Image.asset(
                      'assets/images/feedback_logo.png',
                      width: 80, // Matches reference scale
                      fit: BoxFit.contain,
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // ── Provider Avatar & Info ─────────────────────────────────────
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1E2D4E),
                    ),
                    child: Center(
                      child: Text(
                        widget.providerInitials,
                        style: GoogleFonts.ibmPlexSansCondensed(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.providerName,
                    style: GoogleFonts.ibmPlexSansCondensed(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D0D),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    widget.descriptionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A95A8),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Star Rating Section ────────────────────────────────────────
                Center(
                  child: Text(
                    'How was your experience ?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF0D0D0D),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                RatingStars(
                  onRatingChanged: (rating) {
                    setState(() {
                      _selectedRating = rating;
                    });
                  },
                ),

                const SizedBox(height: 36),

                // ── What went well ? ───────────────────────────────────────────
                Text(
                  'What went well ?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0D0D0D),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _availableTags.map((tag) {
                    return FeedbackChip(
                      label: tag,
                      isSelected: _selectedTags.contains(tag),
                      onTap: () => _toggleTag(tag),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // ── Comment Box ────────────────────────────────────────────────
                CommentBox(controller: _commentController),

                const SizedBox(height: 32),
                
                // ── Send Button ────────────────────────────────────────────────
                FeedbackSendButton(onTap: _submitFeedback),
                
                const SizedBox(height: 32), // Bottom padding for scroll
              ],
            ),
          ),
        ),
      ),
    );
  }
}
