import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'audio_backend.dart';
import 'platform_audio_backend.dart';
import 'granular_parameters.dart';
import 'parameter_definitions.dart';
import 'music_theory.dart';
import '../utils/audio_ui_sync.dart';

/// The main model class for synth parameters
/// 
/// This class holds all parameters controlling the synthesizer and notifies
/// listeners when any parameter changes. It serves as the bridge between the UI
/// and the audio engine (native or web).
class SynthParametersModel extends ChangeNotifier {
  // Reference to the platform-specific audio backend
  late final AudioBackend _engine;
  
  // Master parameters
  double _masterVolume = 0.75;
  bool _isMasterMuted = false;
  
  // Oscillator parameters
  final List<OscillatorParameters> _oscillators = [
    OscillatorParameters(), // Default oscillator
  ];
  
  // Filter parameters
  double _filterCutoff = 1000.0; // Hz
  double _filterResonance = 0.5; // Q
  FilterType _filterType = FilterType.lowPass;
  
  // Envelope parameters
  double _attackTime = 0.01; // seconds
  double _decayTime = 0.1; // seconds
  double _sustainLevel = 0.7; // 0-1
  double _releaseTime = 0.5; // seconds
  
  // Effects parameters
  double _reverbMix = 0.2; // 0-1
  double _delayTime = 0.5; // seconds
  double _delayFeedback = 0.3; // 0-1

  // NEW: Effect enable flags for Phase 6 visual integration
  bool _chorusEnabled = false;
  double _chorusMix = 0.5;
  double _chorusRate = 0.5; // Hz
  bool _distortionEnabled = false;
  double _distortionAmount = 0.0;
  bool _phaserEnabled = false;
  double _phaserRate = 0.5; // Hz
  double _phaserDepth = 0.5;
  bool _compressorEnabled = false;
  double _compressorRatio = 4.0;
  bool _flangerEnabled = false;
  double _flangerDepth = 0.5;
  double _flangerRate = 0.5; // Hz

  // NEW: LFO parameters for Phase 5 testing
  final List<double> _lfoValues = List.filled(4, 0.5); // 4 LFOs, values 0-1
  final List<double> _lfoRates = List.filled(4, 1.0); // Hz
  final List<String> _lfoWaveforms = ['sine', 'triangle', 'square', 'sawtooth']; // Waveform types
  
  // XY Pad parameters
  double _xyPadX = 0.5; // 0-1
  double _xyPadY = 0.5; // 0-1
  XYPadAssignment _xAxisAssignment = XYPadAssignment.filterCutoff;
  XYPadAssignment _yAxisAssignment = XYPadAssignment.filterResonance;
  
  // New XY Pad musical context fields
  // TODO: Move MusicalScale enum to a shared file (e.g., lib/core/music_theory.dart) and import here.
  // For now, defined inline for diff clarity.
  MusicalScale xyPadScaleX = MusicalScale.Chromatic;
  int xyPadRootNoteX = 0; // MIDI offset for C (0-11)
  int xyPadPitch = 60;    // Current quantized MIDI note output of X-axis

  // Granular parameters
  late final GranularParameters _granularParameters;
  
  // Constructor
  SynthParametersModel() {
    // Create platform-specific audio backend
    _engine = createAudioBackend();
    // Initialize granular parameters
    _granularParameters = GranularParameters(_engine);
    // Initialize the engine asynchronously
    _initEngine();
  }
  
  // Initialize the synth engine
  Future<void> _initEngine() async {
    try {
      await _engine.initialize();
      
      // Set initial volume
      _engine.setParameter(AudioParameters.masterVolume, _masterVolume);
      
      // Sync all parameters to the engine
      _syncAllParametersToEngine();
      
      // Initialize audio-UI sync manager
      AudioUISyncManager.instance.initialize(_engine);
      AudioUISyncManager.instance.clearError();
    } catch (e) {
      print('Error initializing synth engine: $e');
      AudioUISyncManager.instance.setError(e.toString());
    }
  }
  
  // Sync all parameters to the C++ engine
  void _syncAllParametersToEngine() {
    if (!_engine.isInitialized) return;
    
    // Master parameters
    _engine.setParameter('master_volume', _masterVolume);
    _engine.setParameter('master_mute', _isMasterMuted ? 1.0 : 0.0);
    
    // Filter parameters
    _engine.setParameter('filter_cutoff', _filterCutoff);
    _engine.setParameter('filter_resonance', _filterResonance);
    _engine.setParameter('filter_type', _filterType.index.toDouble());
    
    // Envelope parameters
    _engine.setParameter('attack_time', _attackTime);
    _engine.setParameter('decay_time', _decayTime);
    _engine.setParameter('sustain_level', _sustainLevel);
    _engine.setParameter('release_time', _releaseTime);
    
    // Effects parameters
    _engine.setParameter('reverb_mix', _reverbMix);
    _engine.setParameter('delay_time', _delayTime);
    _engine.setParameter('delay_feedback', _delayFeedback);
    
    // Oscillator parameters
    for (int i = 0; i < _oscillators.length; i++) {
      final osc = _oscillators[i];
      
      _engine.setParameter('oscillator_${i}_type', osc.type.index.toDouble());
      _engine.setParameter('oscillator_${i}_frequency', osc.frequency);
      _engine.setParameter('oscillator_${i}_detune', osc.detune);
      _engine.setParameter('oscillator_${i}_volume', osc.volume);
      _engine.setParameter('oscillator_${i}_pan', osc.pan);
      _engine.setParameter('oscillator_${i}_wavetable_index', osc.wavetableIndex.toDouble());
      _engine.setParameter('oscillator_${i}_wavetable_position', osc.wavetablePosition);
    }
  }
  
  // Getters
  double get masterVolume => _masterVolume;
  bool get isMasterMuted => _isMasterMuted;
  AudioBackend get engine => _engine;
  List<OscillatorParameters> get oscillators => List.unmodifiable(_oscillators);
  double get filterCutoff => _filterCutoff;
  double get filterResonance => _filterResonance;
  FilterType get filterType => _filterType;
  double get attackTime => _attackTime;
  double get decayTime => _decayTime;
  double get sustainLevel => _sustainLevel;
  double get releaseTime => _releaseTime;
  double get reverbMix => _reverbMix;
  double get delayTime => _delayTime;
  double get delayFeedback => _delayFeedback;
  double get xyPadX => _xyPadX;
  double get xyPadY => _xyPadY;
  XYPadAssignment get xAxisAssignment => _xAxisAssignment;
  XYPadAssignment get yAxisAssignment => _yAxisAssignment;

  // New XY Pad musical context getters
  MusicalScale get xyPadSelectedScaleX => xyPadScaleX; // Renamed for clarity in getter
  int get xyPadSelectedRootNoteX => xyPadRootNoteX; // Renamed for clarity in getter
  int get xyPadCurrentPitchX => xyPadPitch; // Renamed for clarity in getter

  GranularParameters get granularParameters => _granularParameters;

  // Aliases for morph_app.dart compatibility
  double get attack => _attackTime;
  double get decay => _decayTime;
  double get sustain => _sustainLevel;
  double get release => _releaseTime;

  // NEW: Effect getters
  bool get chorusEnabled => _chorusEnabled;
  double get chorusMix => _chorusMix;
  double get chorusRate => _chorusRate;
  bool get distortionEnabled => _distortionEnabled;
  double get distortionAmount => _distortionAmount;
  bool get phaserEnabled => _phaserEnabled;
  double get phaserRate => _phaserRate;
  double get phaserDepth => _phaserDepth;
  bool get compressorEnabled => _compressorEnabled;
  double get compressorRatio => _compressorRatio;
  bool get flangerEnabled => _flangerEnabled;
  double get flangerDepth => _flangerDepth;
  double get flangerRate => _flangerRate;

  // NEW: LFO getters
  double getLFOValue(int index) => (index >= 0 && index < 4) ? _lfoValues[index] : 0.5;
  double getLFORate(int index) => (index >= 0 && index < 4) ? _lfoRates[index] : 1.0;
  String getLFOWaveform(int index) => (index >= 0 && index < 4) ? _lfoWaveforms[index] : 'sine';
  
  
  // Setters
  void setMasterVolume(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _masterVolume = value;
    
    // Update engine
    _engine.setParameter('master_volume', value);
    
    notifyListeners();
  }
  
  void setMasterMuted(bool value) {
    _isMasterMuted = value;
    
    // Update engine
    _engine.setParameter('master_mute', value ? 1.0 : 0.0);
    
    notifyListeners();
  }
  
  void setFilterCutoff(double value) {
    if (value < 20) value = 20;
    if (value > 20000) value = 20000;
    _filterCutoff = value;
    
    // Update engine
    _engine.setParameter('filter_cutoff', value);
    
    notifyListeners();
  }
  
  void setFilterResonance(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _filterResonance = value;
    
    // Update engine
    _engine.setParameter('filter_resonance', value);
    
    notifyListeners();
  }
  
  void setFilterType(FilterType value) {
    _filterType = value;
    
    // Update engine
    _engine.setParameter('filter_type', value.index.toDouble());
    
    notifyListeners();
  }
  
  void setAttackTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 5) value = 5;
    _attackTime = value;
    
    // Update engine
    _engine.setParameter('attack_time', value);
    
    notifyListeners();
  }
  
  void setDecayTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 5) value = 5;
    _decayTime = value;
    
    // Update engine
    _engine.setParameter('decay_time', value);
    
    notifyListeners();
  }
  
  void setSustainLevel(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _sustainLevel = value;
    
    // Update engine
    _engine.setParameter('sustain_level', value);
    
    notifyListeners();
  }
  
  void setReleaseTime(double value) {
    if (value < 0.001) value = 0.001;
    if (value > 10) value = 10;
    _releaseTime = value;
    
    // Update engine
    _engine.setParameter('release_time', value);
    
    notifyListeners();
  }
  
  void setReverbMix(double value) {
    if (value < 0) value = 0;
    if (value > 1) value = 1;
    _reverbMix = value;
    
    // Update engine
    _engine.setParameter('reverb_mix', value);
    
    notifyListeners();
  }
  
  void setDelayTime(double value) {
    if (value < 0.01) value = 0.01;
    if (value > 2) value = 2;
    _delayTime = value;
    
    // Update engine
    _engine.setParameter('delay_time', value);
    
    notifyListeners();
  }
  
  void setDelayFeedback(double value) {
    if (value < 0) value = 0;
    if (value > 0.95) value = 0.95; // Prevent endless feedback loops
    _delayFeedback = value;
    
    // Update engine
    _engine.setParameter('delay_feedback', value);
    
    notifyListeners();
  }
  
  // Aliases for morph_app.dart compatibility
  void setAttack(double value) => setAttackTime(value);
  void setDecay(double value) => setDecayTime(value);
  void setSustain(double value) => setSustainLevel(value);
  void setRelease(double value) => setReleaseTime(value);

  // NEW: Effect setters
  void setChorusEnabled(bool value) {
    _chorusEnabled = value;
    if (_engine.isInitialized) {
      _engine.setParameter('chorus_enabled', value ? 1.0 : 0.0);
    }
    notifyListeners();
  }

  void setChorusMix(double value) {
    _chorusMix = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) {
      _engine.setParameter('chorus_mix', _chorusMix);
    }
    notifyListeners();
  }

  void setChorusRate(double value) {
    _chorusRate = value.clamp(0.1, 10.0);
    if (_engine.isInitialized) {
      _engine.setParameter('chorus_rate', _chorusRate);
    }
    notifyListeners();
  }

  void setDistortionEnabled(bool value) {
    _distortionEnabled = value;
    if (_engine.isInitialized) {
      _engine.setParameter('distortion_enabled', value ? 1.0 : 0.0);
    }
    notifyListeners();
  }

  void setDistortionAmount(double value) {
    _distortionAmount = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) {
      _engine.setParameter('distortion_amount', _distortionAmount);
    }
    notifyListeners();
  }

  void setPhaserEnabled(bool value) {
    _phaserEnabled = value;
    if (_engine.isInitialized) {
      _engine.setParameter('phaser_enabled', value ? 1.0 : 0.0);
    }
    notifyListeners();
  }

  void setPhaserRate(double value) {
    _phaserRate = value.clamp(0.1, 10.0);
    if (_engine.isInitialized) {
      _engine.setParameter('phaser_rate', _phaserRate);
    }
    notifyListeners();
  }

  void setPhaserDepth(double value) {
    _phaserDepth = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) {
      _engine.setParameter('phaser_depth', _phaserDepth);
    }
    notifyListeners();
  }

  void setCompressorEnabled(bool value) {
    _compressorEnabled = value;
    if (_engine.isInitialized) {
      _engine.setParameter('compressor_enabled', value ? 1.0 : 0.0);
    }
    notifyListeners();
  }

  void setCompressorRatio(double value) {
    _compressorRatio = value.clamp(1.0, 20.0);
    if (_engine.isInitialized) {
      _engine.setParameter('compressor_ratio', _compressorRatio);
    }
    notifyListeners();
  }

  void setFlangerEnabled(bool value) {
    _flangerEnabled = value;
    if (_engine.isInitialized) {
      _engine.setParameter('flanger_enabled', value ? 1.0 : 0.0);
    }
    notifyListeners();
  }

  void setFlangerDepth(double value) {
    _flangerDepth = value.clamp(0.0, 1.0);
    if (_engine.isInitialized) {
      _engine.setParameter('flanger_depth', _flangerDepth);
    }
    notifyListeners();
  }

  void setFlangerRate(double value) {
    _flangerRate = value.clamp(0.1, 10.0);
    if (_engine.isInitialized) {
      _engine.setParameter('flanger_rate', _flangerRate);
    }
    notifyListeners();
  }

  // NEW: LFO setters
  void setLFOValue(int index, double value) {
    if (index >= 0 && index < 4) {
      _lfoValues[index] = value.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  void setLFORate(int index, double value) {
    if (index >= 0 && index < 4) {
      _lfoRates[index] = value.clamp(0.01, 20.0);
      notifyListeners();
    }
  }

  void setLFOWaveform(int index, String waveform) {
    if (index >= 0 && index < 4) {
      _lfoWaveforms[index] = waveform;
      notifyListeners();
    }
  }
  
  void setXYPadPosition(double x, double y) {
    _xyPadX = x.clamp(0, 1);
    _xyPadY = y.clamp(0, 1);
    
    // Apply XY pad mapping to target parameters
    _applyXYPadMapping();
    
    notifyListeners();
  }
  
  void setXYPad(double x, double y) => setXYPadPosition(x, y);
  
  void setXAxisAssignment(XYPadAssignment assignment) {
    _xAxisAssignment = assignment;
    _applyXYPadMapping();
    notifyListeners();
  }
  
  void setYAxisAssignment(XYPadAssignment assignment) {
    _yAxisAssignment = assignment;
    _applyXYPadMapping();
    notifyListeners();
  }

  // New XY Pad musical context setters
  void setXYPadScaleX(MusicalScale newScale) {
    xyPadScaleX = newScale;
    // Potentially trigger re-quantization or update related state if needed immediately
    notifyListeners();
  }

  void setXYPadRootNoteX(int newRootNote) {
    xyPadRootNoteX = newRootNote.clamp(0, 11);
    // Potentially trigger re-quantization or update related state if needed immediately
    notifyListeners();
  }

  void setXYPadXPitch(int newPitch) {
    // This primarily reflects the output of the XY pad's X-axis quantization.
    // It might not directly set an engine parameter unless the engine consumes this exact value.
    // The XYPadWidget itself sends the quantized pitch to a dedicated engine parameter.
    xyPadPitch = newPitch;
    notifyListeners();
  }
  
  // Oscillator management
  void addOscillator() {
    _oscillators.add(OscillatorParameters());
    
    // Update oscillator in the engine
    _syncOscillatorsToEngine();
    
    notifyListeners();
  }
  
  void removeOscillator(int index) {
    if (_oscillators.length > 1 && index >= 0 && index < _oscillators.length) {
      _oscillators.removeAt(index);
      
      // Update oscillator in the engine
      _syncOscillatorsToEngine();
      
      notifyListeners();
    }
  }
  
  void updateOscillator(int index, OscillatorParameters params) {
    if (index >= 0 && index < _oscillators.length) {
      _oscillators[index] = params;
      
      // Update oscillator in the engine
      _syncOscillatorToEngine(index);
      
      notifyListeners();
    }
  }
  
  // Sync a specific oscillator to the engine
  void _syncOscillatorToEngine(int index) {
    if (!_engine.isInitialized || index >= _oscillators.length) return;
    
    final osc = _oscillators[index];
    
    _engine.setParameter('oscillator_${index}_type', osc.type.index.toDouble());
    _engine.setParameter('oscillator_${index}_frequency', osc.frequency);
    _engine.setParameter('oscillator_${index}_detune', osc.detune);
    _engine.setParameter('oscillator_${index}_volume', osc.volume);
    _engine.setParameter('oscillator_${index}_pan', osc.pan);
    _engine.setParameter('oscillator_${index}_wavetable_index', osc.wavetableIndex.toDouble());
    _engine.setParameter('oscillator_${index}_wavetable_position', osc.wavetablePosition);
  }
  
  // Sync all oscillators to the engine
  void _syncOscillatorsToEngine() {
    if (!_engine.isInitialized) return;
    
    for (int i = 0; i < _oscillators.length; i++) {
      _syncOscillatorToEngine(i);
    }
  }
  
  // Internal methods
  void _applyXYPadMapping() {
    // Map X axis parameter based on assignment
    switch (_xAxisAssignment) {
      case XYPadAssignment.filterCutoff:
        // Exponential mapping for filter cutoff (20Hz - 20kHz)
        setFilterCutoff(20.0 * math.pow(1000, _xyPadX).toDouble());
        break;
      case XYPadAssignment.filterResonance:
        setFilterResonance(_xyPadX);
        break;
      case XYPadAssignment.oscillatorMix:
        if (_oscillators.length >= 2) {
          // Adjust mix between oscillators 0 and 1
          final osc0 = _oscillators[0];
          final osc1 = _oscillators[1];
          _oscillators[0] = osc0.copyWith(volume: 1 - _xyPadX);
          _oscillators[1] = osc1.copyWith(volume: _xyPadX);
          
          // Update oscillators in the engine
          _syncOscillatorToEngine(0);
          _syncOscillatorToEngine(1);
        }
        break;
      case XYPadAssignment.reverbMix:
        setReverbMix(_xyPadX);
        break;
    }
    
    // Map Y axis parameter based on assignment
    switch (_yAxisAssignment) {
      case XYPadAssignment.filterCutoff:
        // Exponential mapping for filter cutoff (20Hz - 20kHz) 
        setFilterCutoff(20.0 * math.pow(1000, _xyPadY).toDouble());
        break;
      case XYPadAssignment.filterResonance:
        setFilterResonance(_xyPadY);
        break;
      case XYPadAssignment.oscillatorMix:
        if (_oscillators.length >= 2) {
          // Adjust mix between oscillators 0 and 1
          final osc0 = _oscillators[0];
          final osc1 = _oscillators[1];
          _oscillators[0] = osc0.copyWith(volume: 1 - _xyPadY);
          _oscillators[1] = osc1.copyWith(volume: _xyPadY);
          
          // Update oscillators in the engine
          _syncOscillatorToEngine(0);
          _syncOscillatorToEngine(1);
        }
        break;
      case XYPadAssignment.reverbMix:
        setReverbMix(_xyPadY);
        break;
    }
  }
  
  // MIDI note handling
  void noteOn(int note, int velocity) {
    if (_engine.isInitialized) {
      _engine.noteOn(note, velocity / 127.0);
    }
  }
  
  void noteOff(int note) {
    if (_engine.isInitialized) {
      _engine.noteOff(note);
    }
  }
  
  // Alias for triggerNote method expected by UI components
  void triggerNote(int note, [int velocity = 80]) {
    noteOn(note, velocity);
  }
  
  // Convert to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'masterVolume': _masterVolume,
      'isMasterMuted': _isMasterMuted,
      'oscillators': _oscillators.map((o) => o.toJson()).toList(),
      'filterCutoff': _filterCutoff,
      'filterResonance': _filterResonance,
      'filterType': _filterType.index,
      'attackTime': _attackTime,
      'decayTime': _decayTime,
      'sustainLevel': _sustainLevel,
      'releaseTime': _releaseTime,
      'reverbMix': _reverbMix,
      'delayTime': _delayTime,
      'delayFeedback': _delayFeedback,
      'xyPadX': _xyPadX,
      'xyPadY': _xyPadY,
      'xAxisAssignment': _xAxisAssignment.index,
      'yAxisAssignment': _yAxisAssignment.index,

      // New XY Pad musical context fields
      'xyPadScaleX': xyPadScaleX.index,
      'xyPadRootNoteX': xyPadRootNoteX,
      'xyPadPitch': xyPadPitch, // Current output, might be optional to save but good for restoring UI state

      'granular': _granularParameters.toJson(),

      // IMPORTANT FOR NATIVE PRESETS:
      // The C++ SynthPreset struct and its toJsonString/fromJsonString methods
      // in native/src/synth_engine.cpp will need to be updated to
      // serialize/deserialize these new XY Pad musical settings:
      // - "xyPadScaleX": (int, from MusicalScale.index)
      // - "xyPadRootNoteX": (int)
      // - "xyPadPitch": (int) - current output, might be optional to save
      // - "xAxisAssignment": (int, from XYPadAssignment.index) - already exists
      // - "yAxisAssignment": (int, from XYPadAssignment.index) - already exists
      // This ensures presets saved/loaded by the native engine are complete.
    };
  }
  
  // Load from SynthParameters (for AI preset loading)
  void loadParameters(SynthParameters parameters) {
    setFilterCutoff(parameters.filterCutoff);
    setFilterResonance(parameters.filterResonance);
    setAttackTime(parameters.attackTime);
    setReleaseTime(parameters.releaseTime);
    setReverbMix(parameters.reverbMix);
    setMasterVolume(parameters.masterVolume);
    
    if (parameters.xyPadX != null && parameters.xyPadY != null) {
      setXYPadPosition(parameters.xyPadX!, parameters.xyPadY!);
    }
  }

  // Get current parameters as SynthParameters (for AI preset saving)
  SynthParameters getCurrentParameters() {
    return SynthParameters.fromModel(this);
  }

  // Load from a JSON representation
  void loadFromJson(Map<String, dynamic> json) {
    // Load envelope if nested
    if (json['envelope'] != null) {
      final env = json['envelope'];
      _attackTime = env['attack'] ?? env['attackTime'] ?? 0.01;
      _decayTime = env['decay'] ?? env['decayTime'] ?? 0.1;
      _sustainLevel = env['sustain'] ?? env['sustainLevel'] ?? 0.7;
      _releaseTime = env['release'] ?? env['releaseTime'] ?? 0.5;
    } else {
      _attackTime = json['attackTime'] ?? 0.01;
      _decayTime = json['decayTime'] ?? 0.1;
      _sustainLevel = json['sustainLevel'] ?? 0.7;
      _releaseTime = json['releaseTime'] ?? 0.5;
    }
    
    // Load filter if nested
    if (json['filter'] != null) {
      final filter = json['filter'];
      _filterCutoff = filter['cutoff'] ?? filter['filterCutoff'] ?? 1000.0;
      _filterResonance = filter['resonance'] ?? filter['filterResonance'] ?? 0.5;
      _filterType = FilterType.values[filter['type'] ?? filter['filterType'] ?? 0];
    } else {
      _filterCutoff = json['filterCutoff'] ?? 1000.0;
      _filterResonance = json['filterResonance'] ?? 0.5;
      _filterType = FilterType.values[json['filterType'] ?? 0];
    }
    
    // Load effects if nested
    if (json['effects'] != null) {
      final effects = json['effects'];
      _reverbMix = effects['reverb'] ?? effects['reverbMix'] ?? 0.2;
      _delayTime = effects['delayTime'] ?? 0.5;
      _delayFeedback = effects['delayFeedback'] ?? 0.3;
    } else {
      _reverbMix = json['reverbMix'] ?? 0.2;
      _delayTime = json['delayTime'] ?? 0.5;
      _delayFeedback = json['delayFeedback'] ?? 0.3;
    }
    
    _masterVolume = json['masterVolume'] ?? 0.75;
    _isMasterMuted = json['isMasterMuted'] ?? false;
    
    _xyPadX = json['xyPadX'] ?? 0.5;
    _xyPadY = json['xyPadY'] ?? 0.5;
    _xAxisAssignment = XYPadAssignment.values[json['xAxisAssignment'] ?? XYPadAssignment.filterCutoff.index];
    _yAxisAssignment = XYPadAssignment.values[json['yAxisAssignment'] ?? XYPadAssignment.filterResonance.index];

    // Load new XY Pad musical context fields
    // TODO: Move MusicalScale enum to a shared file and import for direct use here.
    // Assuming MusicalScale.values is accessible or using index directly for now.
    // If MusicalScale is not directly accessible, use a helper or default.
    // For this diff, we'll assume it's been moved and is available.
    xyPadScaleX = MusicalScale.values[json['xyPadScaleX'] ?? MusicalScale.Chromatic.index];
    xyPadRootNoteX = json['xyPadRootNoteX'] ?? 0;
    xyPadPitch = json['xyPadPitch'] ?? 60; // Default to C4 if not present
    
    // Load oscillators
    _oscillators.clear();
    final oscillatorsJson = json['oscillators'] as List<dynamic>?;
    if (oscillatorsJson != null && oscillatorsJson.isNotEmpty) {
      for (final oscJson in oscillatorsJson) {
        _oscillators.add(OscillatorParameters.fromJson(oscJson));
      }
    } else {
      _oscillators.add(OscillatorParameters()); // Default oscillator
    }
    
    // Load granular parameters
    if (json['granular'] != null) {
      _granularParameters.loadFromJson(json['granular']);
    }
    
    // Sync all parameters to the engine
    _syncAllParametersToEngine();
    
    notifyListeners();
  }
  
  @override
  void dispose() {
    // Shut down the engine
    _engine.dispose();
    super.dispose();
  }
}

/// Parameters for a single oscillator
class OscillatorParameters {
  final OscillatorType type;
  final double frequency; // Hz
  final double detune; // cents
  final double volume; // 0-1
  final double pan; // -1 to 1
  final int wavetableIndex; // Index of current wavetable
  final double wavetablePosition; // Position within the wavetable (0-1)
  
  OscillatorParameters({
    this.type = OscillatorType.sine,
    this.frequency = 440.0, // A4
    this.detune = 0.0,
    this.volume = 0.5,
    this.pan = 0.0,
    this.wavetableIndex = 0,
    this.wavetablePosition = 0.0,
  });
  
  // Copy with new values
  OscillatorParameters copyWith({
    OscillatorType? type,
    double? frequency,
    double? detune,
    double? volume,
    double? pan,
    int? wavetableIndex,
    double? wavetablePosition,
  }) {
    return OscillatorParameters(
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      detune: detune ?? this.detune,
      volume: volume ?? this.volume,
      pan: pan ?? this.pan,
      wavetableIndex: wavetableIndex ?? this.wavetableIndex,
      wavetablePosition: wavetablePosition ?? this.wavetablePosition,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'frequency': frequency,
      'detune': detune,
      'volume': volume,
      'pan': pan,
      'wavetableIndex': wavetableIndex,
      'wavetablePosition': wavetablePosition,
    };
  }
  
  // Create from JSON
  factory OscillatorParameters.fromJson(Map<String, dynamic> json) {
    return OscillatorParameters(
      type: OscillatorType.values[json['type'] ?? 0],
      frequency: json['frequency'] ?? 440.0,
      detune: json['detune'] ?? 0.0,
      volume: json['volume'] ?? 0.5,
      pan: json['pan'] ?? 0.0,
      wavetableIndex: json['wavetableIndex'] ?? 0,
      wavetablePosition: json['wavetablePosition'] ?? 0.0,
    );
  }
}

/// Possible oscillator waveform types
enum OscillatorType {
  sine,
  square,
  triangle,
  sawtooth,
  noise,
  pulse,
  wavetable,
}

/// Types of filters
enum FilterType {
  lowPass,
  highPass,
  bandPass,
  notch,
  lowShelf,
  highShelf,
}

// MusicalScale enum is now imported from music_theory.dart


/// Possible XY pad parameter assignments
enum XYPadAssignment {
  filterCutoff,
  filterResonance,
  oscillatorMix,
  reverbMix,
  // Consider adding a 'QuantizedPitch' or similar if X-axis is always pitch now,
  // or make the X-axis assignment dropdown control aspects of the pitch quantization.
  // For now, existing assignments are kept.
}

/// Simple data class for serializing synth parameters for AI/Firebase integration
class SynthParameters {
  final double filterCutoff;
  final double filterResonance;
  final double attackTime;
  final double releaseTime;
  final double reverbMix;
  final double masterVolume;
  final double? xyPadX;
  final double? xyPadY;

  const SynthParameters({
    required this.filterCutoff,
    required this.filterResonance,
    required this.attackTime,
    required this.releaseTime,
    required this.reverbMix,
    required this.masterVolume,
    this.xyPadX,
    this.xyPadY,
  });

  /// Create from JSON (used by Firebase)
  factory SynthParameters.fromJson(Map<String, dynamic> json) {
    return SynthParameters(
      filterCutoff: (json['filterCutoff'] ?? 1000.0).toDouble(),
      filterResonance: (json['filterResonance'] ?? 0.5).toDouble(),
      attackTime: (json['attackTime'] ?? 0.01).toDouble(),
      releaseTime: (json['releaseTime'] ?? 0.5).toDouble(),
      reverbMix: (json['reverbMix'] ?? 0.2).toDouble(),
      masterVolume: (json['masterVolume'] ?? 0.75).toDouble(),
      xyPadX: json['xyPadX']?.toDouble(),
      xyPadY: json['xyPadY']?.toDouble(),
    );
  }

  /// Convert to JSON (used by Firebase)
  Map<String, dynamic> toJson() {
    return {
      'filterCutoff': filterCutoff,
      'filterResonance': filterResonance,
      'attackTime': attackTime,
      'releaseTime': releaseTime,
      'reverbMix': reverbMix,
      'masterVolume': masterVolume,
      if (xyPadX != null) 'xyPadX': xyPadX,
      if (xyPadY != null) 'xyPadY': xyPadY,
    };
  }

  /// Create from SynthParametersModel
  factory SynthParameters.fromModel(SynthParametersModel model) {
    return SynthParameters(
      filterCutoff: model.filterCutoff,
      filterResonance: model.filterResonance,
      attackTime: model.attackTime,
      releaseTime: model.releaseTime,
      reverbMix: model.reverbMix,
      masterVolume: model.masterVolume,
      xyPadX: model.xyPadX,
      xyPadY: model.xyPadY,
    );
  }
}

