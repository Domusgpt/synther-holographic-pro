/// Shared parameter definitions for all platforms
/// These IDs must match the C++ implementation for native platforms

/// Parameter IDs used by the synth engine
class SynthParameterId {
  // Master parameters
  static const int masterVolume = 0;
  static const int masterMute = 1;
  
  // Oscillator parameters
  static const int oscillatorType = 2;
  static const int oscillatorVolume = 3;
  static const int oscillatorPanning = 4;
  static const int oscillatorFineTune = 5;
  static const int oscillatorPulseWidth = 6;
  
  // Filter parameters
  static const int filterCutoff = 10;
  static const int filterResonance = 11;
  static const int filterType = 12;
  
  // Envelope parameters
  static const int attackTime = 20;
  static const int decayTime = 21;
  static const int sustainLevel = 22;
  static const int releaseTime = 23;
  
  // Effect parameters
  static const int reverbMix = 30;
  static const int delayTime = 31;
  static const int delayFeedback = 32;
  
  // Granular parameters
  static const int granularActive = 40;
  static const int granularGrainRate = 41;
  static const int granularGrainDuration = 42;
  static const int granularPosition = 43;
  static const int granularPitch = 44;
  static const int granularAmplitude = 45;
  static const int granularPositionVariation = 46;
  static const int granularPitchVariation = 47;
  static const int granularDurationVariation = 48;
  static const int granularPan = 49;
  static const int granularPanVariation = 50;
  static const int granularWindowType = 51;
  static const int granularPositionVar = 52; // Alias
  static const int granularPitchVar = 53; // Alias
  static const int granularDurationVar = 54; // Alias
  static const int granularPanVar = 55; // Alias
  
  // Wavetable parameters
  static const int wavetablePosition = 60;
  
  // Microphone parameters
  static const int microphoneVolume = 70;

  // LFO parameters (example for one LFO)
  static const int lfo1Rate = 80;
  static const int lfo1Amount = 81;
  // Add more LFOs or destinations as needed

  // Mixer parameters
  static const int oscillator1Volume = 3; // Already exists as oscillatorVolume
  static const int oscillator2Volume = 90; // Assuming a second oscillator
  static const int oscillatorMix = 91;     // Mix between Osc1 and Osc2
}

/// Oscillator types
enum OscillatorType {
  sine(0),
  square(1),
  sawtooth(2),
  triangle(3),
  noise(4),
  pulse(5),
  wavetable(6),
  granular(7);
  
  final int value;
  const OscillatorType(this.value);
}

/// Filter types
enum FilterType {
  lowPass(0),
  highPass(1),
  bandPass(2),
  notch(3);
  
  final int value;
  const FilterType(this.value);
}

/// Grain window types
enum GrainWindowType {
  rectangular(0),
  hann(1),
  hamming(2),
  blackman(3);
  
  final int value;
  const GrainWindowType(this.value);
}

/// XY Pad assignment options
enum XYPadAssignment {
  none,
  filterCutoff,
  filterResonance,
  oscillatorPitch,
  oscillatorFineTune,
  envelopeAttack,
  envelopeDecay,
  envelopeSustain,
  envelopeRelease,
  reverbMix,
  delayTime,
  delayFeedback,
  grainsRate,
  grainsDuration,
  grainsPosition,
  grainsPitch,
  grainsPan,
  wavetablePosition,
  oscillatorMix, // Added
  lfoRate,       // Added (maps to lfo1Rate for now)
  // customMidiCc, // For future MIDI CC mapping feature
}

extension XYPadAssignmentDetails on XYPadAssignment {
  String get displayName {
    switch (this) {
      case XYPadAssignment.none: return 'None';
      case XYPadAssignment.filterCutoff: return 'Filter Cutoff';
      case XYPadAssignment.filterResonance: return 'Filter Res';
      case XYPadAssignment.oscillatorPitch: return 'Osc Pitch';
      case XYPadAssignment.oscillatorFineTune: return 'Osc Fine Tune';
      case XYPadAssignment.envelopeAttack: return 'Env Attack';
      case XYPadAssignment.envelopeDecay: return 'Env Decay';
      case XYPadAssignment.envelopeSustain: return 'Env Sustain';
      case XYPadAssignment.envelopeRelease: return 'Env Release';
      case XYPadAssignment.reverbMix: return 'Reverb Mix';
      case XYPadAssignment.delayTime: return 'Delay Time';
      case XYPadAssignment.delayFeedback: return 'Delay Feedback';
      case XYPadAssignment.grainsRate: return 'Grain Rate';
      case XYPadAssignment.grainsDuration: return 'Grain Duration';
      case XYPadAssignment.grainsPosition: return 'Grain Position';
      case XYPadAssignment.grainsPitch: return 'Grain Pitch';
      case XYPadAssignment.grainsPan: return 'Grain Pan';
      case XYPadAssignment.wavetablePosition: return 'Wavetable Pos';
      case XYPadAssignment.oscillatorMix: return 'Osc Mix';
      case XYPadAssignment.lfoRate: return 'LFO 1 Rate';
      // case XYPadAssignment.customMidiCc: return 'Custom MIDI CC';
      default: return name; // Fallback to enum name
    }
  }

  // Helper to get the corresponding SynthParameterId (integer)
  // This mapping is crucial for FFI calls.
  int get parameterId {
    switch (this) {
      case XYPadAssignment.filterCutoff: return SynthParameterId.filterCutoff;
      case XYPadAssignment.filterResonance: return SynthParameterId.filterResonance;
      // case XYPadAssignment.oscillatorPitch: return SynthParameterId.oscillatorPitch; // Needs specific osc target
      case XYPadAssignment.oscillatorFineTune: return SynthParameterId.oscillatorFineTune;
      case XYPadAssignment.envelopeAttack: return SynthParameterId.attackTime;
      case XYPadAssignment.envelopeDecay: return SynthParameterId.decayTime;
      case XYPadAssignment.envelopeSustain: return SynthParameterId.sustainLevel;
      case XYPadAssignment.envelopeRelease: return SynthParameterId.releaseTime;
      case XYPadAssignment.reverbMix: return SynthParameterId.reverbMix;
      case XYPadAssignment.delayTime: return SynthParameterId.delayTime;
      case XYPadAssignment.delayFeedback: return SynthParameterId.delayFeedback;
      case XYPadAssignment.grainsRate: return SynthParameterId.granularGrainRate;
      case XYPadAssignment.grainsDuration: return SynthParameterId.granularGrainDuration;
      case XYPadAssignment.grainsPosition: return SynthParameterId.granularPosition;
      case XYPadAssignment.grainsPitch: return SynthParameterId.granularPitch;
      case XYPadAssignment.grainsPan: return SynthParameterId.granularPan;
      case XYPadAssignment.wavetablePosition: return SynthParameterId.wavetablePosition;
      case XYPadAssignment.oscillatorMix: return SynthParameterId.oscillatorMix;
      case XYPadAssignment.lfoRate: return SynthParameterId.lfo1Rate; // Maps to lfo1Rate
      // case XYPadAssignment.customMidiCc: return -1; // Or a special ID
      case XYPadAssignment.none:
      default:
        return -1; // Represents no assignment or an invalid/unmapped parameter
    }
  }
}


/// Scale types
enum ScalePreset {
  chromatic(0, 'Chromatic'),
  major(1, 'Major'),
  minor(2, 'Minor'),
  pentatonic(3, 'Pentatonic'),
  blues(4, 'Blues'),
  dorian(5, 'Dorian'),
  mixolydian(6, 'Mixolydian'),
  harmonicMinor(7, 'Harmonic Minor'),
  wholeStep(8, 'Whole Step'),
  diminished(9, 'Diminished');
  
  final int value;
  final String name;
  const ScalePreset(this.value, this.name);
}