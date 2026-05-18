import 'package:flutter/material.dart';
import 'widgets/processing_header.dart';
import 'widgets/transcript_card.dart';
import 'widgets/agent_progress_card.dart';
import 'models/processing_models.dart';
import 'provider_screen.dart';
import '../../core/models/orchestrate_models.dart';

/// Processing Screen — displays the 6-agent AI workflow result.
///
/// Backend wiring:
///   Receives a real [OrchestrateResponse] from [ProcessingLoadingScreen].
///   Maps agent data to [AgentProgressModel] list for the UI.
///   Passes [discovery.candidates], [ranking], and [pricing] to [ProviderScreen].
///
///   Widget layer needs zero changes — it consumes models via constructors.
class ProcessingScreen extends StatelessWidget {
  final OrchestrateResponse response;

  const ProcessingScreen({super.key, required this.response});

  // ── Map backend OrchestrateResponse → UI models ──────────────────────────

  ProcessingRequestModel _buildRequestModel() {
    final intent = response.intent;
    final keywords = <String>[
      _humanize(intent.serviceType),
      if (intent.location != null && intent.location!.isNotEmpty)
        intent.location!,
      if (intent.timeWindow.isNotEmpty) _humanizeWindow(intent.timeWindow),
      _humanize(intent.urgency),
      if (intent.specializationHint != null) intent.specializationHint!,
    ];

    // Build a human-readable transcript from intent fields
    final transcript = response.intent.rawNotes?.isNotEmpty == true
        ? response.intent.rawNotes!
        : '${_humanize(intent.serviceType)} — ${intent.location ?? intent.city} — '
            '${_humanizeWindow(intent.timeWindow)}';

    return ProcessingRequestModel(
      transcript: transcript,
      keywords: keywords.where((k) => k.isNotEmpty).take(6).toList(),
    );
  }

  List<AgentProgressModel> _buildAgents() {
    final intent = response.intent;
    final discovery = response.discovery;
    final ranking = response.ranking;
    final pricing = response.pricing;

    return [
      AgentProgressModel(
        agentName: 'Intent Agent',
        description:
            '${_humanize(intent.serviceType)} · ${intent.location ?? intent.city}'
            ' · ${_humanizeWindow(intent.timeWindow)}'
            ' · ${(intent.confidence * 100).toStringAsFixed(0)}% confidence',
        status: AgentStatus.completed,
        leftIconData: Icons.manage_search_rounded,
      ),
      AgentProgressModel(
        agentName: 'Discovery Agent',
        description: discovery != null
            ? '${discovery.candidates.length} providers found'
                '${discovery.alternates.isNotEmpty ? " · ${discovery.alternates.length} alternates" : ""}'
            : response.needsClarification
                ? 'Clarification needed'
                : 'No providers found',
        status: discovery != null && discovery.candidates.isNotEmpty
            ? AgentStatus.completed
            : AgentStatus.pending,
        leftIconData: Icons.travel_explore_rounded,
      ),
      AgentProgressModel(
        agentName: 'Ranking Agent',
        description: ranking != null
            ? 'Top pick: ${_topProviderName()} · ${ranking.confidence} confidence'
            : 'Waiting ...',
        status: ranking != null ? AgentStatus.completed : AgentStatus.pending,
        leftIconData: Icons.leaderboard_rounded,
      ),
      AgentProgressModel(
        agentName: 'Pricing Agent',
        description: pricing != null
            ? 'PKR ${pricing.estimatedTotalPkr.toString().replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+$)'),
                  (m) => '${m[1]},',
                )} estimated'
            : 'Waiting ....',
        status: pricing != null ? AgentStatus.completed : AgentStatus.pending,
        leftIconData: Icons.local_offer_outlined,
      ),
      AgentProgressModel(
        agentName: 'Booking Agent',
        description: response.bookingPreview != null
            ? 'Slot reserved · pending confirmation'
            : 'Waiting ......',
        status: response.bookingPreview != null
            ? AgentStatus.completed
            : AgentStatus.pending,
        leftIconData: Icons.inventory_2_outlined,
      ),
      AgentProgressModel(
        agentName: 'Follow-Up Agent',
        description: response.followupPlanned != null
            ? 'Reminders scheduled'
            : 'Waiting .......',
        status: response.followupPlanned != null
            ? AgentStatus.completed
            : AgentStatus.pending,
        leftIconData: Icons.shield_outlined,
      ),
    ];
  }

  /// Returns the name of the top-ranked provider, or a fallback.
  String _topProviderName() {
    final ranking = response.ranking;
    final discovery = response.discovery;
    if (ranking == null || discovery == null) return 'N/A';
    final id = ranking.recommendedId;
    if (id == null) return 'N/A';
    try {
      return discovery.candidates.firstWhere((c) => c.id == id).name;
    } catch (_) {
      return discovery.candidates.isNotEmpty
          ? discovery.candidates.first.name
          : 'N/A';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _humanize(String s) =>
      s.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty
          ? ''
          : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  static String _humanizeWindow(String window) {
    switch (window) {
      case 'now': return 'Right Now';
      case 'tomorrow_morning': return 'Tomorrow Morning';
      case 'this_friday': return 'This Friday';
      case 'flexible': return 'Flexible';
      default: return _humanize(window);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _goToProviders(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ProviderScreen(response: response),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = _buildRequestModel();
    final agents = _buildAgents();
    final hasProviders = (response.discovery?.candidates.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            ProcessingHeader(onBack: () => _goBack(context)),

            const SizedBox(height: 10),

            // ── Scrollable body ──────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // ── Transcript card ──────────────────────────────────────
                    TranscriptCard(
                      transcript: request.transcript,
                      keywords: request.keywords,
                    ),

                    const SizedBox(height: 16),

                    // ── 6 Agent progress cards ───────────────────────────────
                    ...agents.map(
                      (agent) => AgentProgressCard(agent: agent),
                    ),

                    const SizedBox(height: 24),

                    // ── Continue button if providers are available ────────────
                    if (hasProviders)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _goToProviders(context),
                            icon: const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white),
                            label: const Text('See Providers',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A3A5E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
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
