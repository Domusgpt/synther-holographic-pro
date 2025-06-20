import 'package:flutter/gestures.dart'; // For Offset
import 'key_model.dart';
import 'keyboard_layout_engine.dart'; // For _layoutEngine access

class MPETouch {
  final int touchId; // From Flutter's PointerEvent
  final int channel; // MIDI channel (2-16 for MPE)
  final int note;    // MIDI note number of the key initially struck
  final Offset initialKeyboardPosition; // Position within the full keyboard coordinate space
  Offset currentKeyboardPosition;     // Current position within the full keyboard coordinate space
  double pressure; // Normalized (0.0 to 1.0)
  double xBend;    // Normalized (-1.0 to 1.0, maps to pitch bend)
  double yTimbre;  // Normalized (0.0 to 1.0, maps to CC or other timbre control)
  final DateTime startTime;
  KeyModel? currentKey; // The key currently under this touch

  MPETouch({
    required this.touchId,
    required this.channel,
    required this.note,
    required this.initialKeyboardPosition,
    // currentPosition is initialized with initialKeyboardPosition
    this.pressure = 0.5, // Default initial pressure if not available from event
    this.xBend = 0.0,
    this.yTimbre = 0.0,
    required this.startTime,
    this.currentKey,
  }) : currentKeyboardPosition = initialKeyboardPosition;

  @override
  String toString() {
    return 'MPETouch(id: $touchId, ch: $channel, note: $note, key: ${currentKey?.note}, pos: ${currentKeyboardPosition.dx.toStringAsFixed(1)},${currentKeyboardPosition.dy.toStringAsFixed(1)}, P: ${pressure.toStringAsFixed(2)}, xB: ${xBend.toStringAsFixed(2)}, yT: ${yTimbre.toStringAsFixed(2)})';
  }
}

class MPETouchHandler {
  final KeyboardLayoutEngine _layoutEngine;
  final Map<int, MPETouch> _activeTouches = {};
  int _nextChannel = 2; // MIDI channels 2-16 are typically used for MPE notes

  static const int MPE_MASTER_CHANNEL = 1;
  static const int MPE_START_NOTE_CHANNEL = 2;
  static const int MPE_END_NOTE_CHANNEL = 16;
  static const int CHANNELS_PER_ZONE = MPE_END_NOTE_CHANNEL - MPE_START_NOTE_CHANNEL + 1;

  MPETouchHandler({required KeyboardLayoutEngine layoutEngine}) : _layoutEngine = layoutEngine;

  int _allocateChannel() {
    int allocatedChannel = _nextChannel;
    _nextChannel++;
    if (_nextChannel > MPE_END_NOTE_CHANNEL) {
      _nextChannel = MPE_START_NOTE_CHANNEL;
    }
    int attempts = 0;
    while (_activeTouches.values.any((touch) => touch.channel == allocatedChannel) && attempts < CHANNELS_PER_ZONE) {
        allocatedChannel = _nextChannel;
        _nextChannel++;
        if (_nextChannel > MPE_END_NOTE_CHANNEL) {
          _nextChannel = MPE_START_NOTE_CHANNEL;
        }
        attempts++;
    }
    if (attempts >= CHANNELS_PER_ZONE) {
        print("MPE Warning: No free channels available!");
        return MPE_START_NOTE_CHANNEL; // Fallback
    }
    return allocatedChannel;
  }

  void _releaseChannel(int channel) {
    // print("MPE Channel Released: $channel");
  }

  /// Handles the start of a new touch.
  /// [touchId]: The unique pointer ID from the event.
  /// [positionInKeyboard]: The touch position in the keyboard's local coordinate space (potentially scaled by zoom).
  /// [key]: The KeyModel initially struck.
  /// [initialPressure]: The initial pressure from the pointer event.
  MPETouch? handleTouchStart(int touchId, Offset positionInKeyboard, KeyModel key, double initialPressure) {
    if (_activeTouches.containsKey(touchId)) {
      print("MPE Warning: Touch ID $touchId already active. Ignoring new start.");
      return null;
    }

    int channel = _allocateChannel();
    final newTouch = MPETouch(
      touchId: touchId,
      channel: channel,
      note: key.note,
      initialKeyboardPosition: positionInKeyboard,
      currentKey: key,
      pressure: initialPressure.clamp(0.0, 1.0),
      startTime: DateTime.now(),
    );
    _activeTouches[touchId] = newTouch;

    int velocity = (newTouch.pressure * 127).clamp(1, 127).toInt();
    print("MPE Note On - TouchID: $touchId, Channel: ${newTouch.channel}, Note: ${newTouch.note}, Velocity: $velocity, Pos: (${positionInKeyboard.dx.toStringAsFixed(1)},${positionInKeyboard.dy.toStringAsFixed(1)})");

    // TODO: Send actual MPE MIDI Note On, initial Pitch Bend (0), initial Timbre (0 or from Y), initial Pressure.
    return newTouch;
  }

  MPETouch? handleTouchEnd(int touchId) {
    final touch = _activeTouches.remove(touchId);
    if (touch == null) {
      return null;
    }
    print("MPE Note Off - TouchID: $touchId, Channel: ${touch.channel}, Note: ${touch.note}");
    _releaseChannel(touch.channel);
    // TODO: Send MPE MIDI Note Off.
    return touch;
  }

  /// Handles the movement of an active touch.
  /// [touchId]: The unique pointer ID from the event.
  /// [positionInKeyboard]: The current touch position in the keyboard's local coordinate space.
  /// [eventPressure]: The current pressure from the pointer event.
  MPETouch? handleTouchMove(int touchId, Offset positionInKeyboard, double eventPressure) {
    final touch = _activeTouches[touchId];
    if (touch == null) {
      return null;
    }

    touch.currentKeyboardPosition = positionInKeyboard;
    touch.pressure = eventPressure.clamp(0.0, 1.0);

    // Update current key under touch - this might change if user slides off the key
    touch.currentKey = _layoutEngine.getKeyAtPosition(positionInKeyboard);

    if (touch.currentKey != null) {
      // Calculate local position on the current key
      // This assumes positionInKeyboard and key.bounds are in the same coordinate system (e.g., unscaled)
      final Offset localPositionOnKey = positionInKeyboard - touch.currentKey!.bounds.topLeft;

      touch.xBend = _calculatePitchBend(localPositionOnKey, touch.currentKey!);
      touch.yTimbre = _calculateTimbre(localPositionOnKey, touch.currentKey!);
    } else {
      // Optionally reset bend/timbre if finger slides off all keys, or maintain last values
      // touch.xBend = 0.0; // Or some other neutral/last value logic
      // touch.yTimbre = 0.0; // Or some other neutral/last value logic
    }

    print("MPE Move - TouchID: $touchId, Ch: ${touch.channel}, Note: ${touch.note}, Key: ${touch.currentKey?.note}, X: ${touch.xBend.toStringAsFixed(2)}, Y: ${touch.yTimbre.toStringAsFixed(2)}, P: ${touch.pressure.toStringAsFixed(2)}");

    // TODO: Send MPE MIDI Pitch Bend, Timbre (CC74), and Pressure messages.
    return touch;
  }

  double _calculatePitchBend(Offset localPositionOnKey, KeyModel key) {
    if (key.bounds.width == 0) return 0.0;
    // Normalize X position within the key (0.0 at left edge, 1.0 at right edge)
    final double relativeX = (localPositionOnKey.dx / key.bounds.width).clamp(0.0, 1.0);
    // Map to -1.0 to 1.0, with 0.0 at the center of the key
    return (relativeX - 0.5) * 2.0;
  }

  double _calculateTimbre(Offset localPositionOnKey, KeyModel key) {
    if (key.bounds.height == 0) return 0.0;
    // Normalize Y position within the key (0.0 at top edge, 1.0 at bottom edge)
    final double relativeY = (localPositionOnKey.dy / key.bounds.height).clamp(0.0, 1.0);
    // MPE typically maps Y-axis from bottom (0.0) to top (1.0) for timbre control,
    // or initial Y sets a base timbre and vertical movement modulates it.
    // Here, returning raw relativeY, can be inverted or scaled by caller/synth.
    return relativeY;
  }

  List<MPETouch> getActiveTouches() {
    return _activeTouches.values.toList();
  }

  void clearAllTouches() {
    _activeTouches.keys.toList().forEach((touchId) {
        handleTouchEnd(touchId); // Ensures note-offs are conceptually sent
    });
    _activeTouches.clear();
    _nextChannel = MPE_START_NOTE_CHANNEL;
    print("MPE: All active touches cleared.");
  }
}
