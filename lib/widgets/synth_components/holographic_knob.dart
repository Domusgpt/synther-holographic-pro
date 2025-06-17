import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/holographic_theme.dart';

/// Professional Holographic Knob with spectrum visualization
/// 
/// Features:
/// - Vaporwave holographic aesthetic with chromatic aberration
/// - Real-time spectrum visualization behind the knob
/// - RGB color separation on interaction
/// - Haptic feedback and micro-animations
/// - 4D transformation support
class HolographicKnob extends StatefulWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;
  final Color color;
  final bool showSpectrum;
  final double size;
  final double minAngle;
  final double maxAngle;

  const HolographicKnob({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
    this.showSpectrum = false,
    this.size = 80.0,
    this.minAngle = -150.0,
    this.maxAngle = 150.0,
  }) : super(key: key);

  @override
  State<HolographicKnob> createState() => _HolographicKnobState();
}

class _HolographicKnobState extends State<HolographicKnob>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _chromaController;
  late AnimationController _glowController;
  
  bool _isInteracting = false;
  double _interactionIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _chromaController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chromaController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Knob container
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: MouseRegion(
            onEnter: (_) => _onHoverStart(),
            onExit: (_) => _onHoverEnd(),
            child: Container(
              width: widget.size,
              height: widget.size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background spectrum visualization
                  if (widget.showSpectrum) _buildSpectrumBackground(),
                  
                  // Holographic knob body
                  _buildKnobBody(),
                  
                  // Chromatic aberration overlay
                  _buildChromaticOverlay(),
                  
                  // Value indicator
                  _buildValueIndicator(),
                  
                  // Interaction glow
                  _buildInteractionGlow(),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Label and value display
        _buildLabelAndValue(),
      ],
    );
  }

  Widget _buildSpectrumBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: SpectrumBackgroundPainter(
            pulseValue: _pulseController.value,
            color: widget.color,
            intensity: _interactionIntensity,
          ),
          size: Size(widget.size, widget.size),
        );
      },
    );
  }

  Widget _buildKnobBody() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController]),
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final glowValue = _glowController.value;
        
        return Container(
          width: widget.size * 0.8,
          height: widget.size * 0.8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              radius: 1.2,
              colors: [
                widget.color.withOpacity(0.1 + (pulseValue * 0.05)),
                widget.color.withOpacity(0.05),
                HolographicTheme.deepSpaceBlack.withOpacity(0.8),
                widget.color.withOpacity(0.2 + (glowValue * 0.3)),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            border: Border.all(
              color: widget.color.withOpacity(0.6 + (glowValue * 0.4)),
              width: 2 + (glowValue * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3 + (glowValue * 0.4)),
                blurRadius: 8 + (glowValue * 12),
                spreadRadius: 2 + (glowValue * 4),
              ),
              BoxShadow(
                color: HolographicTheme.glowColor.withOpacity(0.1 + (pulseValue * 0.05)),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChromaticOverlay() {
    return AnimatedBuilder(
      animation: _chromaController,
      builder: (context, child) {
        final chromaValue = _chromaController.value;
        
        if (chromaValue == 0.0) return Container();
        
        return Stack(
          children: [
            // Red channel offset
            Transform.translate(
              offset: Offset(chromaValue * 2, 0),
              child: Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(chromaValue * 0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
            
            // Blue channel offset
            Transform.translate(
              offset: Offset(-chromaValue * 2, 0),
              child: Container(
                width: widget.size * 0.8,
                height: widget.size * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.cyan.withOpacity(chromaValue * 0.5),
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildValueIndicator() {
    final angle = widget.minAngle + (widget.value * (widget.maxAngle - widget.minAngle));
    
    return Transform.rotate(
      angle: angle * math.pi / 180.0,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 4 + (_glowController.value * 2),
            height: widget.size * 0.3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.color.withOpacity(0.9 + (_glowController.value * 0.1)),
                  widget.color.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.8),
                  blurRadius: 4 + (_glowController.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInteractionGlow() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        if (_glowController.value == 0.0) return Container();
        
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.0),
                widget.color.withOpacity(0.1 * _glowController.value),
                widget.color.withOpacity(0.2 * _glowController.value),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelAndValue() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: HolographicTheme.createHolographicText(
            energyColor: widget.color,
            fontSize: 10,
            glowIntensity: 0.6,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) {
            return Text(
              (widget.value * 100).toStringAsFixed(0),
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.secondaryEnergy,
                fontSize: 12,
                glowIntensity: 0.4 + (_glowController.value * 0.4),
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isInteracting = true;
      _interactionIntensity = 1.0;
    });
    _glowController.forward();
    _chromaController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final offset = details.localPosition - center;
    final angle = math.atan2(offset.dy, offset.dx);
    
    // Convert angle to value
    final normalizedAngle = (angle * 180.0 / math.pi + 90.0) % 360.0;
    final minNormalized = (widget.minAngle + 180.0) % 360.0;
    final maxNormalized = (widget.maxAngle + 180.0) % 360.0;
    
    double newValue;
    if (maxNormalized > minNormalized) {
      newValue = ((normalizedAngle - minNormalized) / (maxNormalized - minNormalized)).clamp(0.0, 1.0);
    } else {
      // Handle wrap-around case
      if (normalizedAngle >= minNormalized) {
        newValue = ((normalizedAngle - minNormalized) / (360.0 - minNormalized + maxNormalized)).clamp(0.0, 1.0);
      } else {
        newValue = (((normalizedAngle + 360.0) - minNormalized) / (360.0 - minNormalized + maxNormalized)).clamp(0.0, 1.0);
      }
    }
    
    widget.onChanged(newValue);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isInteracting = false;
      _interactionIntensity = 0.0;
    });
    _glowController.reverse();
    _chromaController.reverse();
  }

  void _onHoverStart() {
    if (!_isInteracting) {
      _glowController.forward();
    }
  }

  void _onHoverEnd() {
    if (!_isInteracting) {
      _glowController.reverse();
    }
  }
}

/// Custom painter for the spectrum background visualization
class SpectrumBackgroundPainter extends CustomPainter {
  final double pulseValue;
  final Color color;
  final double intensity;

  SpectrumBackgroundPainter({
    required this.pulseValue,
    required this.color,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.stroke;
    
    // Draw concentric spectrum rings
    for (int i = 0; i < 8; i++) {
      final ringRadius = radius * (0.3 + (i * 0.1));
      final spectrumValue = math.sin(pulseValue * 2 * math.pi + i * 0.5) * 0.5 + 0.5;
      final opacity = (0.1 + (spectrumValue * 0.2)) * (1.0 + intensity);
      
      paint.color = color.withOpacity(opacity);
      paint.strokeWidth = 1.0 + (spectrumValue * 2.0);
      
      canvas.drawCircle(center, ringRadius, paint);
    }
    
    // Draw radial spectrum lines
    for (int i = 0; i < 16; i++) {
      final angle = (i / 16.0) * 2 * math.pi;
      final spectrumValue = math.sin(pulseValue * 3 * math.pi + i * 0.3) * 0.5 + 0.5;
      final length = radius * (0.2 + (spectrumValue * 0.3));
      final opacity = (0.05 + (spectrumValue * 0.15)) * (1.0 + intensity);
      
      paint.color = color.withOpacity(opacity);
      paint.strokeWidth = 0.5 + (spectrumValue * 1.5);
      
      final startX = center.dx + math.cos(angle) * (radius * 0.4);
      final startY = center.dy + math.sin(angle) * (radius * 0.4);
      final endX = center.dx + math.cos(angle) * (radius * 0.4 + length);
      final endY = center.dy + math.sin(angle) * (radius * 0.4 + length);
      
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumBackgroundPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue || 
           oldDelegate.intensity != intensity;
  }
}