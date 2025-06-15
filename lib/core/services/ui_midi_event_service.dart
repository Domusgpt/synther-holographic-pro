import 'dart:async';

class UiMidiEvent {
  final int targetPanelId;
  final int ccNumber;
  final int ccValue;
  UiMidiEvent(this.targetPanelId, this.ccNumber, this.ccValue);

  @override
  String toString() {
    return 'UiMidiEvent(targetPanelId: $targetPanelId, ccNumber: $ccNumber, ccValue: $ccValue)';
  }
}

class UiMidiEventService {
  // Private constructor
  UiMidiEventService._internal();

  // Singleton instance
  static final UiMidiEventService _instance = UiMidiEventService._internal();

  // Factory constructor to return the singleton instance
  factory UiMidiEventService() {
    return _instance;
  }

  // StreamController to broadcast UI MIDI events
  // Using broadcast so multiple listeners can subscribe if needed in the future.
  final StreamController<UiMidiEvent> _eventController = StreamController<UiMidiEvent>.broadcast();

  // Stream getter for widgets to listen to
  Stream<UiMidiEvent> get events => _eventController.stream;

  // Method to be called by the FFI callback wrapper to publish an event
  void publishEvent(int targetPanelId, int ccNumber, int ccValue) {
    if (!_eventController.isClosed) {
      _eventController.add(UiMidiEvent(targetPanelId, ccNumber, ccValue));
    } else {
      print("UiMidiEventService: Attempted to publish event on a closed controller.");
    }
  }

  // Call this when the app is disposed if the stream needs cleanup,
  // though for a global singleton, it might live for the app's lifetime.
  // For robust applications, ensure this is called appropriately.
  void dispose() {
    _eventController.close();
    print("UiMidiEventService disposed.");
  }
}
