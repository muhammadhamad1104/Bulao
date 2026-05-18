import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/processing_header.dart';
import 'widgets/transcript_card.dart';
import 'widgets/agent_progress_card.dart';
import 'models/processing_models.dart';
import 'provider_screen.dart';

/// Processing Screen — displays the 6-agent AI workflow after audio processing.
///
/// All mock data lives here in one place. To connect the backend:
///   1. Replace [_mockRequest] with STT/API response deserialized to
///      ProcessingRequestModel.
///   2. Replace [_mockAgents] with a stream/state that updates each
///      AgentProgressModel.status as the backend agents complete.
///   3. The widgets below need zero changes — they consume models via
///      constructors only.
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  Timer? _mockNavTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // ── MOCK TIMER: Auto-navigate to ProviderScreen after demo time ────────
    // Later, backend events/websockets will control this transition.
    _mockNavTimer = Timer(const Duration(milliseconds: 4500), () {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const ProviderScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mockNavTimer?.cancel();
    super.dispose();
  }

  // ── MOCK DATA — single source of truth ─────────────────────────────────────
  // Replace these with real API/STT data when backend is connected.

  static const ProcessingRequestModel _mockRequest = ProcessingRequestModel(
    transcript:
        'AC bilkul kaam nahi kar raha, kal subah G-13 mein technician chahiye',
    keywords: [
      'AC Repair',
      'G-13',
      'Technician',
      'Kal Subah',
      'AC Repair',
      'G-13',
    ],
  );

  static const List<AgentProgressModel> _mockAgents = [
    AgentProgressModel(
      agentName: 'Intent Agent',
      description: 'AC Repair . G-13 . Tomorrow . 9-11 AM',
      status: AgentStatus.completed,
      leftIconData: Icons.manage_search_rounded,
    ),
    AgentProgressModel(
      agentName: 'Discovery Agent',
      description: '8 providers found . 6 available tomorrow AM',
      status: AgentStatus.completed,
      leftIconData: Icons.travel_explore_rounded,
    ),
    AgentProgressModel(
      agentName: 'Ranking Agent',
      description:
          'Scoring Six Factors : Distance , rating , reliability.......',
      status: AgentStatus.active,
      leftIconData: Icons.leaderboard_rounded,
    ),
    AgentProgressModel(
      agentName: 'Pricing Agent',
      description: 'Waiting ....',
      status: AgentStatus.pending,
      leftIconData: Icons.local_offer_outlined,
    ),
    AgentProgressModel(
      agentName: 'Booking Agent',
      description: 'Waiting ......',
      status: AgentStatus.pending,
      leftIconData: Icons.inventory_2_outlined,
    ),
    AgentProgressModel(
      agentName: 'Follow-Up Agent',
      description: 'Waiting .......',
      status: AgentStatus.pending,
      leftIconData: Icons.shield_outlined,
    ),
  ];

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _goBack(BuildContext context) {
    _hasNavigated = true; // Prevent timer from firing if user goes back
    _mockNavTimer?.cancel();
    // ProcessingLoadingScreen used pushReplacement, so pop goes to HomeScreen.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // ── Bulao unified app background
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (back arrow + heading + underline + sparkle) ──────────
            ProcessingHeader(onBack: () => _goBack(context)),

            const SizedBox(height: 10),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Transcript card + keyword chips ──────────────────────
                    TranscriptCard(
                      transcript: _mockRequest.transcript,
                      keywords: _mockRequest.keywords,
                    ),

                    const SizedBox(height: 16),

                    // ── 6 Agent progress cards ───────────────────────────────
                    // Driven entirely by _mockAgents list.
                    // Swap list contents with live data when backend is ready.
                    ..._mockAgents.map(
                      (agent) => AgentProgressCard(agent: agent),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
