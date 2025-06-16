#include "synth_engine.h"
#include "synthesis/oscillator.h"
#include "synthesis/filter.h"
#include "synthesis/envelope.h"
#include "synthesis/delay.h"
#include "synthesis/reverb.h"
#include "audio_platform/audio_platform.h"
#include "wavetable/wavetable_manager.h"
#include "wavetable/wavetable_oscillator_impl.h"
#include "granular/granular_synth.h"
#include <cmath>
#include <iostream>
#include "nlohmann/json.hpp" // For JSON handling

// SynthEngine implementation
SynthEngine& SynthEngine::getInstance() {
    static SynthEngine instance;
    return instance;
}

// In SynthEngine::SynthEngine() constructor
SynthEngine::SynthEngine()
    : initialized(false), sampleRate(44100), bufferSize(512),
      masterMute(false), audioPlatform(nullptr),
      fftSize(2048), // Default FFT size, can be made configurable
      masterVolume(0.75f, 20.0f, 44100), // Initial val, default smooth time, default SR (SR updated in initialize)
      midiLearnActive(false), parameterIdToLearn(-1),
      isRecordingAutomation(false), isPlayingAutomation(false),
      automationParameterChangeCallback(nullptr),
      uiControlMidiCallback_{nullptr},      // Initialize new callback
      currentUiTargetPanelId_{0},       // Initialize new panel ID target
      currentXYPadXParameterId(SynthParameterId::filterCutoff), // Default X to filterCutoff
      currentXYPadYParameterId(SynthParameterId::filterResonance) // Default Y to filterResonance
      // automationRecordStartTime, automationPlaybackStartTime are default constructed
      // recordedAutomation, automationPlaybackIndices are default constructed
{
    // Smoothing time for masterVolume will be properly set in initialize() once sampleRate is known.
    // ccToParameterMap and lastCcValue are default constructed.
}

SynthEngine::~SynthEngine() {
    shutdown();
}

bool SynthEngine::initialize(int sr, int bs, float initialVolume) {
    if (initialized) {
        return true; // Already initialized
    }
    
    try {
        sampleRate = sr; // Set sampleRate first
        bufferSize = bs;
        masterVolume.setCurrentAndTarget(initialVolume);
        masterVolume.setSmoothingTime(20.0f, sampleRate); // Default smoothing time e.g. 20ms

        // Initialize audio analysis (FFT related)
        initializeAudioAnalysis(fftSize);
        
        // Initialize wavetable manager
        wavetableManager = std::make_unique<synth::WavetableManager>();
        
        // Initialize granular synth
        granularSynth = std::make_unique<synth::GranularSynthesizer>();
        granularSynth->setSampleRate(sampleRate);
        
        // Initialize modules
        initializeDefaultModules();
        
        // Create audio platform
        audioPlatform = AudioPlatform::createForCurrentPlatform();
        
        // Set up audio callback
        auto callback = [this](float* buffer, int numFrames, int numChannels) {
            this->processAudio(buffer, numFrames, numChannels);
        };
        
        // Initialize audio platform
        if (!audioPlatform->initialize(sampleRate, bufferSize, 2, callback)) {
            std::cerr << "Failed to initialize audio platform: " 
                      << audioPlatform->getLastError() << std::endl;
            return false;
        }
        
        // Start audio processing
        if (!audioPlatform->start()) {
            std::cerr << "Failed to start audio processing: " 
                      << audioPlatform->getLastError() << std::endl;
            return false;
        }
        
        initialized = true;
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::initialize: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::initialize" << std::endl;
        return false;
    }
}

void SynthEngine::shutdown() {
    if (!initialized) {
        return;
    }
    
    // Stop audio processing
    if (audioPlatform) {
        audioPlatform->stop();
    }
    
    // Clean up all modules
    oscillators.clear();
    filter.reset();
    envelope.reset();
    delay.reset();
    reverb.reset();
    wavetableManager.reset();
    granularSynth.reset();
    
    // Clear audio platform
    audioPlatform.reset();
    
    // Clear active notes
    {
        std::lock_guard<std::mutex> lock(notesMutex);
        activeNotes.clear();
    }
    
    // Clear parameter cache
    {
        std::lock_guard<std::mutex> lock(parameterMutex);
        parameterCache.clear();
    }
    
    // Free KissFFT resources
    if (fftPlan) {
        kiss_fftr_free(fftPlan);
        fftPlan = nullptr;
    }
    kissFftInputBuffer.clear();
    kissFftInputBuffer.shrink_to_fit();
    kissFftOutputBuffer.clear();
    kissFftOutputBuffer.shrink_to_fit();
    fftMagnitudes.clear();
    fftMagnitudes.shrink_to_fit();
    analysisWindow.clear();
    analysisWindow.shrink_to_fit();
    analysisInputBuffer.clear(); // Was analysisBuffer previously
    analysisInputBuffer.shrink_to_fit();

    initialized = false;
    std::cout << "SynthEngine shutdown complete." << std::endl;
}

void SynthEngine::processAudio(float* outputBuffer, int numFrames, int numChannels) {
    if (!initialized || masterMute) {
        // Clear the output buffer if engine is not initialized or muted
        for (int i = 0; i < numFrames * numChannels; ++i) {
            outputBuffer[i] = 0.0f;
        }
        return;
    }
    
    // Process audio for each frame
    // Get smoothed master volume per-sample. If smoothing factor is very small (long smooth time),
    // it might be optimized to get it once per block, but per-sample is safest for responsiveness.
    for (int frame = 0; frame < numFrames; ++frame) {
        float currentSmoothedMasterVolume = masterVolume.getNextValue();

        float sampleLeft = 0.0f;
        float sampleRight = 0.0f;
        
        // Process all oscillators
        for (auto& osc : oscillators) {
            float oscSample = osc->process(); // Oscillator internal params (vol, pan, detune) should be smoothed too
            
            // Apply envelope
            if (envelope && envelope->isActive()) {
                oscSample *= envelope->process(); // Envelope output is inherently smoothed
            }
            
            // Apply filter
            if (filter) {
                // filter->process() is assumed to use internal SmoothedParameterF for cutoff/resonance
                // and call getNextValue() on them.
                oscSample = filter->process(oscSample);
            }
            
            // Add to output (simple stereo panning would go here)
            sampleLeft += oscSample;
            sampleRight += oscSample;
        }
        
        // Add granular synthesis if active
        if (granularSynth) {
            float granLeft = 0.0f, granRight = 0.0f;
            // Granular synth parameters (pitch, position etc.) should also be smoothed internally
            granularSynth->process(granLeft, granRight);
            sampleLeft += granLeft;
            sampleRight += granRight;
        }
        
        // Apply effects
        // Effect parameters (mix, time, feedback) should also be smoothed internally by the effect's process method.
        if (delay) {
            sampleLeft = delay->process(sampleLeft);
            sampleRight = delay->process(sampleRight);
        }
        
        if (reverb) {
            sampleLeft = reverb->process(sampleLeft);
            sampleRight = reverb->process(sampleRight);
        }
        
        // Apply master volume
        sampleLeft *= currentSmoothedMasterVolume;
        sampleRight *= currentSmoothedMasterVolume;
        
        // Write to output buffer
        if (numChannels == 1) {
            // Mono output
            outputBuffer[frame] = (sampleLeft + sampleRight) * 0.5f;
        } else {
            // Stereo output
            outputBuffer[frame * numChannels] = sampleLeft;
            outputBuffer[frame * numChannels + 1] = sampleRight;
        }
    }
    
    // Update audio analysis
    updateAudioAnalysis(outputBuffer, numFrames, numChannels);

    // Automation Playback Logic
    if (isPlayingAutomation.load()) {
        std::lock_guard<std::mutex> lock(automationMutex);
        // Get current time relative to playback start
        // Using a simple double for time. In a real engine, this might be sample-based.
        double currentPlaybackTime = std::chrono::duration<double>(
            std::chrono::high_resolution_clock::now() - automationPlaybackStartTime
        ).count();

        for (auto& pair : recordedAutomation) {
            int paramId = pair.first;
            AutomationTrack& track = pair.second;

            // Ensure playback index exists for this track
            if (automationPlaybackIndices.find(paramId) == automationPlaybackIndices.end()) {
                automationPlaybackIndices[paramId] = 0;
            }
            size_t& nextEventIdx = automationPlaybackIndices[paramId];

            while (nextEventIdx < track.size() && track[nextEventIdx].timestamp <= currentPlaybackTime) {
                const auto& event = track[nextEventIdx];

                // Apply the parameter change, marking it as 'fromAutomation'
                // This setParameter call will update the actual synth module and the parameterCache
                this->setParameter(event.parameterId, event.value, true);

                // Invoke the callback to notify Dart/Flutter of the change
                if (automationParameterChangeCallback) {
                   automationParameterChangeCallback(event.parameterId, event.value);
                }
                // std::cout << "Automation playing: Param " << event.parameterId << " Val " << event.value << " Time " << event.timestamp << std::endl;

                nextEventIdx++;
            }
        }
    }
}

bool SynthEngine::noteOn(int note, int velocity) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Normalize velocity to 0.0-1.0
        float normalizedVelocity = static_cast<float>(velocity) / 127.0f;
        
        // Set oscillator frequencies based on MIDI note
        float frequency = noteToFrequency(note);
        for (auto& osc : oscillators) {
            osc->setFrequency(frequency);
        }
        
        // Trigger envelope
        if (envelope) {
            envelope->noteOn(normalizedVelocity);
        }
        
        // Track active note
        {
            std::lock_guard<std::mutex> lock(notesMutex);
            activeNotes[note] = normalizedVelocity;
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::noteOn: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::noteOn" << std::endl;
        return false;
    }
}

bool SynthEngine::noteOff(int note) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Check if this note is active
        bool noteWasActive = false;
        {
            std::lock_guard<std::mutex> lock(notesMutex);
            auto it = activeNotes.find(note);
            if (it != activeNotes.end()) {
                activeNotes.erase(it);
                noteWasActive = true;
            }
        }
        
        if (noteWasActive) {
            // If there are no more active notes, trigger envelope release
            bool anyNotesActive = false;
            {
                std::lock_guard<std::mutex> lock(notesMutex);
                anyNotesActive = !activeNotes.empty();
            }
            
            if (!anyNotesActive && envelope) {
                envelope->noteOff();
            }
        }
        
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::noteOff: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::noteOff" << std::endl;
        return false;
    }
}

bool SynthEngine::processMidiEvent(unsigned char status, unsigned char data1, unsigned char data2) {
    if (!initialized) {
        return false;
    }
    
    try {
        unsigned char messageType = status & 0xF0;
        unsigned char channel = status & 0x0F; // MIDI channel 0-15

        // UI Control MIDI on Channel 16 (0-indexed channel 15)
        if (channel == 15 && messageType == 0xB0) { // CC messages on Channel 16
            int ccNumber = data1;
            int ccValue = data2;

            // Referencing documentation/MIDI_UI_MAPPING_DESIGN.md
            if (ccNumber == 32) { // UI_TARGET_PANEL_ID_LSB
                currentUiTargetPanelId_.store(ccValue % 128); // Ensure it's within 0-127
                std::cout << "SynthEngine: UI Target Panel ID set to " << currentUiTargetPanelId_.load() << std::endl;
                return true;
            } else if (ccNumber == 0) { // UI_TARGET_PANEL_ID_MSB (if/when implemented for >128 panels)
                // Potentially combine with LSB for a larger ID range. For now, ignored.
                std::cout << "SynthEngine: UI Target Panel ID MSB (CC0) received, currently not used for extended range." << std::endl;
                return true;
            } else if (ccNumber == 109) { // UI_CYCLE_NEXT_PANEL_TARGET
                currentUiTargetPanelId_.store((currentUiTargetPanelId_.load() + 1) % 128);
                std::cout << "SynthEngine: UI Target Panel ID cycled to " << currentUiTargetPanelId_.load() << std::endl;
                return true;
            } else if ((ccNumber >= 102 && ccNumber <= 108) || ccNumber == 110) {
                 // UI_VISIBILITY, UI_COLLAPSED_STATE, Position, Size, Theme, Toggle Vault
                if (uiControlMidiCallback_) {
                    uiControlMidiCallback_(currentUiTargetPanelId_.load(), ccNumber, ccValue);
                    // std::cout << "SynthEngine: Forwarded UI CC " << ccNumber << " val " << ccValue << " for panel " << currentUiTargetPanelId_.load() << std::endl;
                    return true;
                } else {
                    std::cout << "SynthEngine: UI Control MIDI CC " << ccNumber << " received on Ch16 but no UI callback registered." << std::endl;
                    return true;
                }
            }
            // std::cout << "SynthEngine: Unhandled CC " << ccNumber << " on UI Channel 16." << std::endl;
            return true; // Consume other CCs on channel 16 to prevent them from affecting sound
        }

        // Normal MIDI processing for sound parameters (channels 0-14, or any non-UI message on Ch15)
        switch (messageType) {
            case 0x90: // Note On
                return (data2 > 0) ? noteOn(data1, data2) : noteOff(data1);
                
            case 0x80: // Note Off
                return noteOff(data1);

            case 0xE0: // Pitch Bend
                {
                    int lsb = data1;
                    int msb = data2;
                    int bendValue = (msb << 7) | lsb; // Combine LSB and MSB for 14-bit value
                    // Normalize from 0-16383 to -1.0 to 1.0 (8192 is center)
                    float normalizedBend = (static_cast<float>(bendValue) - 8192.0f) / 8192.0f;
                    return setParameter(SynthParameterId::pitchBend, normalizedBend);
                }

            case 0xD0: // Channel Aftertouch (Channel Pressure)
                {
                    float normalizedPressure = static_cast<float>(data1) / 127.0f;
                    return setParameter(SynthParameterId::channelAftertouch, normalizedPressure);
                }
                
            case 0xB0: // Control Change
                {
                    int ccNumber = data1;
                    int ccValue = data2;
                    float normalizedCcValue = static_cast<float>(ccValue) / 127.0f;

                    if (midiLearnActive.load()) {
                        std::lock_guard<std::mutex> lock(midiMappingMutex);
                        int paramIdToMap = parameterIdToLearn.load();
                        if (paramIdToMap != -1) {
                            // Remove existing mapping for this paramId if it exists for another CC
                            for (auto it = ccToParameterMap.begin(); it != ccToParameterMap.end(); ) {
                                if (it->second == paramIdToMap) {
                                    it = ccToParameterMap.erase(it);
                                } else {
                                    ++it;
                                }
                            }
                            ccToParameterMap[ccNumber] = paramIdToMap;
                            lastCcValue[ccNumber] = ccValue;
                            std::cout << "MIDI Learn: Mapped CC " << ccNumber << " to ParamID " << paramIdToMap << std::endl;
                        }
                        stopMidiLearn(); // Automatically stop learn mode after one event
                        return true;
                    } else {
                        std::lock_guard<std::mutex> lock(midiMappingMutex);
                        auto it = ccToParameterMap.find(ccNumber);
                        if (it != ccToParameterMap.end()) {
                            // Found a mapping
                            int mappedParamId = it->second;
                            // Unlock before calling setParameter to avoid potential recursive lock if setParameter also logs/uses MIDI
                            // However, setParameter itself has a lock on parameterCache, so it's generally okay.
                            // For safety, if setParameter could ever call back into MIDI processing or learn logic, unlock earlier.
                            // For now, keeping it simple.
                            setParameter(mappedParamId, normalizedCcValue);
                            lastCcValue[ccNumber] = ccValue;
                            return true;
                        } else {
                            // No mapping found, fallback to hardcoded or generic CCs
                            // For now, keeping existing hardcoded CCs as fallback:
                            // This part can be removed if only mapped CCs are desired.
                            switch (ccNumber) {
                                case 7: // Volume
                                    return setParameter(SynthParameterId::masterVolume, normalizedCcValue);
                                case 1: // Modulation wheel - map to filter cutoff
                                    return setParameter(SynthParameterId::filterCutoff,
                                                       20.0f + normalizedCcValue * 19980.0f); // 20Hz to 20kHz
                                default:
                                    // Optionally map to generic CC synth parameters if needed
                                    // if (ccNumber >= 0 && ccNumber <= 119) {
                                    //    return setParameter(SynthParameterId::genericCCStart + ccNumber, normalizedCcValue);
                                    // }
                                    return false; // Unhandled CC
                            }
                        }
                    }
                }
                
            default:
                // Unhandled MIDI message type
                return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::processMidiEvent: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::processMidiEvent" << std::endl;
        return false;
    }
}

bool SynthEngine::setParameter(int parameterId, float value, bool fromAutomation) {
    if (!initialized) {
        return false;
    }
    
    try {
        // Record automation event if recording and not from automation playback
        if (isRecordingAutomation.load() && !fromAutomation) {
            std::lock_guard<std::mutex> lock(automationMutex);
            // Only record if there's a change, or record all settings? For now, record all calls.
            // More sophisticated: check against last recorded value for this param to avoid redundant points.
            double timestamp = std::chrono::duration<double>(
                std::chrono::high_resolution_clock::now() - automationRecordStartTime
            ).count();
            recordedAutomation[parameterId].push_back({parameterId, value, timestamp});
            // std::cout << "Automation recording: Param " << parameterId << " Val " << value << " Time " << timestamp << std::endl;
        }

        // Update parameter cache (always, regardless of source)
        {
            std::lock_guard<std::mutex> lock(parameterMutex);
            parameterCache[parameterId] = value;
        }
        
        // Handle parameter based on ID (apply to synth modules)
        // This part remains largely the same, applying the value to the actual sound-producing components.

        // XY Pad Value Passthrough
        // If Flutter's XY Pad sends its value using one of these master IDs,
        // apply the value to the currently mapped actual parameter.
        if (parameterId == SynthParameterId::xyPadXValue) {
            // Value received is for X-axis, apply it to the parameter stored in currentXYPadXParameterId
            // Note: The 'value' here is the raw X value (e.g., 0.0-1.0).
            // The setParameter method needs to handle appropriate scaling if the target parameter expects a different range.
            // This assumes 'value' is already correctly scaled or that the target setParameter call handles it.
            return this->setParameter(currentXYPadXParameterId.load(), value, fromAutomation);
        }
        if (parameterId == SynthParameterId::xyPadYValue) {
            // Value received is for Y-axis, apply it to the parameter stored in currentXYPadYParameterId
            return this->setParameter(currentXYPadYParameterId.load(), value, fromAutomation);
        }

        switch (parameterId) {
            // Master parameters
            case SynthParameterId::masterVolume:
                masterVolume.setTarget(value);
                return true;
            case SynthParameterId::masterMute:
                masterMute = (value >= 0.5f);
                return true;
            case SynthParameterId::pitchBend:
                // TODO: Implement actual pitch bend logic (e.g., apply to oscillator frequencies)
                // For now, just caching it.
                // std::cout << "Pitch Bend set to: " << value << std::endl;
                return true;
            case SynthParameterId::channelAftertouch:
                // TODO: Implement actual aftertouch logic (e.g., map to filter cutoff, LFO depth, volume)
                // std::cout << "Channel Aftertouch set to: " << value << std::endl;
                return true;

            // Filter parameters
            case SynthParameterId::filterCutoff:
                if (filter) {
                    filter->setCutoff(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::filterResonance:
                if (filter) {
                    filter->setResonance(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::filterType:
                if (filter) {
                    filter->setType(static_cast<int>(value));
                    return true;
                }
                return false;
                
            // Envelope parameters
            case SynthParameterId::attackTime:
                if (envelope) {
                    envelope->setAttack(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::decayTime:
                if (envelope) {
                    envelope->setDecay(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::sustainLevel:
                if (envelope) {
                    envelope->setSustain(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::releaseTime:
                if (envelope) {
                    envelope->setRelease(value);
                    return true;
                }
                return false;
                
            // Effect parameters
            case SynthParameterId::reverbMix:
                if (reverb) {
                    reverb->setMix(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::delayTime:
                if (delay) {
                    delay->setTime(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::delayFeedback:
                if (delay) {
                    delay->setFeedback(value);
                    return true;
                }
                return false;
                
            // Granular parameters
            case SynthParameterId::granularGrainRate:
                if (granularSynth) {
                    granularSynth->setGrainRate(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularGrainDuration:
                if (granularSynth) {
                    granularSynth->setGrainDuration(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPosition:
                if (granularSynth) {
                    granularSynth->setPosition(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPitch:
                if (granularSynth) {
                    granularSynth->setPitch(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularAmplitude:
                if (granularSynth) {
                    granularSynth->setAmplitude(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPositionVar:
                if (granularSynth) {
                    granularSynth->setPositionVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPitchVar:
                if (granularSynth) {
                    granularSynth->setPitchVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularDurationVar:
                if (granularSynth) {
                    granularSynth->setGrainDurationVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPan:
                if (granularSynth) {
                    granularSynth->setPan(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularPanVar:
                if (granularSynth) {
                    granularSynth->setPanVariation(value);
                    return true;
                }
                return false;
                
            case SynthParameterId::granularWindowType:
                if (granularSynth) {
                    granularSynth->setWindowType(static_cast<synth::Grain::WindowType>(static_cast<int>(value)));
                    return true;
                }
                return false;
                
            default:
                // Check if this is an oscillator parameter
                if (parameterId >= SynthParameterId::oscillatorType && parameterId < SynthParameterId::oscillatorType + 1000) {
                    int oscIndex = (parameterId - SynthParameterId::oscillatorType) / 10;
                    int paramOffset = (parameterId - SynthParameterId::oscillatorType) % 10;
                    
                    if (oscIndex >= 0 && oscIndex < oscillators.size()) {
                        switch (paramOffset) {
                            case 0: // Type
                                oscillators[oscIndex]->setType(static_cast<int>(value));
                                return true;
                            case 1: // Frequency
                                oscillators[oscIndex]->setFrequency(value);
                                return true;
                            case 2: // Detune
                                oscillators[oscIndex]->setDetune(value);
                                return true;
                            case 3: // Volume
                                oscillators[oscIndex]->setVolume(value);
                                return true;
                            case 4: // Pan
                                oscillators[oscIndex]->setPan(value);
                                return true;
                            case 5: // Wavetable Index
                                if (auto wtOsc = dynamic_cast<synth::WavetableOscillatorImpl*>(oscillators[oscIndex].get())) {
                                    auto tableNames = wavetableManager->getTableNames();
                                    int tableIndex = static_cast<int>(value);
                                    if (tableIndex >= 0 && tableIndex < tableNames.size()) {
                                        wtOsc->selectWavetable(tableNames[tableIndex]);
                                    }
                                }
                                return true;
                            case 6: // Wavetable Position
                                if (auto wtOsc = dynamic_cast<synth::WavetableOscillatorImpl*>(oscillators[oscIndex].get())) {
                                    wtOsc->setWavetablePosition(value);
                                }
                                return true;
                            default:
                                return false;
                        }
                    }
                }
                
                // Unhandled parameter ID
                return false;
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::setParameter: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::setParameter" << std::endl;
        return false;
    }
}

float SynthEngine::getParameter(int parameterId) {
    if (!initialized) {
        return 0.0f;
    }
    
    try {
        // Check cache first
        {
            std::lock_guard<std::mutex> lock(parameterMutex);
            auto it = parameterCache.find(parameterId);
            if (it != parameterCache.end()) {
                return it->second;
            }
        }
        
        // If not in cache, get the parameter directly
        switch (parameterId) {
            // Master parameters
            case SynthParameterId::masterVolume:
                return masterVolume.getCurrentValueNonSmoothed(); // Return target value
                
            case SynthParameterId::masterMute:
                return masterMute ? 1.0f : 0.0f;
                
            // Filter parameters
            // Assuming Filter class has getTargetValue() or equivalent for its smoothed parameters
            // These are hypothetical method names for the Filter class
            case SynthParameterId::filterCutoff:
                return filter ? filter->getCutoffTarget() : 1000.0f;
                
            case SynthParameterId::filterResonance:
                return filter ? filter->getResonanceTarget() : 0.5f;
                
            // Add other parameter getters as needed. They should return the TARGET value of smoothed params.
                
            default:
                return 0.0f; // Unhandled parameter ID
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::getParameter: " << e.what() << std::endl;
        return 0.0f;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::getParameter" << std::endl;
        return 0.0f;
    }
}

void SynthEngine::initializeDefaultModules() {
    // Create default oscillators with wavetable support
    oscillators.clear();
    auto osc = std::make_unique<synth::WavetableOscillatorImpl>();
    osc->setSampleRate(sampleRate);
    osc->setType(static_cast<int>(Oscillator::WaveformType::Sine));
    osc->setVolume(0.5f);
    osc->setWavetableManager(wavetableManager.get());
    oscillators.push_back(std::move(osc));
    
    // Add a second oscillator
    auto osc2 = std::make_unique<synth::WavetableOscillatorImpl>();
    osc2->setSampleRate(sampleRate);
    osc2->setType(static_cast<int>(Oscillator::WaveformType::Square));
    osc2->setVolume(0.3f);
    osc2->setDetune(5.0f); // Slight detune for width
    osc2->setWavetableManager(wavetableManager.get());
    oscillators.push_back(std::move(osc2));
    
    // Create filter
    filter = std::make_unique<Filter>();
    filter->setSampleRate(sampleRate);
    filter->setCutoff(1000.0f);
    filter->setResonance(0.5f);
    filter->setType(static_cast<int>(Filter::FilterType::LowPass));
    
    // Create envelope
    envelope = std::make_unique<Envelope>();
    envelope->setSampleRate(sampleRate);
    envelope->setAttack(0.01f);
    envelope->setDecay(0.1f);
    envelope->setSustain(0.7f);
    envelope->setRelease(0.5f);
    
    // Create effects
    delay = std::make_unique<Delay>();
    delay->setSampleRate(sampleRate);
    delay->setTime(0.5f);
    delay->setFeedback(0.3f);
    delay->setMix(0.2f);
    
    reverb = std::make_unique<Reverb>();
    reverb->setSampleRate(sampleRate);
    reverb->setRoomSize(0.5f);
    reverb->setDamping(0.5f);
    reverb->setMix(0.2f);
}

float SynthEngine::noteToFrequency(int note) const {
    // A4 = MIDI note 69 = 440 Hz
    return 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

bool SynthEngine::loadGranularBuffer(const std::vector<float>& buffer) {
    if (!initialized || !granularSynth) {
        return false;
    }
    
    try {
        granularSynth->setBuffer(buffer);
        return true;
    } catch (const std::exception& e) {
        std::cerr << "Exception in SynthEngine::loadGranularBuffer: " << e.what() << std::endl;
        return false;
    } catch (...) {
        std::cerr << "Unknown exception in SynthEngine::loadGranularBuffer" << std::endl;
        return false;
    }
}

// --- MIDI Learn Methods ---
void SynthEngine::startMidiLearn(int parameterId) {
    parameterIdToLearn.store(parameterId);
    midiLearnActive.store(true);
    std::cout << "SynthEngine: MIDI Learn started for parameter ID: " << parameterId << std::endl;
}

void SynthEngine::stopMidiLearn() {
    midiLearnActive.store(false);
    parameterIdToLearn.store(-1);
    std::cout << "SynthEngine: MIDI Learn stopped." << std::endl;
}

// --- Automation Control Methods ---
void SynthEngine::startAutomationRecording() {
    std::lock_guard<std::mutex> lock(automationMutex);
    // Clear previous automation when starting a new recording.
    // Alternatively, one might want to append or manage multiple named automation clips.
    recordedAutomation.clear();
    automationPlaybackIndices.clear();

    isRecordingAutomation.store(true);
    isPlayingAutomation.store(false);
    automationRecordStartTime = std::chrono::high_resolution_clock::now();
    std::cout << "SynthEngine: Automation Recording Started." << std::endl;
}

void SynthEngine::stopAutomationRecording() {
    isRecordingAutomation.store(false);
    std::cout << "SynthEngine: Automation Recording Stopped." << std::endl;
    // Optionally sort tracks by timestamp if events could be out of order (shouldn't be if recorded sequentially)
    // for (auto& pair : recordedAutomation) {
    //    std::sort(pair.second.begin(), pair.second.end(), [](const AutomationEvent& a, const AutomationEvent& b) {
    //        return a.timestamp < b.timestamp;
    //    });
    // }
}

void SynthEngine::startAutomationPlayback() {
    std::lock_guard<std::mutex> lock(automationMutex);
    if (recordedAutomation.empty()) {
        std::cout << "SynthEngine: No automation data to play." << std::endl;
        isPlayingAutomation.store(false); // Ensure it's off
        return;
    }

    // Reset playback indices for all tracks
    automationPlaybackIndices.clear();
    for (const auto& pair : recordedAutomation) {
        automationPlaybackIndices[pair.first] = 0;
    }

    isPlayingAutomation.store(true);
    isRecordingAutomation.store(false); // Stop recording if it was active
    automationPlaybackStartTime = std::chrono::high_resolution_clock::now();
    std::cout << "SynthEngine: Automation Playback Started." << std::endl;
}

void SynthEngine::stopAutomationPlayback() {
    isPlayingAutomation.store(false);
    std::cout << "SynthEngine: Automation Playback Stopped." << std::endl;
}

void SynthEngine::clearAutomationData() {
    std::lock_guard<std::mutex> lock(automationMutex);
    recordedAutomation.clear();
    automationPlaybackIndices.clear();
    isRecordingAutomation.store(false); // Also stop recording if active
    isPlayingAutomation.store(false);   // And playback
    std::cout << "SynthEngine: Automation Data Cleared." << std::endl;
}

bool SynthEngine::hasAutomationData() const {
    std::lock_guard<std::mutex> lock(const_cast<std::mutex&>(automationMutex)); // See note in .h if this becomes an issue
    return !recordedAutomation.empty();
}

void SynthEngine::setParameterChangeCallback(std::function<void(int, float)> callback) {
    automationParameterChangeCallback = callback;
}

void SynthEngine::setUiControlMidiCallback(std::function<void(int, int, int)> callback) {
    uiControlMidiCallback_ = callback;
}

// --- Preset Management Methods ---

// NOTE: Proper JSON serialization/deserialization is complex without a library.
// The toJsonString and fromJsonString in SynthPreset are EXTREMELY basic placeholders.
// A real implementation would use something like nlohmann/json.

std::string SynthEngine::getCurrentPresetDataJson(const std::string& name) {
    SynthPreset preset;
    preset.name = name;

    { // Parameters
        std::lock_guard<std::mutex> lock(parameterMutex);
        preset.parameters = this->parameterCache;
        // Ensure all SmoothedParameter current TARGETS are in parameterCache.
        // getParameter() already returns target for masterVolume.
        // For other smoothed params (filter, etc.), their getTarget() should be reflected in cache.
        // For simplicity, we assume parameterCache holds the desired "savable" state.
    }
    { // MIDI Mappings
        std::lock_guard<std::mutex> lock(midiMappingMutex);
        preset.midiCcMappings = this->ccToParameterMap; // Use corrected name
    }
    { // Automation Data - conceptual copy
      // This would be complex to serialize fully. For now, just acknowledge it.
      // If we were to serialize, we'd need to iterate recordedAutomation.
      // preset.automationTracks = this->recordedAutomation; // Deep copy needed
    }
    // TODO: Add wavetable selections, granular sample info, etc.
    // TODO: Serialize automationTracks if needed.

    nlohmann::json j;
    j["name"] = preset.name;

    // Parameters - convert int keys to string for JSON keys
    for (const auto& pair : preset.parameters) {
        j["parameters"][std::to_string(pair.first)] = pair.second;
    }

    // MIDI Mappings - convert int keys to string for JSON keys
    for (const auto& pair : preset.midiCcMappings) {
        j["midiCcMappings"][std::to_string(pair.first)] = pair.second;
    }

    // AutomationData serialization (conceptual example)
    // This would be more complex depending on how AutomationEvent is structured
    // For now, let's assume AutomationEvent is simple enough or skipped
    /*
    if (!preset.automationTracks.empty()) {
        nlohmann::json automationJson;
        for (const auto& track_pair : preset.automationTracks) {
            nlohmann::json trackEventsJson = nlohmann::json::array();
            for (const auto& event : track_pair.second) {
                nlohmann::json eventJson;
                eventJson["parameterId"] = event.parameterId;
                eventJson["value"] = event.value;
                eventJson["timestamp"] = event.timestamp;
                trackEventsJson.push_back(eventJson);
            }
            automationJson[std::to_string(track_pair.first)] = trackEventsJson;
        }
        j["automationTracks"] = automationJson;
    }
    */

    return j.dump(4); // dump with indent 4 for readability, or j.dump() for compact
}

// Applies a map of parameters. fromPresetOrAutomation helps distinguish source.
bool SynthEngine::applyParameterMap(const std::unordered_map<int, float>& parameters, bool fromPresetOrAutomation) {
    bool success = true;
    for (const auto& pair : parameters) {
        if (!setParameter(pair.first, pair.second, fromPresetOrAutomation)) {
            success = false;
            // Optionally log an error for the specific parameter
        }
    }
    return success;
}

// Applies MIDI control change mappings.
bool SynthEngine::applyMidiMap(const std::unordered_map<int, int>& midiMappings) {
    std::lock_guard<std::mutex> lock(midiMappingMutex);
    ccToParameterMap = midiMappings; // Replace current mappings
    // Potentially clear lastCcValue or update it based on new mappings if needed
    return true;
}


bool SynthEngine::applyPresetDataJson(const std::string& jsonString) {
    std::cout << "SynthEngine: Applying preset from JSON string (length " << jsonString.length() << ")" << std::endl;
    try {
        nlohmann::json j = nlohmann::json::parse(jsonString);
        SynthPreset preset; // Helper struct, though we'll apply directly

        // Apply name (optional, could be just for info)
        // preset.name = j.value("name", "Unnamed Preset");

        // Apply parameters
        if (j.contains("parameters") && j["parameters"].is_object()) {
            std::unordered_map<int, float> paramsToApply;
            for (auto& [key_str, val] : j["parameters"].items()) {
                try {
                    int paramId = std::stoi(key_str);
                    if (val.is_number()) {
                        paramsToApply[paramId] = val.get<float>();
                    }
                } catch (const std::invalid_argument& ia) {
                    std::cerr << "Warning: Invalid parameter ID string in JSON: " << key_str << std::endl;
                } catch (const nlohmann::json::type_error& te) {
                    std::cerr << "Warning: Type error for parameter value in JSON for key " << key_str << ": " << te.what() << std::endl;
                }
            }
            if (!applyParameterMap(paramsToApply, true)) { // fromPreset = true
                std::cerr << "Warning: Some parameters failed to apply." << std::endl;
                // Decide if this is a fatal error for preset loading
            }
        }

        // Apply MIDI Mappings
        if (j.contains("midiCcMappings") && j["midiCcMappings"].is_object()) { // Use corrected name
            std::unordered_map<int, int> midiMapToApply;
            for (auto& [key_str, val] : j["midiCcMappings"].items()) {
                try {
                    int ccNumber = std::stoi(key_str);
                    if (val.is_number()) {
                        midiMapToApply[ccNumber] = val.get<int>();
                    }
                } catch (const std::invalid_argument& ia) {
                    std::cerr << "Warning: Invalid MIDI CC number string in JSON: " << key_str << std::endl;
                } catch (const nlohmann::json::type_error& te) {
                     std::cerr << "Warning: Type error for MIDI mapping value in JSON for key " << key_str << ": " << te.what() << std::endl;
                }
            }
            if (!applyMidiMap(midiMapToApply)) {
                std::cerr << "Warning: MIDI map failed to apply." << std::endl;
            }
        }

        // TODO: Apply automation data from j["automationTracks"] if present and structured
        // This would involve parsing the automation structure (similar to how it's serialized)
        // and then setting this->recordedAutomation and resetting playback indices.
        // Example:
        /*
        if (j.contains("automationTracks") && j["automationTracks"].is_object()) {
            std::lock_guard<std::mutex> lock(automationMutex);
            recordedAutomation.clear(); // Clear existing before loading new
            automationPlaybackIndices.clear();
            for (auto& [param_id_str, track_json] : j["automationTracks"].items()) {
                try {
                    int param_id = std::stoi(param_id_str);
                    AutomationTrack track;
                    for (const auto& event_json : track_json) {
                        track.push_back({
                            event_json.value("parameterId", -1),
                            event_json.value("value", 0.0f),
                            event_json.value("timestamp", 0.0)
                        });
                    }
                    recordedAutomation[param_id] = track;
                } catch (const std::exception& e) {
                    std::cerr << "Error parsing automation track for param " << param_id_str << ": " << e.what() << std::endl;
                }
            }
        }
        */

        std::cout << "SynthEngine: Preset application finished." << std::endl;
        return true; // Indicate success, even if some individual parts had warnings.
                     // Or return false if strict parsing is required.

    } catch (const nlohmann::json::parse_error& e) {
        std::cerr << "SynthEngine: Failed to parse preset JSON: " << e.what() << std::endl;
        return false;
    } catch (const std::exception& e) {
        std::cerr << "SynthEngine: Unexpected error applying preset JSON: " << e.what() << std::endl;
        return false;
    }

    // TODO: Apply automation data from preset.automationTracks
    // This would involve:
    // 1. std::lock_guard<std::mutex> lock(automationMutex);
    // 2. recordedAutomation = preset.automationTracks; // (or merge)
    // 3. automationPlaybackIndices.clear(); // Reset for new data
    // 4. Potentially sort each track by timestamp.
    // 5. Update hasAutomationData appropriately.

    // TODO: Apply wavetable selections, granular sample info etc.
    // These would also be read from the nlohmann::json object 'j'.

    // Fallback if parsing failed before reaching a conclusive state (should be caught by try-catch)
    return false;
}


// Audio analysis functions for visualization

void SynthEngine::initializeAudioAnalysis(int fftSze) {
    // Validate fftSize and store it
    if (fftSze <= 0 || (fftSze & (fftSze - 1)) != 0) { // Check if not power of 2 or non-positive
        std::cerr << "SynthEngine: Invalid fftSize " << fftSze << ". Must be a positive power of 2. Defaulting to " << this->fftSize << "." << std::endl;
        // Use the existing this->fftSize if fftSze is invalid, assuming this->fftSize has a valid default.
    } else {
        this->fftSize = fftSze;
    }

    // Free existing plan if any (e.g. if re-initializing with new fftSize)
    if (fftPlan) {
        kiss_fftr_free(fftPlan);
        fftPlan = nullptr;
    }

    fftPlan = kiss_fftr_alloc(this->fftSize, 0 /*is_inverse_fft*/, nullptr, nullptr);
    if (!fftPlan) {
        std::cerr << "SynthEngine: Failed to allocate KissFFT plan for size " << this->fftSize << std::endl;
        throw std::runtime_error("Failed to initialize KissFFT plan in initializeAudioAnalysis.");
    }

    // Allocate buffers based on the potentially updated fftSize
    kissFftInputBuffer.assign(this->fftSize, 0.0f);
    kissFftOutputBuffer.assign(this->fftSize / 2 + 1, {0.0f, 0.0f}); // kiss_fft_cpx {r,i}
    this->fftMagnitudes.assign(this->fftSize / 2 + 1, 0.0f);

    analysisWindow.assign(this->fftSize, 0.0f);
    // M_PI might not be defined on all compilers by default with <cmath>
    // Use a const float for PI.
    const float PI_CONST = 3.14159265358979323846f;
    for (int i = 0; i < this->fftSize; ++i) {
        analysisWindow[i] = 0.5f * (1.0f - std::cos(2.0f * PI_CONST * static_cast<float>(i) / static_cast<float>(this->fftSize - 1)));
    }
    analysisInputBuffer.assign(this->fftSize, 0.0f);
    std::cout << "SynthEngine: Audio analysis initialized with FFT size " << this->fftSize << std::endl;
}

void SynthEngine::performFFT(const float* windowed_audio_block, float* magnitudes_output) {
    if (!fftPlan || kissFftInputBuffer.empty() || kissFftOutputBuffer.empty() ||
        !windowed_audio_block || !magnitudes_output) {
        std::cerr << "SynthEngine::performFFT - Not initialized or invalid buffers/inputs." << std::endl;
        if (magnitudes_output && !this->fftMagnitudes.empty()) { // this->fftMagnitudes has the correct size
             std::fill(magnitudes_output, magnitudes_output + this->fftMagnitudes.size(), 0.0f);
        }
        return;
    }

    // Copy windowed audio data to KissFFT input buffer
    // kiss_fft_scalar is float by default in KissFFT. If it were double, a cast would be needed.
    for(int i = 0; i < this->fftSize; ++i) {
        kissFftInputBuffer[i] = static_cast<kiss_fft_scalar>(windowed_audio_block[i]);
    }

    // Perform FFT
    kiss_fftr(fftPlan, kissFftInputBuffer.data(), kissFftOutputBuffer.data());

    // Compute magnitudes and normalize
    // DC component (bin 0)
    // Normalization factor: For power, divide by N^2. For amplitude, divide by N.
    // KissFFT output needs scaling by 1/N for rfft.
    magnitudes_output[0] = std::fabsf(kissFftOutputBuffer[0].r) / static_cast<float>(this->fftSize);

    // AC components (bins 1 to N/2-1)
    // For these bins, magnitude is sqrt(r^2 + i^2).
    // To get amplitude comparable to input signal, scale by 2/N.
    for (int k = 1; k < this->fftSize / 2; ++k) {
        float real = kissFftOutputBuffer[k].r;
        float imag = kissFftOutputBuffer[k].i;
        magnitudes_output[k] = std::sqrt(real * real + imag * imag) * 2.0f / static_cast<float>(this->fftSize);
    }

    // Nyquist component (bin N/2) - real part only, needs scaling by 1/N
    // Ensure kissFftOutputBuffer has this element before accessing
    if (this->fftSize / 2 < kissFftOutputBuffer.size()) {
         magnitudes_output[this->fftSize / 2] = std::fabsf(kissFftOutputBuffer[this->fftSize / 2].r) / static_cast<float>(this->fftSize);
    } else if (this->fftSize / 2 < (this->fftSize/2 +1) ) { // If kissFftOutputBuffer is exactly N/2+1
         // This case should be covered by the loop if fftSize/2 is the last valid index of magnitudes_output
    }
}

void SynthEngine::updateAudioAnalysis(const float* buffer_input, int numFrames, int numChannels) {
    if (!buffer_input || numFrames <= 0 || this->fftSize <= 0 ||
        analysisInputBuffer.empty() || analysisWindow.empty() || this->fftMagnitudes.empty() || !fftPlan) {
        amplitudeLevel.store(0.0); bassLevel.store(0.0); midLevel.store(0.0); highLevel.store(0.0); dominantFrequency.store(0.0);
        return;
    }

    // For this implementation, we take the latest available 'fftSize' block of samples.
    // A more advanced version would use a circular buffer.
    int samplesToCopy = std::min(numFrames, this->fftSize);

    // Fill analysisInputBuffer with the latest samples, mono-mixed
    for (int i = 0; i < samplesToCopy; ++i) {
        int bufferIdx = (numFrames - samplesToCopy + i); // Get from the end of the input buffer
        if (numChannels == 1) {
            analysisInputBuffer[i] = buffer_input[bufferIdx];
        } else {
            analysisInputBuffer[i] = (buffer_input[bufferIdx * numChannels] + buffer_input[bufferIdx * numChannels + 1]) * 0.5f;
        }
    }
    // Zero-pad if not enough new samples were available
    for (int i = samplesToCopy; i < this->fftSize; ++i) {
        analysisInputBuffer[i] = 0.0f;
    }

    // Apply windowing function
    for (int i = 0; i < this->fftSize; ++i) {
        analysisInputBuffer[i] *= analysisWindow[i];
    }

    // Perform actual FFT using KissFFT, results go into this->fftMagnitudes
    performFFT(analysisInputBuffer.data(), this->fftMagnitudes.data());

    double currentMaxAmplitude = 0.0;
    for(int i = 0; i < numFrames; ++i) {
         float sampleVal = (numChannels == 1) ? buffer_input[i] : (buffer_input[i * numChannels] + buffer_input[i * numChannels + 1]) * 0.5f;
         float sampleVal = (numChannels == 1) ? buffer_input[i] : (buffer_input[i * numChannels] + buffer_input[i * numChannels + 1]) * 0.5f;
         float absSampleVal = std::abs(sampleVal);
         if (absSampleVal > currentMaxAmplitude) {
             currentMaxAmplitude = absSampleVal;
         }
    }
    amplitudeLevel.store(currentMaxAmplitude);

    float nyquist = static_cast<float>(sampleRate) / 2.0f;
    if (nyquist <= 0) nyquist = 22050.0f;

    float bassFreqMax = 250.0f;
    float midFreqMax = 4000.0f;

    int numSpectrumBins = fftSize / 2;
    if (numSpectrumBins <=0) {
        bassLevel.store(0.0); midLevel.store(0.0); highLevel.store(0.0); dominantFrequency.store(0.0);
        return;
    }

    int bassEndBin = static_cast<int>((bassFreqMax / nyquist) * numSpectrumBins);
    bassEndBin = std::min(bassEndBin, numSpectrumBins);

    int midEndBin = static_cast<int>((midFreqMax / nyquist) * numSpectrumBins);
    midEndBin = std::min(midEndBin, numSpectrumBins);

    double bassSum = 0.0, midSum = 0.0, highSum = 0.0;
    double maxMagnitudeInSpectrum = -1.0;
    int dominantBinIndex = 0;

    for (int i = 0; i <= numSpectrumBins; ++i) {
        if (static_cast<size_t>(i) >= fftMagnitudes.size()) break;
        float mag = fftMagnitudes[i];
        if (mag < 0.0f) mag = 0.0f;

        if (mag > maxMagnitudeInSpectrum) {
            maxMagnitudeInSpectrum = mag;
            dominantBinIndex = i;
        }
        float currentBinFreq = (static_cast<float>(i) / static_cast<float>(numSpectrumBins)) * nyquist;
        if (currentBinFreq <= bassFreqMax) {
            bassSum += mag;
        } else if (currentBinFreq <= midFreqMax) {
            midSum += mag;
        } else {
            highSum += mag;
        }
    }

    int bassBinsCount = bassEndBin + 1;
    int midBinsCount = midEndBin - bassEndBin;
    int highBinsCount = numSpectrumBins - midEndBin;

    bassLevel.store(bassBinsCount > 0 ? (bassSum / static_cast<double>(bassBinsCount)) : 0.0);
    midLevel.store(midBinsCount > 0 ? (midSum / static_cast<double>(midBinsCount)) : 0.0);
    highLevel.store(highBinsCount > 0 ? (highSum / static_cast<double>(highBinsCount)) : 0.0);

    float dominantFreqValue = (numSpectrumBins > 0) ? ((static_cast<float>(dominantBinIndex) / static_cast<float>(numSpectrumBins)) * nyquist) : 0.0f;
    dominantFrequency.store(dominantFreqValue);
}

// Audio analysis functions for visualization (getters)
double SynthEngine::getBassLevel() const {
    return bassLevel.load();
}
double SynthEngine::getMidLevel() const {
    return midLevel.load();
}
double SynthEngine::getHighLevel() const {
    return highLevel.load();
}
double SynthEngine::getAmplitudeLevel() const {
    return amplitudeLevel.load();
}
double SynthEngine::getDominantFrequency() const {
    return dominantFrequency.load();
}