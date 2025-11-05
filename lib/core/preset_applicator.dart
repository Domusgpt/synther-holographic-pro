import 'synth_parameters.dart';
import 'parameter_visualizer_bridge.dart';
import 'visual_preset_system.dart';

/// Applies visual presets to the synth and visualizer
class PresetApplicator {
  final SynthParametersModel _synth;
  final ParameterVisualizerBridge _bridge;

  PresetApplicator(this._synth, this._bridge);

  /// Apply a preset to current state
  void applyPreset(VisualPreset preset, {bool smooth = false}) {
    // Set Tier 1-3: Family, Polytope, Geometry
    _bridge.setVisualizerFamily(preset.family);
    _bridge.setPolytope(preset.polytope);
    _bridge.setGeometryType(preset.geometry);

    // Apply Effects
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
  VisualPreset generateRandomPreset({PresetCategory? category}) {
    // TODO: Implement weighted randomization for musical results
    return VisualPreset(
      id: 'random_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Random ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Randomly generated preset',
      category: category ?? PresetCategory.experimental,
      family: VisualizerFamily.values[DateTime.now().millisecond % 3],
      polytope: Polytope.values[DateTime.now().millisecond % 3],
      geometry: GeometryType.values[DateTime.now().millisecond % 8],
      effectsEnabled: {},
      effectParameters: {},
      lfoEnabled: [false, false, false, false],
      lfoRates: [1.0, 1.0, 1.0, 1.0],
      lfoWaveforms: ['sine', 'sine', 'sine', 'sine'],
      isBuiltIn: false,
    );
  }
}
