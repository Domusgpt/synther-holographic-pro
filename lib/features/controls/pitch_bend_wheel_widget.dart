import 'package:flutter/material.dart';
import 'dart:async'; // For Timer, if needed for animation fallback
import '../../core/ffi/native_audio_ffi_factory.dart'; // FFI factory
import '../../ui/holographic/holographic_theme.dart'; // For styling (optional for now)

class PitchBendWheelWidget extends StatefulWidget {
  final Size size;

  const PitchBendWheelWidget({
    Key? key,
    this.size = const Size(60, 150),
  }) : super(key: key);

  @override
  _PitchBendWheelWidgetState createState() => _PitchBendWheelWidgetState();
}

class _PitchBendWheelWidgetState extends State<PitchBendWheelWidget>
    with SingleTickerProviderStateMixin {
  double _currentValue = 0.0; // -1.0 to 1.0
  bool _isInteracting = false;
  final NativeAudioLib _nativeAudioLib = createNativeAudioLib();
  late AnimationController _returnToCenterController;
  Animation<double>? _returnAnimation;

  @override
  void initState() {
    super.initState();
    _returnToCenterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Adjust duration as needed
    )
      ..addListener(() {
        if (_isInteracting) return; // Don't update if user is still dragging
        setState(() {
          _currentValue = _returnAnimation!.value;
        });
        _sendPitchBendValue(_currentValue);
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // Ensure final value is exactly 0.0
          if (!_isInteracting) { // Check again, user might have re-touched
            setState(() {
              _currentValue = 0.0;
            });
          }
          _sendPitchBendValue(0.0);
        }
      });
  }

  void _sendPitchBendValue(double value) {
    // Convert UI value (-1.0 to 1.0) to MIDI Pitch Bend Value (0 to 16383)
    // 0.0 on the wheel = center of MIDI range (8192)
    // 1.0 on the wheel = max MIDI value (16383)
    // -1.0 on the wheel = min MIDI value (0)
    int midiPitchBend = ((value + 1.0) / 2.0 * 16383).round().clamp(0, 16383);

    // For now, print. Later, this will call the FFI function.
    print("Pitch Bend: UI Value: ${value.toStringAsFixed(3)}, MIDI Value: $midiPitchBend");
    _nativeAudioLib.sendPitchBend(midiPitchBend);
  }

  void _handleDragStart(DragStartDetails details) {
    _returnToCenterController.stop(); // Stop any return animation
    _isInteracting = true;
    // Calculate initial value based on touch position
    // This might need adjustment based on how you render the draggable area
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
    // Calculate value: top is 1.0, middle is 0.0, bottom is -1.0
    // yPosition is 0 at the top, widgetHeight at the bottom
    double newValue = (widgetHeight / 2 - yPosition) / (widgetHeight / 2);
    newValue = newValue.clamp(-1.0, 1.0);

    if (_currentValue != newValue) {
      setState(() {
        _currentValue = newValue;
      });
      _sendPitchBendValue(_currentValue);
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    _isInteracting = false;
    // Start animation to return to center (0.0)
    _returnAnimation = Tween<double>(
      begin: _currentValue,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _returnToCenterController,
      curve: Curves.easeOut, // Or another curve you prefer
    ));
    _returnToCenterController.reset();
    _returnToCenterController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onVerticalDragCancel: () { // Also handle cancel
        _isInteracting = false;
        if (!_returnToCenterController.isAnimating) {
           _handleDragEnd(DragEndDetails()); // Treat cancel like end
        }
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
          painter: _PitchBendWheelPainter(_currentValue, widget.size.width),
          size: widget.size,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _returnToCenterController.dispose();
    super.dispose();
  }
}

// Simple painter for the wheel/slider visual
class _PitchBendWheelPainter extends CustomPainter {
  final double value; // -1.0 to 1.0
  final double wheelWidth;

  _PitchBendWheelPainter(this.value, this.wheelWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.fill;

    final Paint thumbPaint = Paint()
      ..color = HolographicTheme.primaryEnergy // Use a theme color
      ..style = PaintingStyle.fill;

    final double trackWidth = wheelWidth * 0.4;
    final double trackCenterX = size.width / 2;

    // Draw track (simple line for now)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(trackCenterX - trackWidth / 2, 0, trackWidth, size.height),
        Radius.circular(trackWidth / 2)
      ),
      trackPaint
    );

    // Thumb position:
    // value = 1.0 (top) => thumbY = thumbRadius
    // value = 0.0 (center) => thumbY = size.height / 2
    // value = -1.0 (bottom) => thumbY = size.height - thumbRadius
    final double thumbRadius = wheelWidth * 0.45; // Thumb is slightly wider than track
    final double usableHeight = size.height - 2 * thumbRadius;
    final double thumbY = (size.height / 2) - (value * usableHeight / 2);

    canvas.drawCircle(Offset(trackCenterX, thumbY.clamp(thumbRadius, size.height - thumbRadius)), thumbRadius, thumbPaint);

    // Center line indicator
    final Paint centerLinePaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(trackCenterX - thumbRadius, size.height / 2),
        Offset(trackCenterX + thumbRadius, size.height / 2),
        centerLinePaint);
  }

  @override
  bool shouldRepaint(covariant _PitchBendWheelPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.wheelWidth != wheelWidth;
  }
}
