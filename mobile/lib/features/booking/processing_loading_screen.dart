import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/animated_audio_waveform.dart';
import 'processing_screen.dart';
import 'widgets/processing_header.dart';
import 'widgets/transcript_card.dart';
import 'widgets/agent_progress_card.dart';
import 'models/processing_models.dart';
import '../../core/services/api_service.dart';
import '../../core/models/orchestrate_models.dart';
import 'package:geolocator/geolocator.dart';

/// Processing Loading screen — shown after the user submits a request.
///
/// Flow:
///   HomeScreen (input dialog) → ProcessingLoadingScreen → ProcessingScreen
///
/// Simulates live progression of agents while waiting for the backend.
class ProcessingLoadingScreen extends StatefulWidget {
  final String requestText;
  final String userId;

  const ProcessingLoadingScreen({
    super.key,
    required this.requestText,
    this.userId = "anonymous",
  });

  @override
  State<ProcessingLoadingScreen> createState() =>
      _ProcessingLoadingScreenState();
}

class _ProcessingLoadingScreenState extends State<ProcessingLoadingScreen> {
  bool _hasNavigated = false;
  bool _showWaveform = true;
  String? _errorMessage;
  int _simulatedStage = 0;
  Timer? _timer;
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocationAndCallBackend();
      _startSimulation();
      
      _waveTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWaveform = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startSimulation() {
    // Stage 0: Intent working
    // Stage 1: Intent completed, Discovery working (after ~8s)
    // Stage 2: Discovery completed, Ranking working (after ~14s)
    _timer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (mounted && _simulatedStage < 2) {
        setState(() {
          _simulatedStage++;
        });
      }
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever.');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _fetchLocationAndCallBackend() async {
    List<double>? userLocation;
    try {
      final position = await _getCurrentLocation();
      if (position != null) {
        userLocation = [position.latitude, position.longitude];
        debugPrint('GPS Location fetched successfully: $userLocation');
      } else {
        debugPrint('GPS Location not available, using backend defaults.');
      }
    } catch (e) {
      debugPrint('Failed to resolve GPS coordinates: $e');
    }
    _callBackend(widget.requestText, userLocation);
  }

  Future<void> _callBackend(String text, List<double>? userLocation) async {
    try {
      final response = await ApiService.instance.orchestrate(
        text: text,
        userId: widget.userId,
        userLocation: userLocation,
      );
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      _navigateToProcessing(response);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.userFriendlyMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Kuch masla aa gaya. Dobara try karein.';
      });
    }
  }

  void _navigateToProcessing(OrchestrateResponse response) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProcessingScreen(response: response, originalText: widget.requestText),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  List<AgentProgressModel> _buildSimulatedAgents() {
    return [
      AgentProgressModel(
        agentName: 'Intent Agent',
        description: _errorMessage != null
            ? 'Error occurred'
            : _simulatedStage >= 1
                ? 'Intent extracted'
                : 'Analyzing request...',
        status: _errorMessage != null
            ? AgentStatus.pending
            : _simulatedStage >= 1
                ? AgentStatus.completed
                : AgentStatus.pending,
        leftIconData: Icons.manage_search_rounded,
      ),
      AgentProgressModel(
        agentName: 'Discovery Agent',
        description: _errorMessage != null
            ? 'Error occurred'
            : _simulatedStage >= 2
                ? 'Locating providers...'
                : _simulatedStage == 1
                    ? 'Searching area...'
                    : 'Waiting ...',
        status: AgentStatus.pending,
        leftIconData: Icons.travel_explore_rounded,
      ),
      AgentProgressModel(
        agentName: 'Ranking Agent',
        description: _errorMessage != null ? 'Error occurred' : 'Waiting ...',
        status: AgentStatus.pending,
        leftIconData: Icons.leaderboard_rounded,
      ),
      AgentProgressModel(
        agentName: 'Pricing Agent',
        description: _errorMessage != null ? 'Error occurred' : 'Waiting ....',
        status: AgentStatus.pending,
        leftIconData: Icons.local_offer_outlined,
      ),
      AgentProgressModel(
        agentName: 'Booking Agent',
        description: _errorMessage != null ? 'Error occurred' : 'Waiting ......',
        status: AgentStatus.pending,
        leftIconData: Icons.inventory_2_outlined,
      ),
      AgentProgressModel(
        agentName: 'Follow-Up Agent',
        description: _errorMessage != null ? 'Error occurred' : 'Waiting .......',
        status: AgentStatus.pending,
        leftIconData: Icons.shield_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_showWaveform && _errorMessage == null) {
      return _buildWaveformScreen(context);
    }
    return _buildAgentsScreen(context);
  }

  Widget _buildWaveformScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.85,
              height: size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 0.80,
                  colors: [
                    const Color(0xFFD4A84B).withValues(alpha: 0.28),
                    const Color(0xFFE8C97A).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.85,
              height: size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width),
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 0.80,
                  colors: [
                    const Color(0xFF7A9EC8).withValues(alpha: 0.32),
                    const Color(0xFFB8CCEC).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFFE1E5ED),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF5A6B87),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Processing Your Service .....',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D0D0D),
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    widget.requestText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      color: const Color(0xFF9AA5B8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.09),
                const AnimatedAudioWaveform(
                  barCount: 19,
                  maxBarHeight: 130,
                  barWidth: 9,
                  barSpacing: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentsScreen(BuildContext context) {
    final agents = _buildSimulatedAgents();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7),
      body: SafeArea(
        child: Column(
          children: [
            ProcessingHeader(onBack: _goBack),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    TranscriptCard(
                      transcript: widget.requestText,
                      keywords: const [], // Empty keywords while simulating
                    ),
                    const SizedBox(height: 16),
                    ...agents.map((agent) => AgentProgressCard(agent: agent)),
                    const SizedBox(height: 24),
                    
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            color: Colors.redAccent,
                            fontSize: 16,
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
