import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FarmListItem extends StatefulWidget {
  final dynamic farm; // Replace with your actual farm model type.
  final VoidCallback onTap;

  const FarmListItem({Key? key, required this.farm, required this.onTap})
      : super(key: key);

  @override
  _FarmListItemState createState() => _FarmListItemState();
}

class _FarmListItemState extends State<FarmListItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          // Using a subtle light gradient background.
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF7F7F7), Colors.white70],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: _isHovered
                ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ]
                : [],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 50,
            horizontalTitleGap: 12,
            leading: FarmPolygonPreview(
              coordinates: widget.farm.coordinates,
              size: 40,
            ),
            title: Text(
              widget.farm.name ?? "Farm Name",
              style: GoogleFonts.quicksand(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4E342E),
              ),
            ),
            subtitle: Text(
              "ID: ${widget.farm.id ?? "N/A"}",
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF908067),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.black54),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

class FarmPolygonPreview extends StatelessWidget {
  final List<LatLng> coordinates;
  final double size;

  const FarmPolygonPreview({Key? key, required this.coordinates, this.size = 40})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // White background for the canvas with extra padding below.
      padding: const EdgeInsets.only(bottom: 4),
      color: Colors.white,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PolygonPainter(coordinates),
      ),
    );
  }
}

class _PolygonPainter extends CustomPainter {
  final List<LatLng> coordinates;
  _PolygonPainter(this.coordinates);

  @override
  void paint(Canvas canvas, Size size) {
    if (coordinates.isEmpty) return;

    // Compute bounding box of the coordinates.
    double minLat = coordinates.map((c) => c.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = coordinates.map((c) => c.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = coordinates.map((c) => c.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = coordinates.map((c) => c.longitude).reduce((a, b) => a > b ? a : b);

    double latRange = maxLat - minLat;
    double lngRange = maxLng - minLng;
    if (latRange == 0) latRange = 0.001;
    if (lngRange == 0) lngRange = 0.001;

    // Create a path for the polygon.
    Path path = Path();
    for (int i = 0; i < coordinates.length; i++) {
      // Normalize the lat/lng to a 0.0 - 1.0 range.
      double normalizedX = (coordinates[i].longitude - minLng) / lngRange;
      double normalizedY = (coordinates[i].latitude - minLat) / latRange;
      // Invert Y so that 0 is at the top.
      double x = normalizedX * size.width;
      double y = size.height - normalizedY * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Draw the polygon with fill and stroke.
    Paint fillPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill;
    Paint strokePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
