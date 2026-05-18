import 'package:flutter/material.dart';

/// A dynamic visual placeholder for the map.
/// Animates pin positions based on tracking status.
class MapPreviewCard extends StatelessWidget {
  final String status;

  const MapPreviewCard({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBE1), // Light cream map base
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8), // Glassy border
          width: 4.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          // Inner subtle shadow to match reference depth
          BoxShadow(
            color: const Color(0xFFD9C9A8).withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _MockMapPainter(),
          child: _buildPins(context),
        ),
      ),
    );
  }

  Widget _buildPins(BuildContext context) {
    // Default positions (Coordinates on our custom paint canvas)
    double userTop = 160;
    double userLeft = 50;
    
    double providerTop = 40;
    double providerLeft = 250;
    
    // Move provider pin based on status
    if (status == 'en_route') {
      providerTop = 100;
      providerLeft = 150;
    } else if (status == 'arrived' || status == 'in_progress' || status == 'completed') {
      providerTop = 140;
      providerLeft = 80; // Close to user
    }

    return Stack(
      children: [
        // User Pin (Navy)
        Positioned(
          top: userTop,
          left: userLeft,
          child: _buildPin(color: const Color(0xFF1E2D4E), label: 'You'),
        ),
        // Provider Pin (Gold)
        Positioned(
          top: providerTop,
          left: providerLeft,
          child: _buildPin(color: const Color(0xFFC9A84C), label: 'Provider'),
        ),
      ],
    );
  }

  Widget _buildPin({required Color color, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10, 
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Icon(
          Icons.location_on,
          size: 32,
          color: color,
        ),
      ],
    );
  }
}

/// A simple painter to draw mock map roads and green areas.
class _MockMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final paintPark = Paint()
      ..color = const Color(0xFFDDE3CE) // Soft green park
      ..style = PaintingStyle.fill;
      
    final paintWater = Paint()
      ..color = const Color(0xFFC9DEE3) // Soft blue water
      ..style = PaintingStyle.fill;

    // Draw a park block
    final parkPath = Path()
      ..moveTo(0, size.height * 0.2)
      ..lineTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(0, size.height * 0.6)
      ..close();
    canvas.drawPath(parkPath, paintPark);
    
    // Draw another park block
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.6, size.height * 0.7, size.width * 0.3, size.height * 0.3), 
      paintPark
    );
    
    // Draw a water body
    final waterPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.4, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(waterPath, paintWater);

    // Draw some intersecting roads
    canvas.drawLine(
      Offset(size.width * 0.1, 0),
      Offset(size.width * 0.5, size.height),
      paintRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.4),
      Offset(size.width, size.height * 0.2),
      paintRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, 0),
      Offset(size.width * 0.9, size.height),
      paintRoad,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.8),
      Offset(size.width, size.height * 0.6),
      paintRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
