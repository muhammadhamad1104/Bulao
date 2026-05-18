import 'package:flutter/material.dart';

/// A static visual placeholder for the map.
/// Matches the reference UI without needing a real map SDK yet.
class MapPreviewCard extends StatelessWidget {
  const MapPreviewCard({super.key});

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
          child: Center(
            child: _buildPin(),
          ),
        ),
      ),
    );
  }

  Widget _buildPin() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 48,
          color: const Color(0xFF1E2D4E), // Navy pin
        ),
        // Small shadow under the pin
        Container(
          width: 24,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.elliptical(12, 4)),
            border: Border.all(color: const Color(0xFFC9A84C), width: 1.5),
            color: Colors.transparent,
          ),
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
