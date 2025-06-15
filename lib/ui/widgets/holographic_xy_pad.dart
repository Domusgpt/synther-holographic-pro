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
  customMidiCC('Custom MIDI CC');
  
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

/// A holographic XY pad widget for multi-parameter control with visual feedback.
///
/// Features:
/// - Assignable X and Y axes to various synthesizer parameters or custom MIDI CCs.
/// - Musical mapping with selectable root note and scale type.
/// - Dynamic visual feedback including:
///   - An energy trail of fading circles following touch movement.
///   - A pulsing touch point indicator during drag.
///   - A subtly reactive background grid that changes based on touch position.
/// - UI for inputting custom MIDI CC numbers when 'Custom MIDI CC' assignment is selected.
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
  final Color energyColor;
  
  /// Creates a HolographicXYPad.
  ///
  /// Parameters:
  /// - [x], [y]: Initial normalized position (0.0-1.0).
  /// - [onPositionChanged]: Callback for position changes.
  /// - [xAssignment], [yAssignment]: Initial parameter assignments for X and Y axes.
  /// - [rootNote], [scaleType]: For musical mapping features.
  /// - [customMidiCCX], [customMidiCCY]: Initial MIDI CC numbers if 'Custom MIDI CC' is selected.
  ///   These are displayed and editable via TextFields when the respective axis is set to custom MIDI CC.
  /// - [onXAssignmentChanged], [onYAssignmentChanged]: Callbacks for axis assignment changes.
  /// - [onRootNoteChanged], [onScaleTypeChanged]: Callbacks for musical mapping changes.
  /// - [onCustomMidiCCXChanged], [onCustomMidiCCYChanged]: Callbacks triggered when the user
  ///   submits a new MIDI CC number through the respective TextField.
  /// - [energyColor]: The primary color theme for the widget.
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

    _midiCCXController = TextEditingController(text: widget.customMidiCCX.toString());
    _midiCCYController = TextEditingController(text: widget.customMidiCCY.toString());
  }
  
  @override
  void dispose() {
    _touchController.dispose();
    _midiCCXController.dispose();
    _midiCCYController.dispose();
    super.dispose();
  }
  
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _energyTrail.clear();
      _touchController.repeat(reverse: true); // Start pulsing
    });
    // _touchController.forward(); // No longer just forward
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
  }
  
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    // Stop pulsing and settle to normal size
    _touchController.stop();
    _touchController.animateTo(0.0, duration: Duration(milliseconds: 150), curve: Curves.easeOut);
    
    // Fade out energy trail
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
                          setState(() {}); // Rebuild to show/hide TextField
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
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
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
                'X: ${(_touchPosition.dx * 100).toInt()}%',
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor,
                  fontSize: 12,
                ),
              ),
              Text(
                widget.rootNote.displayName,
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