# CLAUDE.md - SYNTHER PROFESSIONAL HOLOGRAPHIC

## CRITICAL PROJECT VISION

This is **Synther Professional Holographic** - a next-generation modular synthesizer featuring:

### 🎯 CORE DESIGN PHILOSOPHY
- **4D Polytopal HyperAV Integration** - Every visual element exists in multi-dimensional space
- **Vaporwave Holographic Translucency** - Glass-like surfaces with chromatic aberration
- **RGB Chromatic Separation** - Red/Green/Blue offset effects on interaction
- **Glitch & Moiré Interference** - Digital artifacts as aesthetic features
- **Modular Draggable Everything** - Every knob, control, and panel can be repositioned

### 🎛️ SYNTHESIZER REQUIREMENTS

**NEVER CREATE SIMPLIFIED OR DEMO VERSIONS** - This must be production-ready with:

#### Modular Interface System
- **Individual Draggable Knobs** - Each parameter control is independently positionable
- **Collapsible Parameter Banks** - Effects, oscillators, filters can be hidden/shown
- **Visual Parameter Feedback** - Real-time visualization behind every control
- **Reactive Micro-animations** - Haptic feedback and visual response to interaction

#### Comprehensive Effects Chain
- **Multi-band EQ** with spectral visualization
- **Reverb** (algorithmic, convolution, shimmer)
- **Delay** (tape, digital, ping-pong, grain)
- **Chorus/Flanger/Phaser** with modulation visualization
- **Distortion/Saturation** with harmonic analysis
- **Compressor/Limiter** with gain reduction meter
- **Filters** (low-pass, high-pass, band-pass, comb, formant)

#### Sound Generation
- **Multiple Oscillators** (sine, saw, square, noise, wavetable)
- **FM Synthesis** with operator visualization
- **Granular Synthesis** with particle display
- **Sample Playback** with waveform display
- **Additive Synthesis** with harmonic spectrum

### 🌈 VISUAL SYSTEM SPECIFICATIONS

#### HyperAV 4D Polytopal Integration
```dart
// Every UI element must implement 4D transformation
class PolytopolControl extends StatefulWidget {
  final Vector4 position;      // X, Y, Z, W coordinates
  final Matrix4 transform;     // 4D transformation matrix
  final ChromaticEffect chroma; // RGB separation on interaction
  final MoirePattern moire;    // Interference patterns
}
```

#### Vaporwave Holographic Materials
- **Translucent Glass** - backdrop-filter: blur() with opacity gradients
- **Neon Accents** - Bright cyan/magenta/purple edge lighting
- **Grid Overlays** - Retrowave grid patterns with depth
- **Chromatic Aberration** - RGB channel separation on hover/touch
- **Glitch Artifacts** - Intentional digital noise and displacement

#### RGB Offset Interaction Effects
```css
.knob:hover {
  filter: 
    drop-shadow(2px 0px 0px #ff0066)
    drop-shadow(-2px 0px 0px #00ffff)
    drop-shadow(0px 2px 0px #66ff00);
  transform: translate3d(0, 0, 10px);
}
```

### 🎵 AUDIO ENGINE REQUIREMENTS

#### Real-time Analysis Integration
- **FFT Spectrum Analyzer** - Behind every control
- **Waveform Oscilloscope** - Live audio visualization
- **Phase Correlation** - Stereo field display
- **Harmonic Analysis** - Overtone visualization
- **Envelope Followers** - Visual amplitude tracking

#### Modulation Matrix
- **Visual Connections** - Bezier curves connecting modulators to targets
- **Parameter Morphing** - Smooth interpolation between presets
- **LFO Visualization** - Real-time modulation waveforms
- **Envelope Shapes** - Interactive ADSR with visual feedback

### 🏗️ TECHNICAL ARCHITECTURE

#### Flutter Implementation
- **CustomPainter for all visualizations** - Direct canvas rendering
- **Transform3D widgets** - Hardware-accelerated 3D transforms
- **Shader integration** - GLSL effects for chromatic aberration
- **Provider state management** - Reactive parameter updates
- **Firebase real-time sync** - Cloud preset management

#### Performance Requirements
- **60fps minimum** - Silky smooth animations
- **Low-latency audio** - <10ms buffer sizes
- **GPU acceleration** - All visual effects hardware accelerated
- **Memory efficient** - Streaming large sample libraries

### 🎨 AESTHETIC GUIDELINES

#### Color Palette
- **Primary**: Electric cyan (#00FFFF)
- **Secondary**: Hot magenta (#FF0066) 
- **Accent**: Neon green (#66FF00)
- **Background**: Deep void black (#000011)
- **Glass**: Translucent white (rgba(255,255,255,0.1))

#### Typography
- **Headers**: Futuristic sans-serif with glow effects
- **Parameters**: Monospace with digital styling
- **Values**: Numeric displays with scan-line effects

#### Animation Principles
- **Ease-out curves** - Natural deceleration
- **Anticipation** - Slight reverse before main motion
- **Overshoot** - Elastic settling into position
- **Stagger** - Cascading animations across elements

### 🔧 DEVELOPMENT STANDARDS

#### Code Quality
- **NO PLACEHOLDERS** - Every feature must be fully implemented
- **NO DEMO VERSIONS** - Production-ready code only
- **Comprehensive error handling** - Graceful failure modes
- **Full documentation** - Every class and method documented

#### Testing Requirements
- **Unit tests** for all audio processing
- **Widget tests** for UI components  
- **Integration tests** for complete workflows
- **Performance benchmarks** - Frame rate and audio latency

### 🚀 DEPLOYMENT TARGETS

- **Web** - Primary platform via Firebase Hosting
- **Android** - Native performance with NDK
- **iOS** - Metal rendering for maximum performance
- **Desktop** - Electron wrapper for DAW integration

## REMEMBER: NO SHORTCUTS, NO SIMPLIFICATIONS, NO DEMOS
Every single feature must be implemented to professional standards with full visual integration of the 4D polytopal HyperAV system and vaporwave holographic aesthetic.