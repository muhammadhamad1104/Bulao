import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/processing_models.dart';

/// Agent progress card — visual state driven entirely by [AgentProgressModel].
///
/// completed → light green bg, green border, green check icons
/// active    → warm cream bg, gold left accent bar, gold border, clock icon
/// pending   → white bg, grey border, grey icons and text
///
/// Backend integration:
///   When agent status updates arrive via websocket/API, update the
///   AgentProgressModel status and the card rebuilds automatically.
class AgentProgressCard extends StatelessWidget {
  final AgentProgressModel agent;

  const AgentProgressCard({super.key, required this.agent});

  // ── Resolved style properties per status ────────────────────────────────
  Color get _cardBg {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFFF4FBF5); // near-white pale green — success semantic without green tint on page
      case AgentStatus.active:
        return const Color(0xFFFFF8EE); // warm cream
      case AgentStatus.pending:
        return Colors.white;
    }
  }

  Color get _borderColor {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFF4CAF50); // green
      case AgentStatus.active:
        return const Color(0xFFC9A84C); // gold
      case AgentStatus.pending:
        return const Color(0xFFE0E0E0); // light grey
    }
  }

  Color get _iconBg {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFFD4F5DA); // light green
      case AgentStatus.active:
        return const Color(0xFFFFEDCC); // light gold
      case AgentStatus.pending:
        return const Color(0xFFF0F0F0); // light grey
    }
  }

  Color get _iconColor {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFF2E7D32); // dark green
      case AgentStatus.active:
        return const Color(0xFFC9A84C); // gold
      case AgentStatus.pending:
        return const Color(0xFFAAAAAA); // grey
    }
  }

  Color get _nameColor {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFF1A1A1A);
      case AgentStatus.active:
        return const Color(0xFF1A1A1A);
      case AgentStatus.pending:
        return const Color(0xFF8A8A8A);
    }
  }

  Color get _descColor {
    switch (agent.status) {
      case AgentStatus.completed:
        return const Color(0xFF4A4A4A);
      case AgentStatus.active:
        return const Color(0xFF5A5A5A);
      case AgentStatus.pending:
        return const Color(0xFFAAAAAA);
    }
  }

  // ── Left icon — check for completed, clock for active, original for pending ─
  IconData get _leftIcon {
    switch (agent.status) {
      case AgentStatus.completed:
        return Icons.check_circle_rounded;
      case AgentStatus.active:
        return Icons.access_time_rounded;
      case AgentStatus.pending:
        return agent.leftIconData as IconData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gold left accent bar (active only) ────────────────────────
              if (agent.status == AgentStatus.active)
                Container(
                  width: 4,
                  color: const Color(0xFFC9A84C),
                ),

              // ── Card content ───────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left icon circle
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _iconBg,
                        ),
                        child: Icon(
                          _leftIcon,
                          size: 20,
                          color: _iconColor,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Agent name + description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              agent.agentName,
                              style: GoogleFonts.ibmPlexSansCondensed(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _nameColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              agent.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _descColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right check icon (completed only)
                      if (agent.status == AgentStatus.completed)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
