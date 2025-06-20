// This file defines the interface for the Native Audio Library.
// Implementations will be platform-specific (native, web, stub).

import 'dart:ffi';

// Callback typedef for UI MIDI control messages received from native code
typedef UiControlMidiCallbackNative = Void Function(IntPtr, IntPtr, IntPtr); // panelId, cc, value
// Dart equivalent for easier use if needed, though Pointer.fromFunction requires the Native one.
// typedef UiControlMidiCallbackDart = void Function(int, int, int);


abstract class NativeAudioLibInterface {
  // --- Initialization & Lifecycle ---
  Future<void> initialize();
  void dispose();

  // --- Standard MIDI Events ---
  void sendMidiNoteOn(int note, int velocity, int channel);
  void sendMidiNoteOff(int note, int channel);

  // --- MPE (MIDI Polyphonic Expression) Events ---
  /// Sends an MPE Note On message.
  /// [note]: MIDI note number.
  /// [velocity]: Initial strike velocity (0-127).
  /// [channel]: The per-note MIDI channel (typically 2-16).
  /// [pressure]: Initial pressure (normalized 0.0-1.0, maps to Channel Pressure or Poly AT).
  /// [timbre]: Initial timbre/Y-axis (normalized 0.0-1.0, often maps to CC74).
  /// [pitchBend]: Initial per-note pitch bend (normalized -1.0 to 1.0, maps to per-note PB message).
  void sendMpeNoteOn(int note, int velocity, int channel, double pressure, double timbre, double pitchBend);

  /// Sends an MPE Note Off message.
  /// [note]: MIDI note number.
  /// [channel]: The per-note MIDI channel.
  void sendMpeNoteOff(int note, int channel);

  /// Sends an MPE Pressure update (Channel Pressure or Polyphonic Aftertouch on the note's channel).
  /// [channel]: The per-note MIDI channel.
  /// [pressure]: Normalized pressure value (0.0-1.0).
  void sendMpePressure(int channel, double pressure);

  /// Sends an MPE Timbre update (typically CC74 on the note's channel).
  /// [channel]: The per-note MIDI channel.
  /// [timbre]: Normalized timbre value (0.0-1.0).
  void sendMpeTimbre(int channel, double timbre);

  /// Sends an MPE Pitch Bend update (Per-Note Pitch Bend on the note's channel).
  /// [channel]: The per-note MIDI channel.
  /// [pitchBend]: Normalized pitch bend value (-1.0 to 1.0). Max range is synth-dependent.
  void sendMpePitchBend(int channel, double pitchBend);

  /// Sends Polyphonic Aftertouch message (distinct from MPE channel pressure if needed).
  void sendPolyAftertouch(int noteNumber, int pressure);


  // --- Synthesizer Parameter Control ---
  void setParameter(int parameterId, double value);
  double getParameter(int parameterId); // May not be needed if all state is in SynthParametersModel

  // --- Automation ---
  /// Sets an automation value for a specific parameter and automation slot.
  /// Actual interpretation of 'automationSlot' is up to the native engine.
  void setAutomationValue(int parameterId, double value, int automationSlot);

  // --- Callbacks from Native to Dart ---
  /// Registers a callback for receiving raw audio data (e.g., FFT, oscilloscope).
  /// The function signature of `callback` will depend on the data format.
  /// Example: `void registerAudioDataCallback(void Function(List<double> fftData) callback);`
  /// For simplicity, using a generic Function type here.
  void registerAudioDataCallback(Function callback);

  /// Registers a callback for receiving UI control messages via MIDI CC from native.
  void registerUiControlMidiCallback(Pointer<NativeFunction<UiControlMidiCallbackNative>> callback);

  // --- MIDI Learn ---
  /// Tells the native side to start learning a MIDI CC for the given parameterId.
  void startMidiLearnFfi(int parameterId);

  /// Tells the native side to stop any active MIDI learn process.
  void stopMidiLearnFfi();

  /// Checks if MIDI learn mode is currently active on the native side.
  bool isMidiLearnActiveFfi();

  /// Retrieves the MIDI CC number currently mapped to a parameterId.
  /// Returns -1 or a specific value if no mapping exists.
  int getCcMappingForParamFfi(int parameterId);
}
