import 'dart:typed_data';
import 'dart:math' as math;
import 'synthesis_engine.dart';

/// Professional Granular Synthesis Engine
/// 
/// Features:
/// - Real-time granular processing with particle visualization
/// - Multiple grain shapes (gaussian, hann, triangular, rectangular)
/// - Advanced grain scheduling and overlap control
/// - Source material morphing and time-stretching
/// - Spatial positioning and stereo field control
/// - Professional grain parameter modulation

/// Grain shape types for windowing
enum GrainShape {
  gaussian,
  hann,
  triangular,
  rectangular,
  blackman,
  custom
}

/// Individual grain particle
class Grain {
  final int id;
  final double startTime;
  final double duration;
  final double frequency;
  final double amplitude;
  final double pan;
  final GrainShape shape;
  final Float32List sourceData;
  final double sourcePosition;
  final double pitch;
  
  double currentTime = 0.0;
  bool isActive = true;
  
  Grain({
    required this.id,
    required this.startTime,
    required this.duration,
    required this.frequency,
    required this.amplitude,
    required this.pan,
    required this.shape,
    required this.sourceData,
    required this.sourcePosition,
    required this.pitch,
  });
  
  /// Process grain for one sample
  double process(double sampleRate) {
    if (!isActive || currentTime >= duration) {
      isActive = false;
      return 0.0;
    }
    
    // Calculate grain window envelope
    final progress = currentTime / duration;
    final window = _calculateWindow(progress, shape);
    
    // Calculate source position with pitch shift
    final sourceIndex = sourcePosition + (currentTime * pitch * sampleRate);
    
    // Get interpolated sample from source
    final sample = _getInterpolatedSample(sourceIndex);
    
    // Apply window and amplitude
    final output = sample * window * amplitude;
    
    currentTime += 1.0 / sampleRate;
    
    return output;
  }
  
  /// Calculate window function value
  double _calculateWindow(double progress, GrainShape shape) {
    switch (shape) {
      case GrainShape.gaussian:
        final x = (progress - 0.5) * 6.0; // -3 to +3 sigma
        return math.exp(-0.5 * x * x);
        
      case GrainShape.hann:
        return 0.5 * (1.0 - math.cos(2.0 * math.pi * progress));
        
      case GrainShape.triangular:
        return 1.0 - (2.0 * (progress - 0.5)).abs();
        
      case GrainShape.rectangular:
        return 1.0;
        
      case GrainShape.blackman:
        return 0.42 - 0.5 * math.cos(2.0 * math.pi * progress) + 
               0.08 * math.cos(4.0 * math.pi * progress);
        
      case GrainShape.custom:
        // Custom window (can be modified)
        return math.sin(math.pi * progress);
    }
  }
  
  /// Get interpolated sample from source data
  double _getInterpolatedSample(double position) {
    if (sourceData.isEmpty) return 0.0;
    
    final index = position.floor();
    final fraction = position - index;
    
    final i0 = index % sourceData.length;
    final i1 = (index + 1) % sourceData.length;
    
    return SynthUtils.lerp(sourceData[i0], sourceData[i1], fraction);
  }
  
  /// Get visualization data for this grain
  Map<String, dynamic> getVisualizationData() {
    return {
      'id': id,
      'startTime': startTime,
      'currentTime': currentTime,
      'duration': duration,
      'progress': currentTime / duration,
      'amplitude': amplitude,
      'frequency': frequency,
      'pan': pan,
      'isActive': isActive,
      'shape': shape.toString(),
    };
  }
}

/// Granular voice with multiple simultaneous grains
class GranularVoice extends SynthVoice {
  final List<Grain> grains = [];
  int nextGrainId = 0;
  double lastGrainTime = 0.0;
  
  // Granular parameters
  double grainSize;
  double grainDensity;
  double grainPosition;
  double grainPitch;
  GrainShape grainShape;
  
  GranularVoice({
    required super.noteNumber,
    required super.frequency,
    required super.velocity,
    required super.startTime,
    this.grainSize = 0.1,
    this.grainDensity = 10.0,
    this.grainPosition = 0.0,
    this.grainPitch = 1.0,
    this.grainShape = GrainShape.hann,
  });
  
  /// Add a new grain to this voice
  void addGrain(Grain grain) {
    grains.add(grain);
    
    // Remove old inactive grains to prevent memory buildup
    grains.removeWhere((g) => !g.isActive);
  }
  
  /// Get active grain count
  int get activeGrainCount => grains.where((g) => g.isActive).length;
}

/// Professional Granular Synthesis Engine
class GranularSynthesis extends SynthesisEngine {
  // Source material for granular processing
  final Map<String, Float32List> _sourceMaterials = {};
  String _currentSourceName = 'sine';
  
  // Global granular parameters
  double _grainSize = 0.1;        // Grain duration in seconds
  double _grainDensity = 10.0;    // Grains per second
  double _grainPosition = 0.0;    // Position in source material (0-1)
  double _grainPitch = 1.0;       // Pitch shift ratio
  double _grainSpread = 0.1;      // Random variation in parameters
  GrainShape _grainShape = GrainShape.hann;
  
  // Grain scheduling
  double _globalTime = 0.0;
  int _nextGrainId = 0;
  
  GranularSynthesis({
    super.maxVoices = 8, // Granular can be very CPU intensive
    super.sampleRate = 44100.0,
  }) : super(
    type: SynthesisType.granular,
    name: 'Professional Granular',
  ) {
    _initializeSourceMaterials();
    _initializeGranularParameters();
  }
  
  // Getters
  Map<String, Float32List> get sourceMaterials => Map.unmodifiable(_sourceMaterials);
  String get currentSourceName => _currentSourceName;
  double get grainSize => _grainSize;
  double get grainDensity => _grainDensity;
  double get grainPosition => _grainPosition;
  double get grainPitch => _grainPitch;
  double get grainSpread => _grainSpread;
  GrainShape get grainShape => _grainShape;
  
  /// Initialize source materials for granular processing
  void _initializeSourceMaterials() {
    // Generate basic waveforms as source material
    _sourceMaterials['sine'] = _generateSineWave();
    _sourceMaterials['sawtooth'] = _generateSawtoothWave();
    _sourceMaterials['noise'] = _generateNoise();
    _sourceMaterials['vocal'] = _generateVocalSource();
    _sourceMaterials['bells'] = _generateBellSource();
    _sourceMaterials['texture'] = _generateTextureSource();
  }
  
  /// Initialize granular-specific parameters
  void _initializeGranularParameters() {
    setParameter(SynthParameter.grainSize, _grainSize);
    setParameter(SynthParameter.grainDensity, _grainDensity);
    setParameter(SynthParameter.grainPosition, _grainPosition);
  }
  
  /// Set current source material
  void setSourceMaterial(String sourceName) {
    if (_sourceMaterials.containsKey(sourceName)) {
      _currentSourceName = sourceName;
      notifyListeners();
    }
  }
  
  /// Set grain size (duration)
  void setGrainSize(double size) {
    _grainSize = size.clamp(0.001, 2.0);
    setParameter(SynthParameter.grainSize, _grainSize);
    notifyListeners();
  }
  
  /// Set grain density (grains per second)
  void setGrainDensity(double density) {
    _grainDensity = density.clamp(0.1, 1000.0);
    setParameter(SynthParameter.grainDensity, _grainDensity);
    notifyListeners();
  }
  
  /// Set position in source material
  void setGrainPosition(double position) {
    _grainPosition = position.clamp(0.0, 1.0);
    setParameter(SynthParameter.grainPosition, _grainPosition);
    notifyListeners();
  }
  
  /// Set grain pitch shift
  void setGrainPitch(double pitch) {
    _grainPitch = pitch.clamp(0.1, 4.0);
    notifyListeners();
  }
  
  /// Set grain parameter spread (randomization)
  void setGrainSpread(double spread) {
    _grainSpread = spread.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  /// Set grain shape
  void setGrainShape(GrainShape shape) {
    _grainShape = shape;
    notifyListeners();
  }
  
  @override
  List<SynthParameter> getSupportedParameters() {
    return [
      SynthParameter.frequency,
      SynthParameter.amplitude,
      SynthParameter.grainSize,
      SynthParameter.grainDensity,
      SynthParameter.grainPosition,
      SynthParameter.lfoRate,
      SynthParameter.lfoAmount,
      SynthParameter.envelopeAttack,
      SynthParameter.envelopeDecay,
      SynthParameter.envelopeSustain,
      SynthParameter.envelopeRelease,
    ];
  }
  
  @override
  Map<String, dynamic> getParameterInfo(SynthParameter parameter) {
    switch (parameter) {
      case SynthParameter.grainSize:
        return {
          'name': 'Grain Size',
          'min': 0.001,
          'max': 2.0,
          'default': 0.1,
          'unit': 's',
          'description': 'Duration of individual grains'
        };
      case SynthParameter.grainDensity:
        return {
          'name': 'Grain Density',
          'min': 0.1,
          'max': 1000.0,
          'default': 10.0,
          'unit': '/s',
          'description': 'Number of grains per second'
        };
      case SynthParameter.grainPosition:
        return {
          'name': 'Grain Position',
          'min': 0.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '%',
          'description': 'Position in source material'
        };
      default:
        return {
          'name': parameter.toString(),
          'min': 0.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '',
          'description': 'Parameter description'
        };
    }
  }
  
  @override
  void onNoteOn(SynthVoice voice) {
    if (voice is! GranularVoice) return;
    
    // Initialize granular parameters for this voice
    voice.grainSize = _grainSize;
    voice.grainDensity = _grainDensity;
    voice.grainPosition = _grainPosition;
    voice.grainPitch = _grainPitch * (voice.frequency / 440.0); // Scale by note
    voice.grainShape = _grainShape;
  }
  
  @override
  void onNoteOff(SynthVoice voice) {
    voice.isActive = false;
  }
  
  @override
  Float32List processVoice(SynthVoice voice, int numSamples) {
    final buffer = Float32List(numSamples);
    
    if (voice is! GranularVoice) return buffer;
    
    final sourceData = _sourceMaterials[_currentSourceName] ?? _sourceMaterials['sine']!;
    var currentTime = DateTime.now().difference(voice.startTime).inMicroseconds / 1000000.0;
    
    // Schedule new grains
    _scheduleGrains(voice, sourceData, currentTime, numSamples);
    
    // Process existing grains
    for (int i = 0; i < numSamples; i++) {
      double sample = 0.0;
      
      // Sum all active grains
      for (final grain in voice.grains) {
        if (grain.isActive) {
          sample += grain.process(sampleRate);
        }
      }
      
      // Apply voice envelope
      final envelope = SynthUtils.applyADSR(
        currentTime + (i / sampleRate),
        getParameter(SynthParameter.envelopeAttack),
        getParameter(SynthParameter.envelopeDecay),
        getParameter(SynthParameter.envelopeSustain),
        getParameter(SynthParameter.envelopeRelease),
        !voice.isActive,
        currentTime
      );
      
      // Apply velocity and amplitude
      sample *= voice.velocity * voice.amplitude * envelope;
      
      buffer[i] = sample;
    }
    
    // Clean up inactive grains
    voice.grains.removeWhere((grain) => !grain.isActive);
    
    return buffer;
  }
  
  /// Schedule new grains for a voice
  void _scheduleGrains(GranularVoice voice, Float32List sourceData, double currentTime, int numSamples) {
    final samplesPerGrain = sampleRate / voice.grainDensity;
    final timePerSample = 1.0 / sampleRate;
    
    for (int i = 0; i < numSamples; i++) {
      final sampleTime = currentTime + (i * timePerSample);
      
      // Check if it's time for a new grain
      if (sampleTime - voice.lastGrainTime >= samplesPerGrain / sampleRate) {
        _createNewGrain(voice, sourceData, sampleTime);
        voice.lastGrainTime = sampleTime;
      }
    }
  }
  
  /// Create a new grain
  void _createNewGrain(GranularVoice voice, Float32List sourceData, double startTime) {
    // Apply randomization based on spread parameter
    final random = math.Random();
    
    final sizeVariation = (_grainSpread * 0.5 * (random.nextDouble() - 0.5));
    final positionVariation = (_grainSpread * 0.2 * (random.nextDouble() - 0.5));
    final pitchVariation = (_grainSpread * 0.1 * (random.nextDouble() - 0.5));
    final amplitudeVariation = (_grainSpread * 0.3 * (random.nextDouble() - 0.5));
    
    final grain = Grain(
      id: _nextGrainId++,
      startTime: startTime,
      duration: math.max(0.001, voice.grainSize * (1.0 + sizeVariation)),
      frequency: voice.frequency,
      amplitude: 0.1 * (1.0 + amplitudeVariation), // Scale down for grain overlap
      pan: random.nextDouble() * 2.0 - 1.0, // Random stereo positioning
      shape: voice.grainShape,
      sourceData: sourceData,
      sourcePosition: (voice.grainPosition + positionVariation).clamp(0.0, 1.0) * sourceData.length,
      pitch: voice.grainPitch * (1.0 + pitchVariation),
    );
    
    voice.addGrain(grain);
  }
  
  @override
  Map<String, dynamic> getVisualizationData() {
    // Collect grain data from all active voices
    final allGrains = <Map<String, dynamic>>[];
    int totalActiveGrains = 0;
    
    for (final voice in activeVoices) {
      if (voice is GranularVoice) {
        totalActiveGrains += voice.activeGrainCount;
        
        for (final grain in voice.grains) {
          if (grain.isActive) {
            allGrains.add(grain.getVisualizationData());
          }
        }
      }
    }
    
    return {
      'type': 'granular',
      'sourceMaterial': _currentSourceName,
      'grainSize': _grainSize,
      'grainDensity': _grainDensity,
      'grainPosition': _grainPosition,
      'grainPitch': _grainPitch,
      'grainSpread': _grainSpread,
      'grainShape': _grainShape.toString(),
      'totalActiveGrains': totalActiveGrains,
      'grainData': allGrains.take(100).toList(), // Limit for performance
      'voiceCount': voiceCount,
      'cpuUsage': cpuUsage,
    };
  }
  
  @override
  SynthVoice createVoice(int noteNumber, double frequency, double velocity) {
    return GranularVoice(
      noteNumber: noteNumber,
      frequency: frequency,
      velocity: velocity,
      startTime: DateTime.now(),
      grainSize: _grainSize,
      grainDensity: _grainDensity,
      grainPosition: _grainPosition,
      grainPitch: _grainPitch,
      grainShape: _grainShape,
    );
  }

  
  // Source material generators
  
  Float32List _generateSineWave() {
    const length = 44100; // 1 second at 44.1kHz
    final samples = Float32List(length);
    
    for (int i = 0; i < length; i++) {
      final phase = (i / length) * 2.0 * math.pi;
      samples[i] = math.sin(phase);
    }
    
    return samples;
  }
  
  Float32List _generateSawtoothWave() {
    const length = 44100;
    final samples = Float32List(length);
    
    for (int i = 0; i < length; i++) {
      final phase = i / length;
      samples[i] = SynthUtils.sawtooth(phase);
    }
    
    return samples;
  }
  
  Float32List _generateNoise() {
    const length = 44100;
    final samples = Float32List(length);
    final random = math.Random();
    
    for (int i = 0; i < length; i++) {
      samples[i] = random.nextDouble() * 2.0 - 1.0;
    }
    
    return samples;
  }
  
  Float32List _generateVocalSource() {
    const length = 44100;
    final samples = Float32List(length);
    
    for (int i = 0; i < length; i++) {
      final t = i / length;
      // Simulate vocal formants
      samples[i] = math.sin(t * 2.0 * math.pi * 220) * 0.7 + // Fundamental
                   math.sin(t * 2.0 * math.pi * 660) * 0.3 + // First formant
                   math.sin(t * 2.0 * math.pi * 1320) * 0.1; // Second formant
    }
    
    return samples;
  }
  
  Float32List _generateBellSource() {
    const length = 44100;
    final samples = Float32List(length);
    
    for (int i = 0; i < length; i++) {
      final t = i / length;
      final decay = math.exp(-t * 3.0); // Exponential decay
      
      // Bell-like harmonic content
      samples[i] = (math.sin(t * 2.0 * math.pi * 440) * 1.0 +
                    math.sin(t * 2.0 * math.pi * 880) * 0.6 +
                    math.sin(t * 2.0 * math.pi * 1320) * 0.3 +
                    math.sin(t * 2.0 * math.pi * 1760) * 0.1) * decay;
    }
    
    return samples;
  }
  
  Float32List _generateTextureSource() {
    const length = 44100;
    final samples = Float32List(length);
    final random = math.Random();
    
    // Generate complex texture with multiple frequency components
    for (int i = 0; i < length; i++) {
      final t = i / length;
      double sample = 0.0;
      
      // Add multiple sine components with random phases
      for (int h = 1; h <= 16; h++) {
        final freq = 220.0 * h;
        final phase = random.nextDouble() * 2.0 * math.pi;
        final amplitude = 1.0 / (h * h); // Decreasing amplitude
        
        sample += math.sin(t * 2.0 * math.pi * freq + phase) * amplitude;
      }
      
      samples[i] = sample * 0.1; // Scale down
    }
    
    return samples;
  }
  
  /// Add custom source material
  void addSourceMaterial(String name, Float32List samples) {
    _sourceMaterials[name] = samples;
    notifyListeners();
  }
  
  /// Remove source material
  void removeSourceMaterial(String name) {
    if (name != 'sine') { // Don't remove the default
      _sourceMaterials.remove(name);
      if (_currentSourceName == name) {
        _currentSourceName = 'sine';
      }
      notifyListeners();
    }
  }
}