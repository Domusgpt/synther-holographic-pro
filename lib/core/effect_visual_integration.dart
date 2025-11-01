import '../core/visualizer_configuration.dart';
import '../core/parameter_visualizer_bridge.dart';

/// Phase 6: Effects Chain Expansion
/// Framework for effect-to-visual parity
///
/// This file defines the architecture for integrating audio effects with visual changes.
/// When effects are implemented in the audio engine, they should call these methods.

/// Effect Types
enum EffectType {
  chorus,
  distortion,
  phaser,
  compressor,
  flanger,
  reverb,
  delay,
}

/// Visual effect mapping configuration
class EffectVisualMapping {
  final EffectType effectType;
  final GeometryType? suggestedGeometry;
  final Map<String, double Function(double)> parameterMappings;
  final String description;

  const EffectVisualMapping({
    required this.effectType,
    this.suggestedGeometry,
    required this.parameterMappings,
    required this.description,
  });
}

/// Effect-Visual Integration Manager
class EffectVisualIntegration {
  final ParameterVisualizerBridge _bridge;

  // Track active effects
  final Map<EffectType, bool> _activeEffects = {};
  final Map<EffectType, Map<String, double>> _effectParameters = {};

  // Effect-to-visual mappings
  static final Map<EffectType, EffectVisualMapping> _mappings = {
    EffectType.chorus: EffectVisualMapping(
      effectType: EffectType.chorus,
      suggestedGeometry: GeometryType.interference,
      description: 'Creates wave interference patterns from detuned voices',
      parameterMappings: {
        'interferenceAmount': (mix) => mix,
        'colorShift': (rate) => rate * 0.5,
      },
    ),

    EffectType.distortion: EffectVisualMapping(
      effectType: EffectType.distortion,
      suggestedGeometry: GeometryType.crystalline,
      description: 'Sharp faceted planes representing harmonic shattering',
      parameterMappings: {
        'facetSharpness': (amount) => amount,
        'glitchIntensity': (amount) => amount * 0.15,
        'patternIntensity': (amount) => 1.0 + (amount * 0.5),
      },
    ),

    EffectType.phaser: EffectVisualMapping(
      effectType: EffectType.phaser,
      suggestedGeometry: GeometryType.helix,
      description: 'Spiraling helix structures for phase-rotating comb filter',
      parameterMappings: {
        'helixRotationSpeed': (rate) => rate * 2.0,
        'morphFactor': (depth) => 0.5 + (depth * 0.8),
      },
    ),

    EffectType.compressor: EffectVisualMapping(
      effectType: EffectType.compressor,
      suggestedGeometry: null, // Uses parameter modulation only
      description: 'Breathing/pulsing scale effect for dynamic compression',
      parameterMappings: {
        'breathingDepth': (ratio) => ratio * 0.3,
        'universeModifier': (reduction) => 1.0 - (reduction * 0.3),
      },
    ),

    EffectType.flanger: EffectVisualMapping(
      effectType: EffectType.flanger,
      suggestedGeometry: GeometryType.ribbon,
      description: 'Undulating ribbon surfaces for comb filter sweeps',
      parameterMappings: {
        'morphFactor': (depth) => 0.7 + (depth * 0.8),
        'rotationSpeed': (rate) => 0.5 + (rate * 1.5),
      },
    ),

    EffectType.reverb: EffectVisualMapping(
      effectType: EffectType.reverb,
      suggestedGeometry: GeometryType.membrane, // Could also use particle for diffuse
      description: 'Rippling membrane for spatial reflections',
      parameterMappings: {
        'gridDensity': (mix) => 8.0 + (mix * 8.0),
        'glitchIntensity': (size) => size * 0.05,
      },
    ),

    EffectType.delay: EffectVisualMapping(
      effectType: EffectType.delay,
      suggestedGeometry: null, // Uses parameter modulation
      description: 'Visual echo trails via universe modifier',
      parameterMappings: {
        'universeModifier': (feedback) => 1.0 + (feedback * 0.8),
      },
    ),
  };

  EffectVisualIntegration(this._bridge);

  /// Enable an effect and apply its visual mapping
  void enableEffect(
    EffectType effectType, {
    bool autoSwitchGeometry = true,
    Map<String, double>? parameters,
  }) {
    _activeEffects[effectType] = true;

    final mapping = _mappings[effectType];
    if (mapping == null) return;

    // Auto-switch geometry if suggested and enabled
    if (autoSwitchGeometry && mapping.suggestedGeometry != null) {
      _bridge.setGeometryType(mapping.suggestedGeometry!);
    }

    // Apply parameter mappings
    if (parameters != null) {
      _effectParameters[effectType] = parameters;
      _applyEffectParameters(effectType, parameters, mapping);
    }
  }

  /// Disable an effect and restore default visuals
  void disableEffect(EffectType effectType) {
    _activeEffects[effectType] = false;
    _effectParameters.remove(effectType);

    // Could restore geometry to lattice or previous setting
    // For now, leave geometry as-is (user can manually change)
  }

  /// Update effect parameters (called when effect values change)
  void updateEffectParameters(
    EffectType effectType,
    Map<String, double> parameters,
  ) {
    if (_activeEffects[effectType] != true) return;

    _effectParameters[effectType] = parameters;
    final mapping = _mappings[effectType];
    if (mapping != null) {
      _applyEffectParameters(effectType, parameters, mapping);
    }
  }

  /// Apply parameter mappings to visualizer
  void _applyEffectParameters(
    EffectType effectType,
    Map<String, double> parameters,
    EffectVisualMapping mapping,
  ) {
    mapping.parameterMappings.forEach((visualParam, transform) {
      // Find matching effect parameter
      for (final entry in parameters.entries) {
        final paramName = entry.key;
        final paramValue = entry.value;

        // Apply transformation and update visual parameter
        if (_shouldMapParameter(paramName, visualParam)) {
          final transformedValue = transform(paramValue);
          _bridge.updateParameter(visualParam, transformedValue);
        }
      }
    });
  }

  /// Check if effect parameter should map to visual parameter
  bool _shouldMapParameter(String effectParam, String visualParam) {
    // Simple heuristic matching
    final effectLower = effectParam.toLowerCase();
    final visualLower = visualParam.toLowerCase();

    // Direct matches
    if (effectLower.contains('mix') || effectLower.contains('amount')) {
      return visualLower.contains('intensity') ||
          visualLower.contains('amount') ||
          visualLower.contains('depth');
    }

    if (effectLower.contains('rate') || effectLower.contains('speed')) {
      return visualLower.contains('speed') || visualLower.contains('rotation');
    }

    if (effectLower.contains('depth')) {
      return visualLower.contains('depth') ||
          visualLower.contains('morph') ||
          visualLower.contains('factor');
    }

    return true; // Default: allow mapping
  }

  /// Get all active effects
  List<EffectType> get activeEffects =>
      _activeEffects.entries.where((e) => e.value).map((e) => e.key).toList();

  /// Check if specific effect is active
  bool isEffectActive(EffectType effectType) =>
      _activeEffects[effectType] == true;

  /// Get suggested geometry for effect
  GeometryType? getSuggestedGeometry(EffectType effectType) =>
      _mappings[effectType]?.suggestedGeometry;

  /// Get effect description
  String? getEffectDescription(EffectType effectType) =>
      _mappings[effectType]?.description;
}

/// Example usage:
///
/// ```dart
/// final effectVisuals = EffectVisualIntegration(visualBridge);
///
/// // When chorus is enabled:
/// effectVisuals.enableEffect(
///   EffectType.chorus,
///   parameters: {'mix': 0.5, 'rate': 0.3},
/// );
/// // Result: Switches to interference geometry, applies wave patterns
///
/// // When distortion is enabled:
/// effectVisuals.enableEffect(
///   EffectType.distortion,
///   parameters: {'amount': 0.7},
/// );
/// // Result: Switches to crystalline geometry, shattering facets
///
/// // Update effect in real-time:
/// effectVisuals.updateEffectParameters(
///   EffectType.phaser,
///   {'rate': 2.0, 'depth': 0.8},
/// );
/// // Result: Helix spins faster with deeper modulation
/// ```
