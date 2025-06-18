// Shared music theory definitions for the synthesizer

enum MusicalScale { 
  Chromatic, 
  Major, 
  MinorNatural, 
  MinorHarmonic, 
  MinorMelodic, 
  PentatonicMajor, 
  PentatonicMinor, 
  Blues, 
  Dorian, 
  Mixolydian 
}

const List<String> rootNoteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 
  'F#', 'G', 'G#', 'A', 'A#', 'B'
];

final Map<MusicalScale, List<int>> scaleIntervals = {
  MusicalScale.Chromatic: [0,1,2,3,4,5,6,7,8,9,10,11],
  MusicalScale.Major: [0,2,4,5,7,9,11],
  MusicalScale.MinorNatural: [0,2,3,5,7,8,10],
  MusicalScale.MinorHarmonic: [0,2,3,5,7,8,11],
  MusicalScale.MinorMelodic: [0,2,3,5,7,9,11], // Ascending
  MusicalScale.PentatonicMajor: [0,2,4,7,9],
  MusicalScale.PentatonicMinor: [0,3,5,7,10],
  MusicalScale.Blues: [0,3,5,6,7,10],
  MusicalScale.Dorian: [0,2,3,5,7,9,10],
  MusicalScale.Mixolydian: [0,2,4,5,7,9,10],
};