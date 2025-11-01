import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'parameter_visualizer_bridge.dart';
import 'synth_parameters.dart';

/// Audio-Reactive Visual Controller
///
/// Maps 7 frequency bands to comprehensive visual parameters:
/// - Sub Bass (20-60Hz) → 4D W-axis rotation, density expansion, deep pulses
/// - Bass (60-250Hz) → Perspective shifts, scale pulsing, shake intensity
/// - Low Mids (250-500Hz) → XY rotation, warm color shifts, morphing
/// - Mids (500-2kHz) → Pattern intensity, chaos factor, medium color shifts
/// - High Mids (2k-4kHz) → ZW rotation, glitch bursts, complexity
/// - Presence (4k-6kHz) → Color flashes, brightness pulses, shimmer
/// - Brilliance (6k-20kHz) → Fine detail, chromatic aberration, sparkle
class AudioReactiveController extends ChangeNotifier {
  final ParameterVisualizerBridge _visualBridge;

  // 7-band frequency analysis
  final List<double> _bandLevels = List.filled(7, 0.0);
  final List<double> _bandPeaks = List.filled(7, 0.0);
  final List<double> _bandSmoothed = List.filled(7, 0.0);

  // Derived reactive parameters
  double _totalEnergy = 0.0;
  double _spectralCentroid = 0.0; // Brightness of the sound
  double _spectralFlux = 0.0;     // Rate of change

  // 4D rotation states (accumulated over time)
  double _rotation4dXY = 0.0;
  double _rotation4dZW = 0.0;
  double _rotation4dXW = 0.0;
  double _rotation4dYZ = 0.0;

  // Visual state memory
  double _densityTarget = 8.0;
  double _densityCurrent = 8.0;
  double _chaosTarget = 0.0;
  double _chaosCurrent = 0.0;

  Timer? _updateTimer;

  // Smoothing factors
  static const double _attackTime = 0.05;  // Fast attack
  static const double _releaseTime = 0.3;  // Slower release

  // Sensitivity multipliers
  static const double _subBassRotationSensitivity = 2.0;
  static const double _bassScaleSensitivity = 0.5;
  static const double _midRotationSensitivity = 180.0;
  static const double _highDetailSensitivity = 0.15;

  AudioReactiveController(this._visualBridge) {
    _startReactiveLoop();
  }

  void _startReactiveLoop() {
    // Update at ~60fps for smooth visual response
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateVisualParameters();
    });
  }

  /// Update band levels from audio analysis
  void updateBandLevels(List<double> levels) {
    if (levels.length != 7) return;

    for (int i = 0; i < 7; i++) {
      _bandLevels[i] = levels[i];

      // Update peaks
      if (_bandLevels[i] > _bandPeaks[i]) {
        _bandPeaks[i] = _bandLevels[i];
      } else {
        _bandPeaks[i] *= 0.95; // Peak decay
      }

      // Smooth with attack/release
      if (_bandLevels[i] > _bandSmoothed[i]) {
        _bandSmoothed[i] += (_bandLevels[i] - _bandSmoothed[i]) * _attackTime;
      } else {
        _bandSmoothed[i] += (_bandLevels[i] - _bandSmoothed[i]) * _releaseTime;
      }
    }

    _calculateDerivedParameters();

    // NEW: Send band levels to JavaScript for 5-layer system
    _visualBridge.updateBandLevels(_bandSmoothed);
  }

  void _calculateDerivedParameters() {
    // Total energy (RMS-like)
    _totalEnergy = 0.0;
    for (int i = 0; i < 7; i++) {
      _totalEnergy += _bandSmoothed[i] * _bandSmoothed[i];
    }
    _totalEnergy = math.sqrt(_totalEnergy / 7.0);

    // Spectral centroid (weighted average frequency)
    double weightedSum = 0.0;
    double totalWeight = 0.0;
    for (int i = 0; i < 7; i++) {
      weightedSum += _bandSmoothed[i] * (i + 1);
      totalWeight += _bandSmoothed[i];
    }
    _spectralCentroid = totalWeight > 0.01 ? weightedSum / totalWeight / 7.0 : 0.5;

    // Spectral flux (rate of change)
    double flux = 0.0;
    for (int i = 0; i < 7; i++) {
      double diff = _bandLevels[i] - _bandSmoothed[i];
      flux += diff * diff;
    }
    _spectralFlux = math.sqrt(flux / 7.0);
  }

  void _updateVisualParameters() {
    if (!_visualBridge.isConnected) return;

    // === BAND 0: SUB BASS (20-60Hz) ===
    // Drives: 4D W-axis rotation, density expansion, deep pulses
    final subBass = _bandSmoothed[0];
    final subBassPeak = _bandPeaks[0];

    // 4D rotation on W-axis (most fundamental rotation)
    _rotation4dXW += subBass * _subBassRotationSensitivity;

    // Density expansion on sub bass hits
    _densityTarget = 8.0 + (subBassPeak * 12.0); // 8-20 range
    _densityCurrent += (_densityTarget - _densityCurrent) * 0.1;
    _visualBridge.updateParameter('gridDensity', _densityCurrent);

    // Universe scale pulses
    final universeScale = 1.0 + (subBass * 0.8);
    _visualBridge.updateParameter('universeModifier', universeScale);

    // === BAND 1: BASS (60-250Hz) ===
    // Drives: Perspective shifts, scale pulsing, shake intensity
    final bass = _bandSmoothed[1];
    final bassPeak = _bandPeaks[1];

    // Pattern intensity pulses with bass
    final patternIntensity = 0.8 + (bass * 1.5);
    _visualBridge.updateParameter('patternIntensity', patternIntensity);

    // Scale/zoom effect
    final morphFactor = 0.7 + (bass * 1.0) + (bassPeak * 0.5);
    _visualBridge.updateParameter('morphFactor', morphFactor);

    // Shake/chaos on bass hits
    if (bassPeak > 0.7) {
      _chaosTarget = bassPeak * 0.5;
    }
    _chaosCurrent += (_chaosTarget - _chaosCurrent) * 0.2;
    _chaosTarget *= 0.9; // Decay

    // === BAND 2: LOW MIDS (250-500Hz) ===
    // Drives: XY rotation, warm color shifts, morphing
    final lowMid = _bandSmoothed[2];

    // Primary XY rotation driven by low mids
    _rotation4dXY += lowMid * _midRotationSensitivity * 0.02;
    _visualBridge.updateParameter('rotationX', (_rotation4dXY % 360.0));

    // Warm color shifts (reds, oranges)
    final colorShiftWarm = lowMid * 0.3;

    // === BAND 3: MIDS (500-2kHz) ===
    // Drives: Y rotation, chaos factor, medium color shifts
    final mid = _bandSmoothed[3];
    final midPeak = _bandPeaks[3];

    // Y-axis rotation
    _rotation4dYZ += mid * _midRotationSensitivity * 0.02;
    _visualBridge.updateParameter('rotationY', (_rotation4dYZ % 360.0));

    // Rotation speed increases with mid energy
    final rotationSpeed = 0.3 + (mid * 2.0);
    _visualBridge.updateParameter('rotationSpeed', rotationSpeed);

    // Chaos/glitch increases with mid peaks
    if (midPeak > 0.6) {
      final glitchAmount = midPeak * 0.12;
      _visualBridge.updateParameter('glitchIntensity', glitchAmount);
    }

    // === BAND 4: HIGH MIDS (2k-4kHz) ===
    // Drives: ZW rotation (4D), glitch bursts, complexity
    final highMid = _bandSmoothed[4];
    final highMidPeak = _bandPeaks[4];

    // 4D ZW rotation (more complex 4D movement)
    _rotation4dZW += highMid * _midRotationSensitivity * 0.015;

    // Line thickness varies with high mids
    final lineThickness = 0.02 + (highMid * 0.06);
    _visualBridge.updateParameter('lineThickness', lineThickness);

    // Glitch bursts on high mid peaks
    if (highMidPeak > 0.7) {
      _visualBridge.updateParameter('glitchIntensity', highMidPeak * 0.15);
    }

    // === BAND 5: PRESENCE (4k-6kHz) ===
    // Drives: Color flashes, brightness pulses, shimmer
    final presence = _bandSmoothed[5];
    final presencePeak = _bandPeaks[5];

    // Bright color shifts (cyans, magentas)
    final colorShiftBright = presence * 0.4 + colorShiftWarm;
    _visualBridge.updateParameter('colorShift', colorShiftBright.clamp(0.0, 1.0));

    // Brightness flashes on presence peaks
    if (presencePeak > 0.6) {
      final flashIntensity = 1.2 + (presencePeak * 1.0);
      _visualBridge.updateParameter('patternIntensity', flashIntensity);
    }

    // === BAND 6: BRILLIANCE (6k-20kHz) ===
    // Drives: Fine detail, chromatic aberration, sparkle
    final brilliance = _bandSmoothed[6];
    final brilliancePeak = _bandPeaks[6];

    // Dimension shift on high frequency content
    final dimensionShift = 4.0 + (brilliance * 1.0);
    _visualBridge.updateParameter('dimension', dimensionShift);

    // === DERIVED PARAMETERS ===

    // Overall energy affects global intensity
    if (_totalEnergy > 0.1) {
      final energyBoost = 1.0 + (_totalEnergy * 0.5);
      // Applied as multiplier to existing pattern intensity
    }

    // Spectral centroid affects color temperature
    // Low centroid (bass-heavy) → warm colors
    // High centroid (treble-heavy) → cool colors
    final colorTemp = _spectralCentroid;

    // Spectral flux creates micro-movements
    if (_spectralFlux > 0.3) {
      // Add jitter/chaos to rotation
      _rotation4dXY += (_spectralFlux - 0.3) * 10.0;
    }

    notifyListeners();
  }

  /// Map synth parameters to visual characteristics
  void updateFromSynthParameters(SynthParametersModel synth) {
    // Filter cutoff affects visual sharpness
    final normalizedCutoff = (synth.filterCutoff - 20.0) / 19980.0;
    _visualBridge.updateParameter('lineThickness', 0.01 + (normalizedCutoff * 0.08));

    // Filter resonance affects glitch/artifact intensity
    _visualBridge.updateParameter('glitchIntensity', synth.filterResonance * 0.1);

    // Attack time affects morph speed
    final attackNormalized = (synth.attackTime / 5.0).clamp(0.0, 1.0);
    _visualBridge.updateParameter('morphFactor', 0.5 + (attackNormalized * 1.0));

    // NEW Phase 4: Decay time → contraction speed
    final decayNormalized = (synth.decayTime / 5.0).clamp(0.0, 1.0);
    _visualBridge.updateParameter('contractionSpeed', 0.1 + (decayNormalized * 2.9));

    // NEW Phase 4: Sustain level → stability factor (inverse)
    // Higher sustain = more stable (less jitter)
    final sustainStability = 1.0 - (synth.sustainLevel * 0.5);
    _visualBridge.updateParameter('stabilityFactor', sustainStability);

    // NEW Phase 4: Release time → dissolve factor
    final releaseNormalized = (synth.releaseTime / 10.0).clamp(0.0, 1.0);
    _visualBridge.updateParameter('dissolveFactor', releaseNormalized);

    // Reverb affects density/depth
    final reverbDensity = 8.0 + (synth.reverbMix * 10.0);
    _visualBridge.updateParameter('gridDensity', reverbDensity);

    // Delay time affects rotation phasing
    // Longer delays create slower, more pronounced movements
    final delayFactor = (synth.delayTime / 2.0).clamp(0.0, 1.0);
    final rotationSpeed = 0.5 + (delayFactor * 1.5);
    // Note: This gets overridden by audio reactivity, but sets the base

    // Master volume affects overall visual intensity
    _visualBridge.updateParameter('patternIntensity', 0.5 + (synth.masterVolume * 1.5));

    // NEW Phase 4 & 6: Effect-to-geometry auto-switching
    // This creates immediate visual parity when effects are enabled

    // Note: These would require effect enable/disable flags in SynthParametersModel
    // For now, we'll check effect mix/amount values

    // If reverb is high, suggest using membrane geometry (rippling)
    if (synth.reverbMix > 0.4) {
      // Could auto-switch: _visualBridge.setGeometryType(GeometryType.membrane);
      // For now, just set effect-specific parameters
    }

    // If delay feedback is high, suggest echo trails
    if (synth.delayFeedback > 0.5) {
      _visualBridge.updateParameter('universeModifier', 1.2 + (synth.delayFeedback * 0.8));
    }

    // Placeholder for future chorus/phaser/distortion/compressor
    // These require adding effect enable flags to SynthParametersModel:
    //
    // if (synth.chorusEnabled && synth.chorusMix > 0.1) {
    //   _visualBridge.setGeometryType(GeometryType.interference);
    //   _visualBridge.updateParameter('interferenceAmount', synth.chorusMix);
    // }
    //
    // if (synth.phaserEnabled && synth.phaserRate > 0.0) {
    //   _visualBridge.setGeometryType(GeometryType.helix);
    //   _visualBridge.updateParameter('helixRotationSpeed', synth.phaserRate * 2.0);
    // }
    //
    // if (synth.distortionAmount > 0.1) {
    //   _visualBridge.setGeometryType(GeometryType.crystalline);
    //   _visualBridge.updateParameter('facetSharpness', synth.distortionAmount);
    // }
    //
    // if (synth.compressorEnabled) {
    //   _visualBridge.updateParameter('breathingDepth', synth.compressorRatio * 0.3);
    // }
  }

  /// Get current band levels (for optional UI display)
  List<double> get bandLevels => List.unmodifiable(_bandLevels);
  List<double> get bandPeaks => List.unmodifiable(_bandPeaks);

  /// Get derived parameters for advanced visualizations
  double get totalEnergy => _totalEnergy;
  double get spectralCentroid => _spectralCentroid;
  double get spectralFlux => _spectralFlux;

  /// NEW Phase 5: LFO Visual Integration
  /// Maps LFO modulation to visual parameters with waveform-specific transitions
  /// @param lfoIndex - Which LFO (0-3)
  /// @param value - LFO output value (0-1)
  /// @param rate - LFO rate in Hz
  /// @param waveform - LFO waveform type ('sine', 'triangle', 'square', 'sawtooth', 'random')
  void updateFromLFO(int lfoIndex, double value, double rate, {String waveform = 'sine'}) {
    if (lfoIndex < 0 || lfoIndex > 3) return;

    // Apply waveform-specific transformation
    double transformedValue = value;
    switch (waveform) {
      case 'sine':
        // Smooth interpolation (already 0-1 sine wave)
        transformedValue = value;
        break;
      case 'triangle':
        // Linear ramp up and down
        transformedValue = value;
        break;
      case 'square':
        // Hard step
        transformedValue = value > 0.5 ? 1.0 : 0.0;
        break;
      case 'sawtooth':
        // Ascending ramp
        transformedValue = value;
        break;
      case 'random':
        // Noise-based jitter (add randomness)
        transformedValue = value + (math.Random().nextDouble() * 0.2 - 0.1);
        transformedValue = transformedValue.clamp(0.0, 1.0);
        break;
    }

    // Map each LFO to specific visual parameters
    switch (lfoIndex) {
      case 0:
        // LFO 1 → Rotation speed modulation
        final speedMod = 0.5 + (transformedValue * 1.5);
        _visualBridge.updateParameter('rotationSpeed', speedMod);
        break;

      case 1:
        // LFO 2 → Morph factor oscillation
        final morphMod = 0.5 + (transformedValue * 1.0);
        _visualBridge.updateParameter('morphFactor', morphMod);
        break;

      case 2:
        // LFO 3 → Color shift cycling
        _visualBridge.updateParameter('colorShift', transformedValue);
        break;

      case 3:
        // LFO 4 → Grid density breathing
        final densityMod = 6.0 + (transformedValue * 10.0);
        _visualBridge.updateParameter('gridDensity', densityMod);
        break;
    }
  }

  /// NEW Phase 5: Simplified LFO update (just value, auto-detects waveform from pattern)
  void updateLFO(int lfoIndex, double value) {
    updateFromLFO(lfoIndex, value, 1.0, waveform: 'sine');
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
