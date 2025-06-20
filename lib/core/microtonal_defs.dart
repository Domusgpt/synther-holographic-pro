import 'dart:math'; // For pow, though not used if ratios are cents

class MicrotonalScale {
  final String id;
  final String name;
  /// List of cents for each degree from the root.
  /// Example for 12-TET: [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100]
  final List<double> ratios; // Using 'ratios' as field name, but storing cents.
  final String description;
  final int notesPerOctave; // Number of notes in one octave, defines the length of 'ratios'

  const MicrotonalScale({
    required this.id,
    required this.name,
    required this.ratios,
    this.description = '',
  }) : notesPerOctave = ratios.length;

  // Example scales
  static final MicrotonalScale tet12 = MicrotonalScale(
    id: 'tet12',
    name: '12-TET Chromatic',
    ratios: List.generate(12, (i) => i * 100.0), // 0, 100, 200, ..., 1100 cents
    description: 'Standard 12-tone equal temperament.',
  );

  static final MicrotonalScale tet19 = MicrotonalScale(
    id: 'tet19',
    name: '19-TET',
    ratios: List.generate(19, (i) => i * (1200.0 / 19.0)), // Cents for 19-TET
    description: '19-tone equal temperament.',
  );

  static final MicrotonalScale justMajor = MicrotonalScale(
    id: 'justMajor',
    name: 'Just Intonation Major',
    // Cents: 0 (C), 203.9 (D), 386.3 (E), 498.0 (F), 702.0 (G), 884.4 (A), 1088.3 (B)
    // These are approximations. For ratios: 1/1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8
    // Converting ratios to cents: 1200 * log2(ratio)
    ratios: [
      0.0, // C (Unison)
      1200 * (math.log(9/8) / math.log(2)), // D (Major Second)
      1200 * (math.log(5/4) / math.log(2)), // E (Major Third)
      1200 * (math.log(4/3) / math.log(2)), // F (Perfect Fourth)
      1200 * (math.log(3/2) / math.log(2)), // G (Perfect Fifth)
      1200 * (math.log(5/3) / math.log(2)), // A (Major Sixth)
      1200 * (math.log(15/8) / math.log(2)), // B (Major Seventh)
    ],
    description: 'Diatonic scale based on pure harmonic ratios for major intervals.',
  );

  // Add more scales as needed...
  static List<MicrotonalScale> get availableScales => [
    tet12,
    tet19,
    justMajor,
  ];

  @override
  String toString() {
    return 'MicrotonalScale(id: $id, name: $name, notes: $notesPerOctave)';
  }
}
