// Professional Knob Bank with 6+ Knobs: Cutoff, Resonance, Crystal, Shimmer, Depth, Warp
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/hyperav_bridge.dart';
import '../core/holographic_theme.dart';

class ProfessionalKnobBank extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Function(String, double)? onParameterChanged;

  const ProfessionalKnobBank({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onParameterChanged,
  }) : super(key: key);

  @override
  State<ProfessionalKnobBank> createState() => _ProfessionalKnobBankState();
}

class _ProfessionalKnobBankState extends State<ProfessionalKnobBank>
    with TickerProviderStateMixin {
  
  // Knob parameters and values
  final Map<String, KnobParameter> _knobParameters = {
    'cutoff': KnobParameter(
      'CUTOFF',
      'Filter Cutoff Frequency',
      0.7,
      HolographicTheme.primaryEnergy,
    ),
    'resonance': KnobParameter(
      'RESONANCE', 
      'Filter Resonance',
      0.3,
      HolographicTheme.secondaryEnergy,
    ),
    'crystal': KnobParameter(
      'CRYSTAL',
      'Crystal Effect Intensity',
      0.5,
      HolographicTheme.tertiaryEnergy,
    ),
    'shimmer': KnobParameter(
      'SHIMMER',
      'Shimmer Effect Amount',
      0.4,
      HolographicTheme.primaryEnergy,
    ),
    'depth': KnobParameter(
      'DEPTH',
      'Effect Depth Parameter',
      0.6,
      HolographicTheme.secondaryEnergy,
    ),
    'warp': KnobParameter(
      'WARP',
      'Warp Effect Intensity',
      0.2,
      HolographicTheme.tertiaryEnergy,
    ),
  };

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return _buildCollapsedState();
    }
    
    return _buildFullInterface();
  }

  Widget _buildCollapsedState() {
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: GestureDetector(
        onTap: widget.onToggleCollapse,
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(
            (widget.position ?? Offset.zero) + details.delta,
          );
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.tune,
            color: HolographicTheme.secondaryEnergy,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFullInterface() {
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: Container(
        width: 320,
        height: 420,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Knobs grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: _buildKnobsGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: HolographicTheme.secondaryEnergy.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 20),
          Text(
            'SYNTH CONTROLS',
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
                  blurRadius: 6.0,
                ),
              ],
            ),
          ),
          Spacer(),
          // Collapse button
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: HolographicTheme.secondaryEnergy.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.secondaryEnergy,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildKnobsGrid() {
    final knobEntries = _knobParameters.entries.toList();
    
    return Column(
      children: [
        // Top row: Cutoff, Resonance, Crystal
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildProfessionalKnob(knobEntries[0])),
              SizedBox(width: 15),
              Expanded(child: _buildProfessionalKnob(knobEntries[1])),
              SizedBox(width: 15),
              Expanded(child: _buildProfessionalKnob(knobEntries[2])),
            ],
          ),
        ),
        
        SizedBox(height: 20),
        
        // Bottom row: Shimmer, Depth, Warp
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildProfessionalKnob(knobEntries[3])),
              SizedBox(width: 15),
              Expanded(child: _buildProfessionalKnob(knobEntries[4])),
              SizedBox(width: 15),
              Expanded(child: _buildProfessionalKnob(knobEntries[5])),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalKnob(MapEntry<String, KnobParameter> knobEntry) {
    final knobKey = knobEntry.key;
    final knob = knobEntry.value;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Knob control
            Expanded(
              flex: 3,
              child: GestureDetector(
                onPanUpdate: (details) {
                  _updateKnobValue(knobKey, details.localPosition);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: knob.color.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: knob.color.withOpacity(0.4 * _glowAnimation.value),
                        blurRadius: 15 * _glowAnimation.value,
                        spreadRadius: 3 * _glowAnimation.value,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: ProfessionalKnobPainter(
                      value: knob.value,
                      color: knob.color,
                      glowIntensity: _glowAnimation.value,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // Value display
            Container(
              height: 25,
              decoration: BoxDecoration(
                color: knob.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: knob.color.withOpacity(0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${(knob.value * 100).round()}',
                style: TextStyle(
                  color: knob.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: knob.color.withOpacity(0.8),
                      blurRadius: 3.0,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 5),
            
            // Label
            Text(
              knob.label,
              style: TextStyle(
                color: knob.color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateKnobValue(String knobKey, Offset localPosition) {
    final knob = _knobParameters[knobKey];
    if (knob == null) return;
    
    // Calculate new value based on vertical drag
    final delta = localPosition.dy / 100.0; // Sensitivity
    final newValue = (knob.value - delta * 0.01).clamp(0.0, 1.0);
    
    setState(() {
      _knobParameters[knobKey] = knob.copyWith(value: newValue);
    });
    
    // Trigger callbacks
    widget.onParameterChanged?.call(knobKey, newValue);
    
    // Update HyperAV visualizer
    HyperAVBridge.instance.updateVisualizerParameter(knobKey, newValue);
    
    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
}

// Data class for knob parameters
class KnobParameter {
  final String label;
  final String description;
  final double value;
  final Color color;

  const KnobParameter(
    this.label,
    this.description,
    this.value,
    this.color,
  );

  KnobParameter copyWith({
    String? label,
    String? description,
    double? value,
    Color? color,
  }) {
    return KnobParameter(
      label ?? this.label,
      description ?? this.description,
      value ?? this.value,
      color ?? this.color,
    );
  }
}

// Custom painter for professional knob with energy effects
class ProfessionalKnobPainter extends CustomPainter {
  final double value;
  final Color color;
  final double glowIntensity;

  ProfessionalKnobPainter({
    required this.value,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Draw outer ring
    _drawOuterRing(canvas, center, radius);
    
    // Draw value arc
    _drawValueArc(canvas, center, radius);
    
    // Draw center indicator
    _drawCenterIndicator(canvas, center, radius);
    
    // Draw energy particles
    _drawEnergyParticles(canvas, center, radius);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = color.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    canvas.drawCircle(center, radius, paint);
  }

  void _drawValueArc(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -math.pi / 2 - (math.pi * 0.75);
    final sweepAngle = (math.pi * 1.5) * value;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  void _drawCenterIndicator(Canvas canvas, Offset center, double radius) {
    // Calculate indicator position
    const startAngle = -math.pi / 2 - (math.pi * 0.75);
    final currentAngle = startAngle + (math.pi * 1.5) * value;
    
    final indicatorPos = center + Offset(
      math.cos(currentAngle) * (radius - 8),
      math.sin(currentAngle) * (radius - 8),
    );
    
    // Draw indicator dot
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorPos, 4, paint);
    
    // Draw indicator glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.6 * glowIntensity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorPos, 8, glowPaint);
  }

  void _drawEnergyParticles(Canvas canvas, Offset center, double radius) {
    // Draw energy particles around the knob
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;
      final particleRadius = radius + 10 + math.sin(angle * 3 + value * math.pi) * 5;
      
      final particlePos = center + Offset(
        math.cos(angle) * particleRadius,
        math.sin(angle) * particleRadius,
      );
      
      final particlePaint = Paint()
        ..color = color.withOpacity(0.4 * glowIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(particlePos, 1.5, particlePaint);
    }
  }

  @override
  bool shouldRepaint(ProfessionalKnobPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.glowIntensity != glowIntensity;
  }
}