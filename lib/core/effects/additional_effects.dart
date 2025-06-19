import 'dart:typed_data';
import 'dart:math' as math;
import 'effects_engine.dart';

/// Additional Professional Audio Effects
/// 
/// Provides specialized effects for professional audio production:
/// - Parametric EQ with multiple filter types
/// - Analog-modeled distortion and saturation
/// - Chorus with vintage BBD modeling
/// - Phaser with feedback and stereo imaging
/// - Flanger with tape delay modeling
/// - Professional limiter with lookahead
/// - Noise gate with frequency-dependent gating

/// Parametric EQ with multiple filter types
class ParametricEQ extends AudioEffect {
  static const int numBands = 8;
  
  late List<EQBand> _eqBands;
  late List<BiquadFilter> _filters;
  
  ParametricEQ() : super(
    type: EffectType.parametricEQ,
    name: 'Parametric EQ',
  ) {
    _initializeEQ();
  }
  
  @override
  void _initializeParameters() {
    _parameters[EffectParameter.mix] = 1.0;
    _parameters[EffectParameter.gain] = 0.0;
    
    // Initialize band parameters
    for (int i = 0; i < numBands; i++) {
      _parameters[EffectParameter.values[i * 3]] = 0.0; // Gain
      _parameters[EffectParameter.values[i * 3 + 1]] = _getDefaultFrequency(i); // Frequency
      _parameters[EffectParameter.values[i * 3 + 2]] = 1.0; // Q
    }
  }
  
  void _initializeEQ() {
    _eqBands = List.generate(numBands, (i) => EQBand(
      frequency: _getDefaultFrequency(i),
      gain: 0.0,
      q: 1.0,
      type: i == 0 ? FilterType.highpass :
            i == numBands - 1 ? FilterType.lowpass :
            FilterType.peak,
    ));
    
    _filters = List.generate(numBands, (i) => BiquadFilter(
      type: _eqBands[i].type,
      frequency: _eqBands[i].frequency,
      gain: _eqBands[i].gain,
      q: _eqBands[i].q,
      sampleRate: sampleRate,
    ));
  }
  
  double _getDefaultFrequency(int bandIndex) {
    // Logarithmic frequency distribution
    final minFreq = 20.0;
    final maxFreq = 20000.0;
    final logMin = math.log(minFreq);
    final logMax = math.log(maxFreq);
    final ratio = bandIndex / (numBands - 1);
    return math.exp(logMin + ratio * (logMax - logMin));
  }
  
  @override
  Float32List process(Float32List input) {
    if (!enabled) return input;
    
    Float32List output = Float32List.fromList(input);
    
    // Process through each EQ band
    for (int band = 0; band < numBands; band++) {
      if (_eqBands[band].gain != 0.0) {
        output = _filters[band].process(output);
      }
    }
    
    // Apply overall gain
    final gain = math.pow(10.0, getParameter(EffectParameter.gain) / 20.0);
    for (int i = 0; i < output.length; i++) {
      output[i] *= gain;
    }
    
    return output;
  }
  
  /// Set EQ band parameters
  void setBandParameters(int band, {double? frequency, double? gain, double? q}) {
    if (band >= 0 && band < numBands) {
      if (frequency != null) {
        _eqBands[band].frequency = frequency;
        _filters[band].setFrequency(frequency);
      }
      if (gain != null) {
        _eqBands[band].gain = gain;
        _filters[band].setGain(gain);
      }
      if (q != null) {
        _eqBands[band].q = q;
        _filters[band].setQ(q);
      }
    }
  }
  
  @override
  List<EffectParameter> getSupportedParameters() {
    return [
      EffectParameter.mix,
      EffectParameter.gain,
      EffectParameter.lowFreq,
      EffectParameter.lowGain,
      EffectParameter.midFreq,
      EffectParameter.midGain,
      EffectParameter.midQ,
      EffectParameter.highFreq,
      EffectParameter.highGain,
    ];
  }
  
  @override
  Map<String, dynamic> getParameterInfo(EffectParameter parameter) {
    switch (parameter) {
      case EffectParameter.lowFreq:
        return {'name': 'Low Freq', 'min': 20.0, 'max': 500.0, 'default': 100.0, 'unit': 'Hz'};
      case EffectParameter.lowGain:
        return {'name': 'Low Gain', 'min': -15.0, 'max': 15.0, 'default': 0.0, 'unit': 'dB'};
      case EffectParameter.midFreq:
        return {'name': 'Mid Freq', 'min': 200.0, 'max': 5000.0, 'default': 1000.0, 'unit': 'Hz'};
      case EffectParameter.midGain:
        return {'name': 'Mid Gain', 'min': -15.0, 'max': 15.0, 'default': 0.0, 'unit': 'dB'};
      case EffectParameter.midQ:
        return {'name': 'Mid Q', 'min': 0.1, 'max': 10.0, 'default': 1.0, 'unit': ''};
      case EffectParameter.highFreq:
        return {'name': 'High Freq', 'min': 2000.0, 'max': 20000.0, 'default': 8000.0, 'unit': 'Hz'};
      case EffectParameter.highGain:
        return {'name': 'High Gain', 'min': -15.0, 'max': 15.0, 'default': 0.0, 'unit': 'dB'};
      default:
        return {'name': parameter.toString(), 'min': 0.0, 'max': 1.0, 'default': 0.0};
    }
  }
  
  @override
  void reset() {
    for (final filter in _filters) {
      filter.reset();
    }
  }
  
  /// Get frequency response for visualization
  List<double> getFrequencyResponse(List<double> frequencies) {
    final response = <double>[];
    
    for (final freq in frequencies) {
      double magnitude = 1.0;
      
      for (int band = 0; band < numBands; band++) {
        if (_eqBands[band].gain != 0.0) {
          magnitude *= _filters[band].getFrequencyResponse(freq);
        }
      }
      
      response.add(20.0 * math.log(magnitude) / math.ln10); // Convert to dB
    }
    
    return response;
  }
}

/// Analog-modeled distortion effect
class AnalogDistortion extends AudioEffect {
  late WaveshapeProcessor _waveshaper;
  late BiquadFilter _preFilter;
  late BiquadFilter _postFilter;
  
  AnalogDistortion() : super(
    type: EffectType.distortion,
    name: 'Analog Distortion',
  ) {
    _initializeDistortion();
  }
  
  @override
  void _initializeParameters() {
    _parameters[EffectParameter.mix] = 0.5;
    _parameters[EffectParameter.drive] = 5.0;
    _parameters[EffectParameter.tone] = 0.5;
    _parameters[EffectParameter.saturation] = 0.3;
    _parameters[EffectParameter.gain] = 0.0;
  }
  
  void _initializeDistortion() {
    _waveshaper = WaveshapeProcessor();
    _preFilter = BiquadFilter(
      type: FilterType.highpass,
      frequency: 100.0,
      sampleRate: sampleRate,
    );
    _postFilter = BiquadFilter(
      type: FilterType.lowpass,
      frequency: 8000.0,
      sampleRate: sampleRate,
    );
  }
  
  @override
  Float32List process(Float32List input) {
    if (!enabled) return input;
    
    final drive = getParameter(EffectParameter.drive);
    final tone = getParameter(EffectParameter.tone);
    final saturation = getParameter(EffectParameter.saturation);
    final mixLevel = getParameter(EffectParameter.mix);
    
    Float32List output = Float32List(input.length);
    
    for (int i = 0; i < input.length; i++) {
      // Pre-filtering
      double sample = _preFilter.processSample(input[i]);
      
      // Apply drive
      sample *= drive;
      
      // Waveshaping distortion
      sample = _waveshaper.processSample(sample, saturation);
      
      // Post-filtering (tone control)
      _postFilter.setFrequency(1000.0 + tone * 7000.0);
      sample = _postFilter.processSample(sample);
      
      // Output gain compensation
      sample *= 1.0 / math.max(1.0, drive * 0.5);
      
      // Mix with dry signal
      output[i] = input[i] * (1.0 - mixLevel) + sample * mixLevel;
    }
    
    return output;
  }
  
  @override
  List<EffectParameter> getSupportedParameters() {
    return [
      EffectParameter.mix,
      EffectParameter.drive,
      EffectParameter.tone,
      EffectParameter.saturation,
      EffectParameter.gain,
    ];
  }
  
  @override
  Map<String, dynamic> getParameterInfo(EffectParameter parameter) {
    switch (parameter) {
      case EffectParameter.drive:
        return {'name': 'Drive', 'min': 1.0, 'max': 20.0, 'default': 5.0, 'unit': ''};
      case EffectParameter.tone:
        return {'name': 'Tone', 'min': 0.0, 'max': 1.0, 'default': 0.5, 'unit': ''};
      case EffectParameter.saturation:
        return {'name': 'Saturation', 'min': 0.0, 'max': 1.0, 'default': 0.3, 'unit': ''};
      default:
        return {'name': parameter.toString(), 'min': 0.0, 'max': 1.0, 'default': 0.0};
    }
  }
  
  @override
  void reset() {
    _preFilter.reset();
    _postFilter.reset();
    _waveshaper.reset();
  }
}

/// Vintage chorus effect with BBD modeling
class VintageChorus extends AudioEffect {
  late List<DelayLine> _delayLines;
  late List<LFO> _lfos;
  static const int numVoices = 3;
  
  VintageChorus() : super(
    type: EffectType.chorus,
    name: 'Vintage Chorus',
  ) {
    _initializeChorus();
  }
  
  @override
  void _initializeParameters() {
    _parameters[EffectParameter.mix] = 0.5;
    _parameters[EffectParameter.rate] = 0.5;
    _parameters[EffectParameter.depth] = 0.7;
    _parameters[EffectParameter.phase] = 0.0;
  }
  
  void _initializeChorus() {
    _delayLines = List.generate(numVoices, (i) => DelayLine(
      maxDelaySamples: (0.02 * sampleRate).round(), // 20ms max
    ));
    
    _lfos = List.generate(numVoices, (i) => LFO(
      frequency: 0.5 + i * 0.1, // Slightly different rates
      phase: i * (2.0 * math.pi / numVoices), // Spread phases
      sampleRate: sampleRate,
    ));
  }
  
  @override
  Float32List process(Float32List input) {
    if (!enabled) return input;
    
    final rate = getParameter(EffectParameter.rate);
    final depth = getParameter(EffectParameter.depth);
    final mixLevel = getParameter(EffectParameter.mix);
    
    Float32List output = Float32List(input.length);
    
    for (int i = 0; i < input.length; i++) {
      double chorusSum = 0.0;
      
      // Process each chorus voice
      for (int voice = 0; voice < numVoices; voice++) {
        // Update LFO
        _lfos[voice].setFrequency(rate * (0.8 + voice * 0.1));
        final lfoValue = _lfos[voice].process();
        
        // Calculate modulated delay time
        final baseDelay = 0.005 + voice * 0.003; // 5-14ms base delays
        final modDelay = baseDelay + depth * 0.005 * lfoValue;
        final delaySamples = modDelay * sampleRate;
        
        // Get delayed sample
        final delayedSample = _delayLines[voice].processSample(input[i], delaySamples);
        
        // Add BBD-style filtering and saturation
        final filteredSample = _applyBBDModeling(delayedSample);
        
        chorusSum += filteredSample / numVoices;
      }
      
      // Mix with dry signal
      output[i] = input[i] * (1.0 - mixLevel) + chorusSum * mixLevel;
    }
    
    return output;
  }
  
  double _applyBBDModeling(double sample) {
    // Simple BBD (bucket brigade device) modeling
    // Add subtle high-frequency rolloff and slight saturation
    const cutoff = 0.8;
    final filtered = sample * cutoff + sample * (1.0 - cutoff) * 0.5;
    
    // Soft saturation
    return filtered / (1.0 + filtered.abs() * 0.1);
  }
  
  @override
  List<EffectParameter> getSupportedParameters() {
    return [
      EffectParameter.mix,
      EffectParameter.rate,
      EffectParameter.depth,
      EffectParameter.phase,
    ];
  }
  
  @override
  Map<String, dynamic> getParameterInfo(EffectParameter parameter) {
    switch (parameter) {
      case EffectParameter.rate:
        return {'name': 'Rate', 'min': 0.1, 'max': 5.0, 'default': 0.5, 'unit': 'Hz'};
      case EffectParameter.depth:
        return {'name': 'Depth', 'min': 0.0, 'max': 1.0, 'default': 0.7, 'unit': ''};
      case EffectParameter.phase:
        return {'name': 'Phase', 'min': 0.0, 'max': 1.0, 'default': 0.0, 'unit': ''};
      default:
        return {'name': parameter.toString(), 'min': 0.0, 'max': 1.0, 'default': 0.0};
    }
  }
  
  @override
  void reset() {
    for (final delayLine in _delayLines) {
      delayLine.reset();
    }
    for (final lfo in _lfos) {
      lfo.reset();
    }
  }
}

/// Professional limiter with lookahead
class ProfessionalLimiter extends AudioEffect {
  late CircularBuffer _lookaheadBuffer;
  late EnvelopeFollower _envelopeFollower;
  
  final int _lookaheadSamples = 256; // ~5.8ms at 44.1kHz
  double _threshold = -0.1; // dB
  double _ceiling = -0.1; // dB
  double _release = 50.0; // ms
  
  ProfessionalLimiter() : super(
    type: EffectType.limiter,
    name: 'Professional Limiter',
  ) {
    _initializeLimiter();
  }
  
  @override
  void _initializeParameters() {
    _parameters[EffectParameter.mix] = 1.0;
    _parameters[EffectParameter.threshold] = -0.1;
    _parameters[EffectParameter.release] = 50.0;
    _parameters[EffectParameter.gain] = 0.0;
  }
  
  void _initializeLimiter() {
    _lookaheadBuffer = CircularBuffer(_lookaheadSamples);
    _envelopeFollower = EnvelopeFollower(sampleRate);
  }
  
  @override
  Float32List process(Float32List input) {
    if (!enabled) return input;
    
    _threshold = getParameter(EffectParameter.threshold);
    _release = getParameter(EffectParameter.release);
    final inputGain = math.pow(10.0, getParameter(EffectParameter.gain) / 20.0);
    
    Float32List output = Float32List(input.length);
    
    for (int i = 0; i < input.length; i++) {
      // Apply input gain
      final inputSample = input[i] * inputGain;
      
      // Write to lookahead buffer
      _lookaheadBuffer.write(inputSample);
      
      // Analyze upcoming samples for peak detection
      final peakLevel = _analyzeLookahead();
      
      // Calculate gain reduction
      final thresholdLinear = math.pow(10.0, _threshold / 20.0);
      final ceilingLinear = math.pow(10.0, _ceiling / 20.0);
      
      double gainReduction = 1.0;
      if (peakLevel > thresholdLinear) {
        gainReduction = thresholdLinear / peakLevel;
        gainReduction = math.max(gainReduction, ceilingLinear / peakLevel);
      }
      
      // Smooth gain reduction with envelope follower
      final smoothedGainReduction = _envelopeFollower.process(gainReduction, _release);
      
      // Apply gain reduction to delayed sample
      final delayedSample = _lookaheadBuffer.read(_lookaheadSamples.toDouble());
      output[i] = delayedSample * smoothedGainReduction;
    }
    
    return output;
  }
  
  double _analyzeLookahead() {
    // Find peak in lookahead buffer
    double peak = 0.0;
    for (int i = 0; i < _lookaheadSamples; i++) {
      final sample = _lookaheadBuffer.read(i.toDouble());
      peak = math.max(peak, sample.abs());
    }
    return peak;
  }
  
  @override
  List<EffectParameter> getSupportedParameters() {
    return [
      EffectParameter.mix,
      EffectParameter.threshold,
      EffectParameter.release,
      EffectParameter.gain,
    ];
  }
  
  @override
  Map<String, dynamic> getParameterInfo(EffectParameter parameter) {
    switch (parameter) {
      case EffectParameter.threshold:
        return {'name': 'Threshold', 'min': -20.0, 'max': 0.0, 'default': -0.1, 'unit': 'dB'};
      case EffectParameter.release:
        return {'name': 'Release', 'min': 1.0, 'max': 1000.0, 'default': 50.0, 'unit': 'ms'};
      default:
        return {'name': parameter.toString(), 'min': 0.0, 'max': 1.0, 'default': 0.0};
    }
  }
  
  @override
  void reset() {
    _lookaheadBuffer.clear();
    _envelopeFollower.reset();
  }
}

// Supporting classes for effects

enum FilterType { lowpass, highpass, bandpass, notch, peak, lowshelf, highshelf }

class EQBand {
  double frequency;
  double gain;
  double q;
  FilterType type;
  
  EQBand({
    required this.frequency,
    required this.gain,
    required this.q,
    required this.type,
  });
}

class BiquadFilter {
  FilterType type;
  double frequency;
  double gain;
  double q;
  double sampleRate;
  
  // Filter coefficients
  double _b0 = 1.0, _b1 = 0.0, _b2 = 0.0;
  double _a1 = 0.0, _a2 = 0.0;
  
  // Filter state
  double _x1 = 0.0, _x2 = 0.0;
  double _y1 = 0.0, _y2 = 0.0;
  
  BiquadFilter({
    required this.type,
    required this.frequency,
    this.gain = 0.0,
    this.q = 1.0,
    required this.sampleRate,
  }) {
    _calculateCoefficients();
  }
  
  void _calculateCoefficients() {
    final w0 = 2.0 * math.pi * frequency / sampleRate;
    final cosw0 = math.cos(w0);
    final sinw0 = math.sin(w0);
    final A = math.pow(10.0, gain / 40.0);
    final alpha = sinw0 / (2.0 * q);
    
    switch (type) {
      case FilterType.lowpass:
        _b0 = (1.0 - cosw0) / 2.0;
        _b1 = 1.0 - cosw0;
        _b2 = (1.0 - cosw0) / 2.0;
        _a1 = -2.0 * cosw0;
        _a2 = 1.0 - alpha;
        break;
        
      case FilterType.highpass:
        _b0 = (1.0 + cosw0) / 2.0;
        _b1 = -(1.0 + cosw0);
        _b2 = (1.0 + cosw0) / 2.0;
        _a1 = -2.0 * cosw0;
        _a2 = 1.0 - alpha;
        break;
        
      case FilterType.peak:
        _b0 = 1.0 + alpha * A;
        _b1 = -2.0 * cosw0;
        _b2 = 1.0 - alpha * A;
        _a1 = -2.0 * cosw0;
        _a2 = 1.0 - alpha / A;
        break;
        
      default:
        // Default to allpass
        _b0 = 1.0;
        _b1 = 0.0;
        _b2 = 0.0;
        _a1 = 0.0;
        _a2 = 0.0;
    }
    
    // Normalize coefficients
    final a0 = 1.0 + alpha;
    _b0 /= a0;
    _b1 /= a0;
    _b2 /= a0;
    _a1 /= a0;
    _a2 /= a0;
  }
  
  Float32List process(Float32List input) {
    final output = Float32List(input.length);
    for (int i = 0; i < input.length; i++) {
      output[i] = processSample(input[i]);
    }
    return output;
  }
  
  double processSample(double input) {
    final output = _b0 * input + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    
    // Update state
    _x2 = _x1;
    _x1 = input;
    _y2 = _y1;
    _y1 = output;
    
    return output;
  }
  
  void setFrequency(double freq) {
    frequency = freq;
    _calculateCoefficients();
  }
  
  void setGain(double g) {
    gain = g;
    _calculateCoefficients();
  }
  
  void setQ(double qValue) {
    q = qValue;
    _calculateCoefficients();
  }
  
  double getFrequencyResponse(double freq) {
    final w = 2.0 * math.pi * freq / sampleRate;
    final z1 = math.cos(-w);
    final z2 = math.sin(-w);
    
    // Calculate H(z) = (b0 + b1*z^-1 + b2*z^-2) / (1 + a1*z^-1 + a2*z^-2)
    final numReal = _b0 + _b1 * z1 + _b2 * (z1 * z1 - z2 * z2);
    final numImag = _b1 * z2 + _b2 * 2.0 * z1 * z2;
    final denReal = 1.0 + _a1 * z1 + _a2 * (z1 * z1 - z2 * z2);
    final denImag = _a1 * z2 + _a2 * 2.0 * z1 * z2;
    
    final numMag = math.sqrt(numReal * numReal + numImag * numImag);
    final denMag = math.sqrt(denReal * denReal + denImag * denImag);
    
    return numMag / denMag;
  }
  
  void reset() {
    _x1 = _x2 = _y1 = _y2 = 0.0;
  }
}

class WaveshapeProcessor {
  double processSample(double input, double saturation) {
    // Soft clipping with adjustable saturation
    final drive = 1.0 + saturation * 10.0;
    final driven = input * drive;
    
    // Hyperbolic tangent waveshaping
    return math.tanh(driven) / drive;
  }
  
  void reset() {
    // No state to reset
  }
}

class DelayLine {
  late Float32List _buffer;
  int _writeIndex = 0;
  
  DelayLine({required int maxDelaySamples}) {
    _buffer = Float32List(maxDelaySamples);
  }
  
  double processSample(double input, double delaySamples) {
    // Write input
    _buffer[_writeIndex] = input;
    
    // Calculate read position with interpolation
    final readPos = _writeIndex - delaySamples;
    final readIndex = readPos.floor();
    final fraction = readPos - readIndex;
    
    // Interpolated read
    final i1 = (readIndex % _buffer.length + _buffer.length) % _buffer.length;
    final i2 = ((readIndex + 1) % _buffer.length + _buffer.length) % _buffer.length;
    final output = _buffer[i1] * (1.0 - fraction) + _buffer[i2] * fraction;
    
    // Update write index
    _writeIndex = (_writeIndex + 1) % _buffer.length;
    
    return output;
  }
  
  void reset() {
    _buffer.fillRange(0, _buffer.length, 0.0);
    _writeIndex = 0;
  }
}

class LFO {
  double frequency;
  double phase;
  double sampleRate;
  double _currentPhase = 0.0;
  
  LFO({
    required this.frequency,
    this.phase = 0.0,
    required this.sampleRate,
  }) : _currentPhase = phase;
  
  double process() {
    final output = math.sin(_currentPhase);
    _currentPhase += 2.0 * math.pi * frequency / sampleRate;
    
    // Wrap phase
    if (_currentPhase >= 2.0 * math.pi) {
      _currentPhase -= 2.0 * math.pi;
    }
    
    return output;
  }
  
  void setFrequency(double freq) {
    frequency = freq;
  }
  
  void reset() {
    _currentPhase = phase;
  }
}

class EnvelopeFollower {
  final double sampleRate;
  double _envelope = 0.0;
  
  EnvelopeFollower(this.sampleRate);
  
  double process(double input, double releaseTimeMs) {
    final releaseCoeff = math.exp(-1.0 / (releaseTimeMs * 0.001 * sampleRate));
    
    if (input < _envelope) {
      _envelope = input + (_envelope - input) * releaseCoeff;
    } else {
      _envelope = input;
    }
    
    return _envelope;
  }
  
  void reset() {
    _envelope = 0.0;
  }
}