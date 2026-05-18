/// Data models for the ProcessingScreen.
///
/// Backend integration:
///   Replace the mock static data in ProcessingScreen with API responses
///   that deserialize into these models. The widgets only consume these
///   models via constructors, so the UI layer needs zero changes.

// ── Agent status enum ──────────────────────────────────────────────────────
enum AgentStatus {
  /// Agent has finished successfully.
  completed,

  /// Agent is currently running.
  active,

  /// Agent is waiting for a previous agent to finish.
  pending,
}

// ── Voice/STT request model ────────────────────────────────────────────────
class ProcessingRequestModel {
  /// Raw transcript returned by STT engine.
  /// MOCK: hardcoded for now. Replace with actual STT result.
  final String transcript;

  /// Keyword chips extracted from transcript (by Intent Agent or NLP).
  /// MOCK: hardcoded for now. Replace with backend keyword extraction result.
  final List<String> keywords;

  const ProcessingRequestModel({
    required this.transcript,
    required this.keywords,
  });
}

// ── Per-agent progress model ───────────────────────────────────────────────
class AgentProgressModel {
  /// Display name of the agent.
  final String agentName;

  /// Short description / result line shown below the name.
  /// MOCK: hardcoded for now. Replace with backend agent result text.
  final String description;

  /// Current status driving card styling.
  final AgentStatus status;

  /// Material icon shown in the agent's left icon circle.
  /// Each agent has a distinct icon type matching the reference.
  final dynamic leftIconData; // IconData — kept dynamic for easy JSON mapping later

  const AgentProgressModel({
    required this.agentName,
    required this.description,
    required this.status,
    required this.leftIconData,
  });
}
