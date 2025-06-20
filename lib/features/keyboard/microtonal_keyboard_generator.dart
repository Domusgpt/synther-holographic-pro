import 'package:flutter/material.dart'; // For Size
import '../keyboard/key_model.dart';
import '../keyboard/keyboard_layout.dart';
import '../../core/microtonal_defs.dart';

/// A utility class for generating keyboard key layouts based on different microtonal scales.
/// This class can adapt standard physical layouts (like PianoLayout) or define entirely new ones
/// suitable for specific microtonal systems.
class MicrotonalKeyboardGenerator {

  /// Generates a list of [KeyModel]s for a given [MicrotonalScale].
  ///
  /// This method can delegate to specialized generators based on the scale properties
  /// or use a general approach for scales that fit standard physical layouts.
  static List<KeyModel> generateForScale({
    required MicrotonalScale scale,
    required KeyboardLayout layout, // The base physical layout strategy (e.g., PianoLayout)
    required int octaves,
    required Size keyboardSize,
    required int startMidiNote,
    required int numVisibleWhiteKeys,
  }) {
    // For now, all scales will use the provided layout (e.g., PianoLayout)
    // The 'scale' object is passed to the layout, which might use it for labeling
    // or, in more advanced layouts, to alter the physical key arrangement.
    print("MicrotonalKeyboardGenerator: Using layout '${layout.runtimeType}' for scale '${scale.name}'");

    switch (scale.id) {
      case 'tet12':
        return layout.generateKeys(
          octaves: octaves,
          scale: scale,
          keyboardSize: keyboardSize,
          startMidiNote: startMidiNote,
          numVisibleWhiteKeys: numVisibleWhiteKeys,
        );
      case 'tet19':
        print("MicrotonalKeyboardGenerator: Specific generation for ${scale.name} (using _generate19TET placeholder).");
        return _generate19TET(
          scale: scale,
          layout: layout,
          octaves: octaves,
          keyboardSize: keyboardSize,
          startMidiNote: startMidiNote,
          numVisibleWhiteKeys: numVisibleWhiteKeys,
        );
      // Add other cases for specific scales if they need truly different physical layouts
      // or highly specialized adaptations of a base layout.
      default:
        print("MicrotonalKeyboardGenerator: Generic handling for ${scale.name}.");
        return _generateGenericMicrotonal(
          scale: scale,
          layout: layout,
          octaves: octaves,
          keyboardSize: keyboardSize,
          startMidiNote: startMidiNote,
          numVisibleWhiteKeys: numVisibleWhiteKeys,
        );
    }
  }

  static List<KeyModel> _generate19TET({
    required MicrotonalScale scale,
    required KeyboardLayout layout,
    required int octaves,
    required Size keyboardSize,
    required int startMidiNote,
    required int numVisibleWhiteKeys,
  }) {
    print("Placeholder: _generate19TET called for ${scale.name}. Returning base layout's keys for now.");
    // Future: Could adapt PianoLayout by trying to map 19 notes to the 12 physical keys per octave,
    // perhaps by changing labels, or by creating a new KeyboardLayout specifically for 19-TET visuals.
    return layout.generateKeys(
      octaves: octaves,
      scale: scale, // Pass the 19-TET scale; PianoLayout might use it for labels if adapted
      keyboardSize: keyboardSize,
      startMidiNote: startMidiNote,
      numVisibleWhiteKeys: numVisibleWhiteKeys,
    );
  }

  static List<KeyModel> _generateGenericMicrotonal({
    required MicrotonalScale scale,
    required KeyboardLayout layout,
    required int octaves,
    required Size keyboardSize,
    required int startMidiNote,
    required int numVisibleWhiteKeys,
  }) {
    print("Placeholder: _generateGenericMicrotonal called for ${scale.name}. Returning base layout's keys for now.");
    // Future: Could involve more sophisticated logic to map scale.ratios to MIDI note numbers
    // and generate appropriate labels for a standard physical layout.
    return layout.generateKeys(
      octaves: octaves,
      scale: scale, // Pass the microtonal scale; PianoLayout might use it for labels
      keyboardSize: keyboardSize,
      startMidiNote: startMidiNote,
      numVisibleWhiteKeys: numVisibleWhiteKeys,
    );
  }
}
