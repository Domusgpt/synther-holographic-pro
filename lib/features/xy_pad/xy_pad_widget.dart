import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/synth_parameters.dart'; // Assuming this defines XYPadAssignment and SynthParametersModel
import '../../ui/holographic/holographic_theme.dart';

// Placeholder for SynthParameterId mappings if not provided by synth_parameters.dart
// These should match synth_engine.h or a shared constants definition.
class SynthParameterId {
  static const int filterCutoff = 10;
  static const int filterResonance = 11;
  static const int reverbMix = 30;
  static const int delayTime = 31;
  static const int delayFeedback = 32;
  static const int oscillatorMix = 1000; // Example, ensure these are correct
  // Add more as needed, ensure XYPadAssignment maps to these
}


// Placeholder for AudioEngineInterface - replace with actual engine communication
class AudioEngineInterface {
  static void setParameter(int parameterId, double value) {
    // This would call the native synth engine
    print('AudioEngineInterface: Setting parameter $parameterId to $value');
    // In a real app: SynthEngine.instance.setParameter(parameterId, value.toFloat());
  }
}
// --- End Placeholder Definitions ---

// --- Musical Scale Definitions (copied from VirtualKeyboardWidget for now) ---
// TODO: Move to a shared 'lib/core/music_theory.dart' or similar
enum MusicalScale { Chromatic, Major, MinorNatural, MinorHarmonic, MinorMelodic, PentatonicMajor, PentatonicMinor, Blues, Dorian, Mixolydian }

const List<String> rootNoteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

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
// --- End Musical Scale Definitions ---


/// A widget that displays an XY pad for controlling synthesis parameters.
class XYPadWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  // Callbacks for parent-managed state, if needed for a modular frame
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;


  const XYPadWidget({
    Key? key,
    this.initialSize = const Size(300, 300),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  State<XYPadWidget> createState() => _XYPadWidgetState();
}

class _XYPadWidgetState extends State<XYPadWidget> {
  // Local position state (0.0 to 1.0 range)
  double _xValue = 0.5;
  double _yValue = 0.5;
  
  // State for collapse/expand, managed by this widget via header
  late bool _isCollapsed;
  // State for size, potentially managed by parent through resize handles
  late Size _currentSize;

  // Interaction states for visual feedback
  bool _isHoveringPad = false;
  bool _isDraggingPad = false;

  // State variables for scale and key selection for X-axis
  MusicalScale _selectedScaleX = MusicalScale.Chromatic;
  int _selectedRootNoteMidiOffsetX = 0; // 0 for C
  final Set<int> _notesInCurrentScaleX = {}; // For visual highlighting if needed
  List<int> _quantizedPitchMapX = []; // Holds actual MIDI notes for X-axis quantization

  // TODO: Define SynthParameterId.xyPadPitch in the shared ID list
  //       and ensure the native engine handles it (e.g., by setting a target oscillator's pitch).
  // TODO: Extend SynthParametersModel to include:
  // - xyPadPitch (int) - for the quantized MIDI note output of X-axis
  // - setXYPadXPitch(int pitch)
  // (The other xyPadScaleX/xyPadRootNoteX TODOs were already incorporated in the previous step)


  // Helper to get parameter ID from XYPadAssignment
  // This might need to be more robust or defined in SynthParametersModel/XYPadAssignment itself
  int _getParamId(XYPadAssignment assignment) {
    switch (assignment) {
      case XYPadAssignment.filterCutoff:
        return SynthParameterId.filterCutoff;
      case XYPadAssignment.filterResonance:
        return SynthParameterId.filterResonance;
      case XYPadAssignment.reverbMix:
        return SynthParameterId.reverbMix;
      case XYPadAssignment.oscillatorMix: // Ensure this exists in your enum and engine
        return SynthParameterId.oscillatorMix;
      // Add other cases from XYPadAssignment
      default:
        print("Warning: XYPadAssignment ${assignment.name} not mapped to an ID.");
        return -1; // Invalid ID
    }
  }
  
  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;

    // Initialize with model values if available, otherwise use defaults
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final model = Provider.of<SynthParametersModel>(context, listen: false);
      _xValue = model.xyPadX;
      _yValue = model.xyPadY;
      // Initial parameter send for default assignments
      AudioEngineInterface.setParameter(_getParamId(model.xAxisAssignment), _xValue);
      AudioEngineInterface.setParameter(_getParamId(model.yAxisAssignment), _yValue);

      // Initialize scale settings from the model
      _selectedScaleX = model.xyPadSelectedScaleX; // Use the getter from the model
      _selectedRootNoteMidiOffsetX = model.xyPadSelectedRootNoteX; // Use the getter from the model
      _updateNotesInScaleX(); // This populates _quantizedPitchMapX

      // Send initial pitch after map is populated
      // Ensure _xValue is the current model value or default (already set a few lines above)
      if (_quantizedPitchMapX.isNotEmpty) {
        int initialPitchIndex = (_xValue * (_quantizedPitchMapX.length - 1)).round().clamp(0, _quantizedPitchMapX.length - 1);
        int initialOutputPitchMidiNote = _quantizedPitchMapX[initialPitchIndex];

        const int xyPadPitchParamId = 9999; // Placeholder ID for XY Pad Pitch
        AudioEngineInterface.setParameter(xyPadPitchParamId, initialOutputPitchMidiNote.toDouble());
        model.setXYPadXPitch(initialOutputPitchMidiNote); // Update central model
      } else {
        // This case should ideally not happen if _updateNotesInScaleX has a fallback
        print("Warning: _quantizedPitchMapX is empty in initState after _updateNotesInScaleX. Initial pitch not sent for X-axis.");
      }
    });
  }

  void _updateNotesInScaleX() {
    _notesInCurrentScaleX.clear();
    _quantizedPitchMapX.clear();
    const int baseMidiNote = 36; // C2
    const int numNotesInRange = 36; // 3 octaves: C2 to B4 (MIDI 36 to 71)

    // Populate _notesInCurrentScaleX for visual reference (which notes in an octave are valid)
    if (scaleIntervals.containsKey(_selectedScaleX)) {
      for (int interval in scaleIntervals[_selectedScaleX]!) {
        _notesInCurrentScaleX.add((_selectedRootNoteMidiOffsetX + interval) % 12);
      }
    }

    // Populate _quantizedPitchMapX with actual MIDI notes over the defined range
    if (_selectedScaleX == MusicalScale.Chromatic) {
      for (int i = 0; i < numNotesInRange; i++) {
        _quantizedPitchMapX.add(baseMidiNote + i);
      }
    } else {
      for (int i = 0; i < numNotesInRange; i++) {
        int currentFullMidiNote = baseMidiNote + i;
        // Check if the note (0-11) is in the scale's allowed notes
        if (_notesInCurrentScaleX.contains(currentFullMidiNote % 12)) {
          _quantizedPitchMapX.add(currentFullMidiNote);
        }
      }
    }

    // Fallback: If the scale logic results in an empty map (e.g. bad scale def), fill with chromatic.
    if (_quantizedPitchMapX.isEmpty && numNotesInRange > 0) {
        print("Warning: _quantizedPitchMapX was empty after scale processing for '$_selectedScaleX'. Falling back to Chromatic for safety.");
        for (int i = 0; i < numNotesInRange; i++) {
         _quantizedPitchMapX.add(baseMidiNote + i);
        }
    }

    if (mounted) setState(() {});
  }
  
  void _updateValues(Offset localPosition, Size areaSize, SynthParametersModel model) {
    if (areaSize.width <= 0 || areaSize.height <= 0) return;

    final newXValue = (localPosition.dx / areaSize.width).clamp(0.0, 1.0);
    // Y is often inverted in UI vs audio parameter expectations (0,0 at top-left for UI)
    final newYValue = (1.0 - (localPosition.dy / areaSize.height)).clamp(0.0, 1.0);

    bool xChanged = false;
    if (_xValue != newXValue) {
      _xValue = newXValue;
      xChanged = true;
    }

    if (xChanged) {
      int outputPitchMidiNote = 60; // Default MIDI note (e.g., C4) if map is empty or something goes wrong
      if (_quantizedPitchMapX.isNotEmpty) {
        // Map normalized _xValue (0.0-1.0) to an index in _quantizedPitchMapX
        int pitchIndex = (_xValue * (_quantizedPitchMapX.length - 1)).round().clamp(0, _quantizedPitchMapX.length - 1);
        outputPitchMidiNote = _quantizedPitchMapX[pitchIndex];
      }

      const int xyPadPitchParamId = 9999; // Placeholder ID, ensure this is defined in your actual ID list
      AudioEngineInterface.setParameter(xyPadPitchParamId, outputPitchMidiNote.toDouble());
      model.setXYPadXPitch(outputPitchMidiNote); // Update central model

      // Note: The original model.xAxisAssignment is no longer directly used to send a generic parameter if X is now pitch.
      // If the X-axis dropdown was meant to control something *about* the pitch (e.g. range, octave offset for pitch calc),
      // that logic would need to be incorporated here or in _updateNotesInScaleX.
      // For now, X-axis directly controls this quantized pitch.
    }

    bool yChanged = false;
    if (_yValue != newYValue) {
      _yValue = newYValue;
      yChanged = true;
      // Y-axis continues to use its assigned parameter
      AudioEngineInterface.setParameter(_getParamId(model.yAxisAssignment), _yValue);
    }

    // Update central model for raw X/Y for visual cursor, and call setState if anything changed
    if (xChanged || yChanged) {
      setState(() {}); // Update visual cursor
      model.setXYPadPosition(_xValue, _yValue);
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 1.5), // Slightly more opaque header
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.primaryEnergy.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drag handle would be part of the parent draggable frame
          // Icon(Icons.drag_indicator, color: HolographicTheme.primaryEnergy.withOpacity(0.7), size: 16),
          // const SizedBox(width: 8),
          Text(
            'XY CONTROL PAD',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.primaryEnergy,
              fontSize: 12,
              glowIntensity: 0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: HolographicTheme.primaryEnergy,
            ),
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
              });
              widget.onCollapsedChanged?.call(_isCollapsed);
            },
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          // Resize handle would be part of parent resizable frame
        ],
      ),
    );
  }

  Widget _buildParameterSelectors(SynthParametersModel model) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDropdown('X:', model.xAxisAssignment, (XYPadAssignment? newValue) {
            if (newValue != null) {
              model.setXAxisAssignment(newValue);
              // Send current X value with new parameter assignment
              AudioEngineInterface.setParameter(_getParamId(newValue), _xValue);
              setState(() {}); // To update display name if needed
            }
          }),
          _buildDropdown('Y:', model.yAxisAssignment, (XYPadAssignment? newValue) {
            if (newValue != null) {
              model.setYAxisAssignment(newValue);
              // Send current Y value with new parameter assignment
              AudioEngineInterface.setParameter(_getParamId(newValue), _yValue);
              setState(() {}); // To update display name if needed
            }
          }),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, XYPadAssignment currentValue, ValueChanged<XYPadAssignment?> onChanged) {
     // Access display name from XYPadAssignment enum if it has one, or use a map
    String displayName = currentValue.toString().split('.').last; // Default display
    // If XYPadAssignment has a 'displayName' getter, use it: e.g., currentValue.displayName
    // For now, using the enum value name. The old _getAxisName can be adapted.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.secondaryEnergy,
            fontSize: 10,
            glowIntensity: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: HolographicTheme.secondaryEnergy.withOpacity(0.5)),
          ),
          child: DropdownButton<XYPadAssignment>(
            value: currentValue,
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5), // Adjusted for more translucency
            underline: Container(), // Remove default underline
            icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.secondaryEnergy),
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.secondaryEnergy,
              fontSize: 12,
            ),
            items: XYPadAssignment.values.map((XYPadAssignment param) {
              // Use a more descriptive name if available from the enum, e.g., param.displayName
              String itemDisplayName = param.toString().split('.').last;
              return DropdownMenuItem<XYPadAssignment>(
                value: param,
                child: Text(
                  itemDisplayName, // Use a proper display name here
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.secondaryEnergy,
                    fontSize: 12,
                    glowIntensity: 0.2,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildXYPadArea(SynthParametersModel model) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use constraints to set the size of the pad area for hit detection
          Size padAreaSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (padAreaSize.isEmpty) {
            return const SizedBox.shrink(); // Avoid division by zero if constraints are zero
          }
          return MouseRegion(
            onEnter: (_) => setState(() => _isHoveringPad = true),
            onExit: (_) => setState(() => _isHoveringPad = false),
            child: GestureDetector(
              onPanStart: (details) {
                setState(() => _isDraggingPad = true);
                _updateValues(details.localPosition, padAreaSize, model);
              },
              onPanUpdate: (details) => _updateValues(details.localPosition, padAreaSize, model),
              onPanEnd: (details) => setState(() => _isDraggingPad = false),
              onPanCancel: () => setState(() => _isDraggingPad = false),
              child: Container(
                width: double.infinity, // Take up available space from LayoutBuilder
                height: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.transparent, // See-through center
                ),
                child: CustomPaint(
                  painter: _XYPadHolographicPainter(
                    x: _xValue,
                    y: _yValue,
                    baseColor: HolographicTheme.primaryEnergy,
                    glowColor: HolographicTheme.glowColor,
                    isHovering: _isHoveringPad,
                    isDragging: _isDraggingPad,
                  ),
                  size: Size.infinite, // Painter will use the size from LayoutBuilder
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildValueDisplay(SynthParametersModel model) {
    // Using a similar display as before, but styled with HolographicTheme
    String xParamName = model.xAxisAssignment.toString().split('.').last;
    String yParamName = model.yAxisAssignment.toString().split('.').last;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$xParamName: ${(_xValue * 100).toStringAsFixed(0)}%',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.accentEnergy,
              fontSize: 10,
              glowIntensity: 0.4
            ),
          ),
          Text(
            '$yParamName: ${(_yValue * 100).toStringAsFixed(0)}%',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.accentEnergy,
              fontSize: 10,
              glowIntensity: 0.4
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final model = Provider.of<SynthParametersModel>(context);

    // This main container defines the draggable widget's overall appearance
    return Container(
      width: _isCollapsed ? 200 : _currentSize.width,
      height: _isCollapsed ? 40 : _currentSize.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: HolographicTheme.primaryEnergy,
        intensity: 0.8, // Slightly more intense for the main frame
        cornerRadius: 10,
      ).copyWith(
        // More transparent base for the XY Pad content to show through
        color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.5),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed) ...[
            _buildParameterSelectors(model),
          _buildMusicControls(model), // Renamed for clarity as per subtask suggestion (was _buildScaleSelectors)
            _buildXYPadArea(model),
            _buildValueDisplay(model),
          ],
        ],
      ),
    );
  }

Widget _buildMusicControls(SynthParametersModel model) {
    // The TODO for SynthParametersModel fields (xyPadScaleX, etc.) was removed as they are now implemented.
    // The TODO for SynthParameterId.xyPadPitch remains relevant.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // X-Axis Root Note Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("X-Key:", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 9)),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _selectedRootNoteMidiOffsetX,
                  isDense: true,
                  dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5),
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.accentEnergy.withOpacity(0.9), size: 18),
                  items: rootNoteNames.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() { _selectedRootNoteMidiOffsetX = value; });
                      _updateNotesInScaleX();
                      model.setXYPadRootNoteX(value); // Update central model
                    }
                  },
                ),
              ),
            ],
          ),
          // X-Axis Scale Selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("X-Scale:", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 9)),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 6.0),
                decoration: BoxDecoration(
                  color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<MusicalScale>(
                  value: _selectedScaleX,
                  isDense: true,
                  dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5),
                  underline: Container(),
                  icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.accentEnergy.withOpacity(0.9), size: 18),
                  items: MusicalScale.values.map((MusicalScale scale) {
                    return DropdownMenuItem<MusicalScale>(
                      value: scale,
                      child: Text(scale.name, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
                    );
                  }).toList(),
                  onChanged: (MusicalScale? value) {
                    if (value != null) {
                      setState(() { _selectedScaleX = value; });
                      _updateNotesInScaleX();
                      model.setXYPadScaleX(value); // Update central model
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Renamed and restyled painter
class _XYPadHolographicPainter extends CustomPainter {
  final double x; // Normalized 0-1
  final double y; // Normalized 0-1 (0 at bottom, 1 at top)
  final Color baseColor;
  final Color glowColor;
  final bool isHovering;
  final bool isDragging;

  _XYPadHolographicPainter({
    required this.x,
    required this.y,
    required this.baseColor,
    required this.glowColor,
    required this.isHovering,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Calculate visual position (Y is inverted for typical UI top-left origin)
    final visualX = x * size.width;
    final visualY = (1.0 - y) * size.height;

    // --- Grid Lines ---
    // Value-based reactivity: grid opacity
    final double gridOpacity = (0.2 - ( (x-0.5).abs() * 0.1 + (y-0.5).abs() * 0.1 )).clamp(0.05, 0.2);
    paint
      ..color = baseColor.withOpacity(gridOpacity * (isHovering || isDragging ? 1.2 : 1.0))
      ..strokeWidth = 0.5;

    const int divisions = 4;
    for (int i = 1; i < divisions; i++) {
      final double dx = size.width * i / divisions;
      final double dy = size.height * i / divisions;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint); // Vertical
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint); // Horizontal
    }

    // --- Crosshairs ---
    double crosshairThickness = isDragging ? 1.5 : (isHovering ? 1.2 : 1.0);
    double crosshairOpacity = isDragging ? 0.7 : (isHovering ? 0.55 : 0.4);
    paint
      ..color = baseColor.withOpacity(crosshairOpacity)
      ..strokeWidth = crosshairThickness;
    canvas.drawLine(Offset(0, visualY), Offset(size.width, visualY), paint); // Horizontal
    canvas.drawLine(Offset(visualX, 0), Offset(visualX, size.height), paint); // Vertical

    // --- Central Dot (Cursor) ---
    final double baseDotRadius = 8.0;
    final double dotRadius = baseDotRadius * (isDragging ? 1.8 : (isHovering ? 1.3 : 1.0));

    // Value-based reactivity: cursor color based on X (pitch-like)
    final HSLColor hslBase = HSLColor.fromColor(this.baseColor);
    final Color xModulatedDotColor = hslBase.withHue((hslBase.hue + x * 45) % 360).toColor(); // Shift hue more noticeably
    final Color dotPaintColor = isDragging ? glowColor : xModulatedDotColor;


    final Path dotPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(visualX, visualY), radius: dotRadius));

    // Glow for the dot
    double dotGlowSigma = dotRadius * (isDragging ? 1.0 : 0.8);
    canvas.drawPath(
      dotPath,
      Paint()
        ..color = glowColor.withOpacity(isDragging ? 0.8 : (isHovering ? 0.6 : 0.4))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotGlowSigma),
    );
    if (isDragging) { // Extra wider halo when dragging
         canvas.drawPath(
            dotPath,
            Paint()
                ..color = glowColor.withOpacity(0.3)
                ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotGlowSigma * 2.5),
        );
    }
    
    // Solid dot
    paint
      ..color = dotPaintColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(visualX, visualY), dotRadius, paint);

    // Optional: Dot border for crispness
    paint
      ..color = dotPaintColor.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * (isDragging ? 1.2 : 1.0);
    canvas.drawCircle(Offset(visualX, visualY), dotRadius, paint);
  }

  @override
  bool shouldRepaint(_XYPadHolographicPainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y ||
           oldDelegate.baseColor != baseColor ||
           oldDelegate.glowColor != glowColor ||
           oldDelegate.isHovering != isHovering ||
           oldDelegate.isDragging != isDragging;
  }
}