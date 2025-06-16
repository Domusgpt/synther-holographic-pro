import 'package:flutter/material.dart';
import '../../core/ffi/native_audio_ffi.dart'; // FFI
import '../../ui/holographic/holographic_theme.dart'; // For styling

class ModulationWheelWidget extends StatefulWidget {
  final Size size;
  final int ccNumber;

  const ModulationWheelWidget({
    Key? key,
    this.size = const Size(60, 150),
    this.ccNumber = 1, // Default to Modulation CC
  }) : super(key: key);

  @override
  _ModulationWheelWidgetState createState() => _ModulationWheelWidgetState();
}

class _ModulationWheelWidgetState extends State<ModulationWheelWidget> {
  double _currentValue = 0.0; // 0.0 to 1.0
  bool _isInteracting = false;
  final NativeAudioLib _nativeAudioLib = NativeAudioLib();

  @override
  void initState() {
    super.initState();
    // Send initial value if needed, though typical mod wheels start at 0 and send on first move
    // _sendModulationValue(_currentValue);
  }

  void _sendModulationValue(double value) {
    // Convert UI value (0.0 to 1.0) to MIDI CC Value (0 to 127)
    int midiCCValue = (value * 127).round().clamp(0, 127);

    print("Modulation: CC: ${widget.ccNumber}, UI Value: ${value.toStringAsFixed(3)}, MIDI Value: $midiCCValue");
    _nativeAudioLib.sendControlChange(widget.ccNumber, midiCCValue);
  }

  void _handleDragStart(DragStartDetails details) {
    _isInteracting = true;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    _updateValueFromPosition(localPosition.dy);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    _updateValueFromPosition(localPosition.dy);
  }

  void _updateValueFromPosition(double yPosition) {
    final double widgetHeight = widget.size.height;
    // Calculate value: top is 1.0, bottom is 0.0
    // yPosition is 0 at the top, widgetHeight at the bottom
    double newValue = 1.0 - (yPosition / widgetHeight);
    newValue = newValue.clamp(0.0, 1.0);

    if (_currentValue != newValue) {
      setState(() {
        _currentValue = newValue;
      });
      _sendModulationValue(_currentValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    setState(() {
      _isInteracting = false;
    });
    // No auto-return, but ensure the final value is sent if it hasn't been
    // _sendModulationValue(_currentValue); // Usually already sent by _updateValueFromPosition
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: () {
        setState(() {
          _isInteracting = false;
        });
      },
      child: Container(
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          color: Colors.grey[800], // Placeholder background
          borderRadius: BorderRadius.circular(widget.size.width / 2),
          border: Border.all(color: Colors.grey[600]!, width: 2),
        ),
        child: CustomPaint(
          painter: _ModulationWheelPainter(_currentValue, widget.size.width, _isInteracting),
          size: widget.size,
        ),
      ),
    );
  }
}

// Simple painter for the wheel/slider visual
class _ModulationWheelPainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final double wheelWidth;
  final bool isInteracting;

  _ModulationWheelPainter(this.value, this.wheelWidth, this.isInteracting);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final Paint thumbPaint = Paint()
      ..color = isInteracting ? HolographicTheme.accentEnergy : HolographicTheme.secondaryEnergy // Different color for interaction
      ..style = PaintingStyle.fill;

    final double trackWidth = wheelWidth * 0.4;
    final double trackCenterX = size.width / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(trackCenterX - trackWidth / 2, 0, trackWidth, size.height),
        Radius.circular(trackWidth / 2)
      ),
      trackPaint
    );

    // Thumb position:
    // value = 1.0 (top) => thumbY = thumbRadius
    // value = 0.0 (bottom) => thumbY = size.height - thumbRadius
    final double thumbRadius = wheelWidth * 0.45;
    final double usableHeight = size.height - 2 * thumbRadius; // Space for thumb to move fully top to bottom

    // Inverse relationship for y: value 0 is bottom, value 1 is top
    final double thumbY = (size.height - thumbRadius) - (value * usableHeight);

    canvas.drawCircle(Offset(trackCenterX, thumbY.clamp(thumbRadius, size.height - thumbRadius)), thumbRadius, thumbPaint);

    // Optional: Min/Max indicators or a filled track up to the thumb
    final Paint fillPaint = Paint()
      ..color = thumbPaint.color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    double fillHeight = value * (size.height - 2 * thumbRadius) + thumbRadius;
    fillHeight = fillHeight.clamp(thumbRadius, size.height - thumbRadius);
    if (value > 0.01) { // Only draw fill if value is somewhat up
        canvas.drawRRect(
        RRect.fromRectAndCorners(
            Rect.fromLTRB(
            trackCenterX - trackWidth / 2,
            size.height - fillHeight, // Start from bottom
            trackCenterX + trackWidth / 2,
            size.height - thumbRadius // Go up to bottom of thumb
            ),
            bottomLeft: Radius.circular(trackWidth/2),
            bottomRight: Radius.circular(trackWidth/2),
        ),
        fillPaint
        );
    }


  }

  @override
  bool shouldRepaint(covariant _ModulationWheelPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.wheelWidth != wheelWidth ||
           oldDelegate.isInteracting != isInteracting;
  }
}
