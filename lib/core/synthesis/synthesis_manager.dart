import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'synthesis_engine.dart';
import 'wavetable_synthesis.dart';
import 'fm_synthesis.dart';
import 'granular_synthesis.dart';
import 'additive_synthesis.dart';

/// Professional Synthesis Manager
/// 
/// Coordinates multiple synthesis engines and provides:
/// - Unified interface for all synthesis types
/// - Engine switching and layering capabilities
/// - Cross-engine parameter synchronization
/// - Performance optimization and voice management
/// - Real-time synthesis type morphing
/// - Professional mixing and effects routing

/// Synthesis layer configuration
class SynthesisLayer {
  final SynthesisEngine engine;
  bool enabled;
  double amplitude;
  double pan;
  int midiChannel;
  bool solo;
  bool mute;
  
  SynthesisLayer({
    required this.engine,
    this.enabled = true,
    this.amplitude = 1.0,
    this.pan = 0.0,
    this.midiChannel = 1,
    this.solo = false,
    this.mute = false,
  });
  
  /// Check if layer should play
  bool get shouldPlay => enabled && !mute && amplitude > 0.001;
}

/// Synthesis engine performance metrics
class SynthesisMetrics {
  final double totalCpuUsage;
  final int totalVoiceCount;
  final Map<SynthesisType, double> engineCpuUsage;
  final Map<SynthesisType, int> engineVoiceCount;
  final double bufferUnderruns;
  final double latency;
  
  SynthesisMetrics({
    required this.totalCpuUsage,
    required this.totalVoiceCount,
    required this.engineCpuUsage,
    required this.engineVoiceCount,
    required this.bufferUnderruns,
    required this.latency,
  });
}

/// Professional Synthesis Manager
class SynthesisManager extends ChangeNotifier {
  final Map<SynthesisType, SynthesisLayer> _synthLayers = {};
  SynthesisType _primaryEngine = SynthesisType.wavetable;
  
  // Global synthesis settings
  double _globalAmplitude = 0.8;
  double _globalPan = 0.0;
  double _sampleRate = 44100.0;
  int _bufferSize = 256;
  
  // Engine switching and morphing
  bool _enableEngineLayering = false;
  bool _enableCrossfading = true;
  double _crossfadeTime = 0.5; // seconds
  SynthesisType? _crossfadeTarget;
  double _crossfadeProgress = 0.0;
  
  // Performance management
  bool _enablePerformanceOptimization = true;
  double _cpuThreshold = 0.85;
  int _maxTotalVoices = 64;
  bool _enableVoiceCulling = true;
  
  // Real-time metrics
  SynthesisMetrics? _lastMetrics;
  final List<double> _cpuHistory = [];
  static const int maxCpuHistoryLength = 100;
  
  SynthesisManager({
    double sampleRate = 44100.0,
    int bufferSize = 256,
  }) : _sampleRate = sampleRate, _bufferSize = bufferSize {
    _initializeSynthesisEngines();
  }
  
  // Getters
  Map<SynthesisType, SynthesisLayer> get synthLayers => Map.unmodifiable(_synthLayers);
  SynthesisType get primaryEngine => _primaryEngine;
  double get globalAmplitude => _globalAmplitude;
  double get globalPan => _globalPan;
  double get sampleRate => _sampleRate;
  int get bufferSize => _bufferSize;
  bool get enableEngineLayering => _enableEngineLayering;
  bool get enableCrossfading => _enableCrossfading;
  double get crossfadeTime => _crossfadeTime;
  SynthesisMetrics? get lastMetrics => _lastMetrics;
  List<double> get cpuHistory => List.unmodifiable(_cpuHistory);
  
  /// Initialize all synthesis engines
  void _initializeSynthesisEngines() {
    // Create all synthesis engines
    _synthLayers[SynthesisType.wavetable] = SynthesisLayer(
      engine: WavetableSynthesis(sampleRate: _sampleRate),
      midiChannel: 1,
    );
    
    _synthLayers[SynthesisType.fm] = SynthesisLayer(
      engine: FMSynthesis(sampleRate: _sampleRate),
      enabled: false,
      midiChannel: 2,
    );
    
    _synthLayers[SynthesisType.granular] = SynthesisLayer(
      engine: GranularSynthesis(sampleRate: _sampleRate),
      enabled: false,
      midiChannel: 3,
    );
    
    _synthLayers[SynthesisType.additive] = SynthesisLayer(
      engine: AdditiveSynthesis(sampleRate: _sampleRate),
      enabled: false,
      midiChannel: 4,
    );
    
    // Set up engine change listeners
    for (final layer in _synthLayers.values) {
      layer.engine.addListener(_onEngineChanged);
    }
  }
  
  /// Handle engine parameter changes
  void _onEngineChanged() {
    notifyListeners();
  }
  
  /// Set primary synthesis engine
  void setPrimaryEngine(SynthesisType engineType) {
    if (_synthLayers.containsKey(engineType)) {
      if (_enableCrossfading && _primaryEngine != engineType) {
        _startCrossfade(engineType);
      } else {
        _primaryEngine = engineType;
        _updateEngineStates();
      }
      notifyListeners();
    }
  }
  
  /// Start crossfade between engines
  void _startCrossfade(SynthesisType targetEngine) {
    _crossfadeTarget = targetEngine;
    _crossfadeProgress = 0.0;
    
    // Enable both engines during crossfade
    _synthLayers[_primaryEngine]?.enabled = true;
    _synthLayers[targetEngine]?.enabled = true;
  }
  
  /// Update crossfade progress
  void _updateCrossfade(double deltaTime) {
    if (_crossfadeTarget == null) return;
    
    _crossfadeProgress += deltaTime / _crossfadeTime;
    
    if (_crossfadeProgress >= 1.0) {
      // Crossfade complete
      _primaryEngine = _crossfadeTarget!;
      _crossfadeTarget = null;
      _crossfadeProgress = 0.0;
      _updateEngineStates();
    } else {
      // Update crossfade amplitudes
      final primaryLayer = _synthLayers[_primaryEngine];
      final targetLayer = _synthLayers[_crossfadeTarget!];
      
      if (primaryLayer != null && targetLayer != null) {
        primaryLayer.amplitude = 1.0 - _crossfadeProgress;
        targetLayer.amplitude = _crossfadeProgress;
      }
    }
  }
  
  /// Update engine enabled states based on layering settings
  void _updateEngineStates() {
    if (_enableEngineLayering) {
      // Keep all enabled engines active
      return;
    }
    
    // Single engine mode - only primary engine enabled
    for (final entry in _synthLayers.entries) {
      final layer = entry.value;
      layer.enabled = (entry.key == _primaryEngine);
      layer.amplitude = layer.enabled ? 1.0 : 0.0;
    }
  }
  
  /// Enable/disable engine layering
  void setEngineLayering(bool enabled) {
    _enableEngineLayering = enabled;
    _updateEngineStates();
    notifyListeners();
  }
  
  /// Enable/disable specific synthesis layer
  void setLayerEnabled(SynthesisType engineType, bool enabled) {
    final layer = _synthLayers[engineType];
    if (layer != null) {
      layer.enabled = enabled;
      notifyListeners();
    }
  }
  
  /// Set layer amplitude
  void setLayerAmplitude(SynthesisType engineType, double amplitude) {
    final layer = _synthLayers[engineType];
    if (layer != null) {
      layer.amplitude = amplitude.clamp(0.0, 2.0);
      notifyListeners();
    }
  }
  
  /// Set layer pan
  void setLayerPan(SynthesisType engineType, double pan) {
    final layer = _synthLayers[engineType];
    if (layer != null) {
      layer.pan = pan.clamp(-1.0, 1.0);
      notifyListeners();
    }
  }
  
  /// Solo a specific layer
  void setLayerSolo(SynthesisType engineType, bool solo) {
    final layer = _synthLayers[engineType];
    if (layer != null) {
      layer.solo = solo;
      
      // If soloing, mute other layers
      if (solo) {
        for (final otherLayer in _synthLayers.values) {
          if (otherLayer != layer) {
            otherLayer.mute = true;
          }
        }
      } else {
        // If unsoloing, check if any other layers are still soloed
        final hasOtherSolo = _synthLayers.values.any((l) => l != layer && l.solo);
        if (!hasOtherSolo) {
          // Unmute all layers
          for (final otherLayer in _synthLayers.values) {
            otherLayer.mute = false;
          }
        }
      }
      
      notifyListeners();
    }
  }
  
  /// Mute/unmute layer
  void setLayerMute(SynthesisType engineType, bool mute) {
    final layer = _synthLayers[engineType];
    if (layer != null) {
      layer.mute = mute;
      notifyListeners();
    }
  }
  
  /// Set global amplitude
  void setGlobalAmplitude(double amplitude) {
    _globalAmplitude = amplitude.clamp(0.0, 2.0);
    notifyListeners();
  }
  
  /// Set global pan
  void setGlobalPan(double pan) {
    _globalPan = pan.clamp(-1.0, 1.0);
    notifyListeners();
  }
  
  /// Note on for all active engines
  void noteOn(int noteNumber, double velocity, {SynthesisType? specificEngine}) {
    if (specificEngine != null) {
      // Send to specific engine only
      final layer = _synthLayers[specificEngine];
      if (layer != null && layer.shouldPlay) {
        layer.engine.noteOn(noteNumber, velocity);
      }
    } else {
      // Send to all active engines
      for (final layer in _synthLayers.values) {
        if (layer.shouldPlay) {
          layer.engine.noteOn(noteNumber, velocity);
        }
      }
    }
    
    _checkPerformanceThresholds();
  }
  
  /// Note off for all active engines
  void noteOff(int noteNumber, {SynthesisType? specificEngine}) {
    if (specificEngine != null) {
      // Send to specific engine only
      final layer = _synthLayers[specificEngine];
      if (layer != null) {
        layer.engine.noteOff(noteNumber);
      }
    } else {
      // Send to all active engines
      for (final layer in _synthLayers.values) {
        layer.engine.noteOff(noteNumber);
      }
    }
  }
  
  /// Process audio from all active engines
  Float32List processAudio(int numSamples, {double deltaTime = 0.0}) {
    final buffer = Float32List(numSamples);
    final engineBuffers = <SynthesisType, Float32List>{};
    
    // Update crossfade if active
    if (deltaTime > 0.0) {
      _updateCrossfade(deltaTime);
    }
    
    // Process each active engine
    for (final entry in _synthLayers.entries) {
      final engineType = entry.key;
      final layer = entry.value;
      
      if (layer.shouldPlay) {
        final engineBuffer = layer.engine.processAudio(numSamples);
        engineBuffers[engineType] = engineBuffer;
        
        // Mix engine output into main buffer
        _mixEngineBuffer(buffer, engineBuffer, layer, numSamples);
      }
    }
    
    // Apply global processing
    _applyGlobalProcessing(buffer);
    
    // Update performance metrics
    _updateMetrics(engineBuffers);
    
    return buffer;
  }
  
  /// Mix engine buffer into main buffer with layer settings
  void _mixEngineBuffer(Float32List mainBuffer, Float32List engineBuffer, SynthesisLayer layer, int numSamples) {
    for (int i = 0; i < numSamples; i++) {
      double sample = engineBuffer[i] * layer.amplitude;
      
      // Apply pan (simple stereo simulation for mono)
      if (layer.pan != 0.0) {
        sample *= (1.0 - layer.pan.abs());
      }
      
      mainBuffer[i] += sample;
    }
  }
  
  /// Apply global processing to final buffer
  void _applyGlobalProcessing(Float32List buffer) {
    for (int i = 0; i < buffer.length; i++) {
      // Apply global amplitude
      buffer[i] *= _globalAmplitude;
      
      // Apply global pan (simple implementation)
      if (_globalPan != 0.0) {
        buffer[i] *= (1.0 - _globalPan.abs());
      }
      
      // Soft limiting
      buffer[i] = _softLimit(buffer[i]);
    }
  }
  
  /// Soft limiting function
  double _softLimit(double sample) {
    const threshold = 0.95;
    if (sample.abs() > threshold) {
      final sign = sample.sign;
      final excess = sample.abs() - threshold;
      return sign * (threshold + excess / (1.0 + excess * 2.0));
    }
    return sample;
  }
  
  /// Update performance metrics
  void _updateMetrics(Map<SynthesisType, Float32List> engineBuffers) {
    double totalCpu = 0.0;
    int totalVoices = 0;
    final engineCpu = <SynthesisType, double>{};
    final engineVoices = <SynthesisType, int>{};
    
    for (final entry in _synthLayers.entries) {
      final engineType = entry.key;
      final layer = entry.value;
      
      if (layer.enabled) {
        final cpu = layer.engine.cpuUsage;
        final voices = layer.engine.voiceCount;
        
        totalCpu += cpu;
        totalVoices += voices;
        engineCpu[engineType] = cpu;
        engineVoices[engineType] = voices;
      }
    }
    
    _lastMetrics = SynthesisMetrics(
      totalCpuUsage: totalCpu,
      totalVoiceCount: totalVoices,
      engineCpuUsage: engineCpu,
      engineVoiceCount: engineVoices,
      bufferUnderruns: 0.0, // Would be measured from audio callback
      latency: _bufferSize / _sampleRate * 1000, // Approximate latency in ms
    );
    
    // Update CPU history
    _cpuHistory.add(totalCpu);
    if (_cpuHistory.length > maxCpuHistoryLength) {
      _cpuHistory.removeAt(0);
    }
  }
  
  /// Check and handle performance thresholds
  void _checkPerformanceThresholds() {
    if (!_enablePerformanceOptimization) return;
    
    final metrics = _lastMetrics;
    if (metrics == null) return;
    
    // Check CPU threshold
    if (metrics.totalCpuUsage > _cpuThreshold) {
      _handleCpuOverload();
    }
    
    // Check voice count threshold
    if (metrics.totalVoiceCount > _maxTotalVoices) {
      _handleVoiceOverload();
    }
  }
  
  /// Handle CPU overload
  void _handleCpuOverload() {
    print('Warning: CPU usage high (${(_lastMetrics!.totalCpuUsage * 100).toStringAsFixed(1)}%)');
    
    if (_enableVoiceCulling) {
      // Reduce voice counts for less critical engines
      for (final layer in _synthLayers.values) {
        if (layer.enabled && layer.engine.voiceCount > 4) {
          // Implement voice culling in engine
          layer.engine.reset(); // Temporary solution
        }
      }
    }
  }
  
  /// Handle voice count overload
  void _handleVoiceOverload() {
    print('Warning: Too many voices (${_lastMetrics!.totalVoiceCount})');
    
    // Reset least critical engine
    final sortedLayers = _synthLayers.values.toList()
      ..sort((a, b) => a.amplitude.compareTo(b.amplitude));
    
    for (final layer in sortedLayers) {
      if (layer.enabled && layer.engine.voiceCount > 0) {
        layer.engine.reset();
        break;
      }
    }
  }
  
  /// Set synthesis parameter across all engines
  void setGlobalParameter(SynthParameter parameter, double value) {
    for (final layer in _synthLayers.values) {
      if (layer.enabled && layer.engine.getSupportedParameters().contains(parameter)) {
        layer.engine.setParameter(parameter, value);
      }
    }
    notifyListeners();
  }
  
  /// Set parameter for specific engine
  void setEngineParameter(SynthesisType engineType, SynthParameter parameter, double value) {
    final layer = _synthLayers[engineType];
    if (layer != null && layer.engine.getSupportedParameters().contains(parameter)) {
      layer.engine.setParameter(parameter, value);
      notifyListeners();
    }
  }
  
  /// Get engine by type
  SynthesisEngine? getEngine(SynthesisType engineType) {
    return _synthLayers[engineType]?.engine;
  }
  
  /// Get all visualization data
  Map<String, dynamic> getVisualizationData() {
    final data = <String, dynamic>{
      'primaryEngine': _primaryEngine.toString(),
      'enableEngineLayering': _enableEngineLayering,
      'crossfadeProgress': _crossfadeProgress,
      'crossfadeTarget': _crossfadeTarget?.toString(),
      'globalAmplitude': _globalAmplitude,
      'globalPan': _globalPan,
      'metrics': _lastMetrics != null ? {
        'totalCpuUsage': _lastMetrics!.totalCpuUsage,
        'totalVoiceCount': _lastMetrics!.totalVoiceCount,
        'latency': _lastMetrics!.latency,
      } : null,
      'engines': <String, dynamic>{},
    };
    
    // Add engine-specific visualization data
    for (final entry in _synthLayers.entries) {
      final engineType = entry.key;
      final layer = entry.value;
      
      data['engines'][engineType.toString()] = {
        'enabled': layer.enabled,
        'amplitude': layer.amplitude,
        'pan': layer.pan,
        'solo': layer.solo,
        'mute': layer.mute,
        'shouldPlay': layer.shouldPlay,
        'engineData': layer.engine.getVisualizationData(),
      };
    }
    
    return data;
  }
  
  /// Update sample rate for all engines
  void setSampleRate(double newSampleRate) {
    _sampleRate = newSampleRate;
    for (final layer in _synthLayers.values) {
      layer.engine.setSampleRate(newSampleRate);
    }
    notifyListeners();
  }
  
  /// Set buffer size
  void setBufferSize(int newBufferSize) {
    _bufferSize = newBufferSize;
    notifyListeners();
  }
  
  /// Reset all engines
  void reset() {
    for (final layer in _synthLayers.values) {
      layer.engine.reset();
    }
    _cpuHistory.clear();
    _lastMetrics = null;
    _crossfadeTarget = null;
    _crossfadeProgress = 0.0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Remove listeners
    for (final layer in _synthLayers.values) {
      layer.engine.removeListener(_onEngineChanged);
      layer.engine.dispose();
    }
    _synthLayers.clear();
    super.dispose();
  }
}