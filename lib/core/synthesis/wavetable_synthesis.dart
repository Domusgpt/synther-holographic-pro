import 'dart:typed_data';
import 'dart:math' as math;
import 'synthesis_engine.dart';

/// Professional Wavetable Synthesis Engine
/// 
/// Features:
/// - High-quality wavetable oscillators with cubic interpolation
/// - Real-time wavetable morphing between multiple tables
/// - Anti-aliasing using band-limited wavetables
/// - Spectral analysis and visualization data
/// - Multiple wavetable categories (analog, digital, vocal, etc.)

/// Wavetable data structure
class Wavetable {
  final String name;
  final String category;
  final Float32List samples;
  final int tableSize;
  final double fundamentalFreq;
  final Map<String, dynamic> metadata;
  
  Wavetable({
    required this.name,
    required this.category,
    required this.samples,
    this.tableSize = 2048,
    this.fundamentalFreq = 440.0,
    this.metadata = const {},
  });
  
  /// Get interpolated sample at position
  double getSample(double position) {
    final pos = position * tableSize;
    final index = pos.floor();
    final fraction = pos - index;
    
    // Cubic interpolation for high quality
    final i0 = index % tableSize;
    final i1 = (index + 1) % tableSize;
    final i2 = (index + 2) % tableSize;
    final i3 = (index + 3) % tableSize;
    
    return SynthUtils.cubicInterpolate(
      samples[i0], samples[i1], samples[i2], samples[i3], fraction
    );
  }
  
  /// Get harmonic content analysis
  List<double> getHarmonicSpectrum() {
    // Simple FFT analysis (would use real FFT in production)
    final spectrum = <double>[];
    const numHarmonics = 64;
    
    for (int h = 1; h <= numHarmonics; h++) {
      double magnitude = 0.0;
      for (int i = 0; i < tableSize; i++) {
        final phase = (i / tableSize) * h * 2.0 * math.pi;
        magnitude += samples[i] * math.cos(phase);
      }
      spectrum.add(magnitude.abs() / tableSize);
    }
    
    return spectrum;
  }
}

/// Wavetable oscillator voice
class WavetableVoice extends SynthVoice {
  int currentWavetableIndex;
  double wavetablePosition;
  double morphAmount;
  
  WavetableVoice({
    required super.noteNumber,
    required super.frequency,
    required super.velocity,
    required super.startTime,
    this.currentWavetableIndex = 0,
    this.wavetablePosition = 0.0,
    this.morphAmount = 0.0,
  });
}

/// Professional Wavetable Synthesis Engine
class WavetableSynthesis extends SynthesisEngine {
  final List<Wavetable> _wavetables = [];
  int _selectedWavetableIndex = 0;
  double _morphPosition = 0.0;
  bool _enableMorphing = true;
  
  // Anti-aliasing
  final Map<double, List<Wavetable>> _bandLimitedTables = {};
  
  WavetableSynthesis({
    super.maxVoices = 32,
    super.sampleRate = 44100.0,
  }) : super(
    type: SynthesisType.wavetable,
    name: 'Professional Wavetable',
  ) {
    _initializeWavetables();
    _generateBandLimitedTables();
    _initializeWavetableParameters();
  }
  
  // Getters
  List<Wavetable> get wavetables => List.unmodifiable(_wavetables);
  int get selectedWavetableIndex => _selectedWavetableIndex;
  double get morphPosition => _morphPosition;
  bool get enableMorphing => _enableMorphing;
  
  /// Initialize default wavetables
  void _initializeWavetables() {
    _wavetables.addAll([
      _createAnalogWavetable('Saw', _generateSawtooth),
      _createAnalogWavetable('Square', _generateSquare),
      _createAnalogWavetable('Triangle', _generateTriangle),
      _createDigitalWavetable('Digital 1', _generateDigital1),
      _createDigitalWavetable('Digital 2', _generateDigital2),
      _createVocalWavetable('Vocal Ah', _generateVocalAh),
      _createVocalWavetable('Vocal Eh', _generateVocalEh),
      _createCustomWavetable('Harmonic', _generateHarmonic),
    ]);
  }
  
  /// Initialize wavetable-specific parameters
  void _initializeWavetableParameters() {
    setParameter(SynthParameter.wavetablePosition, 0.0);
    setParameter(SynthParameter.wavetableMorph, 0.0);
  }
  
  /// Generate band-limited versions for anti-aliasing
  void _generateBandLimitedTables() {
    const octaves = 10; // Generate tables for different frequency ranges
    
    for (final wavetable in _wavetables) {
      final bandLimitedVersions = <Wavetable>[];
      
      for (int octave = 0; octave < octaves; octave++) {
        final maxHarmonic = math.pow(2, octaves - octave).toInt();
        final bandLimited = _createBandLimitedVersion(wavetable, maxHarmonic);
        bandLimitedVersions.add(bandLimited);
      }
      
      final baseFreq = wavetable.fundamentalFreq;
      _bandLimitedTables[baseFreq] = bandLimitedVersions;
    }
  }
  
  /// Create band-limited version of wavetable
  Wavetable _createBandLimitedVersion(Wavetable original, int maxHarmonic) {
    final samples = Float32List(original.tableSize);
    
    // Simple harmonic filtering (would use proper FFT filtering in production)
    for (int i = 0; i < original.tableSize; i++) {
      double sample = 0.0;
      for (int h = 1; h <= maxHarmonic; h++) {
        final phase = (i / original.tableSize) * h * 2.0 * math.pi;
        sample += math.sin(phase) / h; // Simple harmonic series
      }
      samples[i] = sample * 0.5; // Scale to prevent clipping
    }
    
    return Wavetable(
      name: '${original.name}_BL$maxHarmonic',
      category: original.category,
      samples: samples,
      tableSize: original.tableSize,
      fundamentalFreq: original.fundamentalFreq,
      metadata: {'bandLimited': true, 'maxHarmonic': maxHarmonic},
    );
  }
  
  /// Set current wavetable
  void setWavetable(int index) {
    if (index >= 0 && index < _wavetables.length) {
      _selectedWavetableIndex = index;
      notifyListeners();
    }
  }
  
  /// Set morph position between wavetables
  void setMorphPosition(double position) {
    _morphPosition = position.clamp(0.0, 1.0);
    setParameter(SynthParameter.wavetableMorph, _morphPosition);
    notifyListeners();
  }
  
  /// Enable/disable wavetable morphing
  void setMorphingEnabled(bool enabled) {
    _enableMorphing = enabled;
    notifyListeners();
  }
  
  @override
  List<SynthParameter> getSupportedParameters() {
    return [
      SynthParameter.frequency,
      SynthParameter.amplitude,
      SynthParameter.phase,
      SynthParameter.wavetablePosition,
      SynthParameter.wavetableMorph,
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
      case SynthParameter.wavetablePosition:
        return {
          'name': 'Table Position',
          'min': 0.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '%',
          'description': 'Position within the current wavetable'
        };
      case SynthParameter.wavetableMorph:
        return {
          'name': 'Morph Amount',
          'min': 0.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '%',
          'description': 'Morphing between wavetables'
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
    // Convert to wavetable voice
    if (voice is! WavetableVoice) return;
    
    voice.currentWavetableIndex = _selectedWavetableIndex;
    voice.wavetablePosition = getParameter(SynthParameter.wavetablePosition);
    voice.morphAmount = getParameter(SynthParameter.wavetableMorph);
  }
  
  @override
  void onNoteOff(SynthVoice voice) {
    // Wavetable-specific note off handling
    voice.isActive = false;
  }
  
  @override
  Float32List processVoice(SynthVoice voice, int numSamples) {
    final buffer = Float32List(numSamples);
    
    if (voice is! WavetableVoice) return buffer;
    
    // Get current wavetable (with band-limiting based on frequency)
    final wavetable = _getBandLimitedWavetable(voice.frequency);
    
    // Calculate time-based parameters
    var currentTime = DateTime.now().difference(voice.startTime).inMicroseconds / 1000000.0;
    
    // Envelope parameters
    final attack = getParameter(SynthParameter.envelopeAttack);
    final decay = getParameter(SynthParameter.envelopeDecay);
    final sustain = getParameter(SynthParameter.envelopeSustain);
    final release = getParameter(SynthParameter.envelopeRelease);
    
    // LFO parameters
    final lfoRate = getParameter(SynthParameter.lfoRate);
    final lfoAmount = getParameter(SynthParameter.lfoAmount);
    
    for (int i = 0; i < numSamples; i++) {
      // Update phase
      voice.phase += voice.frequency / sampleRate;
      if (voice.phase >= 1.0) voice.phase -= 1.0;
      
      // Apply LFO to wavetable position
      final lfoValue = math.sin(currentTime * lfoRate * 2.0 * math.pi);
      final modulatedPosition = voice.wavetablePosition + (lfoValue * lfoAmount);
      
      // Get wavetable sample
      double sample = wavetable.getSample(voice.phase + modulatedPosition);
      
      // Apply morphing if enabled
      if (_enableMorphing && voice.morphAmount > 0.0) {
        final nextWavetableIndex = (voice.currentWavetableIndex + 1) % _wavetables.length;
        final nextWavetable = _getBandLimitedWavetableByIndex(nextWavetableIndex, voice.frequency);
        final nextSample = nextWavetable.getSample(voice.phase + modulatedPosition);
        
        sample = SynthUtils.lerp(sample, nextSample, voice.morphAmount);
      }
      
      // Apply envelope
      final envelope = SynthUtils.applyADSR(
        currentTime, attack, decay, sustain, release,
        !voice.isActive, currentTime
      );
      
      // Apply velocity and amplitude
      sample *= voice.velocity * envelope * voice.amplitude;
      
      buffer[i] = sample;
      currentTime += 1.0 / sampleRate;
    }
    
    return buffer;
  }
  
  /// Get appropriate band-limited wavetable for frequency
  Wavetable _getBandLimitedWavetable(double frequency) {
    final wavetable = _wavetables[_selectedWavetableIndex];
    final bandLimitedVersions = _bandLimitedTables[wavetable.fundamentalFreq];
    
    if (bandLimitedVersions == null || bandLimitedVersions.isEmpty) {
      return wavetable;
    }
    
    // Select appropriate band-limited version based on frequency
    final nyquist = sampleRate / 2.0;
    final maxHarmonic = (nyquist / frequency).floor();
    
    for (final version in bandLimitedVersions) {
      final versionMaxHarmonic = version.metadata['maxHarmonic'] as int? ?? 64;
      if (maxHarmonic <= versionMaxHarmonic) {
        return version;
      }
    }
    
    return bandLimitedVersions.last;
  }
  
  /// Get band-limited wavetable by index
  Wavetable _getBandLimitedWavetableByIndex(int index, double frequency) {
    final oldIndex = _selectedWavetableIndex;
    _selectedWavetableIndex = index;
    final result = _getBandLimitedWavetable(frequency);
    _selectedWavetableIndex = oldIndex;
    return result;
  }
  
  @override
  Map<String, dynamic> getVisualizationData() {
    final currentWavetable = _wavetables[_selectedWavetableIndex];
    
    return {
      'type': 'wavetable',
      'wavetableName': currentWavetable.name,
      'wavetableCategory': currentWavetable.category,
      'samples': currentWavetable.samples,
      'harmonicSpectrum': currentWavetable.getHarmonicSpectrum(),
      'morphPosition': _morphPosition,
      'enableMorphing': _enableMorphing,
      'voiceCount': voiceCount,
      'cpuUsage': cpuUsage,
    };
  }
  
  @override
  SynthVoice createVoice(int noteNumber, double frequency, double velocity) {
    return WavetableVoice(
      noteNumber: noteNumber,
      frequency: frequency,
      velocity: velocity,
      startTime: DateTime.now(),
      currentWavetableIndex: _selectedWavetableIndex,
      wavetablePosition: getParameter(SynthParameter.wavetablePosition),
      morphAmount: getParameter(SynthParameter.wavetableMorph),
    );
  }

  
  // Wavetable generation functions
  
  Wavetable _createAnalogWavetable(String name, Float32List Function() generator) {
    return Wavetable(
      name: name,
      category: 'Analog',
      samples: generator(),
      metadata: {'type': 'analog', 'generated': true},
    );
  }
  
  Wavetable _createDigitalWavetable(String name, Float32List Function() generator) {
    return Wavetable(
      name: name,
      category: 'Digital',
      samples: generator(),
      metadata: {'type': 'digital', 'generated': true},
    );
  }
  
  Wavetable _createVocalWavetable(String name, Float32List Function() generator) {
    return Wavetable(
      name: name,
      category: 'Vocal',
      samples: generator(),
      metadata: {'type': 'vocal', 'generated': true},
    );
  }
  
  Wavetable _createCustomWavetable(String name, Float32List Function() generator) {
    return Wavetable(
      name: name,
      category: 'Custom',
      samples: generator(),
      metadata: {'type': 'custom', 'generated': true},
    );
  }
  
  // Wavetable generators
  
  Float32List _generateSawtooth() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      samples[i] = SynthUtils.sawtooth(phase);
    }
    
    return samples;
  }
  
  Float32List _generateSquare() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      samples[i] = SynthUtils.square(phase);
    }
    
    return samples;
  }
  
  Float32List _generateTriangle() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      samples[i] = SynthUtils.triangle(phase);
    }
    
    return samples;
  }
  
  Float32List _generateDigital1() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      // Digital-style waveform with harmonics
      samples[i] = math.sin(phase * 2.0 * math.pi) + 
                   0.3 * math.sin(phase * 4.0 * math.pi) +
                   0.1 * math.sin(phase * 8.0 * math.pi);
    }
    
    return samples;
  }
  
  Float32List _generateDigital2() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      // Complex digital waveform
      samples[i] = math.sin(phase * 2.0 * math.pi) * 
                   (1.0 + 0.5 * math.sin(phase * 6.0 * math.pi));
    }
    
    return samples;
  }
  
  Float32List _generateVocalAh() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    // Simulate vocal formants for "Ah" sound
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      samples[i] = math.sin(phase * 2.0 * math.pi) + // Fundamental
                   0.6 * math.sin(phase * 3.0 * math.pi) + // Second harmonic
                   0.4 * math.sin(phase * 5.0 * math.pi) + // Third harmonic
                   0.2 * math.sin(phase * 7.0 * math.pi);  // Fourth harmonic
    }
    
    return samples;
  }
  
  Float32List _generateVocalEh() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    // Simulate vocal formants for "Eh" sound
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      samples[i] = math.sin(phase * 2.0 * math.pi) + // Fundamental
                   0.4 * math.sin(phase * 4.0 * math.pi) + // Different harmonic structure
                   0.3 * math.sin(phase * 6.0 * math.pi) +
                   0.1 * math.sin(phase * 10.0 * math.pi);
    }
    
    return samples;
  }
  
  Float32List _generateHarmonic() {
    const tableSize = 2048;
    final samples = Float32List(tableSize);
    
    // Rich harmonic content
    for (int i = 0; i < tableSize; i++) {
      final phase = i / tableSize;
      double sample = 0.0;
      
      // Add first 8 harmonics with decreasing amplitude
      for (int h = 1; h <= 8; h++) {
        sample += math.sin(phase * h * 2.0 * math.pi) / h;
      }
      
      samples[i] = sample * 0.3; // Scale to prevent clipping
    }
    
    return samples;
  }
}