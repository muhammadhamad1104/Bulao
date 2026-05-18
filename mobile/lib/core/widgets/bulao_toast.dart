import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, info }

class BulaoToast {
  static void show(BuildContext context, {required String message, ToastType type = ToastType.info}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        bgColor = const Color(0xFFFAFAF7); // Bulao Cream
        iconColor = const Color(0xFF2E7D32); // Green
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = const Color(0xFFFAFAF7); // Bulao Cream
        iconColor = const Color(0xFFD32F2F); // Red
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.info:
        bgColor = const Color(0xFFFAFAF7); // Bulao Cream
        iconColor = const Color(0xFFC9A84C); // Bulao Gold
        iconData = Icons.info_outline_rounded;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: _ToastAnimation(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E2D4E).withValues(alpha: 0.1), // Soft navy shadow
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(iconData, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.ibmPlexSans(
                        color: const Color(0xFF0D0D0D),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ToastAnimation extends StatefulWidget {
  final Widget child;
  const _ToastAnimation({required this.child});

  @override
  State<_ToastAnimation> createState() => _ToastAnimationState();
}

class _ToastAnimationState extends State<_ToastAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    
    _controller.forward();
    
    // Reverse animation before removal
    Future.delayed(const Duration(milliseconds: 2700), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
