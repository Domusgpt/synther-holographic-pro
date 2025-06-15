import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../holographic/holographic_widget.dart';
import '../holographic/holographic_theme.dart';

/// Assignments for XY pad axes
enum XYPadAssignment {
  filterCutoff('Filter Cutoff'),
  filterResonance('Filter Resonance'),
  oscillatorMix('Oscillator Mix'),
  reverbMix('Reverb Mix'),
  delayTime('Delay Time'),
  lfoRate('LFO Rate'),
  customMidiCC('Custom MIDI CC'),
  pitch('Pitch (X-Axis Quantized)'), // For X-axis pitch control
  lfoDepth('LFO Depth'),
  delayFeedback('Delay Feedback'),
  distortionAmount('Distortion'),
  panPosition('Pan Position'),
  granularDensity('Grain Density'),
  granularSpeed('Grain Speed');
  
  const XYPadAssignment(this.displayName);
  final String displayName;
}

/// Chromatic notes for scale selection
enum ChromaticNote {
  c('C'), cSharp('C#'), d('D'), dSharp('D#'), e('E'), f('F'),
  fSharp('F#'), g('G'), gSharp('G#'), a('A'), aSharp('A#'), b('B');
  
  const ChromaticNote(this.displayName);
  final String displayName;
}

/// Scale types for musical mapping
enum ScaleType {
  chromatic('Chromatic'),
  major('Major'),
  minor('Minor'),
  pentatonic('Pentatonic'),
  blues('Blues'),
  dorian('Dorian'),
  mixolydian('Mixolydian');
  
  const ScaleType(this.displayName);
  final String displayName;
}

/// A holographic XY pad widget for versatile multi-parameter control and musical input.
///
/// Features:
/// - **Assignable Axes:** X and Y axes can be independently assigned to various synthesizer
///   parameters (e.g., filter cutoff, LFO rate, reverb mix) or custom MIDI CCs.
///   The Y-axis typically controls a continuous parameter.
/// - **X-Axis Quantized Pitch:** The X-axis can be configured for musically quantized pitch output.
///   Users can select a root note ([ChromaticNote]) and a scale ([ScaleType]) (e.g., Major, Minor, Pentatonic).
///   The `onPitchChanged` callback provides the calculated MIDI note (0-127).
///   The visual display updates to show the current note name (e.g., "C#4").
/// - **Dynamic Sizing:** The widget can expand on interaction and contract after a period of inactivity,
///   managed via `onInteractionStart` and `onInteractionEnd` callbacks.
/// - **Advanced Visual Feedback:**
///   - **Energy Trail:** A trail of fading particles follows touch movements.
///   - **Touch Point Animation:** The touch point indicator pulses during drag.
///   - **Reactive Grid:** The background grid subtly warps or changes intensity near the touch point.
/// - **MIDI CC Input:** When an axis is assigned to `XYPadAssignment.customMidiCC`, a TextField appears
///   for users to input the desired MIDI CC number.
/// - **Musical Mapping Controls:** Dropdowns allow selection of root note and scale type for pitch quantization.
class HolographicXYPad extends StatefulWidget {
  final double x;
  final double y;
  final ValueChanged<Offset> onPositionChanged;
  final XYPadAssignment xAssignment;
  final XYPadAssignment yAssignment;
  final ChromaticNote rootNote;
  final ScaleType scaleType;
  final int customMidiCCX;
  final int customMidiCCY;
  final ValueChanged<XYPadAssignment>? onXAssignmentChanged;
  final ValueChanged<XYPadAssignment>? onYAssignmentChanged;
  final ValueChanged<ChromaticNote>? onRootNoteChanged;
  final ValueChanged<ScaleType>? onScaleTypeChanged;
  final ValueChanged<int>? onCustomMidiCCXChanged;
  final ValueChanged<int>? onCustomMidiCCYChanged;
  final ValueChanged<int>? onPitchChanged;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final Color energyColor;
  
  /// Creates a HolographicXYPad.
  ///
  /// Parameters:
  /// - [x], [y]: Initial normalized position (0.0-1.0) of the touch point.
  /// - [onPositionChanged]: Callback providing the raw normalized `Offset(x, y)` on drag.
  /// - [xAssignment], [yAssignment]: Initial parameter assignments for X and Y axes.
  ///   See [XYPadAssignment] for available options, including new effect assignments.
  /// - [rootNote], [scaleType]: Used when X-axis is assigned to pitch, for musical quantization.
  /// - [customMidiCCX], [customMidiCCY]: Initial MIDI CC numbers if 'Custom MIDI CC' is selected for an axis.
  ///   Editable via TextFields that appear when `XYPadAssignment.customMidiCC` is active.
  /// - [onXAssignmentChanged], [onYAssignmentChanged]: Callbacks for axis assignment changes.
  /// - [onRootNoteChanged], [onScaleTypeChanged]: Callbacks for musical mapping changes.
  /// - [onCustomMidiCCXChanged], [onCustomMidiCCYChanged]: Callbacks triggered when a user submits
  ///   a new MIDI CC number via the respective TextField.
  /// - [onPitchChanged]: Callback triggered when the X-axis (if assigned to `XYPadAssignment.pitch`)
  ///   calculates a new MIDI note due to position change. Provides `int midiNote`.
  /// - [onInteractionStart]: Callback invoked when the user begins interacting with the pad (e.g., tap down, pan start).
  ///   Used to trigger expansion if the pad is dynamically sized by its parent.
  /// - [onInteractionEnd]: Callback invoked after a delay when the user stops interacting.
  ///   Used to trigger contraction if the pad is dynamically sized.
  /// - [energyColor]: The primary color theme for the widget's holographic effects.
  const HolographicXYPad({
    Key? key,
    required this.x,
    required this.y,
    required this.onPositionChanged,
    this.xAssignment = XYPadAssignment.filterCutoff,
    this.yAssignment = XYPadAssignment.filterResonance,
    this.rootNote = ChromaticNote.c,
    this.scaleType = ScaleType.chromatic,
    this.customMidiCCX = 1,
    this.customMidiCCY = 2,
    this.onXAssignmentChanged,
    this.onYAssignmentChanged,
    this.onRootNoteChanged,
    this.onScaleTypeChanged,
    this.onCustomMidiCCXChanged,
    this.onCustomMidiCCYChanged,
    this.onPitchChanged,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.energyColor = HolographicTheme.primaryEnergy,
  }) : super(key: key);
  
  @override
  State<HolographicXYPad> createState() => _HolographicXYPadState();
}

class _HolographicXYPadState extends State<HolographicXYPad>
    with TickerProviderStateMixin {
  
  late AnimationController _touchController;
  late Animation<double> _touchAnimation;
  
  bool _isDragging = false;
  Offset _touchPosition = Offset.zero;
  List<Offset> _energyTrail = [];
  
  // Controllers for MIDI CC TextFields
  late TextEditingController _midiCCXController;
  late TextEditingController _midiCCYController;

  Timer? _compactTimer; // Timer for contracting the widget
  int _lastSentMidiNote = -1; // To avoid redundant pitch changed calls
  String _currentNoteNameDisplay = ""; // For displaying the current note

  static const Map<ScaleType, List<int>> scaleIntervals = {
    ScaleType.chromatic: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    ScaleType.major: [0, 2, 4, 5, 7, 9, 11],
    ScaleType.minor: [0, 2, 3, 5, 7, 8, 10],
    ScaleType.pentatonic: [0, 2, 4, 7, 9], // Assuming Major Pentatonic
    ScaleType.blues: [0, 3, 5, 6, 7, 10],
    ScaleType.dorian: [0, 2, 3, 5, 7, 9, 10],
    ScaleType.mixolydian: [0, 2, 4, 5, 7, 9, 10],
  };

  static const List<String> noteNamesWithSharps = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  static const List<String> noteNamesWithFlats = ['C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B'];


  @override
  void initState() {
    super.initState();
    
    _touchController = AnimationController(
      duration: const Duration(milliseconds: 500), // Duration for one pulse cycle
      vsync: this,
    );
    _touchAnimation = Tween<double>(begin: 1.0, end: 1.5).animate( // Scale from 1.0 to 1.5
      CurvedAnimation(parent: _touchController, curve: Curves.easeInOut),
    );
    
    _touchPosition = Offset(widget.x, widget.y);
    _updateCurrentNoteNameDisplay();


    _midiCCXController = TextEditingController(text: widget.customMidiCCX.toString());
    _midiCCYController = TextEditingController(text: widget.customMidiCCY.toString());
  }
  
  @override
  void dispose() {
    _touchController.dispose();
    _midiCCXController.dispose();
    _midiCCYController.dispose();
    _compactTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }
  
  void _handleInteractionStart() {
    _compactTimer?.cancel(); // Cancel any pending contraction
    widget.onInteractionStart?.call();
  }

  void _handleInteractionEnd() {
    _compactTimer?.cancel();
    _compactTimer = Timer(const Duration(seconds: 3), () { // 3-second delay
      widget.onInteractionEnd?.call();
    });
  }

  void _onPanStart(DragStartDetails details) {
    _handleInteractionStart();
    setState(() {
      _isDragging = true;
      _energyTrail.clear();
      _touchController.repeat(reverse: true); // Start pulsing
    });
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final size = box.size;
    
    final x = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final y = (localPosition.dy / size.height).clamp(0.0, 1.0);
    
    setState(() {
      _touchPosition = Offset(x, y);
      
      // Add to energy trail
      _energyTrail.add(Offset(x, y));
      if (_energyTrail.length > 20) {
        _energyTrail.removeAt(0);
      }
    });
    
    widget.onPositionChanged(Offset(x, y));

    if (widget.xAssignment == XYPadAssignment.pitch) {
      _handlePitchChange(x);
    }
  }
  
  void _handlePitchChange(double normalizedX) {
    final newMidiNote = _calculateMidiNote(
        normalizedX, widget.rootNote, widget.scaleType, 60); // Assuming C4 = 60
    if (newMidiNote != _lastSentMidiNote) {
      widget.onPitchChanged?.call(newMidiNote);
      _lastSentMidiNote = newMidiNote;
      _updateCurrentNoteNameDisplay(midiNote: newMidiNote);
    }
  }

  String _midiNoteToName(int midiNote) {
    if (midiNote < 0 || midiNote > 127) return "";
    final octave = (midiNote ~/ 12) - 1; // MIDI C4 is 60, so octave 4. -1 to make C0 octave 0.
    final noteIndex = midiNote % 12;

    // Basic preference for sharps, could be made smarter based on key signature
    return noteNamesWithSharps[noteIndex] + octave.toString();
  }

  void _updateCurrentNoteNameDisplay({int? midiNote}) {
    if (widget.xAssignment == XYPadAssignment.pitch) {
      final noteToDisplay = midiNote ?? _lastSentMidiNote;
      if (noteToDisplay != -1) {
        setState(() {
          _currentNoteNameDisplay = _midiNoteToName(noteToDisplay);
        });
      } else {
         // If no note sent yet, calculate initial note for display based on current X
        final initialNote = _calculateMidiNote(_touchPosition.dx, widget.rootNote, widget.scaleType, 60);
        setState(() {
           _currentNoteNameDisplay = _midiNoteToName(initialNote);
        });
      }
    } else {
      setState(() {
        _currentNoteNameDisplay = ""; // Clear if X-axis is not pitch
      });
    }
  }

  int _calculateMidiNote(double normalizedX, ChromaticNote rootNoteEnum, ScaleType scaleTypeEnum, int baseMidiOctaveC4) {
    final List<int> intervals = scaleIntervals[scaleTypeEnum] ?? scaleIntervals[ScaleType.chromatic]!;
    final int rootNoteOffset = rootNoteEnum.index; // C=0, C#=1, etc.

    final int pitchRangeInNotes = 2 * intervals.length; // e.g., 2 octaves of the selected scale

    int noteIndexInScaleRange = (normalizedX * pitchRangeInNotes).floor();
    noteIndexInScaleRange = noteIndexInScaleRange.clamp(0, pitchRangeInNotes -1);

    final int octaveOffset = noteIndexInScaleRange ~/ intervals.length;
    final int noteInScale = intervals[noteIndexInScaleRange % intervals.length];

    int midiNote = baseMidiOctaveC4 + rootNoteOffset + (octaveOffset * 12) + noteInScale;

    return midiNote.clamp(0, 127);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    // Stop pulsing and settle to normal size
    _touchController.stop();
    _touchController.animateTo(0.0, duration: Duration(milliseconds: 150), curve: Curves.easeOut);
    
    _handleInteractionEnd(); // Start timer to contract

    // Fade out energy trail (this existing logic is fine)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _energyTrail.clear();
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return HolographicWidget(
      title: 'XY PAD',
      energyColor: widget.energyColor,
      minWidth: 250,
      minHeight: 300,
      child: Column(
        children: [
          // Control dropdowns
          _buildControlPanel(),
          
          // XY pad area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: _buildXYPadArea(),
            ),
          ),
          
          // Value display
          _buildValueDisplay(),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Parameter assignments
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'X-AXIS',
                      style: HolographicTheme.createHolographicText(
                        energyColor: widget.energyColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    HolographicDropdown<XYPadAssignment>(
                      value: widget.xAssignment,
                      hint: 'X Parameter',
                      energyColor: widget.energyColor,
                      items: XYPadAssignment.values.map((assignment) {
                        return DropdownMenuItem(
                          value: assignment,
                          child: Text(
                            assignment.displayName,
                            style: HolographicTheme.createHolographicText(
                              energyColor: widget.energyColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onXAssignmentChanged?.call(value);
                          _updateCurrentNoteNameDisplay(); // Update display if X-axis assignment changes
                          setState(() {});
                        }
                      },
                    ),
                    if (widget.xAssignment == XYPadAssignment.customMidiCC)
                      _buildMidiCCTextField(_midiCCXController, widget.onCustomMidiCCXChanged),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Y-AXIS',
                      style: HolographicTheme.createHolographicText(
                        energyColor: widget.energyColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    HolographicDropdown<XYPadAssignment>(
                      value: widget.yAssignment,
                      hint: 'Y Parameter',
                      energyColor: widget.energyColor,
                      items: XYPadAssignment.values.map((assignment) {
                        return DropdownMenuItem(
                          value: assignment,
                          child: Text(
                            assignment.displayName,
                            style: HolographicTheme.createHolographicText(
                              energyColor: widget.energyColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onYAssignmentChanged?.call(value);
                           setState(() {}); // Rebuild to show/hide TextField
                        }
                      },
                    ),
                     if (widget.yAssignment == XYPadAssignment.customMidiCC)
                      _buildMidiCCTextField(_midiCCYController, widget.onCustomMidiCCYChanged),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Musical mapping
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROOT NOTE',
                      style: HolographicTheme.createHolographicText(
                        energyColor: widget.energyColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    HolographicDropdown<ChromaticNote>(
                      value: widget.rootNote,
                      hint: 'Root',
                      energyColor: widget.energyColor,
                      items: ChromaticNote.values.map((note) {
                        return DropdownMenuItem(
                          value: note,
                          child: Text(
                            note.displayName,
                            style: HolographicTheme.createHolographicText(
                              energyColor: widget.energyColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onRootNoteChanged?.call(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SCALE',
                      style: HolographicTheme.createHolographicText(
                        energyColor: widget.energyColor,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    HolographicDropdown<ScaleType>(
                      value: widget.scaleType,
                      hint: 'Scale',
                      energyColor: widget.energyColor,
                      items: ScaleType.values.map((scale) {
                        return DropdownMenuItem(
                          value: scale,
                          child: Text(
                            scale.displayName,
                            style: HolographicTheme.createHolographicText(
                              energyColor: widget.energyColor,
                              fontSize: 11,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          widget.onScaleTypeChanged?.call(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMidiCCTextField(TextEditingController controller, ValueChanged<int>? onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: SizedBox(
        height: 30, // Small height for the text field
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: HolographicTheme.createHolographicText(
            energyColor: widget.energyColor,
            fontSize: 11,
          ),
          decoration: InputDecoration(
            hintText: 'CC #',
            hintStyle: HolographicTheme.createHolographicText(
              energyColor: widget.energyColor.withOpacity(0.5),
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: widget.energyColor.withOpacity(0.7), width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: widget.energyColor.withOpacity(0.7), width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: widget.energyColor, width: 1),
            ),
            filled: true,
            fillColor: widget.energyColor.withOpacity(HolographicTheme.widgetTransparency * 0.3),
          ),
          onSubmitted: (value) {
            final cc = int.tryParse(value);
            if (cc != null) {
              onChanged?.call(cc);
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildXYPadArea() {
    return GestureDetector(
      onTapDown: (_) => _handleInteractionStart(), // Expand on tap down too
      onTapUp: (_) => _handleInteractionEnd(),     // Start contraction timer on tap up
      onPanStart: _onPanStart, // Already calls _handleInteractionStart
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,     // Already calls _handleInteractionEnd
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Transparent center - visualizer shows through
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.energyColor.withOpacity(0.6),
            width: 2.0,
          ),
        ),
        child: Stack(
          children: [
            // Grid overlay (subtle)
            CustomPaint(
              painter: _XYPadGridPainter(
                energyColor: widget.energyColor,
                opacity: 0.2, // Base opacity
                touchX: _touchPosition.dx, // Pass normalized touch X
                touchY: _touchPosition.dy, // Pass normalized touch Y
                isDragging: _isDragging,   // Pass dragging state
              ),
              size: Size.infinite,
            ),
            
            // Energy trail
            CustomPaint(
              painter: _EnergyTrailPainter(
                trail: _energyTrail,
                energyColor: widget.energyColor,
              ),
              size: Size.infinite,
            ),
            
            // Touch point
            Positioned(
              // Calculate position based on parent's size after layout
              left: _touchPosition.dx * (context.size?.width ?? 0) - 12,
              top: _touchPosition.dy * (context.size?.height ?? 0) - 12,
              child: ScaleTransition(
                scale: _touchAnimation,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.energyColor.withOpacity(0.4), // Slightly more opaque
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.energyColor,
                      width: 2.0,
                    ),
                    boxShadow: [
                      HolographicTheme.createEnergyGlow(
                        color: widget.energyColor,
                        intensity: 1.5, // Consistent intensity, pulse comes from scale
                        radius: 12.0,  // Consistent radius
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Axis labels
            Positioned(
              bottom: 8,
              left: 8,
              child: Text(
                widget.xAssignment.displayName,
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor.withOpacity(0.8),
                  fontSize: 10,
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  widget.yAssignment.displayName,
                  style: HolographicTheme.createHolographicText(
                    energyColor: widget.energyColor.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildValueDisplay() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (widget.xAssignment == XYPadAssignment.pitch && _currentNoteNameDisplay.isNotEmpty)
                  ? _currentNoteNameDisplay
                  : 'X: ${(_touchPosition.dx * 100).toInt()}%',
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor,
                  fontSize: 12,
                ),
              ),
              Text(
                 (widget.xAssignment == XYPadAssignment.pitch)
                   ? "${widget.rootNote.displayName} ${widget.scaleType.displayName}"
                   : widget.rootNote.displayName, // Fallback or different display if needed
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Y: ${(_touchPosition.dy * 100).toInt()}%',
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor,
                  fontSize: 12,
                ),
              ),
              Text(
                widget.scaleType.displayName,
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Custom painter for XY pad grid
class _XYPadGridPainter extends CustomPainter {
  final Color energyColor;
  final double opacity;
  final double? touchX; // Normalized touch X (0-1)
  final double? touchY; // Normalized touch Y (0-1)
  final bool isDragging;

  _XYPadGridPainter({
    required this.energyColor,
    required this.opacity,
    this.touchX,
    this.touchY,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = energyColor.withOpacity(opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final int gridCount = 8;
    final double maxInfluenceRadius = size.width * 0.3; // How far the touch effect reaches

    for (int i = 1; i < gridCount; i++) {
      final double lineX = size.width * i / gridCount;
      final double lineY = size.height * i / gridCount;

      // Vertical lines
      double currentOpacity = opacity;
      double currentStrokeWidth = 0.5;

      if (isDragging && touchX != null) {
        final double actualTouchX = touchX! * size.width;
        final double distanceToLine = (lineX - actualTouchX).abs();
        if (distanceToLine < maxInfluenceRadius) {
          final double influence = 1.0 - (distanceToLine / maxInfluenceRadius);
          currentOpacity = (opacity + influence * 0.3).clamp(opacity, 0.5);
          currentStrokeWidth = (0.5 + influence * 0.7).clamp(0.5, 1.2);
        }
      }
      final vLinePaint = Paint()
        ..color = energyColor.withOpacity(currentOpacity)
        ..strokeWidth = currentStrokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(lineX, 0), Offset(lineX, size.height), vLinePaint);

      // Horizontal lines
      currentOpacity = opacity;
      currentStrokeWidth = 0.5;
      if (isDragging && touchY != null) {
        final double actualTouchY = touchY! * size.height;
        final double distanceToLine = (lineY - actualTouchY).abs();
        if (distanceToLine < maxInfluenceRadius) {
          final double influence = 1.0 - (distanceToLine / maxInfluenceRadius);
          currentOpacity = (opacity + influence * 0.3).clamp(opacity, 0.5);
          currentStrokeWidth = (0.5 + influence * 0.7).clamp(0.5, 1.2);
        }
      }
      final hLinePaint = Paint()
        ..color = energyColor.withOpacity(currentOpacity)
        ..strokeWidth = currentStrokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, lineY), Offset(size.width, lineY), hLinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _XYPadGridPainter oldDelegate) {
    // Repaint if touch position or dragging state changes
    return oldDelegate.touchX != touchX ||
           oldDelegate.touchY != touchY ||
           oldDelegate.isDragging != isDragging;
  }
}

/// Custom painter for energy trail effect
class _EnergyTrailPainter extends CustomPainter {
  final List<Offset> trail;
  final Color energyColor;
  
  _EnergyTrailPainter({
    required this.trail,
    required this.energyColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (trail.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < trail.length; i++) {
      final double progress = i / (trail.length - 1); // 0.0 at start, 1.0 at end of trail
      final double opacity = (0.8 - (progress * 0.7)).clamp(0.1, 0.8); // Fades towards the end
      final double radius = (3.0 - (progress * 2.0)).clamp(1.0, 3.0); // Smaller towards the end

      paint.color = energyColor.withOpacity(opacity);
      
      final point = Offset(
        trail[i].dx * size.width,
        trail[i].dy * size.height,
      );
      canvas.drawCircle(point, radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}