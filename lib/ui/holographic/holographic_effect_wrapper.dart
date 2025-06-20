import 'package:flutter/material.dart';

/// A conceptual widget that wraps its child with a chromatic aberration effect.
/// The intensity of the effect can be controlled.
class HolographicEffectWrapper extends StatelessWidget {
  final Widget child;
  final double intensity; // Expected range: 0.0 (no effect) to 1.0 (max effect)

  const HolographicEffectWrapper({
    Key? key,
    required this.child,
    this.intensity = 0.0,
  }) : super(key: key);

  // Color matrix for Red channel
  static const List<double> _redChannelMatrix = [
    1, 0, 0, 0, 0, // R
    0, 0, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    0, 0, 0, 1, 0, // A
  ];

  // Color matrix for Green channel (identity for green, removes others)
  // This will be the "base" or non-offset layer in this simplified version.
  static const List<double> _greenChannelMatrix = [
    0, 0, 0, 0, 0, // R
    0, 1, 0, 0, 0, // G
    0, 0, 0, 0, 0, // B
    0, 0, 0, 1, 0, // A
  ];

  // Color matrix for Blue channel
  static const List<double> _blueChannelMatrix = [
    0, 0, 0, 0, 0, // R
    0, 0, 0, 0, 0, // G
    0, 0, 1, 0, 0, // B
    0, 0, 0, 1, 0, // A
  ];

  @override
  Widget build(BuildContext context) {
    // Clamp intensity to ensure it's within the 0.0 to 1.0 range
    final clampedIntensity = intensity.clamp(0.0, 1.0);

    if (clampedIntensity == 0.0) {
      // If intensity is 0, just return the child without any effects.
      return child;
    }

    // Define a maximum offset distance. This can be tuned.
    const double maxOffset = 5.0;

    return Stack(
      alignment: Alignment.center, // Ensure children are centered by default
      children: <Widget>[
        // Red channel - offset to one side
        // Only apply offset if intensity > 0
        if (clampedIntensity > 0.01) // Small threshold to avoid tiny, almost invisible layers
          Transform.translate(
            offset: Offset(clampedIntensity * maxOffset, 0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_redChannelMatrix),
              child: child,
            ),
          ),

        // Green channel (or base child) - no offset, or could be the "main" image
        // For a more traditional RGB split, green would also be filtered.
        // Here, we'll make the green channel the non-offset one for simplicity,
        // or one could simply layer the original child without a color filter here.
        // Let's use the original child as the "main" layer and slightly offset red/blue.
        // child, // The main child, unfiltered and centered.

        // Alternative: Center the Green channel specifically
         ColorFiltered(
           colorFilter: const ColorFilter.matrix(_greenChannelMatrix),
           child: child,
         ),

        // Blue channel - offset to the opposite side
        // Only apply offset if intensity > 0
        if (clampedIntensity > 0.01)
          Transform.translate(
            offset: Offset(clampedIntensity * -maxOffset, 0),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_blueChannelMatrix),
              child: child,
            ),
          ),

        // Render the original child on top, but with opacity based on intensity
        // to blend the effect. If intensity is high, this becomes more transparent
        // allowing the separated channels to be more visible.
        // This might not be the desired effect for pure chromatic aberration.
        // A more common approach is to blend the offset R, G, B layers.
        // For this conceptual version, let's ensure the original child is present
        // and the R/B channels are "ghosts".
        // To achieve a more blended effect, one might use BlendMode.add or Screen on the ColorFiltered layers.
        // For now, this simple stacking will create a basic separation effect.
        // The instructions imply layering R, G, B components.
        // The green layer above is already part of the R,G,B stack.
        // The child itself is used by each ColorFiltered layer.
      ],
    );
  }
}
