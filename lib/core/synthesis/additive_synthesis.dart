import 'dart:typed_data';
import 'dart:math' as math;
import 'synthesis_engine.dart';

/// Professional Additive Synthesis Engine
/// 
/// Features:
/// - 128 independent harmonic oscillators with individual control
/// - Real-time spectral manipulation and morphing
/// - Harmonic envelope generators with independent ADSR
/// - Spectral filtering and resonance modeling
/// - Professional harmonic analysis and visualization
/// - Formant synthesis capabilities for vocal modeling

/// Individual harmonic oscillator
class HarmonicOscillator {
  final int harmonicNumber;
  double amplitude;
  double phase;
  double frequency;
  double detune; // Fine tuning in cents
  bool enabled;
  
  // Independent envelope for this harmonic
  double attack;
  double decay;
  double sustain;
  double release;
  
  // Modulation inputs
  double amplitudeModulation;
  double frequencyModulation;
  double phaseModulation;
  
  HarmonicOscillator({
    required this.harmonicNumber,
    this.amplitude = 0.0,
    this.phase = 0.0,
    this.frequency = 1.0,
    this.detune = 0.0,
    this.enabled = true,
    this.attack = 0.01,
    this.decay = 0.1,
    this.sustain = 0.7,
    this.release = 0.5,
    this.amplitudeModulation = 0.0,
    this.frequencyModulation = 0.0,
    this.phaseModulation = 0.0,
  });
  
  /// Process harmonic for one sample
  double process(double fundamentalFreq, double sampleRate, double time, bool isReleased, double releaseTime) {
    if (!enabled || amplitude <= 0.001) return 0.0;
    
    // Calculate harmonic frequency with detune
    final detuneRatio = math.pow(2.0, detune / 1200.0); // Convert cents to ratio
    final harmonicFreq = fundamentalFreq * harmonicNumber * frequency * detuneRatio;
    
    // Apply frequency modulation
    final modulatedFreq = harmonicFreq * (1.0 + frequencyModulation);
    
    // Update phase
    phase += modulatedFreq / sampleRate;
    if (phase >= 1.0) phase -= 1.0;
    
    // Generate sine wave with phase modulation
    final modulatedPhase = phase + phaseModulation;
    final sample = math.sin(modulatedPhase * 2.0 * math.pi);
    
    // Apply harmonic envelope
    final envelope = SynthUtils.applyADSR(time, attack, decay, sustain, release, isReleased, releaseTime);
    
    // Apply amplitude with modulation
    final finalAmplitude = amplitude * (1.0 + amplitudeModulation) * envelope;
    
    return sample * finalAmplitude;
  }
  
  /// Reset harmonic state
  void reset() {
    phase = 0.0;
    amplitudeModulation = 0.0;
    frequencyModulation = 0.0;
    phaseModulation = 0.0;
  }
  
  /// Get visualization data
  Map<String, dynamic> getVisualizationData() {
    return {
      'harmonicNumber': harmonicNumber,
      'amplitude': amplitude,
      'phase': phase,
      'frequency': frequency,
      'detune': detune,
      'enabled': enabled,
      'amplitudeModulation': amplitudeModulation,
      'frequencyModulation': frequencyModulation,
      'phaseModulation': phaseModulation,
    };
  }
}

/// Spectral template for common harmonic patterns
class SpectralTemplate {
  final String name;
  final String description;
  final List<double> harmonicAmplitudes;
  final List<double> harmonicPhases;
  final Map<String, dynamic> metadata;
  
  SpectralTemplate({
    required this.name,
    required this.description,
    required this.harmonicAmplitudes,
    List<double>? harmonicPhases,
    this.metadata = const {},
  }) : harmonicPhases = harmonicPhases ?? List.filled(harmonicAmplitudes.length, 0.0);
  
  /// Apply template to harmonic oscillators
  void applyToHarmonics(List<HarmonicOscillator> harmonics) {
    for (int i = 0; i < math.min(harmonics.length, harmonicAmplitudes.length); i++) {
      harmonics[i].amplitude = harmonicAmplitudes[i];
      if (i < harmonicPhases.length) {
        harmonics[i].phase = harmonicPhases[i];
      }
      harmonics[i].enabled = harmonicAmplitudes[i] > 0.001;
    }
  }
}

/// Additive voice with multiple harmonics
class AdditiveVoice extends SynthVoice {
  final List<HarmonicOscillator> harmonics;
  int selectedTemplate;
  double spectralTilt;
  double harmonicSpread;
  
  AdditiveVoice({
    required super.noteNumber,
    required super.frequency,
    required super.velocity,
    required super.startTime,
    required this.harmonics,
    this.selectedTemplate = 0,
    this.spectralTilt = 0.0,
    this.harmonicSpread = 0.0,
  });
  
  void reset() {
    for (final harmonic in harmonics) {
      harmonic.reset();
    }
  }
  
  /// Get active harmonic count
  int get activeHarmonicCount => harmonics.where((h) => h.enabled && h.amplitude > 0.001).length;
}

/// Professional Additive Synthesis Engine
class AdditiveSynthesis extends SynthesisEngine {
  static const int maxHarmonics = 128;
  
  final List<SpectralTemplate> _spectralTemplates = [];
  int _selectedTemplateIndex = 0;
  
  // Global additive parameters
  double _spectralTilt = 0.0;        // Overall spectral balance (-1 to 1)
  double _harmonicSpread = 0.0;      // Frequency spread of harmonics
  double _fundamentalAmplitude = 1.0; // Amplitude of fundamental frequency
  double _harmonicDecay = 0.7;       // How much harmonics decay with number
  bool _enableSpectralMorphing = true;
  
  // Spectral analysis
  final List<double> _currentSpectrum = List.filled(maxHarmonics, 0.0);
  final List<double> _targetSpectrum = List.filled(maxHarmonics, 0.0);
  double _morphingSpeed = 0.1;
  
  AdditiveSynthesis({
    super.maxVoices = 16, // Additive can be CPU intensive with many harmonics
    super.sampleRate = 44100.0,
  }) : super(
    type: SynthesisType.additive,
    name: 'Professional Additive',
  ) {
    _initializeSpectralTemplates();
    _initializeAdditiveParameters();
  }
  
  // Getters
  List<SpectralTemplate> get spectralTemplates => List.unmodifiable(_spectralTemplates);
  int get selectedTemplateIndex => _selectedTemplateIndex;
  double get spectralTilt => _spectralTilt;
  double get harmonicSpread => _harmonicSpread;
  double get fundamentalAmplitude => _fundamentalAmplitude;
  double get harmonicDecay => _harmonicDecay;
  bool get enableSpectralMorphing => _enableSpectralMorphing;
  List<double> get currentSpectrum => List.unmodifiable(_currentSpectrum);
  
  /// Initialize spectral templates
  void _initializeSpectralTemplates() {
    _spectralTemplates.addAll([
      // Classic waveforms as additive spectra
      SpectralTemplate(
        name: 'Sawtooth',
        description: 'Classic sawtooth wave with all harmonics',
        harmonicAmplitudes: List.generate(64, (i) => 1.0 / (i + 1)),
        metadata: {'type': 'classic', 'fundamental': true},
      ),
      
      SpectralTemplate(
        name: 'Square Wave',
        description: 'Square wave with odd harmonics only',
        harmonicAmplitudes: List.generate(64, (i) => (i % 2 == 0) ? 1.0 / (i + 1) : 0.0),
        metadata: {'type': 'classic', 'odd_harmonics': true},
      ),
      
      SpectralTemplate(
        name: 'Organ',
        description: 'Church organ with fundamental and octaves',
        harmonicAmplitudes: _generateOrganSpectrum(),
        metadata: {'type': 'instrument', 'formants': false},
      ),
      
      SpectralTemplate(
        name: 'Violin',
        description: 'Violin-like harmonic content',
        harmonicAmplitudes: _generateViolinSpectrum(),
        metadata: {'type': 'instrument', 'bowed': true},
      ),
      
      SpectralTemplate(
        name: 'Vocal Ah',
        description: 'Human voice "Ah" vowel formants',
        harmonicAmplitudes: _generateVocalSpectrum('ah'),
        metadata: {'type': 'vocal', 'vowel': 'ah', 'formants': true},
      ),
      
      SpectralTemplate(
        name: 'Vocal Ee',
        description: 'Human voice "Ee" vowel formants',
        harmonicAmplitudes: _generateVocalSpectrum('ee'),
        metadata: {'type': 'vocal', 'vowel': 'ee', 'formants': true},
      ),
      
      SpectralTemplate(
        name: 'Bell',
        description: 'Metallic bell with inharmonic partials',
        harmonicAmplitudes: _generateBellSpectrum(),
        metadata: {'type': 'metallic', 'inharmonic': true},
      ),
      
      SpectralTemplate(
        name: 'Glass',
        description: 'Glass-like crystalline harmonics',
        harmonicAmplitudes: _generateGlassSpectrum(),
        metadata: {'type': 'crystalline', 'bright': true},
      ),
    ]);
  }
  
  /// Initialize additive-specific parameters
  void _initializeAdditiveParameters() {
    setParameter(SynthParameter.harmonicContent, 0.7);
    setParameter(SynthParameter.spectralTilt, 0.0);
  }
  
  /// Set spectral template
  void setSpectralTemplate(int index) {
    if (index >= 0 && index < _spectralTemplates.length) {
      _selectedTemplateIndex = index;
      
      // Set target spectrum for morphing
      final template = _spectralTemplates[index];
      for (int i = 0; i < math.min(_targetSpectrum.length, template.harmonicAmplitudes.length); i++) {
        _targetSpectrum[i] = template.harmonicAmplitudes[i];
      }
      
      notifyListeners();
    }
  }
  
  /// Set spectral tilt (brightness control)
  void setSpectralTilt(double tilt) {
    _spectralTilt = tilt.clamp(-1.0, 1.0);
    setParameter(SynthParameter.spectralTilt, _spectralTilt);
    notifyListeners();
  }
  
  /// Set harmonic spread
  void setHarmonicSpread(double spread) {
    _harmonicSpread = spread.clamp(0.0, 1.0);
    notifyListeners();
  }
  
  /// Set fundamental amplitude
  void setFundamentalAmplitude(double amplitude) {
    _fundamentalAmplitude = amplitude.clamp(0.0, 2.0);
    notifyListeners();
  }
  
  /// Set harmonic decay rate
  void setHarmonicDecay(double decay) {
    _harmonicDecay = decay.clamp(0.1, 1.0);
    notifyListeners();
  }
  
  /// Enable/disable spectral morphing
  void setSpectralMorphingEnabled(bool enabled) {
    _enableSpectralMorphing = enabled;
    notifyListeners();
  }
  
  /// Set morphing speed
  void setMorphingSpeed(double speed) {
    _morphingSpeed = speed.clamp(0.01, 1.0);
    notifyListeners();
  }
  
  @override
  List<SynthParameter> getSupportedParameters() {
    return [
      SynthParameter.frequency,
      SynthParameter.amplitude,
      SynthParameter.harmonicContent,
      SynthParameter.spectralTilt,
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
      case SynthParameter.harmonicContent:
        return {
          'name': 'Harmonic Content',
          'min': 0.0,
          'max': 1.0,
          'default': 0.7,
          'unit': '%',
          'description': 'Overall harmonic richness'
        };
      case SynthParameter.spectralTilt:
        return {
          'name': 'Spectral Tilt',
          'min': -1.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '',
          'description': 'Brightness/darkness of spectrum'
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
    if (voice is! AdditiveVoice) return;
    
    // Apply current spectral template
    final template = _spectralTemplates[_selectedTemplateIndex];
    template.applyToHarmonics(voice.harmonics);
    
    // Apply global parameters
    voice.spectralTilt = _spectralTilt;
    voice.harmonicSpread = _harmonicSpread;
    
    // Initialize harmonics based on global settings
    _applyGlobalParametersToVoice(voice);
  }
  
  @override
  void onNoteOff(SynthVoice voice) {
    voice.isActive = false;
  }
  
  @override
  Float32List processVoice(SynthVoice voice, int numSamples) {
    final buffer = Float32List(numSamples);
    
    if (voice is! AdditiveVoice) return buffer;
    
    var currentTime = DateTime.now().difference(voice.startTime).inMicroseconds / 1000000.0;
    
    // Update spectrum morphing
    if (_enableSpectralMorphing) {
      _updateSpectrumMorphing();
      _applyMorphedSpectrumToVoice(voice);
    }
    
    for (int i = 0; i < numSamples; i++) {
      double sample = 0.0;
      
      // Process all active harmonics
      for (final harmonic in voice.harmonics) {
        if (harmonic.enabled) {
          sample += harmonic.process(
            voice.frequency, 
            sampleRate, 
            currentTime + (i / sampleRate),
            !voice.isActive,
            currentTime
          );
        }
      }
      
      // Apply spectral tilt
      sample = _applySpectralTilt(sample, voice.spectralTilt);
      
      // Apply voice velocity and amplitude
      sample *= voice.velocity * voice.amplitude;
      
      buffer[i] = sample;
    }
    
    return buffer;
  }
  
  /// Update spectrum morphing between current and target
  void _updateSpectrumMorphing() {
    for (int i = 0; i < _currentSpectrum.length; i++) {
      final difference = _targetSpectrum[i] - _currentSpectrum[i];
      _currentSpectrum[i] += difference * _morphingSpeed;
    }
  }
  
  /// Apply morphed spectrum to voice harmonics
  void _applyMorphedSpectrumToVoice(AdditiveVoice voice) {
    for (int i = 0; i < math.min(voice.harmonics.length, _currentSpectrum.length); i++) {
      final harmonic = voice.harmonics[i];
      harmonic.amplitude = _currentSpectrum[i] * _fundamentalAmplitude;
      
      // Apply harmonic decay
      if (i > 0) {
        harmonic.amplitude *= math.pow(_harmonicDecay, i);
      }
      
      // Apply harmonic spread (detune)
      if (_harmonicSpread > 0.0) {
        final spreadAmount = (_harmonicSpread * 50.0) * (i + 1); // Spread in cents
        harmonic.detune = (math.Random().nextDouble() - 0.5) * spreadAmount;
      }
    }
  }
  
  /// Apply global parameters to voice
  void _applyGlobalParametersToVoice(AdditiveVoice voice) {
    final harmonicContent = getParameter(SynthParameter.harmonicContent);
    
    for (int i = 0; i < voice.harmonics.length; i++) {
      final harmonic = voice.harmonics[i];
      
      // Scale amplitude by harmonic content
      harmonic.amplitude *= harmonicContent;
      
      // Apply harmonic decay
      if (i > 0) {
        harmonic.amplitude *= math.pow(_harmonicDecay, i);
      }
      
      // Set envelope parameters
      harmonic.attack = getParameter(SynthParameter.envelopeAttack);
      harmonic.decay = getParameter(SynthParameter.envelopeDecay);
      harmonic.sustain = getParameter(SynthParameter.envelopeSustain);
      harmonic.release = getParameter(SynthParameter.envelopeRelease);
    }
  }
  
  /// Apply spectral tilt filtering
  double _applySpectralTilt(double sample, double tilt) {
    // Simple spectral tilt simulation (would use proper filtering in production)
    if (tilt > 0.0) {
      // Brighten (high-pass character)
      return sample * (1.0 + tilt * 0.5);
    } else if (tilt < 0.0) {
      // Darken (low-pass character)
      return sample * (1.0 + tilt * 0.3);
    }
    return sample;
  }
  
  @override
  Map<String, dynamic> getVisualizationData() {
    // Collect harmonic data from all active voices
    final harmonicLevels = List.filled(maxHarmonics, 0.0);
    int totalActiveHarmonics = 0;
    
    for (final voice in activeVoices) {
      if (voice is AdditiveVoice) {
        totalActiveHarmonics += voice.activeHarmonicCount;
        
        for (int i = 0; i < math.min(voice.harmonics.length, harmonicLevels.length); i++) {
          final harmonic = voice.harmonics[i];
          if (harmonic.enabled) {
            harmonicLevels[i] = math.max(harmonicLevels[i], harmonic.amplitude);
          }
        }
        break; // Just use first voice for visualization
      }
    }
    
    return {
      'type': 'additive',
      'templateName': _spectralTemplates[_selectedTemplateIndex].name,
      'templateDescription': _spectralTemplates[_selectedTemplateIndex].description,
      'harmonicLevels': harmonicLevels.take(64).toList(), // Limit for visualization
      'currentSpectrum': _currentSpectrum.take(64).toList(),
      'targetSpectrum': _targetSpectrum.take(64).toList(),
      'spectralTilt': _spectralTilt,
      'harmonicSpread': _harmonicSpread,
      'fundamentalAmplitude': _fundamentalAmplitude,
      'harmonicDecay': _harmonicDecay,
      'enableSpectralMorphing': _enableSpectralMorphing,
      'totalActiveHarmonics': totalActiveHarmonics,
      'voiceCount': voiceCount,
      'cpuUsage': cpuUsage,
    };
  }
  
  @override
  SynthVoice createVoice(int noteNumber, double frequency, double velocity) {
    // Create harmonics for the voice
    final harmonics = <HarmonicOscillator>[];
    for (int i = 0; i < maxHarmonics; i++) {
      harmonics.add(HarmonicOscillator(
        harmonicNumber: i + 1,
        amplitude: 0.0, // Will be set by template
        attack: getParameter(SynthParameter.envelopeAttack),
        decay: getParameter(SynthParameter.envelopeDecay),
        sustain: getParameter(SynthParameter.envelopeSustain),
        release: getParameter(SynthParameter.envelopeRelease),
      ));
    }
    
    return AdditiveVoice(
      noteNumber: noteNumber,
      frequency: frequency,
      velocity: velocity,
      startTime: DateTime.now(),
      harmonics: harmonics,
      selectedTemplate: _selectedTemplateIndex,
      spectralTilt: _spectralTilt,
      harmonicSpread: _harmonicSpread,
    );
  }

  
  // Spectral template generators
  
  List<double> _generateOrganSpectrum() {
    final spectrum = List.filled(64, 0.0);
    // Strong fundamental, octaves, and fifth
    spectrum[0] = 1.0;  // Fundamental
    spectrum[1] = 0.8;  // Octave
    spectrum[2] = 0.6;  // Fifth
    spectrum[3] = 0.7;  // Double octave
    spectrum[4] = 0.4;  // Third
    spectrum[7] = 0.5;  // Triple octave
    return spectrum;
  }
  
  List<double> _generateViolinSpectrum() {
    final spectrum = List.filled(64, 0.0);
    // Violin-like harmonic decay with formant peaks
    for (int i = 0; i < spectrum.length; i++) {
      final harmonic = i + 1;
      spectrum[i] = (1.0 / harmonic) * math.exp(-harmonic * 0.1);
      
      // Add formant peaks around harmonics 2-4
      if (harmonic >= 2 && harmonic <= 4) {
        spectrum[i] *= 1.5;
      }
    }
    return spectrum;
  }
  
  List<double> _generateVocalSpectrum(String vowel) {
    final spectrum = List.filled(64, 0.0);
    
    switch (vowel) {
      case 'ah':
        // Formants around 700Hz and 1200Hz (approximate)
        spectrum[0] = 1.0;   // Fundamental
        spectrum[1] = 0.8;   // First formant region
        spectrum[2] = 0.6;   // Second formant region
        spectrum[3] = 0.4;
        spectrum[4] = 0.2;
        break;
        
      case 'ee':
        // Higher formants for "ee" sound
        spectrum[0] = 0.8;   // Fundamental
        spectrum[1] = 0.4;   
        spectrum[2] = 1.0;   // Strong second formant
        spectrum[3] = 0.7;
        spectrum[4] = 0.5;
        spectrum[5] = 0.3;
        break;
    }
    
    return spectrum;
  }
  
  List<double> _generateBellSpectrum() {
    final spectrum = List.filled(64, 0.0);
    // Inharmonic partials typical of bells
    spectrum[0] = 1.0;   // Fundamental
    spectrum[1] = 0.6;   // Slightly sharp octave
    spectrum[2] = 0.4;   // Fifth
    spectrum[4] = 0.8;   // Strong higher partial
    spectrum[6] = 0.5;   
    spectrum[9] = 0.3;   // Scattered inharmonic content
    spectrum[13] = 0.2;
    return spectrum;
  }
  
  List<double> _generateGlassSpectrum() {
    final spectrum = List.filled(64, 0.0);
    // Crystalline, bright harmonic content
    for (int i = 0; i < spectrum.length; i++) {
      final harmonic = i + 1;
      // Emphasis on higher harmonics with some randomness
      spectrum[i] = (1.0 / math.sqrt(harmonic)) * (0.5 + 0.5 * math.sin(harmonic * 0.3));
      
      // Extra brightness in mid-high range
      if (harmonic >= 8 && harmonic <= 20) {
        spectrum[i] *= 1.3;
      }
    }
    return spectrum;
  }
  
  /// Set individual harmonic amplitude
  void setHarmonicAmplitude(int harmonicIndex, double amplitude) {
    if (harmonicIndex >= 0 && harmonicIndex < _currentSpectrum.length) {
      _currentSpectrum[harmonicIndex] = amplitude.clamp(0.0, 1.0);
      _targetSpectrum[harmonicIndex] = _currentSpectrum[harmonicIndex];
      
      // Update all active voices
      for (final voice in activeVoices) {
        if (voice is AdditiveVoice && harmonicIndex < voice.harmonics.length) {
          voice.harmonics[harmonicIndex].amplitude = amplitude;
        }
      }
      
      notifyListeners();
    }
  }
  
  /// Get individual harmonic amplitude
  double getHarmonicAmplitude(int harmonicIndex) {
    if (harmonicIndex >= 0 && harmonicIndex < _currentSpectrum.length) {
      return _currentSpectrum[harmonicIndex];
    }
    return 0.0;
  }
}