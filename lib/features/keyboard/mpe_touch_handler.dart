import 'package:flutter/gestures.dart'; // For Offset
import 'key_model.dart'; // Assuming KeyModel is in the same directory or accessible path

class MPETouch {
  final int touchId; // From Flutter's PointerEvent
  final int channel; // MIDI channel (2-16 for MPE)
  final int note;    // MIDI note number
  final Offset initialPosition;
  Offset currentPosition;
  double pressure; // Normalized (0.0 to 1.0)
  double xBend;    // Normalized (-1.0 to 1.0, maps to pitch bend)
  double yTimbre;  // Normalized (0.0 to 1.0, maps to CC or other timbre control)
  final DateTime startTime;

  MPETouch({
    required this.touchId,
    required this.channel,
    required this.note,
    required this.initialPosition,
    required this.currentPosition,
    this.pressure = 0.5, // Default initial pressure if not available from event
    this.xBend = 0.0,
    this.yTimbre = 0.0,
    required this.startTime,
  });

  @override
  String toString() {
    return 'MPETouch(id: $touchId, ch: $channel, note: $note, pos: ${currentPosition.dx.toStringAsFixed(1)},${currentPosition.dy.toStringAsFixed(1)}, P: ${pressure.toStringAsFixed(2)}, xB: ${xBend.toStringAsFixed(2)}, yT: ${yTimbre.toStringAsFixed(2)})';
  }
}

class MPETouchHandler {
  final Map<int, MPETouch> _activeTouches = {};
  int _nextChannel = 2; // MIDI channels 2-16 are typically used for MPE notes

  // MPE usually reserves channel 1 for global messages and uses 2-16 for notes.
  // So, 15 channels available per zone.
  static const int MPE_MASTER_CHANNEL = 1;
  static const int MPE_START_NOTE_CHANNEL = 2;
  static const int MPE_END_NOTE_CHANNEL = 16;
  static const int CHANNELS_PER_ZONE = MPE_END_NOTE_CHANNEL - MPE_START_NOTE_CHANNEL + 1;


  int _allocateChannel() {
    int allocatedChannel = _nextChannel;
    _nextChannel++;
    if (_nextChannel > MPE_END_NOTE_CHANNEL) {
      _nextChannel = MPE_START_NOTE_CHANNEL; // Wrap around
    }
    // Basic check to see if wrapped channel is already in use (very simple allocation)
    // A more robust system would check all channels or use a free-list.
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
        // Potentially return a fallback or throw an error
        return MPE_START_NOTE_CHANNEL; // Fallback, could lead to conflicts
    }
    return allocatedChannel;
  }

  void _releaseChannel(int channel) {
    // In a more complex system, this channel would be marked as free.
    // For now, _allocateChannel just cycles, so explicit release isn't strictly necessary
    // for that simple allocation logic, but good practice to have.
    // print("MPE Channel Released: $channel");
  }

  MPETouch? handleTouchStart(int touchId, Offset position, KeyModel key, double initialPressure) {
    if (_activeTouches.containsKey(touchId)) {
      print("MPE Warning: Touch ID $touchId already active. Ignoring new start.");
      return null;
    }

    int channel = _allocateChannel();
    final newTouch = MPETouch(
      touchId: touchId,
      channel: channel,
      note: key.note,
      initialPosition: position,
      currentPosition: position,
      pressure: initialPressure.clamp(0.0, 1.0), // Ensure pressure is normalized
      startTime: DateTime.now(),
    );
    _activeTouches[touchId] = newTouch;

    // Placeholder for actual MIDI message sending
    // Velocity could be derived from initial pressure or a fixed value for now
    int velocity = (newTouch.pressure * 127).clamp(1, 127).toInt();
    print("MPE Note On - TouchID: $touchId, Channel: ${newTouch.channel}, Note: ${newTouch.note}, Velocity: $velocity, Pos: (${position.dx.toStringAsFixed(1)},${position.dy.toStringAsFixed(1)})");

    // TODO: Send MIDI Note On (per-note channel)
    // TODO: Send MIDI Initial Pitch Bend (0 for now, calculated on move)
    // TODO: Send MIDI Initial Timbre (CC74, from y-axis, 0 for now)
    // TODO: Send MIDI Initial Pressure (Channel Pressure or Poly Aftertouch)

    return newTouch;
  }

  MPETouch? handleTouchEnd(int touchId) {
    final touch = _activeTouches.remove(touchId);
    if (touch == null) {
      // print("MPE Warning: Touch ID $touchId not found for touch end.");
      return null;
    }

    print("MPE Note Off - TouchID: $touchId, Channel: ${touch.channel}, Note: ${touch.note}");
    _releaseChannel(touch.channel);

    // TODO: Send MIDI Note Off (per-note channel)
    // TODO: Optionally send final pressure/timbre/bend values if needed by synth

    return touch;
  }

  MPETouch? handleTouchMove(int touchId, Offset position, double eventPressure) {
    final touch = _activeTouches[touchId];
    if (touch == null) {
      // This can happen if move events come after a touch end, or for unmanaged pointers
      // print("MPE Warning: Touch ID $touchId not found for touch move.");
      return null;
    }

    touch.currentPosition = position;
    touch.pressure = eventPressure.clamp(0.0, 1.0); // Ensure pressure is normalized

    // Conceptual X-Bend (Pitch Bend) calculation - typically relative to key center or start
    // For now, let's make it relative to the initial touch X position on the key.
    // Max bend range could be, e.g., half a key width for full bend.
    // This needs to be mapped to MIDI pitch bend range (+/- 8191).
    // double xDelta = touch.currentPosition.dx - touch.initialPosition.dx;
    // touch.xBend = (xDelta / (keyWidth / 2)).clamp(-1.0, 1.0); // Example, needs actual keyWidth

    // Conceptual Y-Timbre (CC74) calculation - relative to initial Y or key height
    // double yDelta = touch.initialPosition.dy - touch.currentPosition.dy; // Often inverted
    // touch.yTimbre = (yDelta / keyHeight).clamp(0.0, 1.0); // Example, needs actual keyHeight

    print("MPE Move - TouchID: $touchId, Ch: ${touch.channel}, Note: ${touch.note}, Pos: (${position.dx.toStringAsFixed(1)},${position.dy.toStringAsFixed(1)}), P: ${touch.pressure.toStringAsFixed(2)}");

    // TODO: Send MIDI Pitch Bend (per-note channel) if xBend changed significantly
    // TODO: Send MIDI CC74 (Timbre) (per-note channel) if yTimbre changed significantly
    // TODO: Send MIDI Channel Pressure or Poly Aftertouch (per-note channel) for pressure

    return touch;
  }

  // Method to get all active touches, e.g., for external state updates or drawing
  List<MPETouch> getActiveTouches() {
    return _activeTouches.values.toList();
  }

  void clearAllTouches() {
    // Conceptually, send note-offs for all active touches before clearing
    _activeTouches.keys.toList().forEach((touchId) { // Iterate over a copy of keys
        handleTouchEnd(touchId);
    });
    _activeTouches.clear();
    _nextChannel = MPE_START_NOTE_CHANNEL; // Reset channel allocation
    print("MPE: All active touches cleared.");
  }
}
