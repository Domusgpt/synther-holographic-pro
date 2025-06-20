import 'package:flutter/painting.dart'; // For Size, Offset, Color

import 'key_model.dart';
import 'keyboard_layout.dart';
import '../../core/microtonal_defs.dart'; // For MicrotonalScale

class KeyboardLayoutEngine {
  KeyboardLayout layout; // Made non-final to allow changing layout type
  MicrotonalScale scale;
  int octaves; // Or similar parameter defining the range
  Size keyboardSize;
  int startMidiNote;
  int numVisibleWhiteKeys;

  List<KeyModel> keys = [];

  KeyboardLayoutEngine({
    required this.layout,
    required this.scale,
    required this.octaves,
    required this.keyboardSize,
    required this.startMidiNote,
    required this.numVisibleWhiteKeys,
  }) {
    _generateKeys();
  }

  void _generateKeys() {
    keys = layout.generateKeys(
      octaves: octaves,
      scale: scale,
      keyboardSize: keyboardSize,
      startMidiNote: startMidiNote,
      numVisibleWhiteKeys: numVisibleWhiteKeys,
    );
  }

  void updateDimensions(
    Size newKeyboardSize, {
    MicrotonalScale? newScale,
    int? newOctaves,
    int? newStartMidiNote,
    int? newNumVisibleWhiteKeys,
    KeyboardLayout? newLayout,
  }) {
    bool needsRegeneration = false;
    if (newKeyboardSize != keyboardSize) {
      keyboardSize = newKeyboardSize;
      needsRegeneration = true;
    }
    if (newScale != null && newScale != scale) {
      scale = newScale;
      needsRegeneration = true;
    }
    if (newOctaves != null && newOctaves != octaves) {
      octaves = newOctaves;
      needsRegeneration = true;
    }
    if (newStartMidiNote != null && newStartMidiNote != startMidiNote) {
      startMidiNote = newStartMidiNote;
      needsRegeneration = true;
    }
    if (newNumVisibleWhiteKeys != null && newNumVisibleWhiteKeys != numVisibleWhiteKeys) {
      numVisibleWhiteKeys = newNumVisibleWhiteKeys;
      needsRegeneration = true;
    }
    if (newLayout != null && newLayout != layout) {
      layout = newLayout;
      needsRegeneration = true;
    }

    if (needsRegeneration) {
      _generateKeys();
    }
  }

  KeyModel? getKeyAtPosition(Offset position) {
    // Adjust position if there's a global scroll or zoom factor not handled by key bounds
    return layout.getKeyAtPosition(
      position: position,
      keys: keys,
      keyboardSize: keyboardSize,
    );
  }

  Offset? getKeyPosition({ // Return type is Offset?
    required int noteNumber,
    required List<KeyModel> keys,
    required Size keyboardSize,
  }) {
     // Using a helper extension for firstWhereOrNull for broader compatibility.
    final key = keys.firstWhereOrNull((k) => k.note == noteNumber);
    return key?.bounds.center;
  }

  // Methods to update key state for visual feedback
  void setKeyPressed(int noteNumber, bool isPressed, {Color? overrideColor}) {
    // Using a helper extension for firstWhereOrNull for broader compatibility.
    final key = keys.firstWhereOrNull((k) => k.note == noteNumber);
    if (key != null) {
      key.isPressed = isPressed;
      key.overrideColor = isPressed ? overrideColor : null;
    }
    // else {
    //   print("Key not found for note $noteNumber in setKeyPressed");
    // }
  }

  void clearAllKeyPresses() {
    for (var key in keys) {
      key.isPressed = false;
      key.overrideColor = null;
    }
  }
}

// Helper extension for firstWhereOrNull
extension _FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
