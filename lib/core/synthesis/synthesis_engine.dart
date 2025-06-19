import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Professional Synthesis Engine Architecture
/// 
/// Provides comprehensive synthesis capabilities including:
/// - Wavetable synthesis with real-time morphing
/// - FM synthesis with multi-operator algorithms
/// - Granular synthesis with particle visualization
/// - Additive synthesis with harmonic control
/// - Unified parameter management and modulation

/// Types of synthesis engines available
enum SynthesisType {
  wavetable,
  fm,
  granular,
  additive,
  subtractive, // Traditional analog-style synthesis
  hybrid       // Combination of multiple types
}

/// Common synthesis parameters that all engines support
enum SynthParameter {
  // Oscillator parameters
  frequency,
  amplitude,
  phase,
  
  // Wavetable specific
  wavetablePosition,
  wavetableMorph,
  
  // FM specific
  fmRatio,
  fmAmount,
  fmFeedback,
  
  // Granular specific
  grainSize,
  grainDensity,
  grainPosition,
  
  // Additive specific
  harmonicContent,
  spectralTilt,
  
  // Common modulation
  lfoRate,
  lfoAmount,
  envelopeAttack,
  envelopeDecay,
  envelopeSustain,
  envelopeRelease,
}

/// Voice state for polyphonic synthesis
class SynthVoice {
  final int noteNumber;
  final double frequency;
  final double velocity;
  final DateTime startTime;
  bool isActive;
  double phase;
  double amplitude;
  Map<SynthParameter, double> parameters;
  
  SynthVoice({
    required this.noteNumber,
    required this.frequency,
    required this.velocity,
    required this.startTime,
    this.isActive = true,
    this.phase = 0.0,
    this.amplitude = 1.0,
    Map<SynthParameter, double>? parameters,
  }) : parameters = parameters ?? <SynthParameter, double>{};
  
  /// Update voice with new parameter values
  void updateParameter(SynthParameter param, double value) {
    parameters[param] = value;
  }
  
  /// Get parameter value with fallback to default
  double getParameter(SynthParameter param, [double defaultValue = 0.0]) {
    return parameters[param] ?? defaultValue;
  }
  
  /// Check if voice should be culled (for performance optimization)
  bool shouldCull(Duration maxVoiceTime) {
    return !isActive || 
           DateTime.now().difference(startTime) > maxVoiceTime ||
           amplitude < 0.001;
  }
}

/// Base class for all synthesis engines
abstract class SynthesisEngine extends ChangeNotifier {
  final SynthesisType type;
  final String name;
  final int maxVoices;
  double sampleRate;
  
  // Voice management
  final List<SynthVoice> _activeVoices = [];
  final Map<SynthParameter, double> _globalParameters = {};
  
  // Performance metrics
  int _voiceCount = 0;
  double _cpuUsage = 0.0;
  
  SynthesisEngine({
    required this.type,
    required this.name,
    this.maxVoices = 32,
    this.sampleRate = 44100.0,
  }) {
    _initializeDefaultParameters();
  }
  
  // Getters
  List<SynthVoice> get activeVoices => List.unmodifiable(_activeVoices);
  Map<SynthParameter, double> get globalParameters => Map.unmodifiable(_globalParameters);
  int get voiceCount => _voiceCount;
  double get cpuUsage => _cpuUsage;
  
  /// Initialize default parameter values
  void _initializeDefaultParameters() {
    _globalParameters[SynthParameter.amplitude] = 0.8;
    _globalParameters[SynthParameter.lfoRate] = 1.0;
    _globalParameters[SynthParameter.lfoAmount] = 0.0;
    _globalParameters[SynthParameter.envelopeAttack] = 0.01;
    _globalParameters[SynthParameter.envelopeDecay] = 0.1;
    _globalParameters[SynthParameter.envelopeSustain] = 0.7;
    _globalParameters[SynthParameter.envelopeRelease] = 0.5;
  }
  
  /// Set global parameter value
  void setParameter(SynthParameter parameter, double value) {
    _globalParameters[parameter] = value;
    notifyListeners();
  }
  
  /// Get global parameter value
  double getParameter(SynthParameter parameter, [double defaultValue = 0.0]) {
    return _globalParameters[parameter] ?? defaultValue;
  }
  
  /// Start a new voice
  void noteOn(int noteNumber, double velocity) {
    // Calculate frequency from MIDI note
    final frequency = 440.0 * math.pow(2.0, (noteNumber - 69) / 12.0);
    
    // Create new voice using factory method
    final voice = createVoice(noteNumber, frequency, velocity);
    
    // Voice stealing if at max voices
    if (_activeVoices.length >= maxVoices) {
      _stealOldestVoice();
    }
    
    _activeVoices.add(voice);
    _voiceCount = _activeVoices.length;
    
    // Engine-specific note on handling
    onNoteOn(voice);
    notifyListeners();
  }
  
  /// Factory method for creating engine-specific voice types
  SynthVoice createVoice(int noteNumber, double frequency, double velocity) {
    return SynthVoice(
      noteNumber: noteNumber,
      frequency: frequency,
      velocity: velocity,
      startTime: DateTime.now(),
    );
  }
  
  /// Stop a voice
  void noteOff(int noteNumber) {
    final voice = _activeVoices.where((v) => v.noteNumber == noteNumber).firstOrNull;
    if (voice != null) {
      voice.isActive = false;
      onNoteOff(voice);
    }
    
    // Clean up inactive voices
    _activeVoices.removeWhere((v) => !v.isActive);
    _voiceCount = _activeVoices.length;
    notifyListeners();
  }
  
  /// Steal the oldest voice for voice limiting
  void _stealOldestVoice() {
    if (_activeVoices.isNotEmpty) {
      _activeVoices.sort((a, b) => a.startTime.compareTo(b.startTime));
      final oldestVoice = _activeVoices.first;
      oldestVoice.isActive = false;
      onNoteOff(oldestVoice);
      _activeVoices.removeAt(0);
    }
  }
  
  /// Process audio buffer (main synthesis method)
  Float32List processAudio(int numSamples) {
    final startTime = DateTime.now();
    
    final buffer = Float32List(numSamples);
    
    // Process each active voice
    for (final voice in _activeVoices) {
      if (voice.isActive) {
        final voiceBuffer = processVoice(voice, numSamples);
        
        // Mix voice into main buffer
        for (int i = 0; i < numSamples; i++) {
          buffer[i] += voiceBuffer[i];
        }
      }
    }
    
    // Apply global effects and limiting
    _applyGlobalProcessing(buffer);
    
    // Update performance metrics
    final processingTime = DateTime.now().difference(startTime);
    final maxProcessingTime = Duration(microseconds: (numSamples / sampleRate * 1000000).round());
    _cpuUsage = processingTime.inMicroseconds / maxProcessingTime.inMicroseconds;
    
    // Clean up finished voices
    _activeVoices.removeWhere((voice) => voice.shouldCull(const Duration(seconds: 10)));
    _voiceCount = _activeVoices.length;
    
    return buffer;
  }
  
  /// Apply global processing (limiting, etc.)
  void _applyGlobalProcessing(Float32List buffer) {
    final amplitude = getParameter(SynthParameter.amplitude);
    
    for (int i = 0; i < buffer.length; i++) {
      // Apply global amplitude
      buffer[i] *= amplitude;
      
      // Soft limiting to prevent clipping
      buffer[i] = _softLimit(buffer[i]);
    }
  }
  
  /// Soft limiting function
  double _softLimit(double sample) {
    const threshold = 0.8;
    if (sample.abs() > threshold) {
      final sign = sample.sign;
      final excess = sample.abs() - threshold;
      return sign * (threshold + excess / (1.0 + excess));
    }
    return sample;
  }
  
  /// Get list of supported parameters for this engine
  List<SynthParameter> getSupportedParameters();
  
  /// Get parameter range information
  Map<String, dynamic> getParameterInfo(SynthParameter parameter);
  
  /// Engine-specific note on handling
  void onNoteOn(SynthVoice voice);
  
  /// Engine-specific note off handling  
  void onNoteOff(SynthVoice voice);
  
  /// Engine-specific voice processing
  Float32List processVoice(SynthVoice voice, int numSamples);
  
  /// Get visualization data for the engine
  Map<String, dynamic> getVisualizationData();
  
  /// Update sample rate
  void setSampleRate(double newSampleRate) {
    sampleRate = newSampleRate;
    onSampleRateChanged(newSampleRate);
  }
  
  /// Called when sample rate changes
  void onSampleRateChanged(double newSampleRate) {
    // Override in subclasses if needed
  }
  
  /// Reset engine state
  void reset() {
    _activeVoices.clear();
    _voiceCount = 0;
    _cpuUsage = 0.0;
    notifyListeners();
  }
  
  @override
  void dispose() {
    reset();
    super.dispose();
  }
}

/// Utility functions for synthesis
class SynthUtils {
  /// Convert MIDI note to frequency
  static double midiToFrequency(int midiNote) {
    return 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
  }
  
  /// Convert frequency to MIDI note
  static int frequencyToMidi(double frequency) {
    return (69 + 12 * math.log(frequency / 440.0) / math.ln2).round();
  }
  
  /// Linear interpolation
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  /// Cubic interpolation for high-quality resampling
  static double cubicInterpolate(double y0, double y1, double y2, double y3, double mu) {
    final mu2 = mu * mu;
    final a0 = y3 - y2 - y0 + y1;
    final a1 = y0 - y1 - a0;
    final a2 = y2 - y0;
    final a3 = y1;
    
    return a0 * mu * mu2 + a1 * mu2 + a2 * mu + a3;
  }
  
  /// Generate sine wave sample
  static double sine(double phase) {
    return math.sin(phase * 2.0 * math.pi);
  }
  
  /// Generate sawtooth wave sample
  static double sawtooth(double phase) {
    return 2.0 * (phase - (phase + 0.5).floor());
  }
  
  /// Generate square wave sample
  static double square(double phase) {
    return (phase - phase.floor()) < 0.5 ? -1.0 : 1.0;
  }
  
  /// Generate triangle wave sample
  static double triangle(double phase) {
    final t = phase - phase.floor();
    return t < 0.5 ? 4.0 * t - 1.0 : 3.0 - 4.0 * t;
  }
  
  /// Apply ADSR envelope
  static double applyADSR(double time, double attack, double decay, double sustain, double release, bool isReleased, double releaseTime) {
    if (!isReleased) {
      if (time < attack) {
        // Attack phase
        return time / attack;
      } else if (time < attack + decay) {
        // Decay phase
        final decayProgress = (time - attack) / decay;
        return 1.0 - decayProgress * (1.0 - sustain);
      } else {
        // Sustain phase
        return sustain;
      }
    } else {
      // Release phase
      final releaseProgress = (time - releaseTime) / release;
      return sustain * math.max(0.0, 1.0 - releaseProgress);
    }
  }
  
  /// Convert decibels to linear amplitude
  static double dbToLinear(double db) {
    return math.pow(10.0, db / 20.0).toDouble();
  }
  
  /// Convert linear amplitude to decibels
  static double linearToDb(double linear) {
    return 20.0 * math.log(linear) / math.ln10;
  }
  
  /// Band-limited impulse for anti-aliasing
  static double bandLimitedImpulse(double phase, double frequency, double sampleRate) {
    final nyquist = sampleRate / 2.0;
    final harmonics = (nyquist / frequency).floor();
    
    if (harmonics <= 1) return 1.0;
    
    final x = math.pi * phase;
    if (x.abs() < 1e-10) return 1.0;
    
    return math.sin(harmonics * x) / (harmonics * math.sin(x));
  }
}

/// Performance monitoring for synthesis engines
class SynthPerformanceMonitor {
  final List<double> _cpuHistory = [];
  final List<int> _voiceHistory = [];
  final int maxHistoryLength;
  
  SynthPerformanceMonitor({this.maxHistoryLength = 100});
  
  void addSample(double cpuUsage, int voiceCount) {
    _cpuHistory.add(cpuUsage);
    _voiceHistory.add(voiceCount);
    
    if (_cpuHistory.length > maxHistoryLength) {
      _cpuHistory.removeAt(0);
      _voiceHistory.removeAt(0);
    }
  }
  
  double get averageCpuUsage {
    if (_cpuHistory.isEmpty) return 0.0;
    return _cpuHistory.reduce((a, b) => a + b) / _cpuHistory.length;
  }
  
  double get maxCpuUsage {
    if (_cpuHistory.isEmpty) return 0.0;
    return _cpuHistory.reduce(math.max);
  }
  
  double get averageVoiceCount {
    if (_voiceHistory.isEmpty) return 0.0;
    return _voiceHistory.reduce((a, b) => a + b) / _voiceHistory.length;
  }
  
  int get maxVoiceCount {
    if (_voiceHistory.isEmpty) return 0;
    return _voiceHistory.reduce(math.max);
  }
  
  void reset() {
    _cpuHistory.clear();
    _voiceHistory.clear();
  }
}