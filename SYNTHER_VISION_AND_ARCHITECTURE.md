# SYNTHER - Professional Holographic Synthesizer
## Vision & Architecture Documentation

### Core Vision
Synther is a professional-grade, cross-platform synthesizer with a revolutionary holographic vaporwave interface floating over an unmolested HyperAV 4D audio-reactive visualizer background.

## Interface Philosophy

### Visual Paradigm
- **Pure HyperAV Background**: The audio-reactive 4D visualizer runs completely unfiltered as the background
- **Holographic UI Elements**: All controls float as translucent, energy-like holographic elements
- **See-Through Design**: Empty space shows pure visualizer - NO overlay filters
- **Vaporwave Aesthetic**: Neon edges, energy glows, holographic transparency effects

### UI Element Characteristics
All interface elements must be:
1. **Translucent/Holographic** - Show visualizer through them with energy-like appearance
2. **Draggable** - Can be moved anywhere on screen
3. **Resizable** - Can be scaled up/down
4. **Collapsible** - Can be minimized to small icons
5. **Functional Dropdowns** - Switch between different parameter assignments

## Core Components

### 1. XY Pad
- **Appearance**: Translucent borders with holographic glow, completely see-through center
- **Functionality**: 
  - X-axis dropdown: Filter Cutoff, Resonance, Oscillator Mix, Reverb, Custom MIDI CC
  - Y-axis dropdown: Filter Resonance, Cutoff, LFO Rate, Custom MIDI CC
  - Chromatic note selection: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
  - Key signature selection: All major/minor keys
- **Interaction**: Touch/drag for real-time parameter control
- **Visual**: Visualizer shows through pad, parameters affect visualizer in real-time

### 2. Virtual Keyboard
- **Appearance**: Translucent keys with holographic energy edges
- **Functionality**:
  - **Split Keys**: Individual keys can be separated and repositioned
  - **Octave Selection**: Dropdown or wheel to select octave range (C-1 to C9)
  - **Velocity Sensitivity**: Pressure-sensitive or velocity layers
  - **Key Width Adjustment**: Make keys wider/thinner
  - **Bendwheels**: Pitch bend and modulation wheels (draggable)
- **MIDI**: Full MIDI note output with velocity and aftertouch

### 3. Parameter Knobs/Sliders
- **Appearance**: Holographic energy rings with vaporwave glow effects
- **Functionality**:
  - **Parameter Assignment Dropdown**: Each knob can control any synth parameter
  - **Value Display**: Floating holographic readout
  - **MIDI Learn**: Right-click to assign MIDI CC
  - **Automation**: Record and playback parameter automation
- **Common Assignments**: Filter, Envelope, LFO, Effects, Oscillator parameters

### 4. LLM Preset Generator
- **Appearance**: Translucent terminal-style interface with neon glow
- **Functionality**:
  - Text input for natural language preset descriptions
  - AI-generated parameter settings
  - Preset morphing/interpolation
  - Save/load custom presets
- **Examples**: "warm analog bass", "ethereal pad with reverb", "aggressive lead synth"

### 5. Modular Layout System
- **Widget Management**: All UI elements can be:
  - Dragged to any position
  - Resized via corner handles
  - Collapsed to minimize screen space
  - Grouped into custom layouts
  - Saved as workspace presets
- **Snap Grid**: Optional snap-to-grid for precise alignment
- **Layer Management**: Z-order control for overlapping elements

## Technical Architecture

### Cross-Platform Compatibility
- **Flutter Framework**: Single codebase for Web, Windows, macOS, Linux, iOS, Android
- **Native Audio**: Platform-specific audio engines (ASIO, CoreAudio, ALSA, Web Audio)
- **WebGL Visualizer**: Hardware-accelerated 4D visualizer works on all platforms
- **Responsive Design**: Adapts to different screen sizes and input methods

### Audio Engine Requirements
- **Professional Grade**: 
  - 64-bit floating point processing
  - < 10ms latency
  - 192kHz/32-bit audio support
  - Multi-threaded processing
- **MIDI Support**:
  - Full MIDI I/O (notes, CC, aftertouch, pitch bend)
  - MIDI learn for all parameters
  - Multiple MIDI device support
  - MIDI clock sync
- **Features**:
  - Multiple oscillators with wavetables
  - Advanced filters (LP, HP, BP, Notch, Comb)
  - Professional effects (Reverb, Delay, Chorus, Distortion)
  - Granular synthesis
  - Real-time parameter modulation

### HyperAV Integration
- **Background Visualizer**: 
  - Pure, unfiltered 4D polytopal projection
  - Audio-reactive via microphone input
  - Synth parameter reactive (filter affects visuals)
  - 60fps smooth animation
- **Bridge Communication**:
  - Real-time parameter sync Flutter ↔ Visualizer
  - Audio analysis data sharing
  - Performance optimization

## Development Phases

### Phase 1: Foundational Architecture & Core Audio (Complete)
*   **Status:** Complete.
*   **Details:** Core audio engine using RtAudio/WebAudio, FFI bridge, basic parameter control, and initial visualizer established.

### Phase 2: Holographic UI & Visualizer Integration (Substantially Complete)
*   **Status:** Substantially Complete.
*   **Key Achievements:**
    *   Holographic widget system (draggable, resizable, collapsible).
    *   Glassmorphism and neon aesthetics.
    *   Primary UI layout (`SyntherUnifiedInterface` in `main_unified.dart`).
    *   Hypercube visualizer integrated as a background layer.
    *   Transparent UI elements allowing the visualizer to show through.
*   **Minor Pending Items:**
    *   Further refinement of holographic widget styling and animations.
    *   Performance optimizations for complex UI scenes.
    *   Complete removal of redundant/older UI files (`holographic_professional_interface.dart`, `holographic_synthesizer_interface.dart`, etc.) after ensuring all unique functionalities are migrated.

### Phase 3: Advanced Controls & Initial Feature Set (In Progress)
*   **Status:** In Progress.
*   **Item Status:**
    *   **XY Pad:** Implemented (`HolographicXYPad`). Basic touch input for two-parameter control is functional.
        *   *Needed:* Advanced assignment options, curve responses.
    *   **Holographic Keyboard:** Implemented (`HolographicKeyboard`). Basic note on/off functionality.
        *   *Needed:* Full velocity sensitivity, aftertouch visualization (requires engine support), pitch bend/mod wheel integration. Some TODOs exist in `synth_engine.cpp` for pitch bend and aftertouch.
    *   **Parameter Knobs:** Implemented (`HolographicAssignableKnob`, `NeonOrbitalControl`). Knobs can be assigned to various synth parameters via a dropdown.
        *   *Needed:* Full MIDI learn functionality (currently noted as a future enhancement, several TODOs in `control_panel_widget.dart` relate to this). Comprehensive mapping for all `SynthParameterType` enum values to `AudioEngine` getters/setters (partially complete, TODOs in `holographic_assignable_knob.dart`).
    *   **LLM Preset Generator:** Basic functionality implemented (`LLMPresetButton` in `main_unified.dart`).
        *   *Needed:* More sophisticated preset generation models, user input for generation guidance.
    *   **Visualizer Bridge:** Implemented (`MorphUIVisualizerBridge`). Parameters can animate visualizer.
        *   *Needed:* Smoothing, performance optimization (TODO in `parameter_visualizer_bridge.dart`), ensure all relevant parameters are bridged.
    *   **Automation System:** Basic UI elements for automation controls exist (`AutomationControlsWidget`).
        *   *Needed:* Full implementation of automation recording/playback, event handling (TODOs in `automation_controls_widget.dart` and `synth_engine.cpp` for applying automation from presets).

### Phase 4: Advanced Audio Engine Features (Planned)
*   **Key Pending Features:**
    *   Wavetable synthesis (TODOs in `synth_engine.cpp` regarding wavetable selection in presets).
    *   Granular synthesis elements.
    *   Expanded effects section (more built-in effects, routing).
    *   Modulation matrix improvements.

### Phase 5: Professional Polish & Extensibility (Planned)
*   **Key Pending Features:**
    *   Full MIDI mapping system (beyond basic learn for knobs).
    *   Plugin support (VST/AU, if feasible).
    *   Advanced preset management and sharing (partial TODO in `layout_preset_selector.dart` for sharing).
    *   Comprehensive in-app documentation and tutorials.
    *   Accessibility improvements.

## File Structure
```
/lib/
  /core/                    # Audio engine & parameters
  /ui/
    /holographic/          # Holographic UI components
    /widgets/              # Draggable/resizable widgets
    /styling/              # Vaporwave/holographic themes
  /features/
    /visualizer_bridge/    # HyperAV integration
    /midi/                 # MIDI I/O handling
    /presets/              # LLM preset system
  /utils/                  # Cross-platform utilities

/assets/
  /visualizer/             # HyperAV 4D visualizer files
  /shaders/                # Holographic effect shaders
  /fonts/                  # Vaporwave fonts
```

## Design Principles
1. **Visualizer First**: Never obstruct the 4D visualizer - it's the centerpiece
2. **Holographic Interaction**: UI should feel like floating energy, not solid glass
3. **Professional Function**: Every feature must meet professional synthesizer standards
4. **Modular Flexibility**: Users can customize their workspace completely
5. **Cross-Platform Consistency**: Same experience on all devices
6. **Performance Critical**: 60fps visuals + <10ms audio latency always

This documentation ensures future development maintains the core vision of a professional holographic synthesizer with unobstructed 4D visuals.