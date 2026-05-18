import 'package:flutter/material.dart';

/// Interactive 5-star rating widget.
class RatingStars extends StatefulWidget {
  final ValueChanged<int> onRatingChanged;
  
  const RatingStars({super.key, required this.onRatingChanged});

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  int _currentRating = 0;

  void _setRating(int rating) {
    setState(() {
      _currentRating = rating;
    });
    widget.onRatingChanged(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = starValue <= _currentRating;
        
        return GestureDetector(
          onTap: () => _setRating(starValue),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.star_rounded,
              size: 42,
              color: isSelected 
                  ? const Color(0xFFC9A84C) // Gold
                  : const Color(0xFFE2E2E2), // Light grey matching reference
            ),
          ),
        );
      }),
    );
  }
}
