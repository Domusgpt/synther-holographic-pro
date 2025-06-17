import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';

/// Professional Envelope Section with multiple envelope generators
/// 
/// Features:
/// - Multiple ADSR envelope generators (amplitude, filter, auxiliary)
/// - Real-time envelope visualization with trigger simulation
/// - Velocity sensitivity and curve shaping
/// - Loop modes and sustain variations
/// - Visual envelope editor with interactive control points
/// - Holographic trail effects showing envelope progression
class EnvelopeSection extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const EnvelopeSection({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<EnvelopeSection> createState() => _EnvelopeSectionState();
}

class _EnvelopeSectionState extends State<EnvelopeSection> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _envelopeController;
  late AnimationController _triggerController;
  
  // Envelope generators (amplitude, filter, auxiliary)
  final List<Map<String, double>> _envelopes = [
    {
      'attack': 0.1,    // 0.01 to 10.0 seconds
      'decay': 0.3,     // 0.01 to 10.0 seconds  
      'sustain': 0.7,   // 0.0 to 1.0 level
      'release': 0.5,   // 0.01 to 10.0 seconds
      'velocity': 0.8,  // Velocity sensitivity 0-1
      'curve': 0.5,     // Curve shape 0-1 (linear to exponential)
      'enabled': 1.0,   // On/off
    },
    {
      'attack': 0.05,
      'decay': 0.2,
      'sustain': 0.5,
      'release': 0.8,
      'velocity': 0.6,
      'curve': 0.3,
      'enabled': 1.0,
    },
    {
      'attack': 0.2,
      'decay': 0.1,
      'sustain': 0.0,
      'release': 0.3,
      'velocity': 0.0,
      'curve': 0.7,
      'enabled': 0.0,
    },
  ];

  final List<String> _envelopeNames = ['AMP ENV', 'FILTER ENV', 'AUX ENV'];
  final List<Color> _envelopeColors = [
    HolographicTheme.primaryEnergy,
    HolographicTheme.secondaryEnergy,
    HolographicTheme.accentEnergy,
  ];

  int _selectedEnvelope = 0;
  bool _isTriggered = false;
  double _currentEnvelopePhase = 0.0; // 0-1 through ADSR cycle
  
  // Envelope editor interaction
  bool _isDraggingPoint = false;
  int _draggedPoint = -1; // 0=attack, 1=decay, 2=sustain, 3=release

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _envelopeController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _triggerController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Start envelope simulation
    _startEnvelopeSimulation();
  }

  void _startEnvelopeSimulation() {
    // Simulate envelope triggers every few seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _triggerEnvelope();
        _startEnvelopeSimulation();
      }
    });
  }

  void _triggerEnvelope() {
    setState(() {
      _isTriggered = true;
    });
    
    _triggerController.forward().then((_) {
      _triggerController.reverse();
    });
    
    _envelopeController.reset();
    _envelopeController.forward();
    
    // Reset trigger state after envelope completes
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _isTriggered = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _envelopeController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HolographicTheme.primaryEnergy.withOpacity(0.05 + (_pulseController.value * 0.02)),
                HolographicTheme.secondaryEnergy.withOpacity(0.03),
                HolographicTheme.deepSpaceBlack.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.3 + (_pulseController.value * 0.1)),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Envelope selection tabs
                _buildEnvelopeTabs(),
                
                const SizedBox(height: 16),
                
                // Visual envelope editor
                _buildEnvelopeVisualizer(),
                
                const SizedBox(height: 16),
                
                // ADSR parameter controls
                _buildADSRControls(),
                
                const SizedBox(height: 12),
                
                // Additional envelope controls
                _buildAdditionalControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnvelopeTabs() {
    return Row(
      children: [
        // Envelope selection tabs
        Expanded(
          child: Row(
            children: List.generate(_envelopes.length, (index) {
              final isSelected = index == _selectedEnvelope;
              final isEnabled = _envelopes[index]['enabled']! > 0.5;
              final envelopeColor = _envelopeColors[index];
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEnvelope = index),
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isSelected ? [
                          envelopeColor.withOpacity(0.3),
                          envelopeColor.withOpacity(0.1),
                        ] : [
                          envelopeColor.withOpacity(isEnabled ? 0.15 : 0.05),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                          ? envelopeColor 
                          : envelopeColor.withOpacity(isEnabled ? 0.5 : 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _envelopeNames[index],
                                style: HolographicTheme.createHolographicText(
                                  energyColor: isSelected 
                                    ? envelopeColor 
                                    : envelopeColor.withOpacity(isEnabled ? 1.0 : 0.7),
                                  fontSize: 11,
                                  glowIntensity: isSelected ? 0.8 : (isEnabled ? 0.5 : 0.3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ADSR',
                                style: HolographicTheme.createHolographicText(
                                  energyColor: HolographicTheme.secondaryEnergy.withOpacity(0.6),
                                  fontSize: 8,
                                  glowIntensity: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Enable/disable toggle
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _toggleEnvelope(index),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isEnabled 
                                  ? HolographicTheme.accentEnergy 
                                  : envelopeColor.withOpacity(0.3),
                                shape: BoxShape.circle,
                                boxShadow: isEnabled ? [
                                  BoxShadow(
                                    color: HolographicTheme.accentEnergy.withOpacity(0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Trigger button
        GestureDetector(
          onTap: _triggerEnvelope,
          child: AnimatedBuilder(
            animation: _triggerController,
            builder: (context, child) {
              return Container(
                width: 60,
                height: 50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      HolographicTheme.accentEnergy.withOpacity(0.3 + (_triggerController.value * 0.4)),
                      HolographicTheme.accentEnergy.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: HolographicTheme.accentEnergy.withOpacity(0.6 + (_triggerController.value * 0.4)),
                    width: 1 + (_triggerController.value * 2),
                  ),
                  boxShadow: _triggerController.value > 0 ? [
                    BoxShadow(
                      color: HolographicTheme.accentEnergy.withOpacity(_triggerController.value * 0.6),
                      blurRadius: 8 * _triggerController.value,
                      spreadRadius: 4 * _triggerController.value,
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'TRIG',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.accentEnergy,
                      fontSize: 12,
                      glowIntensity: 0.6 + (_triggerController.value * 0.4),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnvelopeVisualizer() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolographicTheme.deepSpaceBlack.withOpacity(0.9),
            _envelopeColors[_selectedEnvelope].withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _envelopeColors[_selectedEnvelope].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([_envelopeController, _pulseController]),
            builder: (context, child) {
              return CustomPaint(
                painter: EnvelopePainter(
                  envelopeParams: _envelopes[_selectedEnvelope],
                  color: _envelopeColors[_selectedEnvelope],
                  animationValue: _envelopeController.value,
                  pulseValue: _pulseController.value,
                  isTriggered: _isTriggered,
                  isDragging: _isDraggingPoint,
                  draggedPoint: _draggedPoint,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildADSRControls() {
    final currentEnv = _envelopes[_selectedEnvelope];
    
    return Row(
      children: [
        // Attack
        Expanded(
          child: HolographicKnob(
            label: 'ATTACK',
            value: math.log(currentEnv['attack']! * 1000 + 10) / math.log(10010),
            onChanged: (value) => _updateEnvelopeParam(
              'attack', 
              (math.pow(10010, value) - 10) / 1000
            ),
            color: _envelopeColors[_selectedEnvelope],
            showSpectrum: false,
            size: 70,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Decay
        Expanded(
          child: HolographicKnob(
            label: 'DECAY',
            value: math.log(currentEnv['decay']! * 1000 + 10) / math.log(10010),
            onChanged: (value) => _updateEnvelopeParam(
              'decay', 
              (math.pow(10010, value) - 10) / 1000
            ),
            color: _envelopeColors[_selectedEnvelope],
            showSpectrum: false,
            size: 70,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Sustain
        Expanded(
          child: HolographicKnob(
            label: 'SUSTAIN',
            value: currentEnv['sustain']!,
            onChanged: (value) => _updateEnvelopeParam('sustain', value),
            color: _envelopeColors[_selectedEnvelope],
            showSpectrum: false,
            size: 70,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Release
        Expanded(
          child: HolographicKnob(
            label: 'RELEASE',
            value: math.log(currentEnv['release']! * 1000 + 10) / math.log(10010),
            onChanged: (value) => _updateEnvelopeParam(
              'release', 
              (math.pow(10010, value) - 10) / 1000
            ),
            color: _envelopeColors[_selectedEnvelope],
            showSpectrum: false,
            size: 70,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    final currentEnv = _envelopes[_selectedEnvelope];
    
    return Row(
      children: [
        // Velocity sensitivity
        Expanded(
          child: HolographicKnob(
            label: 'VELOCITY',
            value: currentEnv['velocity']!,
            onChanged: (value) => _updateEnvelopeParam('velocity', value),
            color: HolographicTheme.secondaryEnergy,
            showSpectrum: false,
            size: 60,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Curve shape
        Expanded(
          child: HolographicKnob(
            label: 'CURVE',
            value: currentEnv['curve']!,
            onChanged: (value) => _updateEnvelopeParam('curve', value),
            color: HolographicTheme.accentEnergy,
            showSpectrum: false,
            size: 60,
          ),
        ),
        
        // Spacers to maintain layout
        Expanded(child: Container()),
        Expanded(child: Container()),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    // Determine which control point was clicked
    final localPosition = details.localPosition;
    // Implementation would check proximity to ADSR control points
    setState(() {
      _isDraggingPoint = true;
      // _draggedPoint would be set based on proximity detection
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDraggingPoint) return;
    
    // Update envelope parameter based on drag position
    // Implementation would modify the appropriate ADSR value
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDraggingPoint = false;
      _draggedPoint = -1;
    });
  }

  void _toggleEnvelope(int envelopeIndex) {
    setState(() {
      _envelopes[envelopeIndex]['enabled'] = 
          _envelopes[envelopeIndex]['enabled']! > 0.5 ? 0.0 : 1.0;
    });
    
    widget.onParameterChange(
      'envelope_${envelopeIndex}_enabled', 
      _envelopes[envelopeIndex]['enabled']!
    );
  }

  void _updateEnvelopeParam(String param, double value) {
    setState(() {
      _envelopes[_selectedEnvelope][param] = value;
    });
    
    widget.onParameterChange(
      'envelope_${_selectedEnvelope}_$param', 
      value
    );
  }
}

/// Custom painter for envelope visualization
class EnvelopePainter extends CustomPainter {
  final Map<String, double> envelopeParams;
  final Color color;
  final double animationValue;
  final double pulseValue;
  final bool isTriggered;
  final bool isDragging;
  final int draggedPoint;

  EnvelopePainter({
    required this.envelopeParams,
    required this.color,
    required this.animationValue,
    required this.pulseValue,
    required this.isTriggered,
    required this.isDragging,
    required this.draggedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawEnvelopeCurve(canvas, size);
    _drawProgressIndicator(canvas, size);
    _drawControlPoints(canvas, size);
    _drawLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1 + (pulseValue * 0.03))
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Time grid (vertical lines)
    for (int i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Amplitude grid (horizontal lines)
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  void _drawEnvelopeCurve(Canvas canvas, Size size) {
    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final sustain = envelopeParams['sustain']!;
    final release = envelopeParams['release']!;
    final curve = envelopeParams['curve']!;
    
    // Calculate phase durations (normalized to total width)
    final totalTime = attack + decay + 0.5 + release; // 0.5s sustain display
    final attackWidth = (attack / totalTime) * size.width;
    final decayWidth = (decay / totalTime) * size.width;
    final sustainWidth = (0.5 / totalTime) * size.width;
    final releaseWidth = (release / totalTime) * size.width;
    
    final path = Path();
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start at zero
    path.moveTo(0, size.height);
    
    // Attack phase
    final attackEndY = size.height * 0.1; // Near top
    _addCurvedSegment(path, 0, size.height, attackWidth, attackEndY, curve);
    
    // Decay phase
    final sustainY = size.height * (1.0 - sustain);
    _addCurvedSegment(path, attackWidth, attackEndY, attackWidth + decayWidth, sustainY, 1.0 - curve);
    
    // Sustain phase (flat line)
    path.lineTo(attackWidth + decayWidth + sustainWidth, sustainY);
    
    // Release phase
    _addCurvedSegment(
      path, 
      attackWidth + decayWidth + sustainWidth, 
      sustainY, 
      attackWidth + decayWidth + sustainWidth + releaseWidth, 
      size.height, 
      curve
    );

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw animated progress trail if triggered
    if (isTriggered && animationValue > 0) {
      _drawProgressTrail(canvas, size, path);
    }
  }

  void _addCurvedSegment(Path path, double startX, double startY, double endX, double endY, double curveFactor) {
    if (curveFactor < 0.01) {
      // Linear
      path.lineTo(endX, endY);
    } else {
      // Curved using quadratic bezier
      final controlX = startX + (endX - startX) * 0.5;
      final controlY = curveFactor < 0.5 
        ? startY + (endY - startY) * (curveFactor * 2) // Concave
        : startY + (endY - startY) * (2 - curveFactor * 2); // Convex
      
      path.quadraticBezierTo(controlX, controlY, endX, endY);
    }
  }

  void _drawProgressTrail(Canvas canvas, Size size, Path envelopePath) {
    final progressPaint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.8)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create a path that shows progress through the envelope
    final pathMetrics = envelopePath.computeMetrics();
    for (final metric in pathMetrics) {
      final progressLength = metric.length * animationValue;
      final progressPath = metric.extractPath(0, progressLength);
      
      // Draw the progress with a glowing effect
      final glowPaint = Paint()
        ..color = HolographicTheme.accentEnergy.withOpacity(0.4)
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawPath(progressPath, glowPaint);
      canvas.drawPath(progressPath, progressPaint);
    }
  }

  void _drawProgressIndicator(Canvas canvas, Size size) {
    if (!isTriggered || animationValue == 0) return;

    // Draw a moving dot along the envelope curve
    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final sustain = envelopeParams['sustain']!;
    final release = envelopeParams['release']!;
    
    final totalTime = attack + decay + 0.5 + release;
    final currentTime = animationValue * totalTime;
    
    double x, y;
    
    if (currentTime <= attack) {
      // In attack phase
      final progress = currentTime / attack;
      x = (currentTime / totalTime) * size.width;
      y = size.height * (1.0 - progress);
    } else if (currentTime <= attack + decay) {
      // In decay phase
      final progress = (currentTime - attack) / decay;
      x = ((attack + (currentTime - attack)) / totalTime) * size.width;
      y = size.height * (1.0 - (1.0 - progress * (1.0 - sustain)));
    } else if (currentTime <= attack + decay + 0.5) {
      // In sustain phase
      x = ((attack + decay + (currentTime - attack - decay)) / totalTime) * size.width;
      y = size.height * (1.0 - sustain);
    } else {
      // In release phase
      final progress = (currentTime - attack - decay - 0.5) / release;
      x = ((attack + decay + 0.5 + (currentTime - attack - decay - 0.5)) / totalTime) * size.width;
      y = size.height * (1.0 - sustain * (1.0 - progress));
    }

    // Draw the progress dot
    final dotPaint = Paint()
      ..color = HolographicTheme.accentEnergy
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(x, y),
      6.0,
      Paint()
        ..color = HolographicTheme.accentEnergy.withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0),
    );
    
    canvas.drawCircle(Offset(x, y), 4.0, dotPaint);
  }

  void _drawControlPoints(Canvas canvas, Size size) {
    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final sustain = envelopeParams['sustain']!;
    final release = envelopeParams['release']!;
    
    final totalTime = attack + decay + 0.5 + release;
    final attackWidth = (attack / totalTime) * size.width;
    final decayWidth = (decay / totalTime) * size.width;
    final sustainWidth = (0.5 / totalTime) * size.width;
    
    final controlPoints = [
      Offset(attackWidth, size.height * 0.1), // Attack peak
      Offset(attackWidth + decayWidth, size.height * (1.0 - sustain)), // Sustain level
      Offset(attackWidth + decayWidth + sustainWidth, size.height * (1.0 - sustain)), // Sustain end
    ];

    final pointPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final highlightPaint = Paint()
      ..color = HolographicTheme.accentEnergy
      ..style = PaintingStyle.fill;

    for (int i = 0; i < controlPoints.length; i++) {
      final point = controlPoints[i];
      final isHighlighted = draggedPoint == i;
      final radius = isHighlighted ? 6.0 : 4.0;
      
      // Draw glow
      canvas.drawCircle(
        point,
        radius + 2,
        Paint()
          ..color = (isHighlighted ? HolographicTheme.accentEnergy : color).withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0),
      );
      
      // Draw point
      canvas.drawCircle(
        point,
        radius,
        isHighlighted ? highlightPaint : pointPaint,
      );
    }
  }

  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = ['A', 'D', 'S', 'R'];
    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final totalTime = attack + decay + 0.5 + envelopeParams['release']!;
    
    final positions = [
      size.width * 0.1,
      size.width * (attack / totalTime + 0.05),
      size.width * ((attack + decay + 0.25) / totalTime),
      size.width * 0.9,
    ];

    for (int i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: HolographicTheme.createHolographicText(
          energyColor: color.withOpacity(0.8),
          fontSize: 12,
          glowIntensity: 0.5,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(positions[i] - textPainter.width / 2, size.height - 20),
      );
    }
  }

  @override
  bool shouldRepaint(EnvelopePainter oldDelegate) {
    return oldDelegate.envelopeParams != envelopeParams ||
           oldDelegate.animationValue != animationValue ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.isTriggered != isTriggered ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.draggedPoint != draggedPoint;
  }
}