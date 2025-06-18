// Individual Draggable Knob with RGB Chromatic Effects and HyperAV Integration
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/hyperav_bridge.dart';
import '../core/holographic_theme.dart';

class DraggableKnob extends StatefulWidget {
  final String label;
  final String parameter;
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;
  final Color primaryColor;
  final bool showSpectralBackground;
  final Offset? initialPosition;
  final Function(Offset)? onPositionChanged;
  
  const DraggableKnob({
    Key? key,
    required this.label,
    required this.parameter,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.primaryColor = HolographicTheme.primaryEnergy,
    this.showSpectralBackground = true,
    this.initialPosition,
    this.onPositionChanged,
  }) : super(key: key);

  @override
  State<DraggableKnob> createState() => _DraggableKnobState();
}

class _DraggableKnobState extends State<DraggableKnob>
    with TickerProviderStateMixin {
  late AnimationController _interactionController;
  late AnimationController _chromaticController;
  late AnimationController _glitchController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _chromaticOffset;
  
  Offset _position = Offset.zero;
  bool _isInteracting = false;
  bool _isDragging = false;
  double _rotationAngle = 0.0;
  
  // RGB chromatic separation values
  double _redOffset = 0.0;
  double _greenOffset = 0.0;
  double _blueOffset = 0.0;
  
  // Glitch effect state
  bool _shouldShowGlitch = false;
  double _glitchIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    
    _position = widget.initialPosition ?? Offset.zero;
    _rotationAngle = ((widget.value - widget.min) / (widget.max - widget.min)) * 2 * math.pi - math.pi;
    
    // Initialize animation controllers
    _interactionController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _chromaticController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _glitchController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Setup animations
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _interactionController,
      curve: Curves.easeOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _interactionController,
      curve: Curves.easeOut,
    ));
    
    _chromaticOffset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(4.0, 4.0),
    ).animate(CurvedAnimation(
      parent: _chromaticController,
      curve: Curves.elasticOut,
    ));
    
    // Random glitch effects
    _startGlitchTimer();
  }

  void _startGlitchTimer() {
    Future.delayed(Duration(milliseconds: 100 + (math.Random().nextDouble() * 2000).round()), () {
      if (mounted) {
        if (math.Random().nextDouble() < 0.1) {
          _triggerGlitchEffect();
        }
        _startGlitchTimer();
      }
    });
  }

  void _triggerGlitchEffect() {
    setState(() {
      _shouldShowGlitch = true;
      _glitchIntensity = math.Random().nextDouble();
    });
    
    _glitchController.forward().then((_) {
      if (mounted) {
        setState(() {
          _shouldShowGlitch = false;
        });
        _glitchController.reset();
      }
    });
  }

  void _onInteractionStart() {
    setState(() {
      _isInteracting = true;
    });
    
    _interactionController.forward();
    _chromaticController.forward();
    
    // Trigger haptic feedback
    HapticFeedback.lightImpact();
    
    // Update HyperAV visualizer
    HyperAVBridge.instance.updateVisualizerParameter(widget.parameter, widget.value);
    
    // Trigger visual ripple effect
    _triggerGlitchEffect();
  }

  void _onInteractionEnd() {
    setState(() {
      _isInteracting = false;
    });
    
    _interactionController.reverse();
    _chromaticController.reverse();
  }

  void _updateKnobValue(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    
    // Calculate angle from touch position
    double angle = math.atan2(delta.dy, delta.dx);
    
    // Map angle to value range (allowing full 360° rotation)
    double normalizedValue = (angle + math.pi) / (2 * math.pi);
    double newValue = widget.min + normalizedValue * (widget.max - widget.min);
    
    // Clamp to valid range
    newValue = newValue.clamp(widget.min, widget.max);
    
    setState(() {
      _rotationAngle = angle;
    });
    
    widget.onChanged(newValue);
    
    // Update HyperAV visualizer in real-time
    HyperAVBridge.instance.updateVisualizerParameter(widget.parameter, newValue);
    
    // Trigger haptic feedback for value changes
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        dragStartBehavior: DragStartBehavior.down,
        onPanStart: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPositionOnPanStart = renderBox.globalToLocal(details.globalPosition);
          final size = renderBox.size; // Overall widget size (80x120)

          // Knob's visual center: X is center of widget, Y is 30px from top of widget.
          // This assumes _buildKnobBody will place the 60x60 knob such that its center is here.
          final knobVisualCenterX = size.width / 2; // 40.0
          final knobVisualCenterY = 30.0;           // 30.0 (center of a 60px high knob at the top)
          final knobVisualCenter = Offset(knobVisualCenterX, knobVisualCenterY);

          const double knobVisualRadius = 30.0;
          const double rotationTouchPadding = 15.0; // Forgiving touch area
          const double rotationEffectiveRadius = knobVisualRadius + rotationTouchPadding; // 45.0

          final distanceToKnobCenter = (localPositionOnPanStart - knobVisualCenter).distance;

          if (distanceToKnobCenter <= rotationEffectiveRadius) {
            _isDragging = false; // It's a rotation gesture
            _onInteractionStart();

            final knobSize = Size(knobVisualRadius * 2, knobVisualRadius * 2); // Actual knob size (60x60)
            // Convert pan start position to be relative to the knob's own top-left corner.
            final positionRelativeToKnobTopLeft = localPositionOnPanStart - knobVisualCenter + Offset(knobVisualRadius, knobVisualRadius);
            _updateKnobValue(positionRelativeToKnobTopLeft, knobSize);
          } else {
            _isDragging = true; // It's a drag gesture
            _onInteractionStart();
          }
        },
        onPanUpdate: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.globalPosition);
          final size = renderBox.size; // Overall widget size (80x120)

          if (_isDragging) {
            setState(() {
              _position += details.delta;
            });
            widget.onPositionChanged?.call(_position);
          } else {
            // Knob's visual center and size (same as in onPanStart)
            final knobVisualCenterX = size.width / 2;
            final knobVisualCenterY = 30.0;
            final knobVisualCenter = Offset(knobVisualCenterX, knobVisualCenterY);
            const double knobVisualRadius = 30.0;
            final knobSize = Size(knobVisualRadius * 2, knobVisualRadius * 2);

            // Convert current pan position to be relative to the knob's own top-left corner.
            final positionRelativeToKnobTopLeft = localPosition - knobVisualCenter + Offset(knobVisualRadius, knobVisualRadius);
            _updateKnobValue(positionRelativeToKnobTopLeft, knobSize);
          }
        },
        onPanEnd: (details) {
          _onInteractionEnd();
          // _isDragging state is managed by onPanStart.
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _interactionController,
            _chromaticController,
            _glitchController,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 80,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Spectral background (your HyperAV visualizer shows through)
                    if (widget.showSpectralBackground)
                      _buildSpectralBackground(),
                    
                    // Main knob body with RGB chromatic separation
                    _buildKnobBody(),
                    
                    // Glitch overlay
                    if (_shouldShowGlitch)
                      _buildGlitchOverlay(),
                    
                    // Value label
                    _buildValueLabel(),
                    
                    // Parameter name
                    _buildParameterLabel(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpectralBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              widget.primaryColor.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
          borderRadius: BorderRadius.circular(40),
        ),
      ),
    );
  }

  Widget _buildKnobBody() {
    // Aligns the 60x60 knob within the 80x120 Stack area.
    // Alignment(0.0, -0.5) positions the center of the child (knob)
    // at the horizontal center of the parent, and vertically at Y = 30.
    return Align(
      alignment: Alignment(0.0, -0.5),
      child: Container(
        width: 60,
        height: 60,
        child: ClipOval(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isInteracting) ...[
                _buildChromaticCircle(Colors.red.withOpacity(0.6), Offset(2, 0)),
                _buildChromaticCircle(Colors.cyan.withOpacity(0.6), Offset(-2, 0)),
                _buildChromaticCircle(Colors.green.withOpacity(0.6), Offset(0, 2)),
              ],
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.primaryColor.withOpacity(0.15),
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(_glowAnimation.value),
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.primaryColor.withOpacity(_glowAnimation.value * 0.6),
                      blurRadius: 20.0 * _glowAnimation.value,
                      spreadRadius: 5.0 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: CustomPaint(
                  size: Size(60, 60), // Explicitly pass size to painter
                  painter: KnobPainter(
                    value: widget.value,
                    min: widget.min,
                    max: widget.max,
                    color: widget.primaryColor,
                    isInteracting: _isInteracting,
                    rotationAngle: _rotationAngle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChromaticCircle(Color color, Offset offset) {
    // These circles are part of the 60x60 knob body.
    return Transform.translate(
      offset: offset * _chromaticOffset.value.dx * 0.1,
      child: Container(
        width: 60, // Should match the knob's main circle size
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildGlitchOverlay() {
    // This overlay covers the entire 80x120 widget area.
    return Positioned.fill(
      child: CustomPaint(
        clipBehavior: Clip.hardEdge,
        painter: GlitchOverlayPainter(
          intensity: _glitchIntensity,
          time: _glitchController.value,
        ),
      ),
    );
  }

  Widget _buildValueLabel() {
    final displayValue = ((widget.value - widget.min) / (widget.max - widget.min) * 100).round();
    // Positioned relative to the 80x120 container.
    // The knob (60px high) is centered at Y=30 (top edge at Y=0, bottom edge at Y=60).
    // So, top: 70 positions it 10px below the knob.
    return Positioned(
      top: 70,
      left: 0, // To center horizontally
      right: 0,
      child: Align(
        alignment: Alignment.center,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.primaryColor.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            '$displayValue',
            style: TextStyle(
              color: widget.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: widget.primaryColor.withOpacity(0.8),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParameterLabel() {
    // Positioned relative to the 80x120 container, at the bottom.
    return Positioned(
      bottom: 4,
      left: 0, // To center horizontally
      right: 0,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: widget.primaryColor.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: widget.primaryColor.withOpacity(0.6),
                blurRadius: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interactionController.dispose();
    _chromaticController.dispose();
    _glitchController.dispose();
    super.dispose();
  }
}

// Custom painter for the knob indicator
class KnobPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  final bool isInteracting;
  final double rotationAngle;

  KnobPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.isInteracting,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Draw value indicator
    final indicatorPaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final indicatorStart = center + Offset(
      math.cos(rotationAngle) * (radius - 8),
      math.sin(rotationAngle) * (radius - 8),
    );
    
    final indicatorEnd = center + Offset(
      math.cos(rotationAngle) * (radius - 2),
      math.sin(rotationAngle) * (radius - 2),
    );
    
    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);
    
    // Draw center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = color.withOpacity(isInteracting ? 1.0 : 0.8),
    );
  }

  @override
  bool shouldRepaint(KnobPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.isInteracting != isInteracting ||
           oldDelegate.rotationAngle != rotationAngle;
  }
}

// Custom painter for glitch effects
class GlitchOverlayPainter extends CustomPainter {
  final double intensity;
  final double time;

  GlitchOverlayPainter({
    required this.intensity,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity < 0.01) return;
    
    final paint = Paint()
      ..color = Colors.white.withOpacity(intensity * 0.3)
      ..blendMode = BlendMode.overlay;
    
    // Draw scan lines
    for (double y = 0; y < size.height; y += 4) {
      if (math.Random().nextDouble() < intensity) {
        canvas.drawLine(
          Offset(0, y),
          Offset(size.width, y),
          paint,
        );
      }
    }
    
    // Draw digital noise
    for (int i = 0; i < (intensity * 20).round(); i++) {
      final x = math.Random().nextDouble() * size.width;
      final y = math.Random().nextDouble() * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x, y, 2, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GlitchOverlayPainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.time != time;
  }
}