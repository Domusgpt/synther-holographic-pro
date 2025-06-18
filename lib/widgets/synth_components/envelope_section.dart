import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      'hold': 0.5,      // Visual sustain hold time before release
      'velocity': 0.8,  // Velocity sensitivity 0-1
      'curve': 0.5,     // Curve shape 0-1 (linear to exponential)
      'enabled': 1.0,   // On/off
    },
    {
      'attack': 0.05,
      'decay': 0.2,
      'sustain': 0.5,
      'release': 0.8,
      'hold': 0.5,
      'velocity': 0.6,
      'curve': 0.3,
      'enabled': 1.0,
    },
    {
      'attack': 0.2,
      'decay': 0.1,
      'sustain': 0.0,
      'release': 0.3,
      'hold': 0.2,
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
  int _draggedPoint = -1; // 0: Attack Peak, 1: DecayEnd/SustainLevel, 2: SustainVisualEnd/HoldEnd
  Size _painterSize = Size.zero;
  final double _controlPointRadius = 20.0; // Increased for easier touch
  final double _totalDisplayTime = 4.0; // Fixed total time for the X-axis of the painter in seconds

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
              mainAxisSize: MainAxisSize.min,
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
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_envelopes.length, (index) {
              final isSelected = index == _selectedEnvelope;
              final isEnabled = _envelopes[index]['enabled']! > 0.5;
              final envelopeColor = _envelopeColors[index];
              
              return Flexible(
                fit: FlexFit.loose,
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
                            mainAxisSize: MainAxisSize.min,
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
          child: LayoutBuilder( // Ensure LayoutBuilder is outside AnimatedBuilder if _painterSize is set here
            builder: (context, constraints) {
              // Capture painter size for drag calculations if not already set or if it can change
              // However, it's better to get it dynamically in pan handlers if possible,
              // or ensure it's stable. For now, let's assume it's relatively stable once laid out.
              // _painterSize = Size(constraints.maxWidth, constraints.maxHeight);
              return AnimatedBuilder(
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
                      totalDisplayTime: _totalDisplayTime, // Pass fixed display time
                    ),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  );
                },
              );
            }
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
        Flexible(
          fit: FlexFit.loose,
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
        Flexible(
          fit: FlexFit.loose,
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
        Flexible(
          fit: FlexFit.loose,
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
        Flexible(
          fit: FlexFit.loose,
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
      mainAxisSize: MainAxisSize.min,
      children: [
        // Velocity sensitivity
        Flexible(
          fit: FlexFit.loose,
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
        Flexible(
          fit: FlexFit.loose,
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
        Flexible(fit: FlexFit.loose, child: Container()),
        Flexible(fit: FlexFit.loose, child: Container()),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    _painterSize = renderBox.size;
    final localPosition = details.localPosition;

    final currentParams = _envelopes[_selectedEnvelope];
    final attackTime = currentParams['attack']!;
    final decayTime = currentParams['decay']!;
    final sustainLevel = currentParams['sustain']!;
    final holdTime = currentParams['hold']!;

    // Calculate control point screen coordinates based on _totalDisplayTime
    // P0 (Attack Peak)
    final p0x = (attackTime / _totalDisplayTime) * _painterSize.width;
    final p0y = 0.0; // Peak is at the top
    // P1 (Decay End / Sustain Level)
    final p1x = ((attackTime + decayTime) / _totalDisplayTime) * _painterSize.width;
    final p1y = (1.0 - sustainLevel) * _painterSize.height;
    // P2 (Sustain Visual End / Hold End)
    final p2x = ((attackTime + decayTime + holdTime) / _totalDisplayTime) * _painterSize.width;
    final p2y = (1.0 - sustainLevel) * _painterSize.height; // Same Y as p1

    final points = [Offset(p0x, p0y), Offset(p1x, p1y), Offset(p2x, p2y)];
    int newDraggedPoint = -1;

    for (int i = 0; i < points.length; i++) {
      if ((localPosition - points[i]).distance < _controlPointRadius) {
        newDraggedPoint = i;
        break;
      }
    }

    if (newDraggedPoint != -1) {
      setState(() {
        _isDraggingPoint = true;
        _draggedPoint = newDraggedPoint;
        // HapticFeedback.lightImpact(); // Re-enable if available
      });
      HapticFeedback.lightImpact(); // Consider adding haptics
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDraggingPoint || _draggedPoint == -1) return;

    final localPosition = details.localPosition;
    final currentParams = _envelopes[_selectedEnvelope];
    
    // Normalize positions (clamp to painter bounds)
    final normX = (localPosition.dx.clamp(0.0, _painterSize.width)) / _painterSize.width;
    final normY = (localPosition.dy.clamp(0.0, _painterSize.height)) / _painterSize.height;

    double newAttack, newDecay, newSustain, newHold;

    switch (_draggedPoint) {
      case 0: // Attack Peak
        newAttack = normX * _totalDisplayTime;
        // Ensure attack is not negative or excessively small, and respects other segment times
        newAttack = newAttack.clamp(0.01, _totalDisplayTime - (currentParams['decay']! + currentParams['hold']! + 0.02));
        _updateEnvelopeParam('attack', newAttack);
        break;
      case 1: // Decay End / Sustain Level
        final currentAttack = currentParams['attack']!;
        newDecay = (normX * _totalDisplayTime) - currentAttack;
        newDecay = newDecay.clamp(0.01, _totalDisplayTime - currentAttack - currentParams['hold']! - 0.01);
        _updateEnvelopeParam('decay', newDecay);

        newSustain = 1.0 - normY;
        newSustain = newSustain.clamp(0.0, 1.0);
        _updateEnvelopeParam('sustain', newSustain);
        break;
      case 2: // Sustain Visual End / Hold End (also updates sustain level)
        final currentAttack = currentParams['attack']!;
        final currentDecay = currentParams['decay']!;
        newHold = (normX * _totalDisplayTime) - (currentAttack + currentDecay);
        newHold = newHold.clamp(0.01, _totalDisplayTime - currentAttack - currentDecay - 0.01);
        _updateEnvelopeParam('hold', newHold);

        newSustain = 1.0 - normY;
        newSustain = newSustain.clamp(0.0, 1.0);
        _updateEnvelopeParam('sustain', newSustain); // This point also drags sustain up/down
        break;
    }
    // No need to call setState explicitly if _updateEnvelopeParam does it.
    // _updateEnvelopeParam already calls setState.
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDraggingPoint) { // Only update if actively dragging
      setState(() {
        _isDraggingPoint = false;
        _draggedPoint = -1;
      });
    }
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
  final double totalDisplayTime; // Added fixed total display time

  EnvelopePainter({
    required this.envelopeParams,
    required this.color,
    required this.animationValue,
    required this.pulseValue,
    required this.isTriggered,
    required this.isDragging,
    required this.draggedPoint,
    required this.totalDisplayTime, // Added
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
    final hold = envelopeParams['hold'] ?? 0.5; // Use 'hold' from params, fallback to 0.5
    final curve = envelopeParams['curve']!;
    
    // Calculate X positions based on totalDisplayTime
    // These are absolute X coordinates on the canvas
    final attackX = (attack / totalDisplayTime) * size.width;
    final decayX = ((attack + decay) / totalDisplayTime) * size.width;
    final holdX = ((attack + decay + hold) / totalDisplayTime) * size.width;
    // Release phase starts after holdX, its duration is 'release'
    // The visual end of release might be outside totalDisplayTime, clip drawing at size.width.

    final path = Path();
    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start at zero
    path.moveTo(0, size.height);
    
    // Attack phase
    final attackPeakY = 0.0; // Top of the painter
    _addCurvedSegment(path, 0, size.height, attackX.clamp(0, size.width), attackPeakY, curve);
    
    // Decay phase
    final sustainLineY = (1.0 - sustain) * size.height;
    _addCurvedSegment(path, attackX.clamp(0, size.width), attackPeakY, decayX.clamp(0, size.width), sustainLineY, 1.0 - curve);
    
    // Sustain (hold) phase (flat line)
    path.lineTo(holdX.clamp(0, size.width), sustainLineY);
    
    // Release phase
    // Release starts at holdX, sustainLineY. Ends 'release' seconds later.
    final releaseVisualEndX = ((attack + decay + hold + release) / totalDisplayTime) * size.width;
    _addCurvedSegment(
      path, 
      holdX.clamp(0, size.width),
      sustainLineY,
      releaseVisualEndX.clamp(0, size.width), // Clamp to ensure it's drawn within bounds
      size.height, // Ends at bottom
      curve // Use original curve for release, or specify another
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

    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final sustain = envelopeParams['sustain']!;
    final release = envelopeParams['release']!;
    final hold = envelopeParams['hold'] ?? 0.5;

    final double actualTotalEnvelopeTime = attack + decay + hold + release;

    if (actualTotalEnvelopeTime <= 0.00001) return; // Avoid division by zero and handle negligible times

    final double currentTime = animationValue * actualTotalEnvelopeTime;

    double x, y;

    if (currentTime <= attack) {
      final phaseProgress = (attack == 0) ? 1.0 : (currentTime / attack).clamp(0.0, 1.0);
      x = (currentTime / totalDisplayTime) * size.width;
      y = size.height * (1.0 - phaseProgress * (envelopeParams['velocity'] ?? 1.0));
    } else if (currentTime <= attack + decay) {
      final phaseProgress = (decay == 0) ? 1.0 : ((currentTime - attack) / decay).clamp(0.0, 1.0);
      x = (currentTime / totalDisplayTime) * size.width;
      final peakY = size.height * (1.0 - (envelopeParams['velocity'] ?? 1.0));
      final sustainY = size.height * (1.0 - sustain);
      y = peakY + (sustainY - peakY) * phaseProgress;
    } else if (currentTime <= attack + decay + hold) {
      x = (currentTime / totalDisplayTime) * size.width;
      y = size.height * (1.0 - sustain);
    } else if (currentTime <= actualTotalEnvelopeTime) {
      final phaseProgress = (release == 0) ? 1.0 : ((currentTime - attack - decay - hold) / release).clamp(0.0, 1.0);
      x = (currentTime / totalDisplayTime) * size.width;
      final sustainY = size.height * (1.0 - sustain);
      y = sustainY + (size.height - sustainY) * phaseProgress;
    } else {
      x = (actualTotalEnvelopeTime / totalDisplayTime) * size.width;
      y = size.height;
    }

    x = x.clamp(0.0, size.width);
    y = y.clamp(0.0, size.height);

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
    final hold = envelopeParams['hold'] ?? 0.5;
    // release is not used for control point positions here, but for total envelope duration
    
    // Points based on totalDisplayTime for consistent screen positions
    final p0x = (attack / totalDisplayTime) * size.width;
    final p0y = 0.0; // Attack peak is at the top

    final p1x = ((attack + decay) / totalDisplayTime) * size.width;
    final p1y = (1.0 - sustain) * size.height;

    final p2x = ((attack + decay + hold) / totalDisplayTime) * size.width;
    final p2y = (1.0 - sustain) * size.height; // Sustain level is the same Y

    final controlPoints = [
      Offset(p0x.clamp(0,size.width), p0y),
      Offset(p1x.clamp(0,size.width), p1y.clamp(0,size.height)),
      Offset(p2x.clamp(0,size.width), p2y.clamp(0,size.height)),
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
    final labels = ['A', 'D', 'H', 'R']; // Hold instead of Sustain for clarity here
    final attack = envelopeParams['attack']!;
    final decay = envelopeParams['decay']!;
    final hold = envelopeParams['hold'] ?? 0.5;
    // Release time from params
    final release = envelopeParams['release']!;

    // Position labels based on proportions of totalDisplayTime or their actual time values
    // These are approximate centers for the labels A, D, H(old), R(elease)
    // Ensure these calculations use totalDisplayTime for consistency with the visual scale
    final attackLabelX = (attack * 0.5 / totalDisplayTime) * size.width;
    final decayLabelX = ((attack + decay * 0.5) / totalDisplayTime) * size.width;
    final holdLabelX = ((attack + decay + hold * 0.5) / totalDisplayTime) * size.width;
    final releaseLabelX = ((attack + decay + hold + release * 0.5) / totalDisplayTime) * size.width;
    
    final positions = [
      attackLabelX,
      decayLabelX,
      holdLabelX,
      // For Release, it's trickier as its segment might be partially off-screen.
      // Let's place it somewhere reasonable within the visible part if possible.
      (holdLabelX + size.width) / 2, // Midpoint of remaining space or fixed offset
    ].map((x) => x.clamp(0.0, size.width - textPainter.width > 0 ? size.width - textPainter.width : 0.0 )).toList() ;


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