import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Partial-fill golden star rating with numeric label.
/// Larger stars matching Provider.png reference.
class StarRatingDisplay extends StatelessWidget {
  final double rating;   // 0.0 – 5.0
  final double starSize;
  final Color fillColor;
  final Color emptyColor;

  const StarRatingDisplay({
    super.key,
    required this.rating,
    this.starSize = 20,                         // larger default to match reference
    this.fillColor = const Color(0xFFC9A84C),   // Bulao gold
    this.emptyColor = const Color(0xFFDDD0B0),  // warm light gold for empty
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final fill = (rating - i).clamp(0.0, 1.0);
          return SizedBox(
            width: starSize + 2,
            height: starSize,
            child: Stack(
              children: [
                Icon(Icons.star_rounded, size: starSize, color: emptyColor),
                ClipRect(
                  clipper: _WidthClipper(fill),
                  child: Icon(Icons.star_rounded, size: starSize, color: fillColor),
                ),
              ],
            ),
          );
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A4A),
          ),
        ),
      ],
    );
  }
}

class _WidthClipper extends CustomClipper<Rect> {
  final double fill;
  const _WidthClipper(this.fill);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width * fill, size.height);

  @override
  bool shouldReclip(_WidthClipper old) => old.fill != fill;
}
