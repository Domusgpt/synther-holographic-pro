import 'package:flutter/gestures.dart'; // For Offset
import 'package:flutter/material.dart'; // For Size, Colors etc.
import 'key_model.dart';
// import '../../core/synth_parameters.dart'; // No longer assume MicrotonalScale is here
import '../../core/microtonal_defs.dart'; // Import the new MicrotonalScale definition

// Placeholder for MicrotonalScale if not found in synth_parameters.dart
// class MicrotonalScale {
//   final String name;
//   final List<double> ratios; // Ratios relative to the root note (e.g., 1.0, 1.05946, ...)
//   final int notesPerOctave;
//
//   MicrotonalScale({required this.name, required this.ratios, required this.notesPerOctave});
//
//   // Example: Chromatic scale
//   static final MicrotonalScale chromatic = MicrotonalScale(
//     name: 'Chromatic',
//     ratios: List.generate(12, (i) => pow(2, i / 12.0).toDouble()),
//     notesPerOctave: 12,
//   );
// }


/// Abstract class defining the interface for keyboard layout generation.
abstract class KeyboardLayout {
  /// Generates a list of [KeyModel]s based on the provided parameters.
  ///
  /// [octaves] - The number of octaves to generate.
  /// [scale] - The musical scale to use.
  /// [keyboardSize] - The total available size for the keyboard.
  /// [startMidiNote] - The MIDI note number for the first key.
  List<KeyModel> generateKeys({
    required int octaves,
    required MicrotonalScale scale,
    required Size keyboardSize,
    required int startMidiNote,
    int numVisibleWhiteKeys = 14, // Default number of white keys to base width calculation on
  });

  /// Returns the [KeyModel] at a given [Offset] position on the keyboard.
  KeyModel? getKeyAtPosition({
    required Offset position,
    required List<KeyModel> keys,
    required Size keyboardSize,
  });

  /// Returns the center [Offset] position of a key with the given [noteNumber].
  Offset? getKeyPosition({
    required int noteNumber,
    required List<KeyModel> keys,
    required Size keyboardSize,
  });
}

/// A standard piano keyboard layout implementation.
class PianoLayout extends KeyboardLayout {
  // Constants for key dimension ratios (can be tuned)
  static const double whiteKeyWidthToHeightRatio = 52.0 / 150.0; // Approximate standard ratio
  static const double blackKeyToWhiteKeyWidthRatio = 0.6; // Black key is narrower
  static const double blackKeyHeightFactor = 0.6;       // Black key is shorter
  static const double blackKeyOffsetFactor = 0.65;      // How much black key overlaps the white key below it from the side

  @override
  List<KeyModel> generateKeys({
    required int octaves, // Number of C-to-B segments to draw
    required MicrotonalScale scale, // Now typed to MicrotonalScale
    required Size keyboardSize,
    required int startMidiNote,
    int numVisibleWhiteKeys = 14, // Number of white keys that should fit the keyboardSize.width
  }) {
    final List<KeyModel> keys = [];
    final double whiteKeyHeight = keyboardSize.height;
    final double whiteKeyWidth = keyboardSize.width / numVisibleWhiteKeys;
    final double blackKeyWidth = whiteKeyWidth * blackKeyToWhiteKeyWidthRatio;
    final double blackKeyHeight = whiteKeyHeight * blackKeyHeightFactor;

    // Standard piano layout pattern (W, B, W, B, W, W, B, W, B, W, B, W)
    // 0=W, 1=B
    final List<int> keyPattern = [0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0];
    final List<double> whiteKeyOffsets = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]; // Cumulative white key index for black keys

    double currentX = 0;
    int currentMidiNote = startMidiNote;
    int notesInScale = 12; // Default to chromatic for physical layout

    // Try to get notesPerOctave from the scale if it's a MicrotonalScale object
    if (scale is MicrotonalScale && scale.ratios.isNotEmpty) {
        // notesInScale = scale.notesPerOctave; // This would be used for microtonal note assignment
        // For now, physical layout remains based on 12-tone structure
    }


    for (int o = 0; o < octaves; o++) {
      for (int i = 0; i < notesInScale; i++) {
        final bool isBlackKey = keyPattern[i % 12] == 1;
        String keyLabel = "${currentMidiNote}"; // Default label is MIDI note

        // TODO: Integrate scale.getNoteName(currentMidiNote) or similar for labels
        // if (scale is MicrotonalScale) {
        //   keyLabel = scale.getNoteName(currentMidiNote) ?? keyLabel;
        // }

        if (!isBlackKey) {
          keys.add(KeyModel(
            note: currentMidiNote,
            isBlack: false,
            bounds: Rect.fromLTWH(currentX, 0, whiteKeyWidth, whiteKeyHeight),
            label: keyLabel,
          ));
          currentX += whiteKeyWidth;
        } else {
          // Black keys are drawn relative to the previous white key
          // currentX is at the start of the *next* white key after the black key's position
          double blackKeyX = currentX - (whiteKeyWidth * (1.0 - blackKeyOffsetFactor)) - (blackKeyWidth / 2);
          // Simplified: Place black key slightly before the dividing line of two white keys
          // More accurate: currentX - blackKeyWidth / 2; (if currentX was the division line)
          // Corrected logic for blackKeyX:
          // It should be offset from the *start* of the white key it's associated with.
          // Find the white key it's "on top of" or preceding it.
          // This simplified loop places black keys at approximate positions.
          // A more robust approach would map white key indices to their x positions first.

          // For this iteration, let's use a simpler relative positioning based on the current white key pattern
          // The `whiteKeyOffsets` helps determine which white key a black key is related to.
          // `whiteKeyX = whiteKeyOffsets[i % 12] * whiteKeyWidth + (o * 7 * whiteKeyWidth)`
          // `blackKeyX = whiteKeyX + whiteKeyWidth - (blackKeyWidth / 2)` // Old logic, needs review

          // Simpler logic for now:
          // Assume currentX is at the start of the white key that *follows* this black key's group
          // So, the black key is to the left of currentX
           blackKeyX = currentX - blackKeyWidth / 2 - (whiteKeyWidth * (1-blackKeyOffsetFactor) /2) ;
           // This logic is still a bit off, needs precise calculation based on standard piano key distribution.
           // For a standard piano: C#, D# are after C, D. F#, G#, A# are after F, G, A.
           // Black keys are typically placed towards the right half of a white key or spanning a division.

          // Corrected approximate placement:
          // C# is on C, D# is on D, F# is on F, G# is on G, A# is on A
          // Relative to the start of the current octave (o * 7 * whiteKeyWidth)
          // And relative to the white key index within that octave.

          // Based on the keyPattern, when isBlackKey is true, the black key is associated
          // with the white key at `keys.last` (if available and white).
          // A common pattern: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
          // Black keys are offset from the right edge of their preceding white key.
          if (keys.isNotEmpty && !keys.last.isBlack) {
             blackKeyX = keys.last.bounds.right - (blackKeyWidth * blackKeyOffsetFactor);
          } else {
            // Fallback for first key if it were black (not typical for startMidiNote=C)
            // This part of the logic needs to be more robust for arbitrary start notes.
            // For now, we assume a C-based start for simplicity of black key placement.
            blackKeyX = currentX - (blackKeyWidth / 2); // Fallback, less accurate
          }


          keys.add(KeyModel(
            note: currentMidiNote,
            isBlack: true,
            bounds: Rect.fromLTWH(blackKeyX, 0, blackKeyWidth, blackKeyHeight),
            label: keyLabel,
          ));
          // No currentX increment for black keys as they overlay white keys
        }
        currentMidiNote++;
      }
    }
    return keys;
  }

  @override
  KeyModel? getKeyAtPosition({
    required Offset position,
    required List<KeyModel> keys,
    required Size keyboardSize, // keyboardSize might be useful for context if keys don't have absolute bounds
  }) {
    // Iterate in reverse to check black keys first (as they are drawn on top)
    for (int i = keys.length - 1; i >= 0; i--) {
      if (keys[i].bounds.contains(position)) {
        return keys[i];
      }
    }
    return null;
  }

  @override
  Offset? getKeyPosition({
    required int noteNumber,
    required List<KeyModel> keys,
    required Size keyboardSize, // keyboardSize might be useful for context
  }) {
    for (final key in keys) {
      if (key.note == noteNumber) {
        return key.bounds.center;
      }
    }
    return null;
  }
}
