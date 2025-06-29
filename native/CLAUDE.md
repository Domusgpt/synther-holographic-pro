# native/ - C++ Audio Engine Core (CLAUDE.md)

This directory contains the C++ source code for Synther's native audio synthesis engine. This engine is responsible for all real-time audio generation, processing, MIDI handling, and parameter management.

## 1. Overview

The native engine is designed for high performance and low latency. It interfaces with the Flutter application via a C Foreign Function Interface (FFI). Key functionalities include:
- Sound synthesis (oscillators, wavetables, granular).
- Audio effects (filters, reverb, delay).
- MIDI event processing.
- Parameter automation recording and playback.
- Preset management (saving/loading engine state).
- FFT-based audio analysis for visualization.

**Key Guiding Documents for this Directory:**
- Overall Project Architecture: `../../ARCHITECTURE.md`
- Product Vision & Feature Details: `../../SYNTHER_VISION_AND_ARCHITECTURE.md`
- Root Project Context: `../../CLAUDE.md` (if it existed, or use its intended content)
- Public API for FFI: `native/include/synth_engine_api.h` (conceptual, or actual header)

## 2. Core Components & Structure

-   **`native/src/`**: Contains all source files.
    -   `synth_engine.h` & `synth_engine.cpp`: The heart of the audio engine. Implements the `SynthEngine` singleton class which manages all audio modules, processing, and state.
    -   `ffi_bridge.cpp` & `ffi_bridge.h` (or `.hh`): Implements the C functions exposed to Dart via FFI. These functions typically call methods on the `SynthEngine` instance.
    -   **`synthesis/`**: Modules for core sound generation and modification (e.g., `oscillator.h/cpp`, `filter.h/cpp`, `envelope.h/cpp`, `reverb.h/cpp`, `delay.h/cpp`).
    -   **`wavetable/`**: Components for wavetable synthesis (e.g., `wavetable_manager.h/cpp`, `wavetable_oscillator_impl.h/cpp`).
    -   **`granular/`**: Components for granular synthesis (e.g., `granular_synth.h/cpp`).
    -   **`audio_platform/`**: Abstraction layer for platform-specific audio I/O. `audio_platform.h/cpp` defines the interface, and specific implementations (e.g., `audio_platform_rtaudio.cpp` for desktop using RtAudio) provide the actual audio backend. This is crucial for cross-platform low-latency audio.
-   **`native/include/`**: Public header files. `synth_engine_api.h` would define the C API for FFI if it's structured that way.
-   **`native/third_party/`**: (Assumed location for external libraries like `kissfft`).
-   **`native/CMakeLists.txt`**: The build script for compiling the native library using CMake. This defines sources, include directories, and links against necessary libraries (e.g., RtAudio, KissFFT).

## 3. Build Process

-   The native library is built using CMake.
-   Flutter's build system for desktop and mobile platforms is typically configured to invoke CMake to build this native library and package it correctly.
-   For standalone development:
    ```bash
    cd native
    mkdir build && cd build
    cmake ..
    make # (or your specific build command, e.g., ninja)
    ```
    The output is typically a shared library (e.g., `libsynthengine.so`, `synthengine.dll`, `libsynthengine.dylib`).

## 4. Key Development Patterns & Considerations

-   **Real-time Safety**: Code in the audio callback (`SynthEngine::processAudio` and any `process` methods called from it) MUST be real-time safe. This means:
    -   No memory allocations/deallocations (use object pools or pre-allocate).
    -   No file I/O.
    -   No UI calls.
    -   No blocking operations or mutexes if possible (or keep critical sections extremely short).
-   **Parameter Smoothing**: Parameters changed from the UI/MIDI thread should be smoothed (e.g., using `SmoothedParameterF`) before being applied in the audio thread to prevent clicks and zipper noise.
-   **FFI Design**: The C functions in `ffi_bridge.cpp` are the boundary. They should be simple wrappers around `SynthEngine` functionality. Data marshalling (e.g., strings, lists of floats for FFT) needs careful handling.
-   **Memory Management**: Use smart pointers (e.g., `std::unique_ptr`, `std::shared_ptr`) for C++ objects. Memory passed across the FFI boundary needs careful management (e.g., Dart freeing memory allocated by C++ if explicitly documented).
-   **Error Handling**: Native functions should signal errors back to Dart (e.g., via return codes) where appropriate.
-   **Audio Analysis**: FFT data (magnitudes) is generated by `SynthEngine` using KissFFT and should be made available to Flutter via an FFI callback or getter.

## 5. Important Files to Reference

-   `native/src/synth_engine.h` & `.cpp` (main engine logic)
-   `native/src/ffi_bridge.cpp` (FFI implementation)
    - Header: `native/src/ffi_bridge.hh` (based on previous tool output)
-   `native/CMakeLists.txt` (build configuration)
-   Specific module headers/sources in `native/src/synthesis/`, etc., when working on those features.
-   `lib/core/ffi/native_audio_ffi.dart` (Dart side of FFI, for understanding how native functions are called).

## 6. Common Development Tasks (Examples for AI Assistant)

-   **"Add a new chorus effect to the C++ engine"**: Involves creating `chorus.h/cpp` in `native/src/synthesis/`, integrating it into `SynthEngine`, adding FFI controls in `ffi_bridge.cpp`, and exposing it in `native_audio_ffi.dart` and `AudioEngine.dart`.
-   **"Optimize the reverb algorithm for better performance"**: Focus on `native/src/synthesis/reverb.cpp` and its `process` method.
-   **"Expose the current BPM from the audio engine to Flutter"**: Add a getter in `SynthEngine`, an FFI function in `ffi_bridge.cpp`, and corresponding Dart FFI bindings.
-   **"Investigate audio clicks when changing the filter type"**: Check parameter smoothing for filter type and related parameters in `SynthEngine` and the `Filter` module.
