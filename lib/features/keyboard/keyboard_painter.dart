import 'package:flutter/material.dart';
import 'key_model.dart';
import 'keyboard_theme.dart';
import '../../ui/holographic/holographic_theme.dart'; // For holographic colors
// import '../../core/microtonal_defs.dart'; // Not directly used for now, but could be for advanced labeling

class KeyboardPainter extends CustomPainter {
  final List<KeyModel> keys;
  final KeyboardTheme theme;
  // final MicrotonalScale currentScale; // For future scale-based highlighting or key labeling
  // final int currentRootNoteOffset;

  KeyboardPainter({
    required this.keys,
    required this.theme,
    // required this.currentScale,
    // required this.currentRootNoteOffset,
    // Listenable? repaint,
  }) /* : super(repaint: repaint) */;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint keyPaint = Paint();
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw white keys first
    for (final KeyModel key in keys.where((k) => !k.isBlack)) {
      _drawKey(canvas, key, keyPaint, borderPaint);
    }

    // Then draw black keys so they appear on top
    for (final KeyModel key in keys.where((k) => k.isBlack)) {
      _drawKey(canvas, key, keyPaint, borderPaint);
    }
  }

  void _drawKey(Canvas canvas, KeyModel key, Paint keyPaint, Paint borderPaint) {
    Color finalKeyColor;
    Color finalBorderColor;

    // Determine colors based on theme and key state
    if (key.overrideColor != null) { // Highest priority: overrideColor (e.g., for pressed state highlight)
      finalKeyColor = key.overrideColor!;
      finalBorderColor = key.overrideColor!.withAlpha(255).withOpacity(0.8); // Brighter border
    } else if (key.isPressed) {
      if (theme == KeyboardTheme.holographic) {
        finalKeyColor = HolographicTheme.glowColor.withOpacity(HolographicTheme.activeTransparency * 1.5);
        finalBorderColor = HolographicTheme.glowColor.withOpacity(0.9);
      } else { // Standard theme pressed
        finalKeyColor = key.isBlack ? Colors.grey[600]! : Colors.grey[300]!;
        finalBorderColor = Colors.grey[800]!;
      }
    } else { // Default appearance
      if (theme == KeyboardTheme.holographic) {
        // TODO: Re-add scale-based highlighting logic here or on KeyModel if needed
        // For now, all keys are "in scale" visually for simplicity on a piano layout.
        double keyOpacityFactor = 1.0;

        if (key.isBlack) {
          finalKeyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0 * keyOpacityFactor);
          finalBorderColor = HolographicTheme.secondaryEnergy.withOpacity(0.6 * keyOpacityFactor);
        } else {
          finalKeyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.5 * keyOpacityFactor);
          finalBorderColor = HolographicTheme.primaryEnergy.withOpacity(0.6 * keyOpacityFactor);
        }
      } else { // Standard theme default
        finalKeyColor = key.isBlack ? Colors.black : Colors.white;
        finalBorderColor = Colors.grey[700]!;
      }
    }

    keyPaint.color = finalKeyColor;
    borderPaint.color = finalBorderColor;
    borderPaint.strokeWidth = key.isPressed ? 1.5 : 1.0;


    // Draw key body
    // Add a slight margin for white keys for better separation if not handled by bounds directly
    Rect keyBounds = key.bounds;
    // if (!key.isBlack && theme == KeyboardTheme.standard) {
    //   keyBounds = keyBounds.deflate(0.5); // Tiny separation for standard white keys
    // }

    canvas.drawRRect(
        RRect.fromRectAndRadius(keyBounds, Radius.circular(key.isBlack ? 2.0 : 3.0)),
        keyPaint);

    // Draw key border
    canvas.drawRRect(
        RRect.fromRectAndRadius(keyBounds, Radius.circular(key.isBlack ? 2.0 : 3.0)),
        borderPaint);

    // Optional: Draw key label (conceptual) - can be expanded later
    // if (key.label != null) {
    //   final TextSpan span = TextSpan(style: TextStyle(color: key.isBlack ? Colors.white70 : Colors.black87, fontSize: 10), text: key.label);
    //   final TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    //   tp.layout();
    //   tp.paint(canvas, key.bounds.center - Offset(tp.width / 2, tp.height / 2));
    // }
  }


  @override
  bool shouldRepaint(covariant KeyboardPainter oldDelegate) {
    // Repaint if keys list identity changes, theme changes, or content of keys (isPressed, overrideColor) changes.
    // A deep comparison of keys list might be too slow if not managed carefully.
    // Using Listenable approach or just checking list identity + length is common.
    // For now, repainting if keys object itself is different or if theme changed.
    // The actual change detection for individual key states is handled by setState in the widget.
    return oldDelegate.keys != keys || oldDelegate.theme != theme;
  }
}
