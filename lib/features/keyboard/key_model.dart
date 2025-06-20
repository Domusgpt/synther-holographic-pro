import 'package:flutter/painting.dart'; // For Rect

/// Represents the state and properties of a single key on the virtual keyboard.
class KeyModel {
  /// The MIDI note number this key represents.
  final int note;

  /// Whether this key is a black key (sharp/flat).
  final bool isBlack;

  /// The bounding rectangle of the key on the canvas.
  final Rect bounds;

  /// An optional label for the key (e.g., for microtonal scales or alternative tunings).
  final String? label;

  /// Whether the key is currently pressed down.
  bool isPressed;

  /// An optional color override for the key, for visual feedback like highlighting.
  Color? overrideColor;

  KeyModel({
    required this.note,
    required this.isBlack,
    required this.bounds,
    this.label,
    this.isPressed = false,
    this.overrideColor,
  });

  @override
  String toString() {
    return 'KeyModel(note: $note, isBlack: $isBlack, bounds: $bounds, label: $label, isPressed: $isPressed)';
  }
}
