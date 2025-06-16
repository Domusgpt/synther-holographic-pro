#ifndef SYNTH_ENGINE_API_H
#define SYNTH_ENGINE_API_H

#ifdef __cplusplus
extern "C" {
#endif

// Export macros for cross-platform compatibility
#ifdef _WIN32
#define SYNTH_API __declspec(dllexport)
#else
#define SYNTH_API __attribute__((visibility("default"))) __attribute__((used))
#endif

/**
 * Synther Audio Engine - Public FFI API
 * 
 * This header defines the C API for the Synther audio engine,
 * designed for use with Flutter FFI bindings.
 */

// Engine lifecycle
SYNTH_API int InitializeSynthEngine(int sampleRate, int bufferSize, float initialVolume);
SYNTH_API void ShutdownSynthEngine();

// Note control
SYNTH_API int NoteOn(int note, int velocity);
SYNTH_API int NoteOff(int note);
SYNTH_API int ProcessMidiEvent(unsigned char status, unsigned char data1, unsigned char data2);

// Parameter control
SYNTH_API int SetParameter(int parameterId, float value);
SYNTH_API float GetParameter(int parameterId);

// Granular synthesis
SYNTH_API int LoadGranularBuffer(const float* buffer, int length);

// Audio analysis for visualization
SYNTH_API double GetBassLevel();
SYNTH_API double GetMidLevel();
SYNTH_API double GetHighLevel();
SYNTH_API double GetAmplitudeLevel();
SYNTH_API double GetDominantFrequency();

// Parameter IDs (must match Dart parameter_definitions.dart)
#define SYNTH_PARAM_MASTER_VOLUME        0
#define SYNTH_PARAM_MASTER_MUTE          1
#define SYNTH_PARAM_FILTER_CUTOFF        10
#define SYNTH_PARAM_FILTER_RESONANCE     11
#define SYNTH_PARAM_FILTER_TYPE          12
#define SYNTH_PARAM_ATTACK_TIME          20
#define SYNTH_PARAM_DECAY_TIME           21
#define SYNTH_PARAM_SUSTAIN_LEVEL        22
#define SYNTH_PARAM_RELEASE_TIME         23
#define SYNTH_PARAM_REVERB_MIX           30
#define SYNTH_PARAM_DELAY_TIME           31
#define SYNTH_PARAM_DELAY_FEEDBACK       32
#define SYNTH_PARAM_GRANULAR_ACTIVE      40
#define SYNTH_PARAM_GRANULAR_GRAIN_RATE  41
#define SYNTH_PARAM_GRANULAR_GRAIN_DURATION 42
#define SYNTH_PARAM_GRANULAR_POSITION    43
#define SYNTH_PARAM_GRANULAR_PITCH       44
#define SYNTH_PARAM_GRANULAR_AMPLITUDE   45

// Preset management - memory handling
SYNTH_API const char* get_current_preset_json_ffi(const char* name_c_str);
SYNTH_API int apply_preset_json_ffi(const char* preset_json_c_str);
SYNTH_API void free_preset_json_ffi(char* json_string);

// --- MIDI Device Management ---
SYNTH_API const char* get_midi_devices_json();
SYNTH_API void select_midi_device(const char* device_id);

// --- Callbacks ---
// Typedef for MIDI message callback from C++ to Dart
typedef void (*SynthMidiMessageCallback)(const unsigned char* messageData, int length);
SYNTH_API void register_midi_message_callback(SynthMidiMessageCallback callback_ptr);

// Typedef for parameter change callback from C++ to Dart (for automation)
typedef void (*SynthParameterChangeCallback)(int parameterId, float value);
SYNTH_API void register_parameter_change_callback_ffi(SynthParameterChangeCallback callback_ptr);

// Typedef for UI control MIDI callback from C++ to Dart
typedef void (*SynthUiControlMidiCallback)(int targetPanelId, int ccNumber, int ccValue);
SYNTH_API void register_ui_control_midi_callback(SynthUiControlMidiCallback callback_ptr);


// --- MIDI Learn ---
SYNTH_API void start_midi_learn_ffi(int parameter_id);
SYNTH_API void stop_midi_learn_ffi();

// --- Automation ---
SYNTH_API void start_automation_recording_ffi();
SYNTH_API void stop_automation_recording_ffi();
SYNTH_API void start_automation_playback_ffi();
SYNTH_API void stop_automation_playback_ffi();
SYNTH_API void clear_automation_data_ffi();
SYNTH_API bool has_automation_data_ffi();
SYNTH_API bool is_automation_recording_ffi();
SYNTH_API bool is_automation_playing_ffi();

// --- XY Pad Parameter Assignment ---
SYNTH_API void set_xy_pad_x_parameter_ffi(int32_t parameter_id);
SYNTH_API void set_xy_pad_y_parameter_ffi(int32_t parameter_id);

// --- Polyphonic Aftertouch ---
SYNTH_API void send_poly_aftertouch_ffi(int note_number, int pressure);

// --- Pitch Bend & Mod Wheel ---
SYNTH_API void send_pitch_bend_ffi(int value); // 0-16383, 8192 center
SYNTH_API void send_mod_wheel_ffi(int value);  // 0-127


#ifdef __cplusplus
}
#endif

#endif // SYNTH_ENGINE_API_H