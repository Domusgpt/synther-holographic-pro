import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'polytope_math.dart';
import 'polytope_renderer.dart';
import '../synthesis/synthesis_manager.dart';

/// Professional 4D Polytope Visualization Engine
/// 
/// Central coordinator that provides:
/// - Real-time audio analysis from synthesis engines
/// - 4D polytope generation and transformation
/// - Audio-reactive animation and morphing
/// - Performance-optimized rendering pipeline
/// - Multi-polytope management and layering
/// - Professional visualization presets and automation

/// Polytope visualization preset
class VisualizationPreset {
  final String name;
  final String description;
  final PolytopeType primaryPolytope;
  final RenderConfig renderConfig;
  final Map<String, double> audioMappings;
  final Map<String, dynamic> animationSettings;
  
  VisualizationPreset({
    required this.name,
    required this.description,
    required this.primaryPolytope,
    required this.renderConfig,
    required this.audioMappings,
    required this.animationSettings,
  });
}

/// Polytope types supported
enum PolytopeType { tesseract, sixteenCell, twentyFourCell }

/// Audio analysis data
class AudioAnalysisData {
  final double amplitude;
  final double frequency;
  final double spectralCentroid;
  final double harmonicContent;
  final double attackSharpness;
  final double rhythmIntensity;
  final List<double> frequencySpectrum;
  final List<double> harmonicSpectrum;
  
  AudioAnalysisData({
    required this.amplitude,
    required this.frequency,
    required this.spectralCentroid,
    required this.harmonicContent,
    required this.attackSharpness,
    required this.rhythmIntensity,
    required this.frequencySpectrum,
    required this.harmonicSpectrum,
  });
  
  /// Convert to AudioReactiveParams for polytope transformation
  AudioReactiveParams toAudioReactiveParams() {
    return AudioReactiveParams(
      amplitude: amplitude,
      frequency: frequency,
      spectralCentroid: spectralCentroid,
      harmonicContent: harmonicContent,
      attackSharpness: attackSharpness,
      rhythmIntensity: rhythmIntensity,
    );
  }
}

/// Active polytope instance with state
class ActivePolytope {
  final PolytopeType type;
  final Polytope4D polytope;
  final AudioReactiveTransformer transformer;
  bool enabled;
  double opacity;
  double scale;
  RenderConfig renderConfig;
  
  ActivePolytope({
    required this.type,
    required this.polytope,
    required this.transformer,
    this.enabled = true,
    this.opacity = 1.0,
    this.scale = 1.0,
    required this.renderConfig,
  });
}

/// Professional 4D Polytope Visualization Engine
class PolytopeVisualizationEngine extends ChangeNotifier {
  late PolytopeRenderer _renderer;
  late html.CanvasElement _canvas;
  SynthesisManager? _synthesisManager;
  
  // Active polytopes
  final Map<String, ActivePolytope> _activePolytopes = {};
  String _primaryPolytopeId = 'main';
  
  // Animation and timing
  late Timer _animationTimer;
  DateTime _lastFrameTime = DateTime.now();
  double _totalTime = 0.0;
  bool _isAnimating = false;
  
  // Audio analysis
  late AudioAnalysisData _currentAudioData;
  final AudioAnalyzer _audioAnalyzer = AudioAnalyzer();
  
  // Visualization presets
  final List<VisualizationPreset> _presets = [];
  int _currentPresetIndex = 0;
  
  // Performance settings
  int _targetFPS = 60;
  bool _enablePerformanceOptimization = true;
  double _performanceThreshold = 16.67; // 60 FPS target
  
  // Canvas settings
  int _canvasWidth = 800;
  int _canvasHeight = 600;
  
  /// Initialize visualization engine
  Future<bool> initialize(html.CanvasElement canvas, {SynthesisManager? synthesisManager}) async {
    try {
      _canvas = canvas;
      _canvasWidth = canvas.width ?? 800;
      _canvasHeight = canvas.height ?? 600;
      _synthesisManager = synthesisManager;
      
      // Initialize renderer
      _renderer = PolytopeRenderer();
      final rendererInitialized = await _renderer.initialize(canvas);
      
      if (!rendererInitialized) {
        print('Failed to initialize polytope renderer');
        return false;
      }
      
      // Initialize default polytopes
      _initializeDefaultPolytopes();
      
      // Initialize visualization presets
      _initializePresets();
      
      // Initialize audio analysis
      _initializeAudioAnalysis();
      
      // Start animation loop
      _startAnimationLoop();
      
      return true;
    } catch (e) {
      print('Failed to initialize polytope visualization engine: $e');
      return false;
    }
  }
  
  void _initializeDefaultPolytopes() {
    // Create main tesseract
    final tesseract = Tesseract();
    tesseract.generateGeometry();
    
    _activePolytopes['main'] = ActivePolytope(
      type: PolytopeType.tesseract,
      polytope: tesseract,
      transformer: AudioReactiveTransformer(),
      renderConfig: RenderConfig(
        showVertices: true,
        showEdges: true,
        showFaces: true,
        vertexSize: 4.0,
        edgeThickness: 2.5,
        faceOpacity: 0.3,
        vertexColor: [1.0, 1.0, 1.0, 1.0],
        edgeColor: [0.0, 1.0, 1.0, 1.0],
        faceColor: [0.5, 0.0, 1.0, 0.3],
        enableHolographicEffects: true,
        holographicIntensity: 0.8,
        chromaticAberration: 0.015,
        enableDepthGlow: true,
      ),
    );
    
    // Create secondary 16-cell (disabled by default)
    final sixteenCell = SixteenCell();
    sixteenCell.generateGeometry();
    
    _activePolytopes['secondary'] = ActivePolytope(
      type: PolytopeType.sixteenCell,
      polytope: sixteenCell,
      transformer: AudioReactiveTransformer(),
      enabled: false,
      opacity: 0.7,
      scale: 0.8,
      renderConfig: RenderConfig(
        showVertices: true,
        showEdges: true,
        showFaces: false,
        vertexSize: 3.0,
        edgeThickness: 1.5,
        vertexColor: [1.0, 0.5, 0.0, 1.0],
        edgeColor: [1.0, 0.5, 0.0, 0.8],
        enableHolographicEffects: true,
        holographicIntensity: 0.6,
      ),
    );
    
    // Create tertiary 24-cell (disabled by default)
    final twentyFourCell = TwentyFourCell();
    twentyFourCell.generateGeometry();
    
    _activePolytopes['tertiary'] = ActivePolytope(
      type: PolytopeType.twentyFourCell,
      polytope: twentyFourCell,
      transformer: AudioReactiveTransformer(),
      enabled: false,
      opacity: 0.5,
      scale: 1.2,
      renderConfig: RenderConfig(
        showVertices: false,
        showEdges: true,
        showFaces: true,
        edgeThickness: 1.0,
        faceOpacity: 0.2,
        edgeColor: [0.5, 1.0, 0.5, 0.6],
        faceColor: [0.0, 0.8, 0.2, 0.2],
        enableHolographicEffects: true,
        holographicIntensity: 0.4,
      ),
    );
  }
  
  void _initializePresets() {
    _presets.addAll([
      VisualizationPreset(
        name: 'Classic Tesseract',
        description: 'Traditional 4D cube with full geometry display',
        primaryPolytope: PolytopeType.tesseract,
        renderConfig: RenderConfig(
          showVertices: true,
          showEdges: true,
          showFaces: true,
          enableHolographicEffects: true,
        ),
        audioMappings: {
          'amplitude_to_scale': 0.5,
          'frequency_to_rotation': 1.0,
          'spectral_centroid_to_color': 0.8,
          'harmonic_content_to_faces': 1.0,
        },
        animationSettings: {
          'base_rotation_speed': 0.3,
          'audio_sensitivity': 0.7,
          'color_cycling': true,
        },
      ),
      
      VisualizationPreset(
        name: 'Frequency Crystal',
        description: '16-cell optimized for frequency visualization',
        primaryPolytope: PolytopeType.sixteenCell,
        renderConfig: RenderConfig(
          showVertices: true,
          showEdges: true,
          showFaces: false,
          vertexSize: 5.0,
          edgeThickness: 3.0,
          enableHolographicEffects: true,
          holographicIntensity: 1.0,
        ),
        audioMappings: {
          'frequency_to_vertex_size': 1.5,
          'amplitude_to_glow': 1.0,
          'attack_to_burst': 2.0,
        },
        animationSettings: {
          'frequency_response': 'sharp',
          'burst_intensity': 1.5,
        },
      ),
      
      VisualizationPreset(
        name: 'Harmonic Sphere',
        description: '24-cell for complex harmonic visualization',
        primaryPolytope: PolytopeType.twentyFourCell,
        renderConfig: RenderConfig(
          showVertices: false,
          showEdges: true,
          showFaces: true,
          faceOpacity: 0.4,
          enableHolographicEffects: true,
          enableDepthGlow: true,
        ),
        audioMappings: {
          'harmonic_content_to_faces': 1.2,
          'spectral_tilt_to_color': 1.0,
          'rhythm_to_pulse': 0.8,
        },
        animationSettings: {
          'harmonic_sensitivity': 1.0,
          'color_spectrum': 'rainbow',
        },
      ),
      
      VisualizationPreset(
        name: 'Multi-Dimensional',
        description: 'All polytopes layered for complex synthesis',
        primaryPolytope: PolytopeType.tesseract,
        renderConfig: RenderConfig(
          showVertices: true,
          showEdges: true,
          showFaces: true,
          enableHolographicEffects: true,
          holographicIntensity: 0.9,
        ),
        audioMappings: {
          'engine_type_to_polytope': 1.0,
          'voice_count_to_layers': 1.0,
          'cpu_usage_to_intensity': 0.5,
        },
        animationSettings: {
          'layer_coordination': true,
          'synthesis_mapping': true,
        },
      ),
      
      VisualizationPreset(
        name: 'Minimal Wireframe',
        description: 'Clean wireframe for performance and clarity',
        primaryPolytope: PolytopeType.tesseract,
        renderConfig: RenderConfig(
          showVertices: false,
          showEdges: true,
          showFaces: false,
          edgeThickness: 1.5,
          enableHolographicEffects: false,
        ),
        audioMappings: {
          'amplitude_to_edge_thickness': 1.0,
          'frequency_to_rotation': 0.5,
        },
        animationSettings: {
          'minimal_mode': true,
          'performance_optimized': true,
        },
      ),
    ]);
  }
  
  void _initializeAudioAnalysis() {
    _currentAudioData = AudioAnalysisData(
      amplitude: 0.0,
      frequency: 440.0,
      spectralCentroid: 0.5,
      harmonicContent: 0.5,
      attackSharpness: 0.0,
      rhythmIntensity: 0.0,
      frequencySpectrum: List.filled(256, 0.0),
      harmonicSpectrum: List.filled(64, 0.0),
    );
  }
  
  void _startAnimationLoop() {
    _isAnimating = true;
    
    _animationTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ _targetFPS), (timer) {
      if (_isAnimating) {
        _updateVisualization();
      }
    });
  }
  
  void _updateVisualization() {
    final currentTime = DateTime.now();
    final deltaTime = currentTime.difference(_lastFrameTime).inMicroseconds / 1000000.0;
    _lastFrameTime = currentTime;
    _totalTime += deltaTime;
    
    // Update audio analysis
    _updateAudioAnalysis();
    
    // Update polytope transformations
    _updatePolytopeTransformations(deltaTime);
    
    // Render frame
    _renderFrame();
    
    // Performance optimization
    if (_enablePerformanceOptimization) {
      _optimizePerformance();
    }
    
    notifyListeners();
  }
  
  void _updateAudioAnalysis() {
    if (_synthesisManager == null) return;
    
    // Get visualization data from synthesis manager
    final visualizationData = _synthesisManager!.getVisualizationData();
    
    // Extract audio parameters from synthesis engines
    double totalAmplitude = 0.0;
    double avgFrequency = 440.0;
    double avgSpectralCentroid = 0.5;
    double avgHarmonicContent = 0.5;
    int activeVoices = 0;
    
    final engines = visualizationData['engines'] as Map<String, dynamic>? ?? {};
    
    for (final engineData in engines.values) {
      if (engineData['shouldPlay'] == true) {
        final engineVisualization = engineData['engineData'] as Map<String, dynamic>;
        
        // Accumulate audio parameters
        totalAmplitude += (engineVisualization['cpuUsage'] as double? ?? 0.0) * 0.1;
        activeVoices += engineVisualization['voiceCount'] as int? ?? 0;
        
        // Extract frequency information from different synthesis types
        switch (engineVisualization['type']) {
          case 'wavetable':
            final spectrum = engineVisualization['harmonicSpectrum'] as List<dynamic>? ?? [];
            if (spectrum.isNotEmpty) {
              avgSpectralCentroid = _calculateSpectralCentroid(spectrum.cast<double>());
            }
            break;
          case 'fm':
            final operatorFreqs = engineVisualization['operatorFrequencies'] as List<dynamic>? ?? [];
            if (operatorFreqs.isNotEmpty) {
              avgFrequency = operatorFreqs.cast<double>().reduce((a, b) => a + b) / operatorFreqs.length;
            }
            break;
          case 'granular':
            final grainData = engineVisualization['grainData'] as List<dynamic>? ?? [];
            avgHarmonicContent = math.min(1.0, grainData.length / 50.0); // Grain density as harmonic content
            break;
          case 'additive':
            final harmonicLevels = engineVisualization['harmonicLevels'] as List<dynamic>? ?? [];
            if (harmonicLevels.isNotEmpty) {
              avgHarmonicContent = _calculateHarmonicContent(harmonicLevels.cast<double>());
            }
            break;
        }
      }
    }
    
    // Calculate attack sharpness from voice changes
    final voiceCountDiff = (activeVoices - (_currentAudioData.rhythmIntensity * 10)).abs();
    final attackSharpness = math.min(1.0, voiceCountDiff / 5.0);
    
    // Update current audio data
    _currentAudioData = AudioAnalysisData(
      amplitude: math.min(1.0, totalAmplitude),
      frequency: avgFrequency,
      spectralCentroid: avgSpectralCentroid,
      harmonicContent: avgHarmonicContent,
      attackSharpness: attackSharpness,
      rhythmIntensity: activeVoices / 10.0, // Normalize to 0-1
      frequencySpectrum: _currentAudioData.frequencySpectrum, // Would need FFT analysis
      harmonicSpectrum: _currentAudioData.harmonicSpectrum,   // Would need harmonic analysis
    );
  }
  
  double _calculateSpectralCentroid(List<double> spectrum) {
    double weightedSum = 0.0;
    double totalMagnitude = 0.0;
    
    for (int i = 0; i < spectrum.length; i++) {
      weightedSum += i * spectrum[i];
      totalMagnitude += spectrum[i];
    }
    
    return totalMagnitude > 0 ? weightedSum / (totalMagnitude * spectrum.length) : 0.5;
  }
  
  double _calculateHarmonicContent(List<double> harmonicLevels) {
    if (harmonicLevels.isEmpty) return 0.0;
    
    double sum = 0.0;
    for (int i = 0; i < harmonicLevels.length; i++) {
      sum += harmonicLevels[i] * (i + 1); // Weight higher harmonics more
    }
    
    return math.min(1.0, sum / harmonicLevels.length);
  }
  
  void _updatePolytopeTransformations(double deltaTime) {
    final audioParams = _currentAudioData.toAudioReactiveParams();
    
    for (final polytope in _activePolytopes.values) {
      if (polytope.enabled) {
        // Update transformer with audio parameters
        polytope.transformer.updateFromAudio(audioParams, deltaTime);
        
        // Reset polytope geometry to base state
        polytope.polytope.generateGeometry();
        
        // Apply scale
        polytope.polytope.scale(polytope.scale);
        
        // Apply audio-reactive transformation
        polytope.transformer.transformPolytope(polytope.polytope);
      }
    }
  }
  
  void _renderFrame() {
    final primaryPolytope = _activePolytopes[_primaryPolytopeId];
    if (primaryPolytope == null || !primaryPolytope.enabled) return;
    
    // Render primary polytope
    _renderer.updateConfig(primaryPolytope.renderConfig);
    _renderer.renderPolytope(primaryPolytope.polytope, _currentAudioData.toAudioReactiveParams());
    
    // Render additional polytopes if enabled
    for (final entry in _activePolytopes.entries) {
      if (entry.key != _primaryPolytopeId && entry.value.enabled) {
        // Would need multi-polytope rendering support in renderer
        // For now, just render the primary polytope
      }
    }
  }
  
  void _optimizePerformance() {
    final metrics = _renderer.metrics;
    
    if (metrics.frameTime > _performanceThreshold) {
      // Performance is below target, reduce quality
      print('Performance optimization: Frame time ${metrics.frameTime.toStringAsFixed(2)}ms');
      
      // Reduce polytope complexity if needed
      for (final polytope in _activePolytopes.values) {
        if (polytope.enabled) {
          polytope.renderConfig.faceOpacity *= 0.9; // Reduce face opacity
          polytope.renderConfig.edgeThickness *= 0.95; // Reduce edge thickness
        }
      }
    }
  }
  
  /// Set visualization preset
  void setPreset(int presetIndex) {
    if (presetIndex >= 0 && presetIndex < _presets.length) {
      _currentPresetIndex = presetIndex;
      final preset = _presets[presetIndex];
      
      // Apply preset configuration
      _applyPreset(preset);
      notifyListeners();
    }
  }
  
  void _applyPreset(VisualizationPreset preset) {
    // Set primary polytope type
    final primaryPolytope = _findPolytopeByType(preset.primaryPolytope);
    if (primaryPolytope != null) {
      _primaryPolytopeId = primaryPolytope;
    }
    
    // Apply render configuration
    final primary = _activePolytopes[_primaryPolytopeId];
    if (primary != null) {
      primary.renderConfig = preset.renderConfig;
    }
    
    // Configure polytope visibility based on preset
    if (preset.name == 'Multi-Dimensional') {
      // Enable all polytopes
      for (final polytope in _activePolytopes.values) {
        polytope.enabled = true;
      }
    } else {
      // Enable only primary polytope
      for (final entry in _activePolytopes.entries) {
        entry.value.enabled = (entry.key == _primaryPolytopeId);
      }
    }
  }
  
  String? _findPolytopeByType(PolytopeType type) {
    for (final entry in _activePolytopes.entries) {
      if (entry.value.type == type) {
        return entry.key;
      }
    }
    return null;
  }
  
  /// Control polytope visibility
  void setPolytopeEnabled(String polytopeId, bool enabled) {
    final polytope = _activePolytopes[polytopeId];
    if (polytope != null) {
      polytope.enabled = enabled;
      notifyListeners();
    }
  }
  
  /// Set polytope opacity
  void setPolytopeOpacity(String polytopeId, double opacity) {
    final polytope = _activePolytopes[polytopeId];
    if (polytope != null) {
      polytope.opacity = opacity.clamp(0.0, 1.0);
      polytope.renderConfig.faceOpacity = polytope.opacity * 0.5;
      notifyListeners();
    }
  }
  
  /// Set polytope scale
  void setPolytopeScale(String polytopeId, double scale) {
    final polytope = _activePolytopes[polytopeId];
    if (polytope != null) {
      polytope.scale = scale.clamp(0.1, 3.0);
      notifyListeners();
    }
  }
  
  /// Update render configuration
  void updateRenderConfig(String polytopeId, RenderConfig config) {
    final polytope = _activePolytopes[polytopeId];
    if (polytope != null) {
      polytope.renderConfig = config;
      notifyListeners();
    }
  }
  
  /// Resize canvas
  void resize(int width, int height) {
    _canvasWidth = width;
    _canvasHeight = height;
    _renderer.resize(width, height);
  }
  
  /// Get current visualization data
  Map<String, dynamic> getVisualizationData() {
    return {
      'activePolytopes': _activePolytopes.keys.toList(),
      'primaryPolytopeId': _primaryPolytopeId,
      'currentPreset': _presets[_currentPresetIndex].name,
      'audioData': {
        'amplitude': _currentAudioData.amplitude,
        'frequency': _currentAudioData.frequency,
        'spectralCentroid': _currentAudioData.spectralCentroid,
        'harmonicContent': _currentAudioData.harmonicContent,
        'attackSharpness': _currentAudioData.attackSharpness,
        'rhythmIntensity': _currentAudioData.rhythmIntensity,
      },
      'renderMetrics': {
        'fps': _renderer.metrics.fps,
        'frameTime': _renderer.metrics.frameTime,
        'verticesRendered': _renderer.metrics.verticesRendered,
        'edgesRendered': _renderer.metrics.edgesRendered,
        'facesRendered': _renderer.metrics.facesRendered,
      },
      'polytopes': _activePolytopes.map((key, value) => MapEntry(key, {
        'type': value.type.toString(),
        'enabled': value.enabled,
        'opacity': value.opacity,
        'scale': value.scale,
        'vertexCount': value.polytope.vertexCount,
        'edgeCount': value.polytope.edgeCount,
        'faceCount': value.polytope.faceCount,
      })),
    };
  }
  
  /// Get available presets
  List<String> get presetNames => _presets.map((p) => p.name).toList();
  
  /// Get current preset index
  int get currentPresetIndex => _currentPresetIndex;
  
  /// Get render metrics
  RenderMetrics get renderMetrics => _renderer.metrics;
  
  /// Start/stop animation
  void setAnimating(bool animating) {
    _isAnimating = animating;
    if (!animating) {
      _animationTimer.cancel();
    } else {
      _startAnimationLoop();
    }
  }
  
  /// Dispose resources
  void dispose() {
    _animationTimer.cancel();
    _renderer.dispose();
    super.dispose();
  }
}

/// Simple audio analyzer (would be more sophisticated in production)
class AudioAnalyzer {
  // Placeholder for audio analysis functionality
  // In a real implementation, this would use Web Audio API or similar
  
  List<double> analyzeFrequencySpectrum(/* audio data */) {
    // Would perform FFT analysis
    return List.filled(256, 0.0);
  }
  
  List<double> analyzeHarmonicContent(/* audio data */) {
    // Would analyze harmonic content
    return List.filled(64, 0.0);
  }
}