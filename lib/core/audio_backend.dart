// Abstract audio backend interface for cross-platform audio synthesis
abstract class AudioBackend {
  bool get isInitialized;
  
  Future<void> initialize();
  Future<void> dispose();
  
  // Parameter control
  void setParameter(String parameterId, double value);
  
  // Note control
  void noteOn(int midiNote, double velocity);
  void noteOff(int midiNote);
  void allNotesOff();
  
  // Engine control
  void start();
  void stop();
}

// Audio parameter identifiers for the backend
class AudioParameters {
  static const String masterVolume = 'master_volume';
  static const String filterCutoff = 'filter_cutoff';
  static const String filterResonance = 'filter_resonance';
  static const String attack = 'attack';
  static const String decay = 'decay';
  static const String sustain = 'sustain';
  static const String release = 'release';
  static const String reverbMix = 'reverb_mix';
  static const String delayTime = 'delay_time';
  static const String delayFeedback = 'delay_feedback';
}

// Parameter IDs are now defined in parameter_definitions.dart