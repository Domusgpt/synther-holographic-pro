# assets/visualizer/ - HyperAV WebGL Visualizer (CLAUDE.md)

This directory contains all the assets for the HyperAV 4D audio-reactive visualizer, which is a standalone web application embedded into the Synther Flutter app via a WebView (specifically, an IFrame on web).

## 1. Overview

HyperAV is built with vanilla JavaScript (ES6+), HTML, CSS, and WebGL. It's designed to be highly performant and visually captivating, rendering complex 4D geometries that react to audio input and synthesizer parameters.

**Key Guiding Documents for this Directory:**
- Visualizer Specifics: `assets/visualizer/README.md` (this very directory)
- Overall Project Architecture: `../../ARCHITECTURE.md`
- Product Vision & UI/Feature Details: `../../SYNTHER_VISION_AND_ARCHITECTURE.md`
- Root Project Context: `../../CLAUDE.md` (if it existed, or use its intended content)

## 2. Core Components & Structure

-   **`assets/visualizer/index-hyperav.html`** (or `index-flutter.html`, `index.html`): The main HTML file that loads the visualizer. `VisualizerBridgeWidget` in Flutter points to `assets/assets/visualizer/index-hyperav.html` (note the double `assets/` in path from Flutter's perspective due to asset bundling).
-   **`assets/visualizer/js/`**: Contains primary JavaScript logic.
    -   `visualizer-main.js` (or `visualizer-main-hyperav.js`): The main script that initializes the visualizer, sets up the render loop, handles UI interactions (if any enabled), and manages parameter mapping. This is where `window.signalVisualizerCoreReady()` should be called.
    -   `flutter-bridge.js`: Crucial for communication with the Flutter host. It receives messages (parameters, FFT data, commands) from Flutter via `postMessage` and updates the visualizer's internal state (`window.visualParams`, `window.syntherFftData`). It also defines functions that can be called by Flutter and signals readiness back to Flutter.
    -   `visualizer-globals.js`: May define global variables or settings for the visualizer.
-   **`assets/visualizer/core/`**: The core rendering engine of HyperAV.
    -   `HypercubeCore.js`: The main WebGL rendering class, responsible for drawing the 4D geometry, applying transformations, and managing the scene. It consumes parameters from `window.visualParams` (or a similar structure passed to its update methods).
    -   `ShaderManager.js`: Compiles and manages GLSL shaders.
    -   `GeometryManager.js`: Generates 4D geometric primitives.
    -   `ProjectionManager.js`: Handles the 4D to 3D projection mathematics.
-   **`assets/visualizer/css/`**: Stylesheets for the visualizer's HTML elements (though most of its native UI should be disabled when embedded in Synther).
-   **`assets/visualizer/sound/`**: Handles audio input and analysis *if* the visualizer is using its own microphone input (as opposed to receiving FFT data from Synther).
    -   `SoundInterface.js`: Manages audio context and microphone access.
    -   `AnalysisModule.js`: Performs frequency analysis (e.g., FFT) on the audio stream.
    -   `EffectsModule.js`: May map audio analysis results to visual parameters.
    *(Note: When Synther provides its own FFT data, these internal audio processing parts of HyperAV might be partially or fully bypassed by logic in `visualizer-main.js`.)*

## 3. Communication with Flutter

-   Communication is primarily via `window.postMessage` from Flutter to the visualizer's IFrame, and potentially from the IFrame back to Flutter (though currently less used).
-   `flutter-bridge.js` is the key listener for messages from Flutter. It expects messages with a `type` field (e.g., `parameterUpdate`, `fftDataUpdate`, `toggleControls`) and a data payload.
-   The bridge script updates global JavaScript variables (e.g., `window.visualParams`, `window.syntherFftData`) that `visualizer-main.js` then reads in its render loop to update `HypercubeCore.js`.
-   Readiness is signaled from `visualizer-main.js` (after `HypercubeCore.js` is ready) by calling `window.signalVisualizerCoreReady()`, which is defined in `flutter-bridge.js`. This, in turn, notifies Flutter.

## 4. Key Development Patterns & Considerations

-   **Parameter Mapping**: The translation of Synther's parameters (e.g., filter cutoff) to visual effects (e.g., 4D object rotation or color) is defined in the `_parameterMap` within `flutter-bridge.js`. This is a critical area for tuning the audio-visual experience.
-   **Performance**: WebGL performance is key. Shaders should be optimized. The amount of data passed via `postMessage` per frame should be reasonable.
-   **Hiding Native UI**: The visualizer's own HTML controls should be hidden by default when embedded in Synther. `visualizer-main.js` contains `setVisualizerControlsVisibility(show)` for this, triggered by Flutter.
-   **Audio Reactivity Source**: `visualizer-main.js` is configured to prioritize FFT data from Synther (`window.syntherFftData`) if available, falling back to its own microphone/audio analysis.
-   **Debugging**: Use browser developer tools (Console, Debugger, Profiler) when the visualizer is running (either standalone via its HTML file or within the Flutter web app).

## 5. Important Files to Reference

-   `assets/visualizer/js/flutter-bridge.js` (Flutter communication logic)
-   `assets/visualizer/js/visualizer-main.js` (Main visualizer control logic, parameter application)
-   `assets/visualizer/core/HypercubeCore.js` (Core WebGL rendering - to understand what visual parameters it accepts)
-   `assets/visualizer/README.md` (General visualizer info)
-   `lib/features/visualizer_bridge/visualizer_bridge_widget_web.dart` (Flutter side of the bridge)

## 6. Common Development Tasks (Examples for AI Assistant)

-   **"Change how 'filter resonance' affects the visualizer"**: Modify the entry for `filterResonance` in the `_parameterMap` in `assets/visualizer/js/flutter-bridge.js` (both its `target` visual parameter and its `scale` function).
-   **"Add a new visual effect that reacts to the LFO 1 rate from Synther"**:
    1.  Ensure LFO 1 rate is sent from `_syncParametersToVisualizer` in `VisualizerBridgeWidget` (Flutter).
    2.  Add a new entry in `_parameterMap` in `flutter-bridge.js` for `lfo1Rate`, mapping it to a new or existing `target` visual parameter in `HypercubeCore.js`.
    3.  If it's a new visual parameter, modify `HypercubeCore.js` to use it in its rendering logic.
-   **"Debug why the visualizer isn't responding to bass frequencies from Synther's FFT"**: Check `visualizer-main.js` to see how `window.syntherFftData` is processed into `bassLevel`, and how `bassLevel` is used to update `mainVisualizerCore`. Also check `flutter-bridge.js` to ensure FFT data is arriving correctly.
