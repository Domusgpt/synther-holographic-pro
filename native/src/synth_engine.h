#ifndef SYNTH_ENGINE_H
#define SYNTH_ENGINE_H

#include <vector>
#include <memory>
#include <mutex>
#include <atomic>
#include <unordered_map>
#include <functional>
#include <cmath> // For std::exp, std::sqrt, std::abs
#include <chrono> // For automation timing
#include <vector> // Already here, but ensure it's used for kiss_fft_scalar etc.

// KissFFT includes - assuming they are in the include path via CMake
#include "kiss_fftr.h"
// Note: kiss_fft.h might also be needed if _kiss_fft_guts.h is not self-contained for kiss_fft_cpx

// Forward declarations
class Oscillator;
class Filter;
class Envelope;
class Delay;
class Reverb;
class AudioPlatform;

namespace synth {
    class WavetableManager;
    class GranularSynthesizer;
}

/**
 * Main class for the synthesizer engine.
 * 
 * This class handles all audio processing, parameter management,
 * and coordinates between different audio modules.
 */
class SynthEngine {
public:
    // Singleton pattern
    static SynthEngine& getInstance();
    
    // Delete copy and move operations
    SynthEngine(const SynthEngine&) = delete;
    SynthEngine& operator=(const SynthEngine&) = delete;
    SynthEngine(SynthEngine&&) = delete;
    SynthEngine& operator=(SynthEngine&&) = delete;
    
    /**
     * Initialize the engine with given parameters.
     * 
     * @param sampleRate The sample rate to use (e.g., 44100, 48000)
     * @param bufferSize The buffer size to use
     * @param initialVolume The initial master volume (0.0 - 1.0)
     * @return True on success, false on failure
     */
    bool initialize(int sampleRate, int bufferSize, float initialVolume);
    
    /**
     * Shut down the engine and clean up resources.
     */
    void shutdown();
    
    /**
     * Process a batch of audio samples.
     * 
     * @param outputBuffer Pointer to the output buffer
     * @param numFrames Number of frames to process
     * @param numChannels Number of audio channels
     */
    void processAudio(float* outputBuffer, int numFrames, int numChannels);
    
    /**
     * Handle a note-on event.
     * 
     * @param note The MIDI note number (0-127)
     * @param velocity The note velocity (0-127)
     * @return True on success, false on failure
     */
    bool noteOn(int note, int velocity);
    
    /**
     * Handle a note-off event.
     * 
     * @param note The MIDI note number (0-127)
     * @return True on success, false on failure
     */
    bool noteOff(int note);
    
    /**
     * Process a raw MIDI event.
     * 
     * @param status The MIDI status byte
     * @param data1 The first MIDI data byte
     * @param data2 The second MIDI data byte
     * @return True on success, false on failure
     */
    bool processMidiEvent(unsigned char status, unsigned char data1, unsigned char data2);
    
    /**
     * Set a parameter value.
     * 
     * @param parameterId The ID of the parameter to set
     * @param value The new value for the parameter
     * @param fromAutomation True if this call is from automation playback, to prevent re-recording
     * @return True on success, false on failure
     */
    bool setParameter(int parameterId, float value, bool fromAutomation = false);
    
    /**
     * Get a parameter value.
     * 
     * @param parameterId The ID of the parameter to get
     * @return The parameter value
     */
    float getParameter(int parameterId);
    
    /**
     * Get the current sample rate.
     * 
     * @return The current sample rate
     */
    int getSampleRate() const {
        return sampleRate;
    }
    
    /**
     * Get the current buffer size.
     * 
     * @return The current buffer size
     */
    int getBufferSize() const {
        return bufferSize;
    }
    
    /**
     * Check if the engine is initialized.
     * 
     * @return True if initialized, false otherwise
     */
    bool isInitialized() const {
        return initialized;
    }
    
    /**
     * Load an audio buffer for granular synthesis.
     * 
     * @param buffer The audio buffer to load
     * @return True on success, false on failure
     */
    bool loadGranularBuffer(const std::vector<float>& buffer);
    
    /**
     * Audio analysis functions for visualization.
     */
    double getBassLevel() const;
    double getMidLevel() const;
    double getHighLevel() const;
    double getAmplitudeLevel() const;
    double getDominantFrequency() const;

private:
    // Private constructor for singleton
    SynthEngine();
    ~SynthEngine();
    
    // Engine state
    std::atomic<bool> initialized;
    int sampleRate;
    int bufferSize;
    // bool masterMute; // Will be handled by masterVolume target (0 for mute) or a separate SmoothedParameter if gentle mute is needed
    bool masterMute; // Keeping explicit mute for now, can be refactored later if needed.

public: // Made public for easier definition of SmoothedParameterF, or move SmoothedParameterF out
    // Helper class for smoothed parameters
    class SmoothedParameterF {
    public:
        SmoothedParameterF(float initialValue = 0.0f, float smoothingTimeMs = 20.0f, int sr = 44100)
            : currentValue(initialValue), targetValue(initialValue) {
            setSmoothingTime(smoothingTimeMs, sr);
        }

        void setTarget(float target) {
            targetValue = target;
        }

        // Call per sample
        inline float getNextValue() {
            // If the change is very small, snap to target to avoid denormals or endless processing
            if (std::abs(targetValue - currentValue) < 0.00001f) { // Epsilon
                 currentValue = targetValue;
            } else {
                currentValue += (targetValue - currentValue) * alpha;
            }
            return currentValue;
        }

        float getCurrentValueNonSmoothed() const { return targetValue; } // Returns the final target
        float getCurrentSmoothedValue() const { return currentValue; }

        void setSmoothingTime(float timeMs, int sr) {
            if (timeMs <= 0.0f || sr <= 0) {
                alpha = 1.0f; // Instant change
            } else {
                // alpha = 1.0 - exp(-2.0 * PI / (timeSeconds * sampleRate)) - standard one-pole
                // Or simpler: alpha = time_constant / (time_constant + sample_duration)
                // A common heuristic for time constant from ms: alpha = 1.0f - std::exp(-2200.0f / (sr * timeMs)); (approx for -60dB)
                // Or a simpler one often used: coefficient = exp(-1.0 / (time_in_samples))
                // Let's use a common one:
                // roughly: alpha = 1.0 - exp(-DT/TAU) where DT is 1/sampleRate and TAU is time_constant
                // For this example, a simpler factor might be okay, or a fixed small alpha.
                // A common approach for setting via time:
                // alpha = std::exp(-2.0f * M_PI * (1.0f / timeMs) / (sr / 1000.0f)); // This is not quite right
                // Let's use a simple approach: make alpha smaller for longer times.
                // alpha = time_constant_samples / (time_constant_samples + 1)
                // if timeMs = 0, alpha = 1 (immediate)
                // if timeMs > 0, alpha is small.
                // A common one from game audio / JUCE:
                // alpha = 1.0f - std::exp(std::log(0.001f) / (timeMs * sr / 1000.0f)); // time to reach 0.1%
                // Given this is complex to get right without M_PI etc. from cmath which might not be everywhere
                // I'll use a fixed factor approach for now and it can be refined.
                // Let's use a simple fixed factor for this example, assuming it's adjusted externally if needed
                // Or, a simpler time-based calculation:
                if (timeMs < 1.0f) alpha = 1.0f; // Effectively instant for < 1ms
                else alpha = 1.0f - std::exp(-1.0f / ( (timeMs / 1000.0f) * sr )); // time constant approach
                if (alpha > 1.0f) alpha = 1.0f;
                if (alpha < 0.0f) alpha = 0.0f; // Should not happen with exp
            }
        }

        void setCurrentAndTarget(float value) {
            currentValue = value;
            targetValue = value;
        }

    private:
        float currentValue;
        float targetValue;
        float alpha; // Smoothing factor (coefficient)
    };
private:
    SmoothedParameterF masterVolume;
    
    // Audio platform
    std::unique_ptr<AudioPlatform> audioPlatform;
    
    // Audio modules
    std::vector<std::unique_ptr<Oscillator>> oscillators;
    std::unique_ptr<Filter> filter;
    std::unique_ptr<Envelope> envelope;
    std::unique_ptr<Delay> delay;
    std::unique_ptr<Reverb> reverb;
    std::unique_ptr<synth::WavetableManager> wavetableManager;
    std::unique_ptr<synth::GranularSynthesizer> granularSynth;
    
    // Note tracking
    std::unordered_map<int, float> activeNotes; // note -> velocity
    std::mutex notesMutex;
    
    // Parameter cache
    std::unordered_map<int, float> parameterCache;
    std::mutex parameterMutex;

    // MIDI Learn and Mapping
    std::atomic<bool> midiLearnActive{false};
    std::atomic<int> parameterIdToLearn{-1}; // -1 indicates no parameter selected for learning
    std::unordered_map<int, int> ccToParameterMap; // Maps MIDI CC number to SynthParameterId
    std::unordered_map<int, int> lastCcValue; // Stores the last raw 0-127 value for a CC for relative adjustments or UI.
    std::mutex midiMappingMutex; // To protect ccToParameterMap and lastCcValue during access/modification

    // --- Automation Data & State ---
    struct AutomationEvent {
        int parameterId;
        float value;
        double timestamp; // Timestamp in seconds relative to recording start
    };
    using AutomationTrack = std::vector<AutomationEvent>;
    using AutomationData = std::unordered_map<int /*parameterId*/, AutomationTrack>;

    std::atomic<bool> isRecordingAutomation{false};
    std::atomic<bool> isPlayingAutomation{false};
    std::chrono::time_point<std::chrono::high_resolution_clock> automationRecordStartTime;
    std::chrono::time_point<std::chrono::high_resolution_clock> automationPlaybackStartTime;

    AutomationData recordedAutomation;
    std::unordered_map<int, size_t> automationPlaybackIndices; // parameterId -> nextEventIndex
    std::mutex automationMutex; // Protects recordedAutomation and playbackIndices
    
    // Audio analysis data
    // These will be updated by the new FFT based analyzer
    std::vector<float> fftMagnitudes;  // Stores the final magnitude spectrum (size fftSize/2 + 1)
    std::vector<float> analysisWindow; // Windowing function for FFT input (size fftSize)
    std::vector<float> analysisInputBuffer; // Buffer to hold audio data for FFT input, after windowing (size fftSize)
                                         // Renamed from analysisBuffer for clarity vs KissFFT's own types
    int fftSize{2048}; // Default, can be set in initializeAudioAnalysis

    // KissFFT specific members
    kiss_fftr_cfg fftPlan{nullptr};              // KissFFT plan for real FFT
    std::vector<kiss_fft_scalar> kissFftInputBuffer; // Input buffer for kiss_fftr (float / double based on KissFFT build)
                                                 // kiss_fft_scalar is float by default.
    std::vector<kiss_fft_cpx> kissFftOutputBuffer;   // Output buffer for kiss_fftr (complex values)

    mutable std::atomic<double> bassLevel{0.0};
    mutable std::atomic<double> midLevel{0.0};
    mutable std::atomic<double> highLevel{0.0};
    mutable std::atomic<double> amplitudeLevel{0.0};
    mutable std::atomic<double> dominantFrequency{0.0};
    
    // Internal methods
    void initializeDefaultModules();
    void initializeAudioAnalysis(int fftSze); // New method for FFT setup
    float noteToFrequency(int note) const;
    void updateAudioAnalysis(const float* buffer, int numFrames, int numChannels); // Will be updated for FFT

    // Placeholder for an actual FFT function
    // In a real scenario, this would call an FFT library (e.g., FFTW, KissFFT)
    // or a self-implemented one.
    // This is a simplified signature. A real one might take a pre-allocated output.
    void performFFT(const float* audio_block, float* fft_magnitudes_output);

public:
    // MIDI Learn specific methods
    void startMidiLearn(int parameterId);
    void stopMidiLearn();
    // void clearMidiMapping(int parameterId); // Optional: To remove a mapping
    // const std::unordered_map<int, int>& getMidiMappings() const; // Optional: For saving/FFI
    // void setMidiMappings(const std::unordered_map<int, int>& mappings); // Optional: For loading/FFI

    // Automation Control Methods
    void startAutomationRecording();
    void stopAutomationRecording();
    void startAutomationPlayback();
    void stopAutomationPlayback();
    void clearAutomationData();
    bool hasAutomationData() const; // To check if there's any automation recorded
    // Note: isRecordingAutomation and isPlayingAutomation atomics can be read directly if needed by FFI for status

    // Callback for parameter changes driven by automation
    void setParameterChangeCallback(std::function<void(int, float)> callback);

    // --- Preset Management ---
    // Note: Actual JSON parsing/serialization might be too complex for direct C++ here without a library.
    // These might operate on simplified string representations or expect Dart to handle full JSON.
    // For this iteration, we'll assume they get/set a string that Dart prepares/parses as JSON.
    std::string getCurrentPresetDataJson(const std::string& name); // Gets state as a JSON-like string
    bool applyPresetDataJson(const std::string& jsonString);    // Applies state from a JSON-like string

private:
    std::function<void(int, float)> automationParameterChangeCallback{nullptr};

    // Internal helper for preset application
    bool applyParameterMap(const std::unordered_map<int, float>& parameters, bool fromPreset);
    bool applyMidiMap(const std::unordered_map<int, int>& midiMappings);
    // ApplyAutomationData would be complex, involving clearing and then adding events.

public: // Temporarily public for easier struct definition visibility, or move struct out.
    struct SynthPreset {
        std::string name;
        std::unordered_map<int, float> parameters; // parameterId -> value
        std::unordered_map<int, int> midiC পরিবর্তনMappings; // ccNumber -> parameterId
        AutomationData automationTracks;
        // Add fields for wavetable names, granular sample ID, etc.
        // std::vector<std::string> oscWavetableNames;
        // std::string granularSampleId;

        // Basic "serialization" to a conceptual JSON-like string (very simplified)
        std::string toJsonString() const {
            std::string s = "{";
            s += "\"name\":\"" + name + "\",";
            s += "\"parameters\":{";
            for (auto const& [key, val] : parameters) {
                s += "\"" + std::to_string(key) + "\":" + std::to_string(val) + ",";
            }
            if (!parameters.empty()) s.pop_back(); // Remove last comma
            s += "},";
            s += "\"midiMappings\":{";
            for (auto const& [key, val] : midiC পরিবর্তনMappings) {
                 s += "\"" + std::to_string(key) + "\":" + std::to_string(val) + ",";
            }
            if (!midiC পরিবর্তনMappings.empty()) s.pop_back();
            s += "}";
            // Automation data serialization would be complex and is omitted for brevity
            s += "}";
            return s;
        }

        // Basic "deserialization" (very simplified, assumes perfect format)
        // In a real app, use a proper JSON library (e.g. nlohmann/json)
        static SynthPreset fromJsonString(const std::string& jsonStr) {
            SynthPreset p;
            // This is a placeholder for actual JSON parsing.
            // For example, find "name":"some_name"
            size_t namePos = jsonStr.find("\"name\":\"");
            if (namePos != std::string::npos) {
                size_t nameEndPos = jsonStr.find("\"", namePos + 8);
                if (nameEndPos != std::string::npos) {
                    p.name = jsonStr.substr(namePos + 8, nameEndPos - (namePos + 8));
                }
            }
            // Similar crude parsing for parameters and midiMappings would go here.
            // This is too complex and error-prone to implement fully without a JSON lib.
            // The FFI functions will just deal with passing the string.
            // The C++ side will populate the preset object directly in getCurrentPresetDataJson
            // and parse it (conceptually) in applyPresetDataJson.
            return p;
        }
    };
};

// Parameter IDs
namespace SynthParameterId {
    // Master parameters
    constexpr int masterVolume = 0;
    constexpr int masterMute = 1;
    constexpr int pitchBend = 2; // New global parameter for pitch bend
    constexpr int channelAftertouch = 3; // New global parameter for channel aftertouch
    
    // Filter parameters
    constexpr int filterCutoff = 10;
    constexpr int filterResonance = 11;
    constexpr int filterType = 12;
    
    // Envelope parameters
    constexpr int attackTime = 20;
    constexpr int decayTime = 21;
    constexpr int sustainLevel = 22;
    constexpr int releaseTime = 23;
    
    // Effect parameters
    constexpr int reverbMix = 30;
    constexpr int delayTime = 31;
    constexpr int delayFeedback = 32;
    
    // Granular parameters
    constexpr int granularActive = 40;
    constexpr int granularGrainRate = 41;
    constexpr int granularGrainDuration = 42;
    constexpr int granularPosition = 43;
    constexpr int granularPitch = 44;
    constexpr int granularAmplitude = 45;
    constexpr int granularPositionVar = 46;
    constexpr int granularPitchVar = 47;
    constexpr int granularDurationVar = 48;
    constexpr int granularPan = 49;
    constexpr int granularPanVar = 50;
    constexpr int granularWindowType = 51;
    
    // Oscillator parameters (per oscillator)
    // For oscillator n, use: oscillatorType + (n * 10)
    constexpr int oscillatorType = 100;
    constexpr int oscillatorFrequency = 101;
    constexpr int oscillatorDetune = 102;
    constexpr int oscillatorVolume = 103;
    constexpr int oscillatorPan = 104;
    constexpr int oscillatorWavetableIndex = 105;
    constexpr int oscillatorWavetablePosition = 106;

    // Placeholder for unmapped parameters or direct MIDI CC access if needed
    // This range assumes CCs 0-119 can be mapped.
    // FFI might expose these if direct CC binding is desired without named parameters.
    constexpr int genericCCStart = 200; // CC_0 would be 200, CC_1 would be 201, etc.
    constexpr int genericCCEnd = 319;   // Covers CC 0 through CC 119
}

#endif // SYNTH_ENGINE_H