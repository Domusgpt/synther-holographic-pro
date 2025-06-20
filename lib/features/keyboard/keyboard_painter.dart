import 'package:flutter/material.dart';
import 'key_model.dart';
import 'keyboard_theme.dart';
import '../../ui/holographic/holographic_theme.dart'; // For holographic colors
import '../../core/microtonal_defs.dart'; // For MicrotonalScale, though not directly used in this simplified painter yet

class KeyboardPainter extends CustomPainter {
  final List<KeyModel> keys;
  final KeyboardTheme theme;
  // final MicrotonalScale currentScale; // For future scale-based highlighting
  // final int currentRootNoteOffset; // For future scale-based highlighting

  KeyboardPainter({
    required this.keys,
    required this.theme,
    // required this.currentScale,
    // required this.currentRootNoteOffset,
    // Listenable? repaint, // If repaint is managed by a ChangeNotifier
  }) /* : super(repaint: repaint) */;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint keyPaint = Paint();
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    Color borderColor; // Declare borderColor

    for (final KeyModel key in keys) {
      // Determine colors based on theme and key state
      if (key.overrideColor != null) { // Highest priority: overrideColor (e.g., for pressed state)
        keyPaint.color = key.overrideColor!;
        borderColor = key.overrideColor!.withAlpha(255); // Brighter border for override
      } else if (key.isPressed) { // Next: isPressed state
        if (theme == KeyboardTheme.holographic) {
          keyPaint.color = HolographicTheme.glowColor.withOpacity(HolographicTheme.activeTransparency * 1.8);
          borderColor = HolographicTheme.glowColor;
        } else { // Standard theme pressed
          keyPaint.color = key.isBlack ? Colors.grey[700]! : Colors.grey[400]!;
          borderColor = Colors.black;
        }
      } else { // Default appearance
        if (theme == KeyboardTheme.holographic) {
          // Basic holographic theme colors (simplified from _buildKey)
          // TODO: Re-add scale-based highlighting logic here or on KeyModel if needed
          bool isNoteConceptuallyInScale = true; // Placeholder
          double keyOpacityFactor = 1.0; // Placeholder

          if (key.isBlack) {
            keyPaint.color = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.2 * keyOpacityFactor);
            borderColor = HolographicTheme.secondaryEnergy.withOpacity(0.7 * keyOpacityFactor);
          } else {
            keyPaint.color = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.6 * keyOpacityFactor);
            borderColor = HolographicTheme.primaryEnergy.withOpacity(0.7 * keyOpacityFactor);
          }
          // Example: if (isNoteConceptuallyInScale) borderColor = HolographicTheme.accentEnergy;

        } else { // Standard theme default
          keyPaint.color = key.isBlack ? Colors.black : Colors.white;
          borderColor = Colors.black;
        }
      }

      // Draw key body
      canvas.drawRect(key.bounds, keyPaint);

      // Draw key border
      borderPaint.color = borderColor;
      canvas.drawRect(key.bounds, borderPaint);

      // Optional: Draw key label (conceptual)
      // if (key.label != null) {
      //   final TextSpan span = TextSpan(style: TextStyle(color: key.isBlack ? Colors.white70 : Colors.black87, fontSize: 10), text: key.label);
      //   final TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      //   tp.layout();
      //   tp.paint(canvas, key.bounds.center - Offset(tp.width / 2, tp.height / 2));
      // }
    }
  }

  @override
  bool shouldRepaint(covariant KeyboardPainter oldDelegate) {
    // For simplicity, always repaint if keys object changes or theme changes.
    // A more granular check could compare individual key states if keys list itself doesn't change identity.
    return oldDelegate.keys != keys || oldDelegate.theme != theme;
    // return true; // Simplest, but less performant
  }
}
