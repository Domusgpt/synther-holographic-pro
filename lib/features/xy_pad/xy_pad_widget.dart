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
   // Add noteOn/noteOff if the XY pad itself will handle note mode directly
   // For now, assuming parameter control only based on subtask focus.
}


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
    });
  }
  
  void _updateValues(Offset localPosition, Size areaSize, SynthParametersModel model) {
    if (areaSize.width <= 0 || areaSize.height <= 0) return;

    final newXValue = (localPosition.dx / areaSize.width).clamp(0.0, 1.0);
    // Y is often inverted in UI vs audio parameter expectations (0,0 at top-left for UI)
    final newYValue = (1.0 - (localPosition.dy / areaSize.height)).clamp(0.0, 1.0);

    bool changed = false;
    if (_xValue != newXValue) {
      _xValue = newXValue;
      changed = true;
      AudioEngineInterface.setParameter(_getParamId(model.xAxisAssignment), _xValue);
    }
    if (_yValue != newYValue) {
      _yValue = newYValue;
      changed = true;
      AudioEngineInterface.setParameter(_getParamId(model.yAxisAssignment), _yValue);
    }

    if (changed) {
      setState(() {}); // Update visual cursor
      model.setXYPadPosition(_xValue, _yValue); // Update the central model
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
            dropdownColor: Colors.black.withOpacity(HolographicTheme.activeTransparency * 2.5), // Dark, translucent dropdown
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
          return GestureDetector(
            onPanStart: (details) => _updateValues(details.localPosition, padAreaSize, model),
            onPanUpdate: (details) => _updateValues(details.localPosition, padAreaSize, model),
            // onPanEnd and onTapUp are not strictly needed if we only send updates on move
            child: Container(
              width: double.infinity, // Take up available space from LayoutBuilder
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent, // See-through center
              ),
              child: CustomPaint(
                painter: _XYPadHolographicPainter( // Using the new Holographic Painter
                  x: _xValue,
                  y: _yValue,
                  baseColor: HolographicTheme.primaryEnergy,
                  glowColor: HolographicTheme.glowColor,
                ),
                size: Size.infinite, // Painter will use the size from LayoutBuilder
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
            _buildXYPadArea(model),
            _buildValueDisplay(model),
          ],
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

  _XYPadHolographicPainter({
    required this.x,
    required this.y,
    required this.baseColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Calculate visual position (Y is inverted for typical UI top-left origin)
    final visualX = x * size.width;
    final visualY = (1.0 - y) * size.height;

    // --- Grid Lines ---
    paint
      ..color = baseColor.withOpacity(0.2) // More subtle grid
      ..strokeWidth = 0.5; // Thinner grid lines

    const int divisions = 4; // Fewer, more subtle divisions
    for (int i = 1; i < divisions; i++) {
      final double dx = size.width * i / divisions;
      final double dy = size.height * i / divisions;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint); // Vertical
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint); // Horizontal
    }

    // --- Crosshairs ---
    paint
      ..color = baseColor.withOpacity(0.4) // Visible but not overpowering
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, visualY), Offset(size.width, visualY), paint); // Horizontal
    canvas.drawLine(Offset(visualX, 0), Offset(visualX, size.height), paint); // Vertical

    // --- Central Dot (Cursor) ---
    final dotRadius = 8.0;
    final Path dotPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(visualX, visualY), radius: dotRadius));

    // Inner Glow for the dot
    canvas.drawPath(
      dotPath,
      Paint()
        ..color = glowColor.withOpacity(0.6) // Brighter inner glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, dotRadius * 0.8), // Tighter blur
    );
    // Outer halo/glow for the dot
    canvas.drawPath(
      dotPath,
      Paint()
        ..color = glowColor.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, dotRadius * 2.5), // Wider, softer halo
    );
    
    // Solid dot
    paint
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(visualX, visualY), dotRadius, paint);

    // Optional: Dot border for crispness
    paint
      ..color = baseColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(visualX, visualY), dotRadius, paint);
  }

  @override
  bool shouldRepaint(_XYPadHolographicPainter oldDelegate) {
    return oldDelegate.x != x || oldDelegate.y != y ||
           oldDelegate.baseColor != baseColor ||
           oldDelegate.glowColor != glowColor;
  }
}