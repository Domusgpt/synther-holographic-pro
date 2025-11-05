import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'visualizer_configuration.dart';

/// Complete visual state snapshot for presets
class VisualPreset {
  final String id;
  final String name;
  final String description;
  final PresetCategory category;

  // Tier 1-3: Visual Configuration
  final VisualizerFamily family;
  final Polytope polytope;
  final GeometryType geometry;

  // Effects
  final Map<String, bool> effectsEnabled;
  final Map<String, double> effectParameters;

  // LFOs
  final List<bool> lfoEnabled;
  final List<double> lfoRates;
  final List<String> lfoWaveforms;

  // Visual Parameters
  final double rotationSpeed;
  final double morphFactor;
  final double gridDensity;
  final double glitchIntensity;
  final double colorShift;

  // Metadata
  final List<String> tags;
  final DateTime createdAt;
  final bool isBuiltIn;

  const VisualPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.family,
    required this.polytope,
    required this.geometry,
    required this.effectsEnabled,
    required this.effectParameters,
    required this.lfoEnabled,
    required this.lfoRates,
    required this.lfoWaveforms,
    this.rotationSpeed = 0.5,
    this.morphFactor = 0.7,
    this.gridDensity = 8.0,
    this.glitchIntensity = 0.02,
    this.colorShift = 0.0,
    this.tags = const [],
    DateTime? createdAt,
    this.isBuiltIn = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'family': family.name,
    'polytope': polytope.name,
    'geometry': geometry.name,
    'effectsEnabled': effectsEnabled,
    'effectParameters': effectParameters,
    'lfoEnabled': lfoEnabled,
    'lfoRates': lfoRates,
    'lfoWaveforms': lfoWaveforms,
    'rotationSpeed': rotationSpeed,
    'morphFactor': morphFactor,
    'gridDensity': gridDensity,
    'glitchIntensity': glitchIntensity,
    'colorShift': colorShift,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'isBuiltIn': isBuiltIn,
  };

  factory VisualPreset.fromJson(Map<String, dynamic> json) => VisualPreset(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    category: PresetCategory.values.firstWhere((c) => c.name == json['category']),
    family: VisualizerFamily.values.firstWhere((f) => f.name == json['family']),
    polytope: Polytope.values.firstWhere((p) => p.name == json['polytope']),
    geometry: GeometryType.values.firstWhere((g) => g.name == json['geometry']),
    effectsEnabled: Map<String, bool>.from(json['effectsEnabled']),
    effectParameters: Map<String, double>.from(json['effectParameters']),
    lfoEnabled: List<bool>.from(json['lfoEnabled']),
    lfoRates: List<double>.from(json['lfoRates']),
    lfoWaveforms: List<String>.from(json['lfoWaveforms']),
    rotationSpeed: json['rotationSpeed'] ?? 0.5,
    morphFactor: json['morphFactor'] ?? 0.7,
    gridDensity: json['gridDensity'] ?? 8.0,
    glitchIntensity: json['glitchIntensity'] ?? 0.02,
    colorShift: json['colorShift'] ?? 0.0,
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    isBuiltIn: json['isBuiltIn'] ?? false,
  );

  VisualPreset copyWith({
    String? id,
    String? name,
    String? description,
    PresetCategory? category,
    VisualizerFamily? family,
    Polytope? polytope,
    GeometryType? geometry,
    Map<String, bool>? effectsEnabled,
    Map<String, double>? effectParameters,
    List<bool>? lfoEnabled,
    List<double>? lfoRates,
    List<String>? lfoWaveforms,
    double? rotationSpeed,
    double? morphFactor,
    double? gridDensity,
    double? glitchIntensity,
    double? colorShift,
    List<String>? tags,
    DateTime? createdAt,
    bool? isBuiltIn,
  }) => VisualPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    family: family ?? this.family,
    polytope: polytope ?? this.polytope,
    geometry: geometry ?? this.geometry,
    effectsEnabled: effectsEnabled ?? this.effectsEnabled,
    effectParameters: effectParameters ?? this.effectParameters,
    lfoEnabled: lfoEnabled ?? this.lfoEnabled,
    lfoRates: lfoRates ?? this.lfoRates,
    lfoWaveforms: lfoWaveforms ?? this.lfoWaveforms,
    rotationSpeed: rotationSpeed ?? this.rotationSpeed,
    morphFactor: morphFactor ?? this.morphFactor,
    gridDensity: gridDensity ?? this.gridDensity,
    glitchIntensity: glitchIntensity ?? this.glitchIntensity,
    colorShift: colorShift ?? this.colorShift,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
  );
}

enum PresetCategory {
  ambient,      // Calm, flowing, ethereal
  energetic,    // Fast, intense, dynamic
  glitch,       // Artifacts, distortion, chaos
  minimal,      // Clean, simple, elegant
  psychedelic,  // Complex, colorful, morphing
  rhythmic,     // Beat-synced, pulsing
  cinematic,    // Dramatic, sweeping, epic
  experimental, // Unusual combinations
  custom,       // User-created
}

extension PresetCategoryExtension on PresetCategory {
  String get displayName {
    switch (this) {
      case PresetCategory.ambient: return '🌊 Ambient';
      case PresetCategory.energetic: return '⚡ Energetic';
      case PresetCategory.glitch: return '📺 Glitch';
      case PresetCategory.minimal: return '◻️ Minimal';
      case PresetCategory.psychedelic: return '🌀 Psychedelic';
      case PresetCategory.rhythmic: return '🥁 Rhythmic';
      case PresetCategory.cinematic: return '🎬 Cinematic';
      case PresetCategory.experimental: return '🔬 Experimental';
      case PresetCategory.custom: return '✨ Custom';
    }
  }

  String get description {
    switch (this) {
      case PresetCategory.ambient: return 'Calm, flowing, ethereal visuals';
      case PresetCategory.energetic: return 'Fast-paced, intense, dynamic motion';
      case PresetCategory.glitch: return 'Digital artifacts, distortion, chaos';
      case PresetCategory.minimal: return 'Clean lines, simple elegance';
      case PresetCategory.psychedelic: return 'Complex patterns, color cycling';
      case PresetCategory.rhythmic: return 'Beat-synchronized pulsations';
      case PresetCategory.cinematic: return 'Dramatic, sweeping movements';
      case PresetCategory.experimental: return 'Unusual, boundary-pushing';
      case PresetCategory.custom: return 'Your own creations';
    }
  }
}

/// Built-in preset library
class PresetLibrary {
  static final List<VisualPreset> builtInPresets = [
    // AMBIENT PRESETS
    VisualPreset(
      id: 'ambient_ocean',
      name: 'Ocean Depths',
      description: 'Gentle waves in deep blue space',
      category: PresetCategory.ambient,
      family: VisualizerFamily.holographic,
      polytope: Polytope.hypersphere,
      geometry: GeometryType.membrane,
      effectsEnabled: {'chorus': false, 'reverb': true, 'distortion': false, 'phaser': false, 'compressor': false, 'flanger': false},
      effectParameters: {'reverbMix': 0.6},
      lfoEnabled: [true, true, false, true],
      lfoRates: [0.3, 0.5, 1.0, 0.4],
      lfoWaveforms: ['sine', 'sine', 'sine', 'triangle'],
      rotationSpeed: 0.2,
      morphFactor: 0.6,
      gridDensity: 6.0,
      glitchIntensity: 0.0,
      colorShift: 0.15,
      tags: ['calm', 'flowing', 'blue'],
      isBuiltIn: true,
    ),

    VisualPreset(
      id: 'ambient_nebula',
      name: 'Cosmic Nebula',
      description: 'Particle clouds in vast space',
      category: PresetCategory.ambient,
      family: VisualizerFamily.quantum,
      polytope: Polytope.hypersphere,
      geometry: GeometryType.particle,
      effectsEnabled: {'chorus': true, 'reverb': false, 'distortion': false, 'phaser': false, 'compressor': false, 'flanger': false},
      effectParameters: {'chorusMix': 0.4, 'chorusRate': 0.3},
      lfoEnabled: [false, true, true, true],
      lfoRates: [1.0, 0.4, 0.2, 0.6],
      lfoWaveforms: ['sine', 'sine', 'sine', 'triangle'],
      rotationSpeed: 0.15,
      morphFactor: 0.8,
      gridDensity: 12.0,
      glitchIntensity: 0.01,
      colorShift: 0.0,
      tags: ['space', 'particles', 'soft'],
      isBuiltIn: true,
    ),

    // ENERGETIC PRESETS
    VisualPreset(
      id: 'energetic_pulse',
      name: 'Electric Pulse',
      description: 'Fast-rotating crystalline energy',
      category: PresetCategory.energetic,
      family: VisualizerFamily.faceted,
      polytope: Polytope.hypercube,
      geometry: GeometryType.crystalline,
      effectsEnabled: {'chorus': false, 'reverb': false, 'distortion': true, 'phaser': false, 'compressor': true, 'flanger': false},
      effectParameters: {'distortionAmount': 0.3, 'compressorRatio': 6.0},
      lfoEnabled: [true, false, true, true],
      lfoRates: [2.0, 1.0, 4.0, 1.5],
      lfoWaveforms: ['square', 'sine', 'sawtooth', 'square'],
      rotationSpeed: 0.8,
      morphFactor: 0.5,
      gridDensity: 10.0,
      glitchIntensity: 0.08,
      colorShift: 0.0,
      tags: ['fast', 'intense', 'sharp'],
      isBuiltIn: true,
    ),

    VisualPreset(
      id: 'energetic_helix',
      name: 'Spiral Vortex',
      description: 'Spinning helix with phaser modulation',
      category: PresetCategory.energetic,
      family: VisualizerFamily.holographic,
      polytope: Polytope.hypertetrahedron,
      geometry: GeometryType.helix,
      effectsEnabled: {'chorus': false, 'reverb': false, 'distortion': false, 'phaser': true, 'compressor': false, 'flanger': false},
      effectParameters: {'phaserRate': 3.0, 'phaserDepth': 0.7},
      lfoEnabled: [true, true, false, false],
      lfoRates: [1.5, 2.0, 1.0, 1.0],
      lfoWaveforms: ['triangle', 'sine', 'sine', 'sine'],
      rotationSpeed: 0.7,
      morphFactor: 0.9,
      gridDensity: 8.0,
      glitchIntensity: 0.03,
      colorShift: 0.3,
      tags: ['spinning', 'vortex', 'dynamic'],
      isBuiltIn: true,
    ),

    // GLITCH PRESETS
    VisualPreset(
      id: 'glitch_digital',
      name: 'Digital Decay',
      description: 'Heavy distortion with artifacts',
      category: PresetCategory.glitch,
      family: VisualizerFamily.faceted,
      polytope: Polytope.hypercube,
      geometry: GeometryType.crystalline,
      effectsEnabled: {'chorus': false, 'reverb': false, 'distortion': true, 'phaser': false, 'compressor': false, 'flanger': false},
      effectParameters: {'distortionAmount': 0.8},
      lfoEnabled: [false, false, true, false],
      lfoRates: [1.0, 1.0, 6.0, 1.0],
      lfoWaveforms: ['sine', 'sine', 'random', 'sine'],
      rotationSpeed: 0.4,
      morphFactor: 0.3,
      gridDensity: 15.0,
      glitchIntensity: 0.18,
      colorShift: 0.0,
      tags: ['glitchy', 'harsh', 'digital'],
      isBuiltIn: true,
    ),

    // MINIMAL PRESETS
    VisualPreset(
      id: 'minimal_lattice',
      name: 'Pure Geometry',
      description: 'Clean lines, no effects',
      category: PresetCategory.minimal,
      family: VisualizerFamily.holographic,
      polytope: Polytope.hypercube,
      geometry: GeometryType.lattice,
      effectsEnabled: {'chorus': false, 'reverb': false, 'distortion': false, 'phaser': false, 'compressor': false, 'flanger': false},
      effectParameters: {},
      lfoEnabled: [true, false, false, false],
      lfoRates: [0.5, 1.0, 1.0, 1.0],
      lfoWaveforms: ['sine', 'sine', 'sine', 'sine'],
      rotationSpeed: 0.3,
      morphFactor: 0.5,
      gridDensity: 8.0,
      glitchIntensity: 0.0,
      colorShift: 0.0,
      tags: ['clean', 'simple', 'geometric'],
      isBuiltIn: true,
    ),

    // PSYCHEDELIC PRESETS
    VisualPreset(
      id: 'psychedelic_interference',
      name: 'Moiré Dreams',
      description: 'Wave interference with color cycling',
      category: PresetCategory.psychedelic,
      family: VisualizerFamily.holographic,
      polytope: Polytope.hypersphere,
      geometry: GeometryType.interference,
      effectsEnabled: {'chorus': true, 'reverb': false, 'distortion': false, 'phaser': false, 'compressor': false, 'flanger': false},
      effectParameters: {'chorusMix': 0.7, 'chorusRate': 1.5},
      lfoEnabled: [true, true, true, true],
      lfoRates: [0.6, 0.8, 2.5, 1.0],
      lfoWaveforms: ['sine', 'triangle', 'sine', 'triangle'],
      rotationSpeed: 0.4,
      morphFactor: 0.9,
      gridDensity: 10.0,
      glitchIntensity: 0.02,
      colorShift: 0.0,
      tags: ['colorful', 'patterns', 'trippy'],
      isBuiltIn: true,
    ),

    // RHYTHMIC PRESETS
    VisualPreset(
      id: 'rhythmic_pulse',
      name: 'Compressor Pulse',
      description: 'Breathing with rhythm',
      category: PresetCategory.rhythmic,
      family: VisualizerFamily.faceted,
      polytope: Polytope.hypercube,
      geometry: GeometryType.lattice,
      effectsEnabled: {'chorus': false, 'reverb': false, 'distortion': false, 'phaser': false, 'compressor': true, 'flanger': false},
      effectParameters: {'compressorRatio': 8.0},
      lfoEnabled: [true, false, false, true],
      lfoRates: [2.0, 1.0, 1.0, 2.0],
      lfoWaveforms: ['square', 'sine', 'sine', 'square'],
      rotationSpeed: 0.5,
      morphFactor: 0.6,
      gridDensity: 8.0,
      glitchIntensity: 0.0,
      colorShift: 0.0,
      tags: ['rhythmic', 'pulsing', 'beat-synced'],
      isBuiltIn: true,
    ),

    // EXPERIMENTAL PRESETS
    VisualPreset(
      id: 'experimental_fractal',
      name: 'Recursive Chaos',
      description: 'Fractal patterns with all LFOs',
      category: PresetCategory.experimental,
      family: VisualizerFamily.quantum,
      polytope: Polytope.hypertetrahedron,
      geometry: GeometryType.fractal,
      effectsEnabled: {'chorus': true, 'reverb': false, 'distortion': false, 'phaser': true, 'compressor': false, 'flanger': true},
      effectParameters: {'chorusMix': 0.5, 'phaserRate': 2.0, 'phaserDepth': 0.6, 'flangerDepth': 0.4, 'flangerRate': 1.5},
      lfoEnabled: [true, true, true, true],
      lfoRates: [1.3, 1.7, 2.1, 0.9],
      lfoWaveforms: ['random', 'triangle', 'sawtooth', 'sine'],
      rotationSpeed: 0.6,
      morphFactor: 1.1,
      gridDensity: 14.0,
      glitchIntensity: 0.06,
      colorShift: 0.0,
      tags: ['complex', 'chaotic', 'evolving'],
      isBuiltIn: true,
    ),
  ];

  static List<VisualPreset> getPresetsByCategory(PresetCategory category) {
    return builtInPresets.where((p) => p.category == category).toList();
  }

  static VisualPreset? getPresetById(String id) {
    try {
      return builtInPresets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<VisualPreset> searchPresets(String query) {
    final lowerQuery = query.toLowerCase();
    return builtInPresets.where((p) =>
      p.name.toLowerCase().contains(lowerQuery) ||
      p.description.toLowerCase().contains(lowerQuery) ||
      p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}

/// Preset manager with save/load functionality
class PresetManager extends ChangeNotifier {
  final List<VisualPreset> _customPresets = [];
  VisualPreset? _currentPreset;

  List<VisualPreset> get allPresets => [...PresetLibrary.builtInPresets, ..._customPresets];
  List<VisualPreset> get customPresets => List.unmodifiable(_customPresets);
  VisualPreset? get currentPreset => _currentPreset;

  void setCurrentPreset(VisualPreset? preset) {
    _currentPreset = preset;
    notifyListeners();
  }

  void addCustomPreset(VisualPreset preset) {
    _customPresets.add(preset);
    notifyListeners();
  }

  void removeCustomPreset(String id) {
    _customPresets.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void updateCustomPreset(VisualPreset preset) {
    final index = _customPresets.indexWhere((p) => p.id == preset.id);
    if (index != -1) {
      _customPresets[index] = preset;
      notifyListeners();
    }
  }

  List<VisualPreset> getPresetsByCategory(PresetCategory category) {
    return allPresets.where((p) => p.category == category).toList();
  }

  VisualPreset? getPresetById(String id) {
    try {
      return allPresets.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // TODO: Implement persistence with shared_preferences or firebase
  Future<void> saveToStorage() async {
    // Save _customPresets to local storage
  }

  Future<void> loadFromStorage() async {
    // Load _customPresets from local storage
  }

  /// Export a preset to JSON string
  String exportPreset(VisualPreset preset) {
    return jsonEncode(preset.toJson());
  }

  /// Export multiple presets to JSON string
  String exportPresets(List<VisualPreset> presets) {
    return jsonEncode(presets.map((p) => p.toJson()).toList());
  }

  /// Export all custom presets to JSON string
  String exportAllCustomPresets() {
    return exportPresets(_customPresets);
  }

  /// Import a preset from JSON string
  /// Returns the imported preset or null if import failed
  VisualPreset? importPreset(String jsonString) {
    try {
      final json = jsonDecode(jsonString);
      final preset = VisualPreset.fromJson(json);

      // Generate new ID if it conflicts with existing presets
      final existingIds = allPresets.map((p) => p.id).toSet();
      if (existingIds.contains(preset.id)) {
        final newPreset = VisualPreset(
          id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
          name: preset.name,
          description: preset.description,
          category: preset.category,
          family: preset.family,
          polytope: preset.polytope,
          geometry: preset.geometry,
          effectsEnabled: preset.effectsEnabled,
          effectParameters: preset.effectParameters,
          lfoEnabled: preset.lfoEnabled,
          lfoRates: preset.lfoRates,
          lfoWaveforms: preset.lfoWaveforms,
          rotationSpeed: preset.rotationSpeed,
          morphFactor: preset.morphFactor,
          gridDensity: preset.gridDensity,
          glitchIntensity: preset.glitchIntensity,
          colorShift: preset.colorShift,
          tags: preset.tags,
          isBuiltIn: false,
        );
        addCustomPreset(newPreset);
        return newPreset;
      } else {
        addCustomPreset(preset);
        return preset;
      }
    } catch (e) {
      debugPrint('Failed to import preset: $e');
      return null;
    }
  }

  /// Import multiple presets from JSON string
  /// Returns list of successfully imported presets
  List<VisualPreset> importPresets(String jsonString) {
    try {
      final jsonList = jsonDecode(jsonString) as List;
      final imported = <VisualPreset>[];

      for (final json in jsonList) {
        try {
          final preset = VisualPreset.fromJson(json);

          // Generate new ID if it conflicts
          final existingIds = allPresets.map((p) => p.id).toSet();
          if (existingIds.contains(preset.id)) {
            final newPreset = VisualPreset(
              id: 'imported_${DateTime.now().millisecondsSinceEpoch}_${imported.length}',
              name: preset.name,
              description: preset.description,
              category: preset.category,
              family: preset.family,
              polytope: preset.polytope,
              geometry: preset.geometry,
              effectsEnabled: preset.effectsEnabled,
              effectParameters: preset.effectParameters,
              lfoEnabled: preset.lfoEnabled,
              lfoRates: preset.lfoRates,
              lfoWaveforms: preset.lfoWaveforms,
              rotationSpeed: preset.rotationSpeed,
              morphFactor: preset.morphFactor,
              gridDensity: preset.gridDensity,
              glitchIntensity: preset.glitchIntensity,
              colorShift: preset.colorShift,
              tags: preset.tags,
              isBuiltIn: false,
            );
            addCustomPreset(newPreset);
            imported.add(newPreset);
          } else {
            addCustomPreset(preset);
            imported.add(preset);
          }
        } catch (e) {
          debugPrint('Failed to import preset from batch: $e');
        }
      }

      return imported;
    } catch (e) {
      debugPrint('Failed to import presets: $e');
      return [];
    }
  }
}
