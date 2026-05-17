import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/provider_models.dart';

/// A single ranking factor row with alternating navy/green progress bars
/// exactly matching the Provider.png reference.
class RankingFactorsPanel extends StatelessWidget {
  final List<RankingFactorModel> factors;

  const RankingFactorsPanel({super.key, required this.factors});

  // Alternating colors: navy for odd rows, green for even — matching reference
  static const List<Color> _barColors = [
    Color(0xFF2A3A5E), // navy
    Color(0xFF4CAF50), // green
    Color(0xFF2A3A5E),
    Color(0xFF4CAF50),
    Color(0xFF2A3A5E),
    Color(0xFF4CAF50),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ranking Factors',
          style: GoogleFonts.ibmPlexSansCondensed(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(factors.length, (i) {
          final f = factors[i];
          final barColor = _barColors[i % _barColors.length];
          return _FactorRow(factor: f, barColor: barColor);
        }),
      ],
    );
  }
}

class _FactorRow extends StatelessWidget {
  final RankingFactorModel factor;
  final Color barColor;

  const _FactorRow({required this.factor, required this.barColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Label — fixed width
          SizedBox(
            width: 96,
            child: Text(
              factor.label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6A6A6A),
              ),
            ),
          ),

          // Progress bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: factor.progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE4E4E4),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Value — fixed width, right-aligned
          SizedBox(
            width: 44,
            child: Text(
              factor.valueString,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
