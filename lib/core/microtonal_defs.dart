import 'dart:math'; // For log

class MicrotonalScale {
  final String id;
  final String name;
  // List of cents for each degree from the root.
  // Example for 12-TET: [0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100]
  final List<double> ratios; // Field name is 'ratios', but stores cents.
  final String description;
  final int notesPerOctave;

  const MicrotonalScale({
    required this.id,
    required this.name,
    required this.ratios,
    this.description = '',
  }) : notesPerOctave = ratios.length;

  static final MicrotonalScale tet12 = MicrotonalScale(
    id: 'tet12',
    name: '12-TET Chromatic',
    ratios: List.generate(12, (i) => i * 100.0),
    description: 'Standard 12-tone equal temperament.',
  );

  static final MicrotonalScale tet19 = MicrotonalScale(
    id: 'tet19',
    name: '19-TET',
    ratios: List.generate(19, (i) => i * (1200.0 / 19.0)),
    description: '19-tone equal temperament.',
  );

  static final MicrotonalScale justMajor = MicrotonalScale(
    id: 'justMajor',
    name: 'Just Intonation Major (approx)',
    ratios: [
      0.0, // C (Unison)
      1200 * (log(9/8) / log(2)),   // D (203.91 cents)
      1200 * (log(5/4) / log(2)),   // E (386.31 cents)
      1200 * (log(4/3) / log(2)),   // F (498.04 cents)
      1200 * (log(3/2) / log(2)),   // G (701.96 cents)
      1200 * (log(5/3) / log(2)),   // A (884.36 cents)
      1200 * (log(15/8) / log(2)),  // B (1088.27 cents)
    ],
    description: 'Diatonic scale based on pure harmonic ratios for major intervals.',
  );

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
