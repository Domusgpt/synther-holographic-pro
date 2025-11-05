import 'package:flutter/material.dart';
import '../design_system/design_system.dart';

/// Visualizer Family - The "arch grandest choice"
/// Defines the fundamental rendering paradigm
/// All families share the 5-layer quaternion rotation system but render differently
enum VisualizerFamily {
  faceted,     // Sharp, crystalline, geometric - Subtractive synthesis aesthetic
  quantum,     // Probabilistic, particle-based - Granular synthesis aesthetic
  holographic, // Translucent, layered, ethereal - Additive synthesis aesthetic
}

extension VisualizerFamilyExtension on VisualizerFamily {
  String get displayName {
    switch (this) {
      case VisualizerFamily.faceted:
        return 'Faceted';
      case VisualizerFamily.quantum:
        return 'Quantum';
      case VisualizerFamily.holographic:
        return 'Holographic';
    }
  }

  String get description {
    switch (this) {
      case VisualizerFamily.faceted:
        return 'Sharp, crystalline, geometric - Subtractive synthesis';
      case VisualizerFamily.quantum:
        return 'Probabilistic, particle-based - Granular synthesis';
      case VisualizerFamily.holographic:
        return 'Translucent, layered, ethereal - Additive synthesis';
    }
  }

  Color get color {
    switch (this) {
      case VisualizerFamily.faceted:
        return DesignTokens.neonCyan;
      case VisualizerFamily.quantum:
        return DesignTokens.neonPurple;
      case VisualizerFamily.holographic:
        return DesignTokens.neonPink;
    }
  }

  String get jsValue {
    return name; // 'faceted', 'quantum', 'holographic'
  }
}

/// Polytope - Tier 2 of hierarchy
/// Defines rotation behavior and grid line morphing
enum Polytope {
  hypercube,         // 16 vertices, 32 edges - Discrete, stepped - Quantized waveforms
  hypersphere,       // Continuous surface - Smooth, flowing - Analog waveforms
  hypertetrahedron,  // 5 vertices, 10 edges - Angular, faceted - Sharp transients
}

extension PolytopeExtension on Polytope {
  String get displayName {
    switch (this) {
      case Polytope.hypercube:
        return 'Hypercube';
      case Polytope.hypersphere:
        return 'Hypersphere';
      case Polytope.hypertetrahedron:
        return 'Hyper Tetrahedron';
    }
  }

  String get description {
    switch (this) {
      case Polytope.hypercube:
        return 'Discrete, stepped rotation - Quantized waveforms';
      case Polytope.hypersphere:
        return 'Smooth, flowing rotation - Analog waveforms';
      case Polytope.hypertetrahedron:
        return 'Angular, faceted rotation - Sharp transients';
    }
  }

  Color get color {
    switch (this) {
      case Polytope.hypercube:
        return DesignTokens.neonCyan;
      case Polytope.hypersphere:
        return DesignTokens.neonGreen;
      case Polytope.hypertetrahedron:
        return DesignTokens.neonOrange;
    }
  }

  String get jsValue {
    return name; // 'hypercube', 'hypersphere', 'hypertetrahedron'
  }
}

/// Geometry Type - Tier 3 of hierarchy
/// Defines topology/form of lines and movements
/// Works uniquely depending on which Visualizer Family and Polytope are selected
enum GeometryType {
  lattice,       // Straight grid lines - Clean tones, pure intervals
  ribbon,        // Curved surface strips - Vibrato, modulation
  particle,      // Disconnected points - Granular texture, noise
  helix,         // Spiraling paths - Phase modulation, flanging
  fractal,       // Self-similar branching - Feedback, resonance
  interference,  // Overlapping waves - Chorus, detuning
  membrane,      // Tensioned surfaces - Filter sweeps, wah
  crystalline,   // Sharp, faceted planes - Distortion, bit crushing
}

extension GeometryTypeExtension on GeometryType {
  String get displayName {
    switch (this) {
      case GeometryType.lattice:
        return 'Lattice';
      case GeometryType.ribbon:
        return 'Ribbon';
      case GeometryType.particle:
        return 'Particle';
      case GeometryType.helix:
        return 'Helix';
      case GeometryType.fractal:
        return 'Fractal';
      case GeometryType.interference:
        return 'Interference';
      case GeometryType.membrane:
        return 'Membrane';
      case GeometryType.crystalline:
        return 'Crystalline';
    }
  }

  String get description {
    switch (this) {
      case GeometryType.lattice:
        return 'Straight grid lines - Clean tones, pure intervals';
      case GeometryType.ribbon:
        return 'Curved surface strips - Vibrato, modulation';
      case GeometryType.particle:
        return 'Disconnected points - Granular texture, noise';
      case GeometryType.helix:
        return 'Spiraling paths - Phase modulation, flanging';
      case GeometryType.fractal:
        return 'Self-similar branching - Feedback, resonance';
      case GeometryType.interference:
        return 'Overlapping waves - Chorus, detuning';
      case GeometryType.membrane:
        return 'Tensioned surfaces - Filter sweeps, wah';
      case GeometryType.crystalline:
        return 'Sharp, faceted planes - Distortion, bit crushing';
    }
  }

  Color get color {
    switch (this) {
      case GeometryType.lattice:
        return DesignTokens.neonCyan;
      case GeometryType.ribbon:
        return DesignTokens.neonPurple;
      case GeometryType.particle:
        return DesignTokens.neonGreen;
      case GeometryType.helix:
        return DesignTokens.neonPink;
      case GeometryType.fractal:
        return DesignTokens.neonOrange;
      case GeometryType.interference:
        return DesignTokens.neonBlue;
      case GeometryType.membrane:
        return const Color(0xFF00FFFF);
      case GeometryType.crystalline:
        return const Color(0xFFFF0066);
    }
  }

  String get jsValue {
    return name; // 'lattice', 'ribbon', 'particle', etc.
  }

  /// Get the sonic effect this geometry type is mapped to
  String get sonicMapping {
    switch (this) {
      case GeometryType.lattice:
        return 'Dry, unprocessed sound';
      case GeometryType.ribbon:
        return 'Vibrato, LFO modulation';
      case GeometryType.particle:
        return 'Granular processing';
      case GeometryType.helix:
        return 'Phasing, flanging';
      case GeometryType.fractal:
        return 'Feedback, resonance';
      case GeometryType.interference:
        return 'Chorus, detune';
      case GeometryType.membrane:
        return 'Filter modulation';
      case GeometryType.crystalline:
        return 'Distortion, overdrive';
    }
  }
}

/// Complete visualizer configuration model
/// Represents the full state of the visualizer across all 4 tiers
class VisualizerConfiguration {
  final VisualizerFamily family;
  final Polytope polytope;
  final GeometryType geometryType;

  // Parameters (Tier 4) are handled by ParameterVisualizerBridge

  const VisualizerConfiguration({
    this.family = VisualizerFamily.holographic,
    this.polytope = Polytope.hypercube,
    this.geometryType = GeometryType.lattice,
  });

  VisualizerConfiguration copyWith({
    VisualizerFamily? family,
    Polytope? polytope,
    GeometryType? geometryType,
  }) {
    return VisualizerConfiguration(
      family: family ?? this.family,
      polytope: polytope ?? this.polytope,
      geometryType: geometryType ?? this.geometryType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family': family.jsValue,
      'polytope': polytope.jsValue,
      'geometryType': geometryType.jsValue,
    };
  }

  factory VisualizerConfiguration.fromJson(Map<String, dynamic> json) {
    return VisualizerConfiguration(
      family: VisualizerFamily.values.firstWhere(
        (f) => f.jsValue == json['family'],
        orElse: () => VisualizerFamily.holographic,
      ),
      polytope: Polytope.values.firstWhere(
        (p) => p.jsValue == json['polytope'],
        orElse: () => Polytope.hypercube,
      ),
      geometryType: GeometryType.values.firstWhere(
        (g) => g.jsValue == json['geometryType'],
        orElse: () => GeometryType.lattice,
      ),
    );
  }

  @override
  String toString() {
    return 'VisualizerConfiguration(family: ${family.displayName}, '
           'polytope: ${polytope.displayName}, '
           'geometryType: ${geometryType.displayName})';
  }
}

/// 5-Layer system configuration
/// Each layer corresponds to specific frequency bands
enum VisualizerLayer {
  foundation,   // Layer 0: Sub Bass (20-60Hz) - XW, YW rotations
  bassStruct,   // Layer 1: Bass (60-250Hz) - XY, YZ rotations
  midLattice,   // Layer 2: Low Mids + Mids (250-2kHz) - ZW, XZ rotations
  highDetail,   // Layer 3: High Mids + Presence (2k-6kHz) - YW, XW offset
  brilliance,   // Layer 4: Brilliance (6k-20kHz) - All planes micro-rotations
}

extension VisualizerLayerExtension on VisualizerLayer {
  String get displayName {
    switch (this) {
      case VisualizerLayer.foundation:
        return 'Foundation';
      case VisualizerLayer.bassStruct:
        return 'Bass Structure';
      case VisualizerLayer.midLattice:
        return 'Mid Lattice';
      case VisualizerLayer.highDetail:
        return 'High Detail';
      case VisualizerLayer.brilliance:
        return 'Brilliance';
    }
  }

  String get frequencyRange {
    switch (this) {
      case VisualizerLayer.foundation:
        return '20-60 Hz';
      case VisualizerLayer.bassStruct:
        return '60-250 Hz';
      case VisualizerLayer.midLattice:
        return '250-2k Hz';
      case VisualizerLayer.highDetail:
        return '2k-6k Hz';
      case VisualizerLayer.brilliance:
        return '6k-20k Hz';
    }
  }

  /// Which audio bands from the 7-band analyzer feed this layer
  List<int> get bandIndices {
    switch (this) {
      case VisualizerLayer.foundation:
        return [0]; // Sub bass
      case VisualizerLayer.bassStruct:
        return [1]; // Bass
      case VisualizerLayer.midLattice:
        return [2, 3]; // Low mids + Mids
      case VisualizerLayer.highDetail:
        return [4, 5]; // High mids + Presence
      case VisualizerLayer.brilliance:
        return [6]; // Brilliance
    }
  }

  String get rotationPlanes {
    switch (this) {
      case VisualizerLayer.foundation:
        return 'XW, YW';
      case VisualizerLayer.bassStruct:
        return 'XY, YZ';
      case VisualizerLayer.midLattice:
        return 'ZW, XZ';
      case VisualizerLayer.highDetail:
        return 'YW, XW (offset)';
      case VisualizerLayer.brilliance:
        return 'All planes (micro)';
    }
  }

  int get index {
    return VisualizerLayer.values.indexOf(this);
  }
}
