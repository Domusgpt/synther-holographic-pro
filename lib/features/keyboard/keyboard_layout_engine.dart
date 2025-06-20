import 'package:flutter/material.dart'; // For Size, Offset
import 'key_model.dart';
import 'keyboard_layout.dart';
// import '../../core/synth_parameters.dart'; // For MicrotonalScale (assumed)
import '../../core/microtonal_defs.dart'; // Import the new MicrotonalScale definition

// Placeholder for MicrotonalScale if not defined in synth_parameters.dart
// class MicrotonalScale {
//   final String name;
//   final List<double> ratios;
//   final int notesPerOctave;
//   MicrotonalScale({required this.name, required this.ratios, required this.notesPerOctave});
//   static final MicrotonalScale chromatic = MicrotonalScale(name: 'Chromatic', ratios: [], notesPerOctave: 12);
// }

/// Manages the keyboard's visual layout and state.
///
/// It uses a [KeyboardLayout] strategy to generate and manage [KeyModel]s.
class KeyboardLayoutEngine {
  KeyboardLayout layout;
  MicrotonalScale scale; // Changed from dynamic to MicrotonalScale
  int octaves;
  Size keyboardSize;
  int startMidiNote;
  int numVisibleWhiteKeys; // Number of white keys the layout should be based on for width

  List<KeyModel> keys = [];

  KeyboardLayoutEngine({
    required this.layout,
    required this.scale,
    required this.octaves,
    required this.keyboardSize,
    this.startMidiNote = 48, // Default to C3
    this.numVisibleWhiteKeys = 14, // Default to two octaves of white keys
  }) {
    generateKeys();
  }

  /// Generates or re-generates the keys based on the current properties.
  void generateKeys() {
    keys = layout.generateKeys(
      octaves: octaves,
      scale: scale,
      keyboardSize: keyboardSize,
      startMidiNote: startMidiNote,
      numVisibleWhiteKeys: numVisibleWhiteKeys,
    );
  }

  /// Updates the keyboard dimensions and regenerates keys.
  void updateDimensions(Size newSize, {int? newOctaves, int? newStartMidiNote, int? newNumVisibleWhiteKeys, MicrotonalScale? newScale}) {
    keyboardSize = newSize;
    if (newOctaves != null) octaves = newOctaves;
    if (newStartMidiNote != null) startMidiNote = newStartMidiNote;
    if (newNumVisibleWhiteKeys != null) numVisibleWhiteKeys = newNumVisibleWhiteKeys;
    if (newScale != null) scale = newScale;

    generateKeys();
  }

  /// Finds the key at a given visual position.
  KeyModel? getKeyAtPosition(Offset position) {
    return layout.getKeyAtPosition(
      position: position,
      keys: keys,
      keyboardSize: keyboardSize,
    );
  }

  /// Gets the visual position (center) of a key by its MIDI note number.
  Offset? getKeyPosition(int noteNumber) {
    return layout.getKeyPosition(
      noteNumber: noteNumber,
      keys: keys,
      keyboardSize: keyboardSize,
    );
  }

  /// Sets the pressed state of a key.
  void setKeyPressed(int noteNumber, bool isPressed, {Color? overrideColor}) {
    final key = keys.firstWhere((k) => k.note == noteNumber, orNull: () => null);
    if (key != null) {
      key.isPressed = isPressed;
      key.overrideColor = isPressed ? overrideColor : null;
    }
  }

  /// Resets the pressed state of all keys.
  void clearAllKeyPresses() {
    for (var key in keys) {
      key.isPressed = false;
      key.overrideColor = null;
    }
  }
}

// Helper extension for firstWhereOrNull if not available (Flutter SDK dependent)
extension _FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
