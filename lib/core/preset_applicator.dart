import 'dart:math';
import 'synth_parameters.dart';
import 'parameter_visualizer_bridge.dart';
import 'visual_preset_system.dart';

/// Applies visual presets to the synth and visualizer
class PresetApplicator {
  final SynthParametersModel _synth;
  final ParameterVisualizerBridge _bridge;

  PresetApplicator(this._synth, this._bridge);

  /// Apply a preset to current state
  /// If smooth is true, parameters will interpolate over time
  /// Note: Tier 1-3 changes (family, polytope, geometry) are always immediate
  void applyPreset(VisualPreset preset, {bool smooth = false}) {
    // Set Tier 1-3: Family, Polytope, Geometry (always immediate)
    _bridge.setVisualizerFamily(preset.family);
    _bridge.setPolytope(preset.polytope);
    _bridge.setGeometryType(preset.geometry);

    // Apply Effects (immediate, but parameters can be smooth)
    preset.effectsEnabled.forEach((effect, enabled) {
      switch (effect) {
        case 'chorus':
          _synth.setChorusEnabled(enabled);
          if (enabled && preset.effectParameters.containsKey('chorusMix')) {
            _synth.setChorusMix(preset.effectParameters['chorusMix']!);
          }
          if (enabled && preset.effectParameters.containsKey('chorusRate')) {
            _synth.setChorusRate(preset.effectParameters['chorusRate']!);
          }
          break;
        case 'distortion':
          _synth.setDistortionEnabled(enabled);
          if (enabled && preset.effectParameters.containsKey('distortionAmount')) {
            _synth.setDistortionAmount(preset.effectParameters['distortionAmount']!);
          }
          break;
        case 'phaser':
          _synth.setPhaserEnabled(enabled);
          if (enabled && preset.effectParameters.containsKey('phaserRate')) {
            _synth.setPhaserRate(preset.effectParameters['phaserRate']!);
          }
          if (enabled && preset.effectParameters.containsKey('phaserDepth')) {
            _synth.setPhaserDepth(preset.effectParameters['phaserDepth']!);
          }
          break;
        case 'compressor':
          _synth.setCompressorEnabled(enabled);
          if (enabled && preset.effectParameters.containsKey('compressorRatio')) {
            _synth.setCompressorRatio(preset.effectParameters['compressorRatio']!);
          }
          break;
        case 'flanger':
          _synth.setFlangerEnabled(enabled);
          if (enabled && preset.effectParameters.containsKey('flangerDepth')) {
            _synth.setFlangerDepth(preset.effectParameters['flangerDepth']!);
          }
          if (enabled && preset.effectParameters.containsKey('flangerRate')) {
            _synth.setFlangerRate(preset.effectParameters['flangerRate']!);
          }
          break;
        case 'reverb':
          if (preset.effectParameters.containsKey('reverbMix')) {
            _synth.setReverbMix(preset.effectParameters['reverbMix']!);
          }
          break;
      }
    });

    // Apply LFOs
    for (int i = 0; i < 4; i++) {
      if (i < preset.lfoEnabled.length) {
        _synth.setLFOEnabled(i, preset.lfoEnabled[i]);
      }
      if (i < preset.lfoRates.length) {
        _synth.setLFORate(i, preset.lfoRates[i]);
      }
      if (i < preset.lfoWaveforms.length) {
        _synth.setLFOWaveform(i, preset.lfoWaveforms[i]);
      }
    }

    // Apply Visual Parameters
    _bridge.updateParameter('rotationSpeed', preset.rotationSpeed);
    _bridge.updateParameter('morphFactor', preset.morphFactor);
    _bridge.updateParameter('gridDensity', preset.gridDensity);
    _bridge.updateParameter('glitchIntensity', preset.glitchIntensity);
    _bridge.updateParameter('colorShift', preset.colorShift);
  }

  /// Capture current state as a preset
  VisualPreset captureCurrentState({
    required String name,
    required String description,
    PresetCategory category = PresetCategory.custom,
    List<String> tags = const [],
  }) {
    return VisualPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      family: _bridge.currentConfiguration.family,
      polytope: _bridge.currentConfiguration.polytope,
      geometry: _bridge.currentConfiguration.geometryType,
      effectsEnabled: {
        'chorus': _synth.chorusEnabled,
        'distortion': _synth.distortionEnabled,
        'phaser': _synth.phaserEnabled,
        'compressor': _synth.compressorEnabled,
        'flanger': _synth.flangerEnabled,
        'reverb': _synth.reverbMix > 0.1,
      },
      effectParameters: {
        'chorusMix': _synth.chorusMix,
        'chorusRate': _synth.chorusRate,
        'distortionAmount': _synth.distortionAmount,
        'phaserRate': _synth.phaserRate,
        'phaserDepth': _synth.phaserDepth,
        'compressorRatio': _synth.compressorRatio,
        'flangerDepth': _synth.flangerDepth,
        'flangerRate': _synth.flangerRate,
        'reverbMix': _synth.reverbMix,
      },
      lfoEnabled: [
        _synth.getLFOEnabled(0),
        _synth.getLFOEnabled(1),
        _synth.getLFOEnabled(2),
        _synth.getLFOEnabled(3),
      ],
      lfoRates: [
        _synth.getLFORate(0),
        _synth.getLFORate(1),
        _synth.getLFORate(2),
        _synth.getLFORate(3),
      ],
      lfoWaveforms: [
        _synth.getLFOWaveform(0),
        _synth.getLFOWaveform(1),
        _synth.getLFOWaveform(2),
        _synth.getLFOWaveform(3),
      ],
      tags: tags,
      isBuiltIn: false,
    );
  }

  /// Randomize within musical constraints
  /// Uses weighted selection to create musically useful presets
  VisualPreset generateRandomPreset({PresetCategory? category}) {
    final random = Random();
    final selectedCategory = category ?? _randomCategory(random);

    // Weighted selection based on category
    final family = _randomFamily(random, selectedCategory);
    final polytope = _randomPolytope(random, selectedCategory);
    final geometry = _randomGeometry(random, selectedCategory, family);

    // Generate effects based on category constraints
    final effectsConfig = _randomEffects(random, selectedCategory);

    // Generate LFOs with musical rates
    final lfoConfig = _randomLFOs(random, selectedCategory);

    // Generate visual parameters within aesthetic ranges
    final visualParams = _randomVisualParameters(random, selectedCategory);

    return VisualPreset(
      id: 'random_${DateTime.now().millisecondsSinceEpoch}',
      name: '${selectedCategory.displayName} ${_randomNameSuffix(random)}',
      description: 'Randomly generated ${selectedCategory.displayName.toLowerCase()} preset',
      category: selectedCategory,
      family: family,
      polytope: polytope,
      geometry: geometry,
      effectsEnabled: effectsConfig['enabled'] as Map<String, bool>,
      effectParameters: effectsConfig['parameters'] as Map<String, double>,
      lfoEnabled: lfoConfig['enabled'] as List<bool>,
      lfoRates: lfoConfig['rates'] as List<double>,
      lfoWaveforms: lfoConfig['waveforms'] as List<String>,
      rotationSpeed: visualParams['rotationSpeed']!,
      morphFactor: visualParams['morphFactor']!,
      gridDensity: visualParams['gridDensity']!,
      glitchIntensity: visualParams['glitchIntensity']!,
      colorShift: visualParams['colorShift']!,
      isBuiltIn: false,
    );
  }

  PresetCategory _randomCategory(Random random) {
    // Weighted towards more musical categories
    final weights = [
      25, // ambient
      20, // energetic
      10, // glitch
      15, // minimal
      10, // psychedelic
      15, // rhythmic
      5,  // cinematic
      5,  // experimental
    ];

    final total = weights.reduce((a, b) => a + b);
    final value = random.nextInt(total);
    var sum = 0;

    for (var i = 0; i < weights.length; i++) {
      sum += weights[i];
      if (value < sum) {
        return PresetCategory.values[i];
      }
    }

    return PresetCategory.ambient;
  }

  VisualizerFamily _randomFamily(Random random, PresetCategory category) {
    switch (category) {
      case PresetCategory.ambient:
      case PresetCategory.cinematic:
        // Prefer holographic and quantum for ambient
        return random.nextBool() ? VisualizerFamily.holographic :
               (random.nextBool() ? VisualizerFamily.quantum : VisualizerFamily.faceted);

      case PresetCategory.energetic:
      case PresetCategory.rhythmic:
        // Prefer faceted for energetic
        return random.nextBool() ? VisualizerFamily.faceted :
               (random.nextBool() ? VisualizerFamily.holographic : VisualizerFamily.quantum);

      case PresetCategory.glitch:
      case PresetCategory.experimental:
        // All families equally likely
        return VisualizerFamily.values[random.nextInt(VisualizerFamily.values.length)];

      case PresetCategory.minimal:
        // Prefer holographic for minimal
        return VisualizerFamily.holographic;

      case PresetCategory.psychedelic:
        // Prefer quantum and holographic
        return random.nextBool() ? VisualizerFamily.quantum : VisualizerFamily.holographic;

      default:
        return VisualizerFamily.values[random.nextInt(VisualizerFamily.values.length)];
    }
  }

  Polytope _randomPolytope(Random random, PresetCategory category) {
    // Sphere is most common, followed by cube, then tetrahedron
    final value = random.nextDouble();
    if (value < 0.5) return Polytope.hypersphere;
    if (value < 0.85) return Polytope.hypercube;
    return Polytope.hypertetrahedron;
  }

  GeometryType _randomGeometry(Random random, PresetCategory category, VisualizerFamily family) {
    final geometries = GeometryType.values;

    switch (category) {
      case PresetCategory.ambient:
        // Prefer smooth geometries
        final smoothGeos = [GeometryType.membrane, GeometryType.particle, GeometryType.ribbon];
        return smoothGeos[random.nextInt(smoothGeos.length)];

      case PresetCategory.energetic:
        // Prefer angular geometries
        final angularGeos = [GeometryType.crystalline, GeometryType.lattice, GeometryType.helix];
        return angularGeos[random.nextInt(angularGeos.length)];

      case PresetCategory.glitch:
        // Prefer glitchy geometries
        final glitchGeos = [GeometryType.interference, GeometryType.fractal, GeometryType.crystalline];
        return glitchGeos[random.nextInt(glitchGeos.length)];

      case PresetCategory.minimal:
        // Prefer simple geometries
        final simpleGeos = [GeometryType.lattice, GeometryType.membrane];
        return simpleGeos[random.nextInt(simpleGeos.length)];

      case PresetCategory.psychedelic:
        // All geometries with emphasis on complex ones
        final psychGeos = [GeometryType.interference, GeometryType.fractal, GeometryType.particle, GeometryType.ribbon];
        return psychGeos[random.nextInt(psychGeos.length)];

      case PresetCategory.rhythmic:
        final rhythmicGeos = [GeometryType.lattice, GeometryType.crystalline, GeometryType.helix];
        return rhythmicGeos[random.nextInt(rhythmicGeos.length)];

      default:
        return geometries[random.nextInt(geometries.length)];
    }
  }

  Map<String, dynamic> _randomEffects(Random random, PresetCategory category) {
    final enabled = <String, bool>{};
    final parameters = <String, double>{};

    switch (category) {
      case PresetCategory.ambient:
        // Heavy reverb, light chorus
        enabled['reverb'] = true;
        parameters['reverbMix'] = 0.4 + random.nextDouble() * 0.4; // 0.4-0.8

        if (random.nextDouble() < 0.6) {
          enabled['chorus'] = true;
          parameters['chorusMix'] = 0.2 + random.nextDouble() * 0.3;
          parameters['chorusRate'] = 0.1 + random.nextDouble() * 0.4;
        }
        break;

      case PresetCategory.energetic:
        // Distortion, compressor, maybe phaser
        enabled['distortion'] = true;
        parameters['distortionAmount'] = 0.3 + random.nextDouble() * 0.5;

        enabled['compressor'] = true;
        parameters['compressorRatio'] = 8.0 + random.nextDouble() * 8.0;

        if (random.nextDouble() < 0.5) {
          enabled['phaser'] = true;
          parameters['phaserRate'] = 0.5 + random.nextDouble() * 2.0;
          parameters['phaserDepth'] = 0.4 + random.nextDouble() * 0.4;
        }
        break;

      case PresetCategory.glitch:
        // Heavy distortion, maybe flanger
        enabled['distortion'] = true;
        parameters['distortionAmount'] = 0.6 + random.nextDouble() * 0.4;

        if (random.nextDouble() < 0.7) {
          enabled['flanger'] = true;
          parameters['flangerDepth'] = 0.5 + random.nextDouble() * 0.5;
          parameters['flangerRate'] = 0.3 + random.nextDouble() * 1.0;
        }
        break;

      case PresetCategory.minimal:
        // Light reverb only
        enabled['reverb'] = true;
        parameters['reverbMix'] = 0.1 + random.nextDouble() * 0.2;
        break;

      case PresetCategory.psychedelic:
        // All modulation effects
        enabled['chorus'] = true;
        parameters['chorusMix'] = 0.4 + random.nextDouble() * 0.4;
        parameters['chorusRate'] = 0.2 + random.nextDouble() * 0.8;

        enabled['phaser'] = true;
        parameters['phaserRate'] = 0.3 + random.nextDouble() * 1.5;
        parameters['phaserDepth'] = 0.5 + random.nextDouble() * 0.5;

        enabled['reverb'] = true;
        parameters['reverbMix'] = 0.3 + random.nextDouble() * 0.4;
        break;

      case PresetCategory.rhythmic:
        // Compressor, maybe chorus
        enabled['compressor'] = true;
        parameters['compressorRatio'] = 6.0 + random.nextDouble() * 10.0;

        if (random.nextDouble() < 0.5) {
          enabled['chorus'] = true;
          parameters['chorusMix'] = 0.2 + random.nextDouble() * 0.3;
          parameters['chorusRate'] = 0.5 + random.nextDouble() * 1.0;
        }
        break;

      default:
        // Random selection
        if (random.nextDouble() < 0.5) {
          enabled['reverb'] = true;
          parameters['reverbMix'] = 0.2 + random.nextDouble() * 0.5;
        }
    }

    return {'enabled': enabled, 'parameters': parameters};
  }

  Map<String, dynamic> _randomLFOs(Random random, PresetCategory category) {
    final enabled = <bool>[];
    final rates = <double>[];
    final waveforms = <String>[];
    final waveformOptions = ['sine', 'triangle', 'square', 'sawtooth', 'random'];

    // LFO probability based on category
    double lfoProbability;
    switch (category) {
      case PresetCategory.psychedelic:
        lfoProbability = 0.9; // Very likely to have LFOs
        break;
      case PresetCategory.rhythmic:
        lfoProbability = 0.7;
        break;
      case PresetCategory.energetic:
        lfoProbability = 0.6;
        break;
      case PresetCategory.minimal:
        lfoProbability = 0.2; // Unlikely
        break;
      default:
        lfoProbability = 0.5;
    }

    for (int i = 0; i < 4; i++) {
      final isEnabled = random.nextDouble() < lfoProbability;
      enabled.add(isEnabled);

      if (isEnabled) {
        // Musical LFO rates (0.1-5 Hz, with emphasis on slower rates)
        final rateValue = random.nextDouble();
        final rate = rateValue < 0.7 ?
          0.1 + random.nextDouble() * 1.4 :  // 70% slow (0.1-1.5 Hz)
          1.5 + random.nextDouble() * 3.5;   // 30% fast (1.5-5.0 Hz)
        rates.add(rate);

        // Waveform selection based on category
        String waveform;
        if (category == PresetCategory.rhythmic) {
          // Prefer square and sawtooth for rhythmic
          waveform = random.nextBool() ? 'square' : 'sawtooth';
        } else if (category == PresetCategory.glitch || category == PresetCategory.experimental) {
          // Prefer random for glitch
          waveform = random.nextDouble() < 0.5 ? 'random' : waveformOptions[random.nextInt(waveformOptions.length)];
        } else {
          // Prefer smooth waveforms
          waveform = random.nextDouble() < 0.7 ?
            (random.nextBool() ? 'sine' : 'triangle') :
            waveformOptions[random.nextInt(waveformOptions.length)];
        }
        waveforms.add(waveform);
      } else {
        rates.add(1.0);
        waveforms.add('sine');
      }
    }

    return {'enabled': enabled, 'rates': rates, 'waveforms': waveforms};
  }

  Map<String, double> _randomVisualParameters(Random random, PresetCategory category) {
    switch (category) {
      case PresetCategory.ambient:
        return {
          'rotationSpeed': 0.1 + random.nextDouble() * 0.4, // Slow
          'morphFactor': 0.2 + random.nextDouble() * 0.4,
          'gridDensity': 8.0 + random.nextDouble() * 4.0,
          'glitchIntensity': 0.0 + random.nextDouble() * 0.1, // Minimal glitch
          'colorShift': 0.0 + random.nextDouble() * 0.3,
        };

      case PresetCategory.energetic:
        return {
          'rotationSpeed': 0.8 + random.nextDouble() * 0.7, // Fast
          'morphFactor': 0.5 + random.nextDouble() * 0.5,
          'gridDensity': 10.0 + random.nextDouble() * 6.0,
          'glitchIntensity': 0.1 + random.nextDouble() * 0.3,
          'colorShift': 0.3 + random.nextDouble() * 0.4,
        };

      case PresetCategory.glitch:
        return {
          'rotationSpeed': 0.3 + random.nextDouble() * 1.0,
          'morphFactor': 0.6 + random.nextDouble() * 0.4,
          'gridDensity': 6.0 + random.nextDouble() * 10.0,
          'glitchIntensity': 0.5 + random.nextDouble() * 0.5, // High glitch
          'colorShift': 0.4 + random.nextDouble() * 0.6,
        };

      case PresetCategory.minimal:
        return {
          'rotationSpeed': 0.2 + random.nextDouble() * 0.3,
          'morphFactor': 0.0 + random.nextDouble() * 0.2,
          'gridDensity': 8.0 + random.nextDouble() * 4.0,
          'glitchIntensity': 0.0,
          'colorShift': 0.0 + random.nextDouble() * 0.1,
        };

      case PresetCategory.psychedelic:
        return {
          'rotationSpeed': 0.4 + random.nextDouble() * 0.6,
          'morphFactor': 0.6 + random.nextDouble() * 0.4,
          'gridDensity': 8.0 + random.nextDouble() * 8.0,
          'glitchIntensity': 0.2 + random.nextDouble() * 0.4,
          'colorShift': 0.6 + random.nextDouble() * 0.4, // High color shift
        };

      case PresetCategory.rhythmic:
        return {
          'rotationSpeed': 0.5 + random.nextDouble() * 0.5,
          'morphFactor': 0.3 + random.nextDouble() * 0.4,
          'gridDensity': 10.0 + random.nextDouble() * 4.0,
          'glitchIntensity': 0.1 + random.nextDouble() * 0.2,
          'colorShift': 0.2 + random.nextDouble() * 0.3,
        };

      default:
        return {
          'rotationSpeed': 0.2 + random.nextDouble() * 0.8,
          'morphFactor': 0.3 + random.nextDouble() * 0.5,
          'gridDensity': 8.0 + random.nextDouble() * 8.0,
          'glitchIntensity': 0.0 + random.nextDouble() * 0.5,
          'colorShift': 0.0 + random.nextDouble() * 0.7,
        };
    }
  }

  String _randomNameSuffix(Random random) {
    final suffixes = [
      'Dream', 'Vibe', 'Flow', 'Pulse', 'Wave', 'Shift', 'Drift',
      'Echo', 'Glow', 'Haze', 'Mist', 'Storm', 'Void', 'Bloom',
      'Spark', 'Flare', 'Beam', 'Ray', 'Aura', 'Field', 'Zone',
    ];
    return suffixes[random.nextInt(suffixes.length)];
  }

  /// Morph between two presets
  /// Creates a new preset that blends parameters from presetA and presetB
  /// morphFactor: 0.0 = 100% presetA, 1.0 = 100% presetB
  VisualPreset morphPresets(
    VisualPreset presetA,
    VisualPreset presetB,
    double morphFactor, {
    String? name,
    String? description,
  }) {
    final t = morphFactor.clamp(0.0, 1.0);

    // For discrete values (family, polytope, geometry), switch at 0.5
    final family = t < 0.5 ? presetA.family : presetB.family;
    final polytope = t < 0.5 ? presetA.polytope : presetB.polytope;
    final geometry = t < 0.5 ? presetA.geometry : presetB.geometry;

    // Blend effect parameters
    final effectsEnabled = <String, bool>{};
    final effectParameters = <String, double>{};

    // Combine all effect keys from both presets
    final allEffects = <String>{
      ...presetA.effectsEnabled.keys,
      ...presetB.effectsEnabled.keys,
    };

    for (final effect in allEffects) {
      final enabledA = presetA.effectsEnabled[effect] ?? false;
      final enabledB = presetB.effectsEnabled[effect] ?? false;

      // Effect is enabled if either preset has it enabled and morph factor favors it
      if (t < 0.5) {
        effectsEnabled[effect] = enabledA;
      } else {
        effectsEnabled[effect] = enabledB;
      }
    }

    // Blend effect parameter values
    final allParams = <String>{
      ...presetA.effectParameters.keys,
      ...presetB.effectParameters.keys,
    };

    for (final param in allParams) {
      final valueA = presetA.effectParameters[param] ?? 0.0;
      final valueB = presetB.effectParameters[param] ?? 0.0;
      effectParameters[param] = _lerp(valueA, valueB, t);
    }

    // Blend LFO states
    final lfoEnabled = <bool>[];
    final lfoRates = <double>[];
    final lfoWaveforms = <String>[];

    for (int i = 0; i < 4; i++) {
      // LFO enabled switches at 0.5
      lfoEnabled.add(t < 0.5 ?
        (i < presetA.lfoEnabled.length ? presetA.lfoEnabled[i] : false) :
        (i < presetB.lfoEnabled.length ? presetB.lfoEnabled[i] : false));

      // Blend LFO rates
      final rateA = i < presetA.lfoRates.length ? presetA.lfoRates[i] : 1.0;
      final rateB = i < presetB.lfoRates.length ? presetB.lfoRates[i] : 1.0;
      lfoRates.add(_lerp(rateA, rateB, t));

      // Waveform switches at 0.5
      lfoWaveforms.add(t < 0.5 ?
        (i < presetA.lfoWaveforms.length ? presetA.lfoWaveforms[i] : 'sine') :
        (i < presetB.lfoWaveforms.length ? presetB.lfoWaveforms[i] : 'sine'));
    }

    // Blend visual parameters
    final rotationSpeed = _lerp(presetA.rotationSpeed, presetB.rotationSpeed, t);
    final morphFactorVal = _lerp(presetA.morphFactor, presetB.morphFactor, t);
    final gridDensity = _lerp(presetA.gridDensity, presetB.gridDensity, t);
    final glitchIntensity = _lerp(presetA.glitchIntensity, presetB.glitchIntensity, t);
    final colorShift = _lerp(presetA.colorShift, presetB.colorShift, t);

    // Determine category based on blend
    PresetCategory category;
    if (t < 0.5) {
      category = presetA.category;
    } else {
      category = presetB.category;
    }

    return VisualPreset(
      id: 'morph_${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? '${presetA.name} ⟷ ${presetB.name}',
      description: description ?? 'Morphed blend of ${presetA.name} and ${presetB.name} (${(t * 100).toInt()}% B)',
      category: category,
      family: family,
      polytope: polytope,
      geometry: geometry,
      effectsEnabled: effectsEnabled,
      effectParameters: effectParameters,
      lfoEnabled: lfoEnabled,
      lfoRates: lfoRates,
      lfoWaveforms: lfoWaveforms,
      rotationSpeed: rotationSpeed,
      morphFactor: morphFactorVal,
      gridDensity: gridDensity,
      glitchIntensity: glitchIntensity,
      colorShift: colorShift,
      isBuiltIn: false,
    );
  }

  /// Linear interpolation helper
  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
