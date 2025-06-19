import 'dart:typed_data';
import 'dart:math' as math;
import 'synthesis_engine.dart';

/// Professional FM Synthesis Engine
/// 
/// Features:
/// - 6-operator FM synthesis with flexible routing
/// - Multiple algorithm presets (DX7-style and custom)
/// - Real-time operator visualization
/// - Feedback routing and self-modulation
/// - Enhanced envelope generators per operator
/// - Professional modulation matrix integration

/// FM Operator configuration
class FMOperator {
  String name;
  double frequency;      // Frequency ratio (1.0 = fundamental)
  double amplitude;      // Operator output level
  double phase;          // Current phase accumulator
  double feedback;       // Self-feedback amount
  bool isAdditive;       // True = additive, False = modulator
  
  // Envelope parameters
  double attack;
  double decay;
  double sustain;
  double release;
  
  // Modulation connections
  final Map<int, double> modulationInputs = {}; // operatorIndex -> amount
  
  FMOperator({
    required this.name,
    this.frequency = 1.0,
    this.amplitude = 1.0,
    this.phase = 0.0,
    this.feedback = 0.0,
    this.isAdditive = true,
    this.attack = 0.01,
    this.decay = 0.1,
    this.sustain = 0.7,
    this.release = 0.5,
  });
  
  /// Reset operator state
  void reset() {
    phase = 0.0;
    modulationInputs.clear();
  }
  
  /// Process operator for one sample
  double process(double baseFrequency, double sampleRate, double deltaTime) {
    // Calculate instantaneous frequency
    double instFreq = baseFrequency * frequency;
    
    // Apply modulation inputs
    double modulationSum = 0.0;
    for (final modAmount in modulationInputs.values) {
      modulationSum += modAmount;
    }
    
    // Apply feedback (previous output fed back to phase)
    final feedbackAmount = feedback * modulationSum;
    
    // Update phase with modulation
    phase += (instFreq / sampleRate) + feedbackAmount;
    if (phase >= 1.0) phase -= 1.0;
    if (phase < 0.0) phase += 1.0;
    
    // Generate sine wave output
    final output = math.sin(phase * 2.0 * math.pi) * amplitude;
    
    return output;
  }
  
  /// Apply envelope to operator output
  double applyEnvelope(double sample, double time, bool isReleased, double releaseTime) {
    final envelope = SynthUtils.applyADSR(time, attack, decay, sustain, release, isReleased, releaseTime);
    return sample * envelope;
  }
}

/// FM Algorithm definition (routing matrix)
class FMAlgorithm {
  final String name;
  final String description;
  final Map<int, Map<int, double>> connections; // carrier -> {modulator -> amount}
  final List<int> outputs; // Which operators contribute to final output
  
  FMAlgorithm({
    required this.name,
    required this.description,
    required this.connections,
    required this.outputs,
  });
}

/// FM Voice with multiple operators
class FMVoice extends SynthVoice {
  final List<FMOperator> operators;
  int algorithmIndex;
  final List<double> operatorOutputs; // Store operator outputs for routing
  
  FMVoice({
    required super.noteNumber,
    required super.frequency,
    required super.velocity,
    required super.startTime,
    required this.operators,
    this.algorithmIndex = 0,
  }) : operatorOutputs = List.filled(operators.length, 0.0);
  
  void reset() {
    for (final op in operators) {
      op.reset();
    }
    operatorOutputs.fillRange(0, operatorOutputs.length, 0.0);
  }
}

/// Professional FM Synthesis Engine
class FMSynthesis extends SynthesisEngine {
  static const int numOperators = 6;
  
  final List<FMAlgorithm> _algorithms = [];
  int _selectedAlgorithmIndex = 0;
  
  // Global FM parameters
  double _globalRatio = 1.0;
  double _globalFeedback = 0.0;
  double _modulationDepth = 1.0;
  
  FMSynthesis({
    super.maxVoices = 16, // FM is more CPU intensive
    super.sampleRate = 44100.0,
  }) : super(
    type: SynthesisType.fm,
    name: 'Professional FM',
  ) {
    _initializeAlgorithms();
    _initializeFMParameters();
  }
  
  // Getters
  List<FMAlgorithm> get algorithms => List.unmodifiable(_algorithms);
  int get selectedAlgorithmIndex => _selectedAlgorithmIndex;
  double get globalRatio => _globalRatio;
  double get globalFeedback => _globalFeedback;
  double get modulationDepth => _modulationDepth;
  
  /// Initialize FM algorithm presets
  void _initializeAlgorithms() {
    _algorithms.addAll([
      // Classic DX7-style algorithms
      FMAlgorithm(
        name: 'Classic Stack',
        description: '6 -> 5 -> 4 -> 3 -> 2 -> 1 (linear cascade)',
        connections: {
          0: {1: 1.0},           // Op 1 modulated by Op 2
          1: {2: 1.0},           // Op 2 modulated by Op 3
          2: {3: 1.0},           // Op 3 modulated by Op 4
          3: {4: 1.0},           // Op 4 modulated by Op 5
          4: {5: 1.0},           // Op 5 modulated by Op 6
        },
        outputs: [0], // Only operator 1 outputs
      ),
      
      FMAlgorithm(
        name: 'Parallel Modulators',
        description: 'Multiple modulators affecting one carrier',
        connections: {
          0: {1: 0.8, 2: 0.6, 3: 0.4}, // Op 1 modulated by 2, 3, 4
        },
        outputs: [0, 4, 5], // Operators 1, 5, 6 output
      ),
      
      FMAlgorithm(
        name: 'Bell Algorithm',
        description: 'Classic bell-like tones',
        connections: {
          0: {1: 1.0},           // Op 1 modulated by Op 2
          2: {3: 1.0},           // Op 3 modulated by Op 4
        },
        outputs: [0, 2, 4, 5], // Multiple carriers
      ),
      
      FMAlgorithm(
        name: 'Feedback Stack',
        description: 'Stack with feedback loops',
        connections: {
          0: {1: 1.0},           // Linear chain
          1: {2: 1.0},
          2: {3: 1.0},
          3: {0: 0.3},           // Feedback loop
        },
        outputs: [0],
      ),
      
      FMAlgorithm(
        name: 'Complex Web',
        description: 'Complex interconnected modulation',
        connections: {
          0: {1: 0.8, 3: 0.4},   // Op 1 modulated by 2 and 4
          1: {2: 1.0, 5: 0.6},   // Op 2 modulated by 3 and 6
          2: {4: 0.5},           // Op 3 modulated by 5
        },
        outputs: [0, 1, 5],
      ),
      
      FMAlgorithm(
        name: 'Additive Hybrid',
        description: 'Mix of FM and additive synthesis',
        connections: {
          0: {1: 0.6},           // Minimal modulation
          2: {3: 0.4},
        },
        outputs: [0, 1, 2, 4, 5], // Most operators output
      ),
    ]);
  }
  
  /// Initialize FM-specific parameters
  void _initializeFMParameters() {
    setParameter(SynthParameter.fmRatio, 1.0);
    setParameter(SynthParameter.fmAmount, 0.5);
    setParameter(SynthParameter.fmFeedback, 0.0);
  }
  
  /// Set FM algorithm
  void setAlgorithm(int index) {
    if (index >= 0 && index < _algorithms.length) {
      _selectedAlgorithmIndex = index;
      notifyListeners();
    }
  }
  
  /// Set global frequency ratio
  void setGlobalRatio(double ratio) {
    _globalRatio = ratio.clamp(0.1, 10.0);
    setParameter(SynthParameter.fmRatio, _globalRatio);
    notifyListeners();
  }
  
  /// Set global feedback amount
  void setGlobalFeedback(double feedback) {
    _globalFeedback = feedback.clamp(0.0, 1.0);
    setParameter(SynthParameter.fmFeedback, _globalFeedback);
    notifyListeners();
  }
  
  /// Set modulation depth
  void setModulationDepth(double depth) {
    _modulationDepth = depth.clamp(0.0, 2.0);
    setParameter(SynthParameter.fmAmount, _modulationDepth);
    notifyListeners();
  }
  
  @override
  List<SynthParameter> getSupportedParameters() {
    return [
      SynthParameter.frequency,
      SynthParameter.amplitude,
      SynthParameter.phase,
      SynthParameter.fmRatio,
      SynthParameter.fmAmount,
      SynthParameter.fmFeedback,
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
      case SynthParameter.fmRatio:
        return {
          'name': 'FM Ratio',
          'min': 0.1,
          'max': 10.0,
          'default': 1.0,
          'unit': ':1',
          'description': 'Frequency ratio between operators'
        };
      case SynthParameter.fmAmount:
        return {
          'name': 'FM Amount',
          'min': 0.0,
          'max': 2.0,
          'default': 0.5,
          'unit': '',
          'description': 'Overall FM modulation depth'
        };
      case SynthParameter.fmFeedback:
        return {
          'name': 'FM Feedback',
          'min': 0.0,
          'max': 1.0,
          'default': 0.0,
          'unit': '%',
          'description': 'Operator self-feedback amount'
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
    if (voice is! FMVoice) return;
    
    // Initialize operators for this voice
    voice.algorithmIndex = _selectedAlgorithmIndex;
    
    // Set up operator frequencies based on note
    final baseFreq = voice.frequency;
    
    // Classic FM operator ratios (can be customized)
    final operatorRatios = [1.0, 2.0, 3.0, 4.0, 5.0, 7.0];
    
    for (int i = 0; i < voice.operators.length; i++) {
      final op = voice.operators[i];
      op.frequency = operatorRatios[i] * _globalRatio;
      op.feedback = _globalFeedback;
      op.reset();
    }
  }
  
  @override
  void onNoteOff(SynthVoice voice) {
    voice.isActive = false;
  }
  
  @override
  Float32List processVoice(SynthVoice voice, int numSamples) {
    final buffer = Float32List(numSamples);
    
    if (voice is! FMVoice) return buffer;
    
    final algorithm = _algorithms[voice.algorithmIndex];
    var currentTime = DateTime.now().difference(voice.startTime).inMicroseconds / 1000000.0;
    
    for (int i = 0; i < numSamples; i++) {
      // Clear operator outputs
      voice.operatorOutputs.fillRange(0, voice.operatorOutputs.length, 0.0);
      
      // Process operators in dependency order
      for (int opIndex = numOperators - 1; opIndex >= 0; opIndex--) {
        final operator = voice.operators[opIndex];
        
        // Clear modulation inputs
        operator.modulationInputs.clear();
        
        // Apply modulation from other operators
        final connections = algorithm.connections[opIndex];
        if (connections != null) {
          for (final entry in connections.entries) {
            final modulatorIndex = entry.key;
            final modulationAmount = entry.value * _modulationDepth;
            
            if (modulatorIndex < voice.operatorOutputs.length) {
              operator.modulationInputs[modulatorIndex] = 
                voice.operatorOutputs[modulatorIndex] * modulationAmount;
            }
          }
        }
        
        // Process operator
        final output = operator.process(voice.frequency, sampleRate, 1.0 / sampleRate);
        
        // Apply envelope
        final envelopedOutput = operator.applyEnvelope(
          output, currentTime, !voice.isActive, currentTime
        );
        
        voice.operatorOutputs[opIndex] = envelopedOutput;
      }
      
      // Mix output operators
      double finalSample = 0.0;
      for (final outputIndex in algorithm.outputs) {
        if (outputIndex < voice.operatorOutputs.length) {
          finalSample += voice.operatorOutputs[outputIndex];
        }
      }
      
      // Apply voice velocity and global amplitude
      finalSample *= voice.velocity * voice.amplitude;
      
      buffer[i] = finalSample;
      currentTime += 1.0 / sampleRate;
    }
    
    return buffer;
  }
  
  @override
  Map<String, dynamic> getVisualizationData() {
    final algorithm = _algorithms[_selectedAlgorithmIndex];
    
    // Generate operator activity data
    final operatorLevels = <double>[];
    final operatorFrequencies = <double>[];
    
    for (final voice in activeVoices) {
      if (voice is FMVoice) {
        for (int i = 0; i < voice.operators.length; i++) {
          if (operatorLevels.length <= i) {
            operatorLevels.add(0.0);
            operatorFrequencies.add(0.0);
          }
          operatorLevels[i] = math.max(operatorLevels[i], voice.operators[i].amplitude);
          operatorFrequencies[i] = voice.operators[i].frequency * voice.frequency;
        }
        break; // Just use first voice for visualization
      }
    }
    
    return {
      'type': 'fm',
      'algorithmName': algorithm.name,
      'algorithmDescription': algorithm.description,
      'algorithmConnections': algorithm.connections,
      'operatorLevels': operatorLevels,
      'operatorFrequencies': operatorFrequencies,
      'globalRatio': _globalRatio,
      'globalFeedback': _globalFeedback,
      'modulationDepth': _modulationDepth,
      'voiceCount': voiceCount,
      'cpuUsage': cpuUsage,
    };
  }
  
  @override
  SynthVoice createVoice(int noteNumber, double frequency, double velocity) {
    // Create operators for the voice
    final operators = <FMOperator>[];
    for (int i = 0; i < numOperators; i++) {
      operators.add(FMOperator(
        name: 'Op ${i + 1}',
        frequency: 1.0,
        amplitude: 0.8,
        attack: getParameter(SynthParameter.envelopeAttack),
        decay: getParameter(SynthParameter.envelopeDecay),
        sustain: getParameter(SynthParameter.envelopeSustain),
        release: getParameter(SynthParameter.envelopeRelease),
      ));
    }
    
    return FMVoice(
      noteNumber: noteNumber,
      frequency: frequency,
      velocity: velocity,
      startTime: DateTime.now(),
      operators: operators,
      algorithmIndex: _selectedAlgorithmIndex,
    );
  }

  
  /// Get operator configuration for UI
  List<Map<String, dynamic>> getOperatorConfigs() {
    final configs = <Map<String, dynamic>>[];
    
    // Return default operator configuration
    for (int i = 0; i < numOperators; i++) {
      configs.add({
        'index': i,
        'name': 'Op ${i + 1}',
        'frequency': 1.0,
        'amplitude': 0.8,
        'feedback': 0.0,
        'isAdditive': _algorithms[_selectedAlgorithmIndex].outputs.contains(i),
        'attack': getParameter(SynthParameter.envelopeAttack),
        'decay': getParameter(SynthParameter.envelopeDecay),
        'sustain': getParameter(SynthParameter.envelopeSustain),
        'release': getParameter(SynthParameter.envelopeRelease),
      });
    }
    
    return configs;
  }
  
  /// Update operator parameter
  void setOperatorParameter(int operatorIndex, String parameter, double value) {
    // Update all active voices
    for (final voice in activeVoices) {
      if (voice is FMVoice && operatorIndex < voice.operators.length) {
        final operator = voice.operators[operatorIndex];
        
        switch (parameter) {
          case 'frequency':
            operator.frequency = value;
            break;
          case 'amplitude':
            operator.amplitude = value;
            break;
          case 'feedback':
            operator.feedback = value;
            break;
          case 'attack':
            operator.attack = value;
            break;
          case 'decay':
            operator.decay = value;
            break;
          case 'sustain':
            operator.sustain = value;
            break;
          case 'release':
            operator.release = value;
            break;
        }
      }
    }
    
    notifyListeners();
  }
}