import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Simple utility to generate a placeholder app icon
// Run this once to create placeholder icons for testing
Future<void> main() async {
  // Ensure the directory exists
  Directory('assets/icons').createSync(recursive: true);
  
  // Create main app icon
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final size = Size(1024, 1024);
  
  // Draw background
  final bgPaint = Paint()..color = Colors.blue;
  canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
  
  // Draw shopping cart icon
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 80;
  
  // Draw a simplified cart shape
  final path = Path();
  path.moveTo(250, 750);  // Bottom left of cart
  path.lineTo(800, 750);  // Bottom right of cart
  path.lineTo(850, 400);  // Top right of cart
  path.lineTo(150, 400);  // Top left of cart
  path.lineTo(250, 750);  // Close bottom
  
  // Draw cart handle
  path.moveTo(200, 400);
  path.lineTo(300, 200);
  
  canvas.drawPath(path, iconPaint);
  
  // Add text "SS"
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'SS',
      style: TextStyle(
        color: Colors.white,
        fontSize: 300,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset(size.width/2 - textPainter.width/2, size.height/2 - textPainter.height/2));
  
  // Save the image
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  File('assets/icons/app_icon.png').writeAsBytesSync(buffer);
  File('assets/icons/app_icon_foreground.png').writeAsBytesSync(buffer);
  
  log('Placeholder icons generated successfully.');
}
