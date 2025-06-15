# lib/ - Flutter Application Core (CLAUDE.md)

This directory contains all the Dart code for the Synther Flutter application.

## 1. Overview

The `lib/` directory houses the user interface, application logic, state management, and the Dart-side interface to the native audio engine and JavaScript visualizer. It's structured to separate concerns into core logic, UI features, design system elements, and platform-specific services.

**Key Guiding Documents for this Directory:**
- Overall Project Architecture: `../../ARCHITECTURE.md`
- Product Vision & UI/Feature Details: `../../SYNTHER_VISION_AND_ARCHITECTURE.md`
- Root Project Context: `../../CLAUDE.md` (if it existed, or use its intended content)

## 2. Core Sub-directories & Their Roles

-   **`lib/core/`**:
    -   Contains fundamental services and models.
    -   `audio_engine.dart`: Primary Dart interface for interacting with the native C++ audio engine.
    -   `synth_parameters.dart`: Defines the `SynthParametersModel` (using `ChangeNotifier`) which holds the state of all synthesizer parameters. This is crucial for UI reactivity.
    -   `ffi/native_audio_ffi.dart`: Manages FFI bindings to the C++ native library.
    -   `*_backend.dart` files: Handle platform-specific audio initializations or abstractions.

-   **`lib/features/`**:
    -   Houses widgets and logic for distinct application features. Each sub-directory typically represents a major UI component or functionality.
    -   Examples:
        -   `xy_pad/xy_pad_widget.dart`: The interactive XY pad control.
        -   `keyboard/keyboard_widget.dart`: The virtual keyboard.
        -   `controls/control_panel_widget.dart`: Hosts knobs, sliders.
        -   `llm_presets/llm_preset_widget.dart`: UI for AI preset generation.
        -   `automation/automation_controls_widget.dart`: UI for automation recording/playback.
        -   `presets/preset_manager_widget.dart`: UI for saving/loading presets.
        -   `visualizer_bridge/`: Widgets and logic for embedding and communicating with the HyperAV visualizer (WebView-based).
        -   `midi_settings/`: UI for MIDI configuration.

-   **`lib/ui/`**:
    -   Focuses on visual presentation and overall UI shell.
    -   `holographic/holographic_theme.dart`: Defines the core color palette, styles, and visual effects (glows, translucency) for the "Holographic" aesthetic. This is fundamental to the app's look and feel.
    -   `holographic_widgets.dart` (or similar): May contain reusable UI elements specific to the holographic theme.
    -   Files like `holographic_professional_interface.dart` or `interactive_draggable_interface.dart` likely define the main application layout and draggable panel system.

-   **`lib/design_system/`**:
    -   May contain the "Morph UI" components, a more general set of reusable UI elements (buttons, knobs, faders, panes) that are then styled by the `HolographicTheme`.

-   **`lib/services/`**:
    -   For external service integrations, e.g., `firebase_service.dart`.

-   **`lib/utils/`**:
    -   General utility functions and helper classes.

-   **`lib/main_unified.dart` (or `main.dart`)**:
    -   The main entry point for the Flutter application. Initializes services, sets up `Provider`s (like `SynthParametersModel`), and launches the root widget.

## 3. State Management

-   The primary state for synthesizer parameters is managed in `SynthParametersModel` (`lib/core/synth_parameters.dart`).
-   This model uses `ChangeNotifier` and is provided to the widget tree using `ChangeNotifierProvider` (typically in `main_unified.dart` or `morph_app.dart`).
-   UI widgets that display or control synth parameters should consume `SynthParametersModel` to react to state changes.
-   **Critical Note for AI Development**: Parameter changes can originate from the UI, MIDI input, automation playback (from C++ engine), or preset loading (from C++ engine). A robust FFI callback mechanism (`ParameterChangeCallback` in C++, bridged to Dart) is intended to update `SynthParametersModel` when changes come from the native side. UI widgets *must* listen to this model to reflect these external changes, not just rely on their local state after user interaction.

## 4. Key Development Patterns & Considerations

-   **Holographic Styling**: When creating new UI, always use `HolographicTheme` to ensure visual consistency.
-   **Modularity**: Features are generally encapsulated in their own directories under `lib/features/`.
-   **FFI Interaction**: All native audio engine calls go through `AudioEngine` and `NativeAudioLib` (FFI).
-   **Performance**:
    -   Be mindful of widget rebuilds, especially for controls that update frequently or are driven by audio-rate data.
    -   Custom painters (`CustomPaint`) are used for many controls; optimize their `paint` methods.
    -   The visualizer is WebView-based, so communication via `postMessage` should be efficient.
-   **Context for AI**: When asked to modify or add UI features:
    -   Refer to `HolographicTheme` for styling.
    -   Check existing widgets in `lib/features/` for patterns.
    -   Understand how data flows from `SynthParametersModel` to widgets and from widgets to `AudioEngine`.

## 5. Important Files to Reference

-   `lib/core/synth_parameters.dart` (for synth state)
-   `lib/core/audio_engine.dart` (for engine interaction)
-   `lib/ui/holographic/holographic_theme.dart` (for styling)
-   The specific widget file if modifying an existing feature (e.g., `lib/features/xy_pad/xy_pad_widget.dart`).
-   `lib/main_unified.dart` or `morph_app.dart` (for app setup and providers).
