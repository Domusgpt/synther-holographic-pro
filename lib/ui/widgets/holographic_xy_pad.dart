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

/// Holographic XY pad with parameter assignment dropdowns and musical mapping
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
  
  @override
  void initState() {
    super.initState();
    
    _touchController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _touchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _touchController, curve: Curves.elasticOut),
    );
    
    _touchPosition = Offset(widget.x, widget.y);
  }
  
  @override
  void dispose() {
    _touchController.dispose();
    super.dispose();
  }
  
  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _energyTrail.clear();
    });
    _touchController.forward();
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
    _touchController.reverse();
    
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
                        }
                      },
                    ),
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
                opacity: 0.2,
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
            AnimatedBuilder(
              animation: _touchAnimation,
              builder: (context, child) {
                return Positioned(
                  left: _touchPosition.dx * 300 - 12,
                  top: _touchPosition.dy * 200 - 12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.energyColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.energyColor,
                        width: 2.0,
                      ),
                      boxShadow: [
                        HolographicTheme.createEnergyGlow(
                          color: widget.energyColor,
                          intensity: _isDragging ? 2.0 : 1.0,
                          radius: _isDragging ? 16.0 : 8.0,
                        ),
                      ],
                    ),
                  ),
                );
              },
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
  
  _XYPadGridPainter({
    required this.energyColor,
    required this.opacity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = energyColor.withOpacity(opacity)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    
    // Draw subtle grid lines
    final gridCount = 8;
    for (int i = 1; i < gridCount; i++) {
      final x = size.width * i / gridCount;
      final y = size.height * i / gridCount;
      
      // Vertical lines
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      
      // Horizontal lines
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    
    for (int i = 0; i < trail.length - 1; i++) {
      final opacity = (i + 1) / trail.length * 0.5;
      final paint = Paint()
        ..color = energyColor.withOpacity(opacity)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      
      final start = Offset(
        trail[i].dx * size.width,
        trail[i].dy * size.height,
      );
      final end = Offset(
        trail[i + 1].dx * size.width,
        trail[i + 1].dy * size.height,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}