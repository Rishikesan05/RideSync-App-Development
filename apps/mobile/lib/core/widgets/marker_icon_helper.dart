import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ridesync/core/constants.dart';

enum StopMarkerType {
  origin,
  destination,
  passengerStop,
  intermediate,
}

class MarkerIconHelper {
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Creates a high-fidelity custom Bus marker with direction pointer,
  /// circular badge, and bus icon.
  static Future<BitmapDescriptor> createBusMarker({
    double size = 110,
    Color color = AppColors.primaryOrange,
    Color borderColor = Colors.white,
  }) async {
    final key = 'bus_marker_${size}_${color.toARGB32()}_${borderColor.toARGB32()}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final double radius = size / 2.0;

    // 1. Draw outer soft shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(radius, radius + 2), radius - 10, shadowPaint);

    // 2. Draw outer border ring (white)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - 8, borderPaint);

    // 3. Draw main colored circle (orange)
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(radius, radius), radius - 13, circlePaint);

    // 4. Draw Direction Pointer Triangle at top (heading indicator)
    final pointerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pointerPath = Path()
      ..moveTo(radius, 2)
      ..lineTo(radius - 8, 14)
      ..lineTo(radius + 8, 14)
      ..close();
    canvas.drawPath(pointerPath, pointerPaint);

    final pointerInnerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final pointerInnerPath = Path()
      ..moveTo(radius, 5)
      ..lineTo(radius - 5, 13)
      ..lineTo(radius + 5, 13)
      ..close();
    canvas.drawPath(pointerInnerPath, pointerInnerPaint);

    // 5. Draw Bus Icon (Material Icons.directions_bus)
    const iconData = Icons.directions_bus_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: size * 0.44,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        radius - (textPainter.width / 2.0),
        radius - (textPainter.height / 2.0) + 1,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(uint8List);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Creates a custom Stop Pin Marker based on stop type.
  static Future<BitmapDescriptor> createStopMarker({
    required StopMarkerType type,
    String? stopNumber,
    double size = 90,
  }) async {
    final key = 'stop_marker_${type.name}_${stopNumber ?? ""}_$size';
    if (_cache.containsKey(key)) return _cache[key]!;

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final double width = size;
    final double height = size * 1.15;
    final double cx = width / 2.0;

    Color pinColor;
    IconData icon;
    String? label;

    switch (type) {
      case StopMarkerType.origin:
        pinColor = const Color(0xFF10B981); // Emerald Green
        icon = Icons.trip_origin_rounded;
        label = 'A';
        break;
      case StopMarkerType.destination:
        pinColor = const Color(0xFFEF4444); // Red
        icon = Icons.flag_rounded;
        label = 'B';
        break;
      case StopMarkerType.passengerStop:
        pinColor = const Color(0xFF2563EB); // Royal Blue
        icon = Icons.person_pin_circle_rounded;
        label = 'YOU';
        break;
      case StopMarkerType.intermediate:
        pinColor = AppColors.primaryOrange;
        icon = Icons.directions_bus_filled;
        label = stopNumber;
        break;
    }

    // Shadow for pin
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cx + 2), cx - 12, shadowPaint);

    // Outer white pin circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cx), cx - 10, whitePaint);

    // Inner colored circle
    final innerPaint = Paint()..color = pinColor;
    canvas.drawCircle(Offset(cx, cx), cx - 14, innerPaint);

    // Pin bottom tip pointer
    final tipPath = Path()
      ..moveTo(cx - 10, cx + 12)
      ..lineTo(cx + 10, cx + 12)
      ..lineTo(cx, height - 4)
      ..close();
    canvas.drawPath(tipPath, whitePaint);

    final tipInnerPath = Path()
      ..moveTo(cx - 7, cx + 12)
      ..lineTo(cx + 7, cx + 12)
      ..lineTo(cx, height - 8)
      ..close();
    canvas.drawPath(tipInnerPath, innerPaint);

    // Draw Icon or Text Label inside circle
    if (type == StopMarkerType.intermediate && label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: size * 0.28,
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), cx - (textPainter.height / 2)),
      );
    } else {
      final textPainter = TextPainter(textDirection: TextDirection.ltr);
      textPainter.text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.36,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - (textPainter.width / 2), cx - (textPainter.height / 2)),
      );
    }

    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    final descriptor = BitmapDescriptor.bytes(uint8List);
    _cache[key] = descriptor;
    return descriptor;
  }
}
