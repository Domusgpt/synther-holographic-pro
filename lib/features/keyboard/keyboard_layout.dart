import 'package:flutter/gestures.dart'; // For Offset
import 'package:flutter/material.dart'; // For Size, Colors etc.
import 'key_model.dart';
import '../../core/microtonal_defs.dart'; // Import the new MicrotonalScale definition


/// Abstract class defining the interface for keyboard layout generation.
abstract class KeyboardLayout {
  /// Generates a list of [KeyModel]s based on the provided parameters.
  ///
  /// [octaves] - The number of octaves to generate.
  /// [scale] - The musical scale to use.
  /// [keyboardSize] - The total available size for the keyboard.
  /// [startMidiNote] - The MIDI note number for the first key.
  /// [numVisibleWhiteKeys] - The number of white keys the layout width should be based on.
  List<KeyModel> generateKeys({
    required int octaves,
    required MicrotonalScale scale,
    required Size keyboardSize,
    required int startMidiNote,
    int numVisibleWhiteKeys = 14,
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
  static const double whiteKeyWidthToHeightRatio = 52.0 / 150.0;
  static const double blackKeyToWhiteKeyWidthRatio = 0.6;
  static const double blackKeyHeightFactor = 0.6;
  // Defines how far from the *left* edge of a white key a black key starts, as a factor of white key width.
  // Standard black keys (C#, D#, F#, G#, A#) relative to C=0:
  // C# (1) is on C (0)
  // D# (3) is on D (2)
  // F# (6) is on F (5)
  // G# (8) is on G (7)
  // A# (10) is on A (9)
  // Values > 0.5 mean they are on the right half of the white key.
  static const Map<int, double> blackKeyRelativePositionFactor = {
    1: 0.65, // C# on C
    3: 0.65, // D# on D
    6: 0.60, // F# on F (often a bit more to the left)
    8: 0.65, // G# on G
    10: 0.65, // A# on A
  };


  @override
  List<KeyModel> generateKeys({
    required int octaves,
    required MicrotonalScale scale,
    required Size keyboardSize,
    required int startMidiNote,
    int numVisibleWhiteKeys = 14,
  }) {
    final List<KeyModel> keys = [];
    final double whiteKeyHeight = keyboardSize.height;
    // Calculate white key width based on the number of white keys to be visible in the given keyboard width
    final double whiteKeyWidth = keyboardSize.width / numVisibleWhiteKeys.toDouble();
    final double blackKeyWidth = whiteKeyWidth * blackKeyToWhiteKeyWidthRatio;
    final double blackKeyHeight = whiteKeyHeight * blackKeyHeightFactor;

    // Standard 12 notes in a piano octave
    const int notesPerOctaveStandard = 12;
    // Pattern of white (0) and black (1) keys in a standard octave: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    const List<bool> isBlackKeyPattern = [false, true, false, true, false, false, true, false, true, false, true, false];
    // White key count leading up to each note in the 12-tone octave (C=0, D=1, E=2, F=3, G=4, A=5, B=6)
    const List<int> whiteKeyIndexOfNote = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

    int currentMidiNote = startMidiNote;

    // Calculate total number of actual white keys to generate based on octaves,
    // this might exceed numVisibleWhiteKeys if octaves * 7 > numVisibleWhiteKeys,
    // implying the keyboard can be scrolled.
    int totalWhiteKeysToGenerate = octaves * 7;


    for (int i = 0; i < totalWhiteKeysToGenerate * 2; i++) { // Iterate enough times to catch all notes for given octaves
        int octaveIndex = (currentMidiNote - startMidiNote) ~/ notesPerOctaveStandard;
        if (octaveIndex >= octaves) break; // Stop if we've generated enough octaves

        int noteInOctave = (currentMidiNote - startMidiNote) % notesPerOctaveStandard;

        bool isBlack = isBlackKeyPattern[noteInOctave];
        String keyLabel = "${currentMidiNote}"; // Default label

        // TODO: Use MicrotonalScale 'scale' to generate proper labels based on scale.ratios and root note
        // For now, physical layout is piano-like, labels are MIDI notes.

        if (!isBlack) {
            // Calculate the x-position of the current white key
            // This needs to be based on its actual index in the sequence of all white keys generated so far.
            int overallWhiteKeyIndex = octaveIndex * 7 + whiteKeyIndexOfNote[noteInOctave];
            double x = overallWhiteKeyIndex * whiteKeyWidth;

            if (x + whiteKeyWidth <= keyboardSize.width * octaves) { // Ensure it's within drawable area (conceptual for scrolling)
                 keys.add(KeyModel(
                    note: currentMidiNote,
                    isBlack: false,
                    bounds: Rect.fromLTWH(x, 0, whiteKeyWidth, whiteKeyHeight),
                    label: keyLabel,
                ));
            }
        }
        currentMidiNote++;
    }

    // Add black keys separately, positioning them relative to white keys
    // This ensures black keys are added after all white keys for hit-testing order (if relevant)
    // and correct positioning.
    currentMidiNote = startMidiNote; // Reset for black key pass
    for (int i = 0; i < octaves * notesPerOctaveStandard; i++) {
        int octaveIndex = (currentMidiNote - startMidiNote) ~/ notesPerOctaveStandard;
        if (octaveIndex >= octaves) break;

        int noteInOctave = (currentMidiNote - startMidiNote) % notesPerOctaveStandard;
        bool isBlack = isBlackKeyPattern[noteInOctave];
        String keyLabel = "${currentMidiNote}";

        if (isBlack) {
            // Find the preceding white key's model to position this black key
            // The MIDI note of the white key just before or "under" this black key
            int precedingWhiteKeyNote = currentMidiNote - 1;
            // Adjust if the black key is C# (so preceding is C, not B of previous octave if startMidiNote is C)
            // This logic depends on the pattern, C# (1) follows C (0), D# (3) follows D(2) etc.
            // F# (6) follows E (4) if we consider index, but visually on F (5).
            // This needs to be robust. Let's use the whiteKeyIndexOfNote to find the white key
            // that this black key is associated with (the one to its left).

            int associatedWhiteKeyIndexInOctave = whiteKeyIndexOfNote[noteInOctave];
            int overallWhiteKeyIndex = octaveIndex * 7 + associatedWhiteKeyIndexInOctave;
            double whiteKeyX = overallWhiteKeyIndex * whiteKeyWidth;

            double blackKeyX = whiteKeyX + (whiteKeyWidth * (blackKeyRelativePositionFactor[noteInOctave] ?? 0.65)) - (blackKeyWidth / 2);
             if (blackKeyX + blackKeyWidth <= keyboardSize.width * octaves) { // Ensure it's within drawable area
                keys.add(KeyModel(
                    note: currentMidiNote,
                    isBlack: true,
                    bounds: Rect.fromLTWH(blackKeyX, 0, blackKeyWidth, blackKeyHeight),
                    label: keyLabel,
                ));
            }
        }
        currentMidiNote++;
    }

    // Sort keys by note number for consistent order, though drawing order (black on top) is handled by painter or widget list order.
    // keys.sort((a, b) => a.note.compareTo(b.note));
    // For hit-testing, it's often better to have black keys later in the list if iterating forwards.
    // The current two-pass generation (all white, then all black) achieves this.

    return keys;
  }

  @override
  KeyModel? getKeyAtPosition({
    required Offset position,
    required List<KeyModel> keys,
    required Size keyboardSize,
  }) {
    // Iterate in reverse to check black keys first (as they are often drawn on top and might overlap)
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
    required Size keyboardSize,
  }) {
    for (final key in keys) {
      if (key.note == noteNumber) {
        return key.bounds.center;
      }
    }
    return null;
  }
}
