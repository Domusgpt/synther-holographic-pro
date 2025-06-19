import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Professional Microtonal Scale System
/// 
/// Provides comprehensive support for microtonal music including:
/// - Advanced scale definitions with metadata
/// - Intelligent quantization with configurable strength
/// - Real-time harmonic analysis
/// - Visual scale representation data
/// - Historical temperament support

/// Categories of microtonal scales for organization
enum ScaleCategory {
  equalTemperament,    // 12-TET, 19-TET, 31-TET, etc.
  justIntonation,      // Pure ratios, harmonic series
  historicalTemperament, // Pythagorean, Meantone, etc.
  worldMusic,          // Maqams, Ragas, Gamelan
  experimental,        // Bohlen-Pierce, Carlos scales
  custom              // User-defined scales
}

/// Result of frequency quantization with analysis data
class QuantizationResult {
  final double originalFrequency;
  final double quantizedFrequency;
  final int scaleDegree;
  final String degreeName;
  final double centsOffset;     // How far off from scale degree
  final bool isStrongDegree;    // Is this a emphasized scale degree
  final List<int> harmonicRelations; // Other degrees that harmonize
  
  QuantizationResult({
    required this.originalFrequency,
    required this.quantizedFrequency,
    required this.scaleDegree,
    required this.degreeName,
    required this.centsOffset,
    required this.isStrongDegree,
    required this.harmonicRelations,
  });
}

/// Analysis of intervals and harmonic relationships in a scale
class ScaleAnalysis {
  final List<double> intervals;        // Intervals between adjacent degrees
  final List<double> cumulativeIntervals; // Intervals from root
  final Map<int, List<int>> consonances;  // Consonant interval pairs
  final Map<int, List<int>> dissonances;  // Dissonant interval pairs
  final double averageStepSize;        // Average interval size in cents
  final int symmetryDegree;           // Rotational symmetry (0 = none)
  
  ScaleAnalysis({
    required this.intervals,
    required this.cumulativeIntervals,
    required this.consonances,
    required this.dissonances,
    required this.averageStepSize,
    required this.symmetryDegree,
  });
}

/// Enhanced microtonal scale with comprehensive metadata
class AdvancedMicrotonalScale {
  final String name;
  final String description;
  final ScaleCategory category;
  final List<double> ratios;           // Frequency ratios
  final List<String> degreeNames;      // Names for each degree
  final List<int> strongDegrees;       // Emphasized degrees (for coloring)
  final int periodCents;               // Octave/period size in cents
  final double baseFrequency;          // Reference frequency (default A4 = 440Hz)
  final Map<String, dynamic> metadata; // Composer, origin, etc.
  final List<double>? cents;           // Explicit cent values (optional)
  
  const AdvancedMicrotonalScale({
    required this.name,
    required this.description,
    required this.category,
    required this.ratios,
    required this.degreeNames,
    this.strongDegrees = const [],
    this.periodCents = 1200,
    this.baseFrequency = 440.0,
    this.metadata = const {},
    this.cents,
  });
  
  /// Get frequency for a specific scale degree
  double getFrequency(int degree, {double? baseFreq}) {
    final base = baseFreq ?? baseFrequency;
    if (degree < 0 || degree >= ratios.length) {
      // Handle octave extensions
      final octaves = degree ~/ ratios.length;
      final normalizedDegree = degree % ratios.length;
      return base * ratios[normalizedDegree] * math.pow(2.0, octaves);
    }
    return base * ratios[degree];
  }
  
  /// Get the nearest scale degree for a given frequency
  int getNearestDegree(double frequency, {double? baseFreq}) {
    final base = baseFreq ?? baseFrequency;
    final ratio = frequency / base;
    
    // Find closest ratio
    double minDistance = double.infinity;
    int closestDegree = 0;
    
    for (int i = 0; i < ratios.length; i++) {
      final distance = (ratio - ratios[i]).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestDegree = i;
      }
    }
    
    return closestDegree;
  }
  
  /// Generate harmonic series based on fundamental degree
  List<double> getHarmonicSeries(int fundamentalDegree, int harmonics) {
    final fundamentalRatio = ratios[fundamentalDegree];
    return List.generate(harmonics, (i) => fundamentalRatio * (i + 1));
  }
  
  /// Analyze intervals and harmonic relationships
  ScaleAnalysis analyzeIntervals() {
    final intervals = <double>[];
    final cumulativeIntervals = <double>[];
    final consonances = <int, List<int>>{};
    final dissonances = <int, List<int>>{};
    
    // Calculate intervals in cents
    for (int i = 0; i < ratios.length; i++) {
      if (i > 0) {
        final intervalCents = 1200 * math.log(ratios[i] / ratios[i-1]) / math.ln2;
        intervals.add(intervalCents);
      }
      
      final cumulativeCents = 1200 * math.log(ratios[i]) / math.ln2;
      cumulativeIntervals.add(cumulativeCents);
    }
    
    // Analyze consonance/dissonance relationships
    for (int i = 0; i < ratios.length; i++) {
      consonances[i] = [];
      dissonances[i] = [];
      
      for (int j = i + 1; j < ratios.length; j++) {
        final intervalRatio = ratios[j] / ratios[i];
        if (_isConsonant(intervalRatio)) {
          consonances[i]!.add(j);
        } else {
          dissonances[i]!.add(j);
        }
      }
    }
    
    final averageStepSize = intervals.isNotEmpty 
      ? intervals.reduce((a, b) => a + b) / intervals.length 
      : 0.0;
    
    final symmetryDegree = _calculateSymmetry();
    
    return ScaleAnalysis(
      intervals: intervals,
      cumulativeIntervals: cumulativeIntervals,
      consonances: consonances,
      dissonances: dissonances,
      averageStepSize: averageStepSize,
      symmetryDegree: symmetryDegree,
    );
  }
  
  /// Check if an interval ratio is considered consonant
  bool _isConsonant(double ratio) {
    // Simple consonance check based on small integer ratios
    const consonantRatios = [
      1.0,     // Unison
      2.0,     // Octave
      1.5,     // Perfect fifth
      4.0/3.0, // Perfect fourth
      5.0/4.0, // Major third
      6.0/5.0, // Minor third
      5.0/3.0, // Major sixth
      8.0/5.0, // Minor sixth
    ];
    
    const tolerance = 0.02; // 2% tolerance
    
    for (final consonant in consonantRatios) {
      if ((ratio - consonant).abs() < tolerance) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Calculate rotational symmetry degree
  int _calculateSymmetry() {
    // Check for rotational symmetry in the scale structure
    for (int step = 1; step < ratios.length; step++) {
      bool symmetric = true;
      for (int i = 0; i < ratios.length; i++) {
        final rotatedIndex = (i + step) % ratios.length;
        final originalInterval = i > 0 ? ratios[i] / ratios[i-1] : ratios[0];
        final rotatedInterval = rotatedIndex > 0 
          ? ratios[rotatedIndex] / ratios[rotatedIndex-1] 
          : ratios[0];
        
        if ((originalInterval - rotatedInterval).abs() > 0.01) {
          symmetric = false;
          break;
        }
      }
      if (symmetric) return step;
    }
    return 0; // No symmetry
  }
  
  /// Convert to simple MicrotonalScale for backward compatibility
  MicrotonalScale toSimpleScale() {
    return MicrotonalScale(name, ratios, periodCents);
  }
}

/// Intelligent quantization engine for microtonal scales
class ScaleQuantizer extends ChangeNotifier {
  AdvancedMicrotonalScale _currentScale;
  double _quantizationStrength = 1.0; // 0.0 = off, 1.0 = full snap
  double _baseFrequency = 440.0;
  bool _visualFeedbackEnabled = true;
  
  ScaleQuantizer({
    AdvancedMicrotonalScale? initialScale,
    double quantizationStrength = 1.0,
    double baseFrequency = 440.0,
  }) : _currentScale = initialScale ?? MicrotonalScaleLibrary.standard12TET,
       _quantizationStrength = quantizationStrength,
       _baseFrequency = baseFrequency;
  
  // Getters
  AdvancedMicrotonalScale get currentScale => _currentScale;
  double get quantizationStrength => _quantizationStrength;
  double get baseFrequency => _baseFrequency;
  bool get visualFeedbackEnabled => _visualFeedbackEnabled;
  
  /// Set the current scale with notification
  void setScale(AdvancedMicrotonalScale scale) {
    if (_currentScale != scale) {
      _currentScale = scale;
      notifyListeners();
    }
  }
  
  /// Set quantization strength (0.0 = off, 1.0 = full snap)
  void setQuantizationStrength(double strength) {
    final clampedStrength = strength.clamp(0.0, 1.0);
    if (_quantizationStrength != clampedStrength) {
      _quantizationStrength = clampedStrength;
      notifyListeners();
    }
  }
  
  /// Set base frequency (reference pitch)
  void setBaseFrequency(double frequency) {
    if (_baseFrequency != frequency && frequency > 0) {
      _baseFrequency = frequency;
      notifyListeners();
    }
  }
  
  /// Enable/disable visual feedback for quantization
  void setVisualFeedback(bool enabled) {
    if (_visualFeedbackEnabled != enabled) {
      _visualFeedbackEnabled = enabled;
      notifyListeners();
    }
  }
  
  /// Quantize a frequency to the current scale
  double quantizeFrequency(double inputFrequency) {
    if (_quantizationStrength == 0.0) {
      return inputFrequency; // No quantization
    }
    
    final nearestDegree = _currentScale.getNearestDegree(inputFrequency, baseFreq: _baseFrequency);
    final quantizedFreq = _currentScale.getFrequency(nearestDegree, baseFreq: _baseFrequency);
    
    // Interpolate between original and quantized based on strength
    return inputFrequency + (quantizedFreq - inputFrequency) * _quantizationStrength;
  }
  
  /// Quantize a MIDI note number to the current scale
  int quantizeMidiNote(int midiNote) {
    final frequency = 440.0 * math.pow(2.0, (midiNote - 69) / 12.0);
    final quantizedFreq = quantizeFrequency(frequency);
    return (69 + 12 * math.log(quantizedFreq / 440.0) / math.ln2).round();
  }
  
  /// Get detailed quantization information
  QuantizationResult getQuantizationInfo(double inputFrequency) {
    final nearestDegree = _currentScale.getNearestDegree(inputFrequency, baseFreq: _baseFrequency);
    final quantizedFreq = _currentScale.getFrequency(nearestDegree, baseFreq: _baseFrequency);
    
    final centsOffset = 1200 * math.log(inputFrequency / quantizedFreq) / math.ln2;
    final degreeName = nearestDegree < _currentScale.degreeNames.length 
      ? _currentScale.degreeNames[nearestDegree] 
      : nearestDegree.toString();
    
    final isStrongDegree = _currentScale.strongDegrees.contains(nearestDegree);
    
    // Find harmonic relations (simple implementation)
    final harmonicRelations = <int>[];
    final analysis = _currentScale.analyzeIntervals();
    if (analysis.consonances.containsKey(nearestDegree)) {
      harmonicRelations.addAll(analysis.consonances[nearestDegree]!);
    }
    
    return QuantizationResult(
      originalFrequency: inputFrequency,
      quantizedFrequency: quantizedFreq,
      scaleDegree: nearestDegree,
      degreeName: degreeName,
      centsOffset: centsOffset,
      isStrongDegree: isStrongDegree,
      harmonicRelations: harmonicRelations,
    );
  }
}

/// Comprehensive library of microtonal scales
class MicrotonalScaleLibrary {
  // Equal Temperament Scales
  static const standard12TET = AdvancedMicrotonalScale(
    name: '12-TET',
    description: 'Standard 12-tone equal temperament',
    category: ScaleCategory.equalTemperament,
    ratios: [1.0, 1.0595, 1.1225, 1.1892, 1.2599, 1.3348, 1.4142, 1.4983, 1.5874, 1.6818, 1.7818, 1.8877],
    degreeNames: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'],
    strongDegrees: [0, 2, 4, 5, 7, 9, 11], // Natural notes
    metadata: {'origin': 'Western music standard', 'year': '18th century'},
  );
  
  static const edo19 = AdvancedMicrotonalScale(
    name: '19-TET',
    description: '19-tone equal temperament',
    category: ScaleCategory.equalTemperament,
    ratios: [1.0, 1.0376, 1.0765, 1.1168, 1.1585, 1.2019, 1.2469, 1.2936, 1.3421, 1.3925, 1.4448, 1.4992, 1.5556, 1.6143, 1.6751, 1.7383, 1.8038, 1.8717, 1.9422],
    degreeNames: ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18'],
    strongDegrees: [0, 3, 6, 9, 12, 15, 18], // Approximate major scale degrees
    metadata: {'composer': 'Various', 'characteristics': 'Good for chromatic music'},
  );
  
  static final edo31 = AdvancedMicrotonalScale(
    name: '31-TET',
    description: '31-tone equal temperament',
    category: ScaleCategory.equalTemperament,
    ratios: _generateEDORatios(31),
    degreeNames: _generateNumberedDegrees(31),
    strongDegrees: const [0, 5, 10, 13, 18, 23, 28], // Approximate diatonic degrees
    metadata: const {'characteristics': 'Excellent approximation of just intonation'},
  );
  
  // Just Intonation Scales
  static const justMajor = AdvancedMicrotonalScale(
    name: 'Just Major',
    description: 'Major scale in just intonation (5-limit)',
    category: ScaleCategory.justIntonation,
    ratios: [1.0, 9.0/8.0, 5.0/4.0, 4.0/3.0, 3.0/2.0, 5.0/3.0, 15.0/8.0],
    degreeNames: ['C', 'D', 'E', 'F', 'G', 'A', 'B'],
    strongDegrees: [0, 2, 4, 6], // Tonic, third, fifth, seventh
    metadata: {'limit': '5-limit', 'origin': 'Natural harmonic ratios'},
  );
  
  static final harmonic16 = AdvancedMicrotonalScale(
    name: 'Harmonic 16',
    description: 'First 16 harmonics',
    category: ScaleCategory.justIntonation,
    ratios: List.generate(16, (i) => (i + 1).toDouble()),
    degreeNames: List.generate(16, (i) => 'H${i + 1}'),
    strongDegrees: const [0, 1, 3, 7, 15], // Powers of 2
    metadata: const {'origin': 'Natural harmonic series'},
  );
  
  // Historical Temperaments
  static const pythagorean = AdvancedMicrotonalScale(
    name: 'Pythagorean',
    description: 'Pythagorean tuning based on perfect fifths',
    category: ScaleCategory.historicalTemperament,
    ratios: [1.0, 256.0/243.0, 9.0/8.0, 32.0/27.0, 81.0/64.0, 4.0/3.0, 729.0/512.0, 3.0/2.0, 128.0/81.0, 27.0/16.0, 16.0/9.0, 243.0/128.0],
    degreeNames: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'],
    strongDegrees: [0, 2, 4, 5, 7, 9, 11],
    metadata: {'origin': 'Ancient Greece', 'method': 'Chain of perfect fifths'},
  );
  
  // Experimental Scales
  static const bohlenPierce = AdvancedMicrotonalScale(
    name: 'Bohlen-Pierce',
    description: 'Non-octave scale based on tritave (3:1)',
    category: ScaleCategory.experimental,
    ratios: [1.0, 25.0/21.0, 9.0/7.0, 7.0/5.0, 5.0/3.0, 9.0/5.0, 49.0/25.0, 7.0/3.0, 25.0/9.0],
    degreeNames: ['0', '1', '2', '3', '4', '5', '6', '7', '8'],
    strongDegrees: [0, 2, 4, 6, 8],
    periodCents: 1902, // Tritave instead of octave
    metadata: {'composers': 'Heinz Bohlen, Kees van Prooijen, John Pierce'},
  );
  
  /// Generate ratios for equal division of octave
  static List<double> _generateEDORatios(int divisions) {
    return List.generate(divisions, (i) => math.pow(2.0, i / divisions).toDouble());
  }
  
  /// Generate numbered degree names
  static List<String> _generateNumberedDegrees(int count) {
    return List.generate(count, (i) => i.toString());
  }
  
  /// Get all available scales
  static List<AdvancedMicrotonalScale> getAllScales() {
    return [
      standard12TET,
      edo19,
      edo31,
      justMajor,
      harmonic16,
      pythagorean,
      bohlenPierce,
    ];
  }
  
  /// Get scales by category
  static List<AdvancedMicrotonalScale> getScalesByCategory(ScaleCategory category) {
    return getAllScales().where((scale) => scale.category == category).toList();
  }
}

/// Backward compatibility with existing MicrotonalScale class
class MicrotonalScale {
  final String name;
  final List<double> ratios;
  final int periodCents;
  
  const MicrotonalScale(this.name, this.ratios, this.periodCents);
  
  const MicrotonalScale.standard12TET() 
    : name = '12-TET',
      ratios = const [1.0, 1.0595, 1.1225, 1.1892, 1.2599, 1.3348, 1.4142, 1.4983, 1.5874, 1.6818, 1.7818, 1.8877],
      periodCents = 1200;
  
  const MicrotonalScale.edo19() 
    : name = '19-TET',
      ratios = const [1.0, 1.0376, 1.0765, 1.1168, 1.1585, 1.2019, 1.2469, 1.2936, 1.3421, 1.3925, 1.4448, 1.4992, 1.5556, 1.6143, 1.6751, 1.7383, 1.8038, 1.8717, 1.9422],
      periodCents = 1200;
  
  const MicrotonalScale.edo31() 
    : name = '31-TET',
      ratios = const [], // Would contain 31 ratios
      periodCents = 1200;
  
  /// Convert to AdvancedMicrotonalScale
  AdvancedMicrotonalScale toAdvancedScale() {
    return AdvancedMicrotonalScale(
      name: name,
      description: 'Converted from simple scale',
      category: ScaleCategory.custom,
      ratios: ratios,
      degreeNames: List.generate(ratios.length, (i) => i.toString()),
    );
  }
}