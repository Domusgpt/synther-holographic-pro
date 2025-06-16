import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:isolate'; // Required for Isolate.current.debugName
import 'package:ffi/ffi.dart';

// --- Typedefs for C functions ---
typedef InitializeSynthEngineC = Int32 Function(Int32 sampleRate, Int32 bufferSize, Float initialVolume);
typedef ShutdownSynthEngineC = Void Function();
typedef ProcessMidiEventC = Int32 Function(Uint8 status, Uint8 data1, Uint8 data2);
typedef SetParameterC = Int32 Function(Int32 parameterId, Float value);
typedef GetParameterC = Float Function(Int32 parameterId);
typedef NoteOnC = Int32 Function(Int32 note, Int32 velocity);
typedef NoteOffC = Int32 Function(Int32 note);
typedef LoadGranularBufferC = Int32 Function(Pointer<Float> buffer, Int32 length);

// Analysis functions
typedef GetAnalysisValueC = Double Function(); // For GetBassLevel, etc.

// New MIDI functions
typedef GetMidiDevicesJsonC = Pointer<Utf8> Function();
typedef SelectMidiDeviceC = Void Function(Pointer<Utf8> deviceId);

// Callback for MIDI messages from native to Dart
// Native side will send a pointer to an array of bytes and its length
typedef MidiMessageCallbackNative = Void Function(Pointer<Uint8> messageData, Int32 length);
// Dart side representation of the callback
typedef MidiMessageCallbackDart = void Function(Pointer<Uint8> messageData, int length);
typedef RegisterMidiMessageCallbackC = Void Function(Pointer<NativeFunction<MidiMessageCallbackNative>> callbackPointer);

// MIDI Learn functions
typedef StartMidiLearnC = Void Function(Int32 parameterId);
typedef StopMidiLearnC = Void Function();

// Automation functions
typedef VoidActionC = Void Function(); // For start/stop/clear
typedef BoolStateC = Bool Function();   // For has_data, is_recording, is_playing

// Parameter change callback from native to Dart (for automation playback)
typedef ParameterChangeCallbackNative = Void Function(Int32 parameterId, Float value);
typedef ParameterChangeCallbackDart = void Function(int parameterId, double value);
typedef RegisterParameterChangeCallbackC = Void Function(Pointer<NativeFunction<ParameterChangeCallbackNative>> callbackPointer);

// Preset Management FFI functions
typedef GetCurrentPresetJsonC = Pointer<Utf8> Function(Pointer<Utf8> nameJson);
typedef ApplyPresetJsonC = Int32 Function(Pointer<Utf8> presetJson);
typedef FreePresetJsonC = Void Function(Pointer<Utf8> jsonString);

// XY Pad Parameter Assignment FFI functions
typedef SetXYPadAxisParameterC = Void Function(Int32 parameterId);

// Polyphonic Aftertouch FFI function
typedef SendPolyAftertouchC = Void Function(Int32 noteNumber, Int32 pressure);

// Pitch Bend & Mod Wheel FFI functions
typedef SendPitchBendC = Void Function(Int32 value);
typedef SendModWheelC = Void Function(Int32 value); // Specific to CC1 (Mod Wheel)
typedef SendControlChangeC = Void Function(Int32 controller, Int32 value); // Generic CC


// --- Typedefs for Dart functions ---
typedef InitializeSynthEngineDart = int Function(int sampleRate, int bufferSize, double initialVolume);
typedef ShutdownSynthEngineDart = void Function();
typedef ProcessMidiEventDart = int Function(int status, int data1, int data2);
typedef SetParameterDart = int Function(int parameterId, double value);
typedef GetParameterDart = double Function(int parameterId);
typedef NoteOnDart = int Function(int note, int velocity);
typedef NoteOffDart = int Function(int note);
typedef LoadGranularBufferDart = int Function(Pointer<Float> buffer, int length);

typedef GetAnalysisValueDart = double Function();

typedef GetMidiDevicesJsonDart = Pointer<Utf8> Function();
typedef SelectMidiDeviceDart = void Function(Pointer<Utf8> deviceId);
typedef RegisterMidiMessageCallbackDart = void Function(Pointer<NativeFunction<MidiMessageCallbackNative>> callbackPointer);

typedef StartMidiLearnDart = void Function(int parameterId);
typedef StopMidiLearnDart = void Function();

typedef VoidActionDart = void Function();
typedef BoolStateDart = bool Function();
typedef RegisterParameterChangeCallbackDart = void Function(Pointer<NativeFunction<ParameterChangeCallbackNative>> callbackPointer);

typedef GetCurrentPresetJsonDart = Pointer<Utf8> Function(Pointer<Utf8> nameJson);
typedef ApplyPresetJsonDart = int Function(Pointer<Utf8> presetJson);
typedef FreePresetJsonDart = void Function(Pointer<Utf8> jsonString);

typedef SetXYPadAxisParameterDart = void Function(int parameterId);

typedef SendPolyAftertouchDart = void Function(int noteNumber, int pressure);

typedef SendPitchBendDart = void Function(int value);
typedef SendModWheelDart = void Function(int value); // Specific to CC1 (Mod Wheel)
typedef SendControlChangeDart = void Function(int controller, int value); // Generic CC


class NativeAudioLib {
  static final NativeAudioLib _instance = NativeAudioLib._internal();
  factory NativeAudioLib() => _instance;

  late DynamicLibrary _dylib;

  late InitializeSynthEngineDart initializeSynthEngine;
  late ShutdownSynthEngineDart shutdownSynthEngine;
  late ProcessMidiEventDart processMidiEvent;
  late SetParameterDart setParameter;
  late GetParameterDart getParameter;
  late NoteOnDart noteOn;
  late NoteOffDart noteOff;
  late LoadGranularBufferDart loadGranularBuffer;

  late GetAnalysisValueDart getBassLevel;
  late GetAnalysisValueDart getMidLevel;
  late GetAnalysisValueDart getHighLevel;
  late GetAnalysisValueDart getAmplitudeLevel;
  late GetAnalysisValueDart getDominantFrequency;

  // New MIDI functions
  late GetMidiDevicesJsonDart getMidiDevicesJson;
  late SelectMidiDeviceDart selectMidiDevice;
  late RegisterMidiMessageCallbackDart registerMidiMessageCallbackNative; // Renamed to avoid conflict
  late StartMidiLearnDart startMidiLearn;
  late StopMidiLearnDart stopMidiLearn;

  // Automation functions
  late VoidActionDart startAutomationRecording;
  late VoidActionDart stopAutomationRecording;
  late VoidActionDart startAutomationPlayback;
  late VoidActionDart stopAutomationPlayback;
  late VoidActionDart clearAutomationData;
  late BoolStateDart hasAutomationData;
  late BoolStateDart isAutomationRecording;
  late BoolStateDart isAutomationPlaying;
  late RegisterParameterChangeCallbackDart registerParameterChangeCallbackNative; // Renamed

  // Preset Management
  late GetCurrentPresetJsonDart getCurrentPresetJson;
  late ApplyPresetJsonDart applyPresetJson;
  late FreePresetJsonDart freePresetJson;

  // XY Pad Parameter Assignment
  late SetXYPadAxisParameterDart setXYPadXParameter;
  late SetXYPadAxisParameterDart setXYPadYParameter;

  // Polyphonic Aftertouch
  late SendPolyAftertouchDart sendPolyAftertouch;

  // Pitch Bend & Mod Wheel

  /// Sends a MIDI Pitch Bend message.
  ///
  /// The [bendValue] is a 14-bit integer (0-16383), where 8192 represents
  /// no pitch change (center). 0 is maximum bend down, and 16383 is maximum
  /// bend up.
  late SendPitchBendDart sendPitchBend;

  /// Sends a MIDI Mod Wheel message (Control Change #1).
  /// This is a specific instance of a Control Change message.
  ///
  /// The [value] is a 7-bit integer (0-127).
  late SendModWheelDart sendModWheel; // Specific to CC1

  /// Sends a generic MIDI Control Change (CC) message.
  ///
  /// The [controller] number (0-127) identifies the CC parameter.
  /// The [value] (0-127) is the value for that controller.
  late SendControlChangeDart sendControlChange; // Generic CC


  NativeAudioLib._internal() {
    _dylib = _loadLibrary();
    _lookupFunctions(); // This looks up C functions callable from Dart

    // Setup and register Dart callbacks that C can call
    // These Callables must be kept alive. Static fields are a good way.
    _parameterChangeCallable = NativeCallable<ParameterChangeCallbackNative>.isolateLocal(
      _staticParameterChangeHandler,
      exceptionalReturn: Void(), // Or some other way to signal error if needed
    );
    _midiMessageCallable = NativeCallable<MidiMessageCallbackNative>.isolateLocal(
      _staticMidiMessageHandler,
      exceptionalReturn: Void(),
    );

    // Automatically register them if the native functions are available
    if (_dylib.providesSymbol('register_parameter_change_callback_ffi')) {
       this.registerParameterChangeCallbackNative(_parameterChangeCallable!.nativeFunction);
       print("NativeAudioLib: ParameterChangeCallback registered with native.");
    } else {
      print("NativeAudioLib: register_parameter_change_callback_ffi not found in library.");
    }

    if (_dylib.providesSymbol('register_midi_message_callback')) {
      this.registerMidiMessageCallbackNative(_midiMessageCallable!.nativeFunction);
      print("NativeAudioLib: MidiMessageCallback registered with native.");
    } else {
      print("NativeAudioLib: register_midi_message_callback not found in library.");
    }
  }

  // Static references to NativeCallables to keep them alive
  static NativeCallable<ParameterChangeCallbackNative>? _parameterChangeCallable;
  static NativeCallable<MidiMessageCallbackNative>? _midiMessageCallable;

  // Static handler functions that are called by C++ via NativeCallable
  // These run on the main Dart isolate.
  static void _staticParameterChangeHandler(int parameterId, double value) {
    // This is where you'd typically forward the event to your application's state management
    // For example, using a StreamController, Provider, Riverpod, Bloc, etc.
    print('Dart: ParameterChangeCallback - ID: $parameterId, Value: $value (Thread: ${Isolate.current.debugName})');
    // Example: _parameterChangeStreamController.add({'id': parameterId, 'value': value});
  }

  static void _staticMidiMessageHandler(Pointer<Uint8> messageData, int length) {
    // This is where you'd forward the MIDI event
    final message = List<int>.generate(length, (i) => messageData[i]);
    print('Dart: MidiMessageCallback - Data: $message (Thread: ${Isolate.current.debugName})');
    // Example: _midiMessageStreamController.add(message);
  }

  // Public methods to allow external listeners (optional, depends on app architecture)
  // static final _parameterChangeStreamController = StreamController<Map<String, dynamic>>.broadcast();
  // static Stream<Map<String, dynamic>> get onParameterChanged => _parameterChangeStreamController.stream;

  // static final _midiMessageStreamController = StreamController<List<int>>.broadcast();
  // static Stream<List<int>> get onMidiMessage => _midiMessageStreamController.stream;

  // Call this method to clean up the NativeCallables when the library is no longer needed.
  void disposeCallables() {
    _parameterChangeCallable?.close();
    _parameterChangeCallable = null;
    _midiMessageCallable?.close();
    _midiMessageCallable = null;
    print("NativeAudioLib: Callbacks disposed.");
  }


  DynamicLibrary _loadLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.open('libSynthEngine.framework/libSynthEngine'); // Adjust if needed
    } else if (Platform.isAndroid) {
      return DynamicLibrary.open('libSynthEngine.so');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('SynthEngine.dll'); // Adjust if needed
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libSynthEngine.so');
    }
    throw UnsupportedError('Unsupported platform');
  }

  void _lookupFunctions() {
    initializeSynthEngine = _dylib.lookup<NativeFunction<InitializeSynthEngineC>>('InitializeSynthEngine').asFunction();
    shutdownSynthEngine = _dylib.lookup<NativeFunction<ShutdownSynthEngineC>>('ShutdownSynthEngine').asFunction();
    processMidiEvent = _dylib.lookup<NativeFunction<ProcessMidiEventC>>('ProcessMidiEvent').asFunction();
    setParameter = _dylib.lookup<NativeFunction<SetParameterC>>('SetParameter').asFunction();
    getParameter = _dylib.lookup<NativeFunction<GetParameterC>>('GetParameter').asFunction();
    noteOn = _dylib.lookup<NativeFunction<NoteOnC>>('NoteOn').asFunction();
    noteOff = _dylib.lookup<NativeFunction<NoteOffC>>('NoteOff').asFunction();
    loadGranularBuffer = _dylib.lookup<NativeFunction<LoadGranularBufferC>>('LoadGranularBuffer').asFunction();

    getBassLevel = _dylib.lookup<NativeFunction<GetAnalysisValueC>>('GetBassLevel').asFunction();
    getMidLevel = _dylib.lookup<NativeFunction<GetAnalysisValueC>>('GetMidLevel').asFunction();
    getHighLevel = _dylib.lookup<NativeFunction<GetAnalysisValueC>>('GetHighLevel').asFunction();
    getAmplitudeLevel = _dylib.lookup<NativeFunction<GetAnalysisValueC>>('GetAmplitudeLevel').asFunction();
    getDominantFrequency = _dylib.lookup<NativeFunction<GetAnalysisValueC>>('GetDominantFrequency').asFunction();

    // New MIDI functions
    getMidiDevicesJson = _dylib.lookup<NativeFunction<GetMidiDevicesJsonC>>('get_midi_devices_json').asFunction();
    selectMidiDevice = _dylib.lookup<NativeFunction<SelectMidiDeviceC>>('select_midi_device').asFunction();
    registerMidiMessageCallbackNative = _dylib.lookup<NativeFunction<RegisterMidiMessageCallbackC>>('register_midi_message_callback').asFunction();
    startMidiLearn = _dylib.lookup<NativeFunction<StartMidiLearnC>>('start_midi_learn_ffi').asFunction();
    stopMidiLearn = _dylib.lookup<NativeFunction<StopMidiLearnC>>('stop_midi_learn_ffi').asFunction();

    // Automation functions
    startAutomationRecording = _dylib.lookup<NativeFunction<VoidActionC>>('start_automation_recording_ffi').asFunction();
    stopAutomationRecording = _dylib.lookup<NativeFunction<VoidActionC>>('stop_automation_recording_ffi').asFunction();
    startAutomationPlayback = _dylib.lookup<NativeFunction<VoidActionC>>('start_automation_playback_ffi').asFunction();
    stopAutomationPlayback = _dylib.lookup<NativeFunction<VoidActionC>>('stop_automation_playback_ffi').asFunction();
    clearAutomationData = _dylib.lookup<NativeFunction<VoidActionC>>('clear_automation_data_ffi').asFunction();
    hasAutomationData = _dylib.lookup<NativeFunction<BoolStateC>>('has_automation_data_ffi').asFunction();
    isAutomationRecording = _dylib.lookup<NativeFunction<BoolStateC>>('is_automation_recording_ffi').asFunction();
    isAutomationPlaying = _dylib.lookup<NativeFunction<BoolStateC>>('is_automation_playing_ffi').asFunction();
    registerParameterChangeCallbackNative = _dylib.lookup<NativeFunction<RegisterParameterChangeCallbackC>>('register_parameter_change_callback_ffi').asFunction();

    // Preset Management
    getCurrentPresetJson = _dylib.lookup<NativeFunction<GetCurrentPresetJsonC>>('get_current_preset_json_ffi').asFunction();
    applyPresetJson = _dylib.lookup<NativeFunction<ApplyPresetJsonC>>('apply_preset_json_ffi').asFunction();
    freePresetJson = _dylib.lookup<NativeFunction<FreePresetJsonC>>('free_preset_json_ffi').asFunction();

    // XY Pad Parameter Assignment
    setXYPadXParameter = _dylib.lookupFunction<SetXYPadAxisParameterC, SetXYPadAxisParameterDart>('set_xy_pad_x_parameter_ffi');
    setXYPadYParameter = _dylib.lookupFunction<SetXYPadAxisParameterC, SetXYPadAxisParameterDart>('set_xy_pad_y_parameter_ffi');

    // Polyphonic Aftertouch
    sendPolyAftertouch = _dylib.lookupFunction<SendPolyAftertouchC, SendPolyAftertouchDart>('send_poly_aftertouch_ffi');

    // Pitch Bend & Mod Wheel
    sendPitchBend = _dylib.lookupFunction<SendPitchBendC, SendPitchBendDart>('send_pitch_bend_ffi');
    sendModWheel = _dylib.lookupFunction<SendModWheelC, SendModWheelDart>('send_mod_wheel_ffi'); // Existing, specific to CC1
    // Lookup for the new generic sendControlChange function
    // Assuming the native function is named 'send_control_change_ffi'
    sendControlChange = _dylib.lookupFunction<SendControlChangeC, SendControlChangeDart>('send_control_change_ffi');
  }
}
