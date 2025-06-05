# SYNTHER - Implementation Roadmap
## Holographic UI Development Plan

### Immediate Tasks (Phase 2)

#### 1. Remove Visualizer Overlay Filter
**File:** `lib/simple_professional_interface.dart`
- Remove the `VisualizerOverlay` opacity wrapper
- Ensure pure HyperAV visualizer as background
- No filters, gradients, or overlays

#### 2. Create Holographic Widget Framework
**New Files:**
- `lib/ui/holographic/holographic_widget.dart` - Base draggable/resizable widget
- `lib/ui/holographic/holographic_theme.dart` - Vaporwave styling
- `lib/ui/styling/vaporwave_effects.dart` - Glow, energy effects

**Features:**
- Drag handles with holographic appearance
- Resize corners with energy glow
- Collapse/expand animations
- Translucent backgrounds with energy borders

#### 3. Holographic XY Pad
**File:** `lib/ui/widgets/holographic_xy_pad.dart`

**Features:**
- Translucent borders only, see-through center
- Dropdown for X-axis assignment:
  - Filter Cutoff
  - Filter Resonance  
  - Oscillator Mix
  - Reverb Mix
  - Custom MIDI CC (1-127)
- Dropdown for Y-axis assignment (same options)
- Chromatic note selection dropdown:
  - Root note: C, C#, D, D#, E, F, F#, G, G#, A, A#, B
  - Scale: Major, Minor, Chromatic, Pentatonic, etc.
- Key signature selection
- Holographic touch point with energy trail

#### 4. Holographic Keyboard
**File:** `lib/ui/widgets/holographic_keyboard.dart`

**Features:**
- Individual translucent keys with energy edges
- **Split Key Mode**: Each key can be dragged independently
- **Octave Selector**: Dropdown or wheel (C-1 to C9)
- **Key Width Adjustment**: Slider to make keys wider/thinner  
- **Bendwheels**: 
  - Pitch bend wheel (left side)
  - Modulation wheel (right side)
  - Both draggable independently
- **Velocity Layers**: Visual feedback for velocity
- Full MIDI output with note on/off, velocity, aftertouch

#### 5. Holographic Parameter Controls
**File:** `lib/ui/widgets/holographic_knob.dart`

**Features:**
- Energy ring appearance with vaporwave glow
- **Parameter Assignment Dropdown**:
  - Filter: Cutoff, Resonance, Drive
  - Envelope: Attack, Decay, Sustain, Release
  - LFO: Rate, Depth, Shape
  - Effects: Reverb, Delay, Chorus levels
  - Oscillator: Volume, Detune, Wavetable position
  - Custom MIDI CC assignment
- **MIDI Learn**: Right-click or long-press
- Floating holographic value display
- **Automation**: Record/playback mode indicator

#### 6. Layout Management System
**File:** `lib/ui/layout/workspace_manager.dart`

**Features:**
- Save/load workspace layouts
- Snap-to-grid option
- Z-order management
- Widget grouping
- Quick minimize all/restore

### Code Structure Examples

#### Holographic Widget Base
```dart
class HolographicWidget extends StatefulWidget {
  final Widget child;
  final bool isDraggable;
  final bool isResizable;
  final bool isCollapsible;
  final VoidCallback? onCollapse;
  
  // Holographic appearance
  final Color energyColor;
  final double glowIntensity;
  final double transparency;
}
```

#### XY Pad Dropdown System
```dart
enum XYPadAssignment {
  filterCutoff,
  filterResonance,
  oscillatorMix,
  reverbMix,
  delayTime,
  lfoRate,
  customMidiCC
}

class HolographicXYPad {
  XYPadAssignment xAssignment;
  XYPadAssignment yAssignment;
  int customMidiCCX; // 1-127
  int customMidiCCY; // 1-127
  ChromaticNote rootNote;
  ScaleType scaleType;
}
```

#### Keyboard Split System
```dart
class SplitKey {
  final int midiNote;
  Offset position;
  Size size;
  bool isPressed;
  double velocity;
}

class HolographicKeyboard {
  List<SplitKey> keys;
  int octaveRange; // -1 to 9
  double keyWidth;
  PitchBendWheel bendWheel;
  ModulationWheel modWheel;
}
```

### Visual Design Specifications

#### Color Palette (Vaporwave)
- **Primary Energy**: `#FF00FF` (Magenta)
- **Secondary Energy**: `#00FFFF` (Cyan)  
- **Accent**: `#FFFF00` (Electric Yellow)
- **Glow**: `#FF0080` (Hot Pink)
- **Background**: Transparent with 10-20% tint
- **Borders**: Bright neon with glow effect

#### Effects
- **Energy Glow**: Box shadow with color spread
- **Holographic Transparency**: 15-30% opacity
- **Edge Lighting**: Bright 1-2px borders
- **Hover Effects**: Intensity increase + scale
- **Touch Ripples**: Expanding energy circles

#### Animations
- **Drag**: Smooth follow with trail effect
- **Resize**: Elastic scaling with energy burst
- **Collapse**: Shrink to glowing dot
- **Expand**: Burst from dot with energy waves
- **Parameter Changes**: Pulse glow on value change

### Testing Requirements

#### Functionality Tests
- [ ] All widgets draggable without lag
- [ ] Resize maintains aspect ratio when needed
- [ ] Dropdowns work in all widget positions
- [ ] MIDI output matches UI interactions
- [ ] Visualizer remains unobstructed
- [ ] Cross-platform touch/mouse compatibility

#### Performance Tests  
- [ ] 60fps maintained with all widgets visible
- [ ] No visualizer frame drops during UI interaction
- [ ] Memory usage stable during drag/resize
- [ ] Audio latency under 10ms maintained

#### Visual Tests
- [ ] Holographic effects render on all platforms
- [ ] Energy glow effects work on mobile
- [ ] Transparency shows visualizer clearly
- [ ] No Z-fighting between widgets
- [ ] Consistent appearance across screen sizes

This roadmap ensures we build the exact holographic interface you envisioned while maintaining professional audio functionality.