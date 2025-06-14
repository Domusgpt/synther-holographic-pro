// Professional XY Pad with Parameter Assignment Dropdowns
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/hyperav_bridge.dart';
import '../core/holographic_theme.dart';

enum SynthParameter {
  filterCutoff('CUTOFF', 'Filter Cutoff Frequency'),
  filterResonance('RESONANCE', 'Filter Resonance'),
  oscillatorMix('OSC MIX', 'Oscillator Mix'),
  reverbAmount('REVERB', 'Reverb Amount'),
  delayTime('DELAY', 'Delay Time'),
  lfoRate('LFO RATE', 'LFO Rate'),
  attackTime('ATTACK', 'Envelope Attack'),
  releaseTime('RELEASE', 'Envelope Release'),
  crystal('CRYSTAL', 'Crystal Effect'),
  shimmer('SHIMMER', 'Shimmer Effect'),
  depth('DEPTH', 'Depth Parameter'),
  warp('WARP', 'Warp Parameter'),
  distortion('DISTORT', 'Distortion Amount'),
  chorus('CHORUS', 'Chorus Effect'),
  phaser('PHASER', 'Phaser Effect'),
  pitchBend('PITCH', 'Pitch Bend'),
  modWheel('MOD', 'Modulation Wheel'),
  volume('VOLUME', 'Master Volume'),
  panning('PAN', 'Stereo Panning'),
  bassBoost('BASS', 'Bass Boost');

  const SynthParameter(this.displayName, this.description);
  final String displayName;
  final String description;
}

class ProfessionalXYPad extends StatefulWidget {
  final double width;
  final double height;
  final SynthParameter xParameter;
  final SynthParameter yParameter;
  final Function(SynthParameter)? onXParameterChanged;
  final Function(SynthParameter)? onYParameterChanged;
  final Function(double, double)? onValueChanged;
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const ProfessionalXYPad({
    Key? key,
    this.width = 300.0,
    this.height = 300.0,
    this.xParameter = SynthParameter.filterCutoff,
    this.yParameter = SynthParameter.filterResonance,
    this.onXParameterChanged,
    this.onYParameterChanged,
    this.onValueChanged,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
  }) : super(key: key);

  @override
  State<ProfessionalXYPad> createState() => _ProfessionalXYPadState();
}

class _ProfessionalXYPadState extends State<ProfessionalXYPad>
    with TickerProviderStateMixin {
  late AnimationController _interactionController;
  late AnimationController _glowController;
  late AnimationController _energyController;
  
  late Animation<double> _glowAnimation;
  late Animation<double> _energyAnimation;
  
  double _xValue = 0.5;
  double _yValue = 0.5;
  bool _isInteracting = false;
  Offset _touchPosition = Offset(0.5, 0.5);
  
  // Energy particle system
  List<EnergyParticle> _particles = [];
  
  @override
  void initState() {
    super.initState();
    
    _interactionController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _energyController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _energyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_energyController);
    
    // Start ambient glow cycle
    _glowController.repeat(reverse: true);
    _energyController.repeat();
    
    // Initialize particles
    _initializeParticles();
  }

  void _initializeParticles() {
    _particles.clear();
    for (int i = 0; i < 8; i++) {
      _particles.add(EnergyParticle(
        position: Offset(
          math.Random().nextDouble(),
          math.Random().nextDouble(),
        ),
        velocity: Offset(
          (math.Random().nextDouble() - 0.5) * 0.02,
          (math.Random().nextDouble() - 0.5) * 0.02,
        ),
        life: math.Random().nextDouble(),
      ));
    }
  }

  void _updateTouchPosition(Offset localPosition) {
    final size = Size(widget.width, widget.height);
    
    setState(() {
      _xValue = (localPosition.dx / size.width).clamp(0.0, 1.0);
      _yValue = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
      _touchPosition = Offset(_xValue, 1.0 - _yValue);
      _isInteracting = true;
    });
    
    // Update synthesizer parameters
    widget.onValueChanged?.call(_xValue, _yValue);
    
    // Update HyperAV visualizer
    HyperAVBridge.instance.updateVisualizerParameter(
      widget.xParameter.name.toLowerCase(),
      _xValue,
    );
    HyperAVBridge.instance.updateVisualizerParameter(
      widget.yParameter.name.toLowerCase(),
      _yValue,
    );
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Trigger energy effect
    _interactionController.forward().then((_) {
      _interactionController.reverse();
    });
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
            color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0), // Adjusted
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.hoverTransparency), // Adjusted
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 4.0), // Adjusted
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.control_camera,
            color: HolographicTheme.primaryEnergy,
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
        width: widget.width,
        height: widget.height + 80, // Reduced extra space for controls
        child: Column(
          children: [
            // Header with collapse button
            _buildHeader(),
            SizedBox(height: 10),
            
            // Parameter assignment dropdowns
            _buildParameterControls(),
            SizedBox(height: 15),
            
            // Main XY pad
            _buildXYPad(),
            SizedBox(height: 10),
            
            // Value displays
            _buildValueDisplays(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: widget.width,
      height: 40,
      decoration: BoxDecoration(
        color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency), // Adjusted
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 4.0), // Adjusted
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Text(
            'XY PAD',
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6), // Adjusted
                  blurRadius: 4.0,
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
                color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0), // Adjusted
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.hoverTransparency), // Adjusted
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.primaryEnergy,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildParameterControls() {
    return Row(
      children: [
        // X Parameter Dropdown
        Expanded(
          child: _buildParameterDropdown(
            'X AXIS',
            widget.xParameter,
            widget.onXParameterChanged,
          ),
        ),
        SizedBox(width: 10),
        
        // Y Parameter Dropdown
        Expanded(
          child: _buildParameterDropdown(
            'Y AXIS',
            widget.yParameter,
            widget.onYParameterChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildParameterDropdown(
    String label,
    SynthParameter currentParameter,
    Function(SynthParameter)? onChanged,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency), // Adjusted
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 4.0), // Adjusted
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 20,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.7), // Adjusted
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SynthParameter>(
                value: currentParameter,
                isExpanded: true,
                dropdownColor: Colors.black.withOpacity(HolographicTheme.activeTransparency * 1.5), // Adjusted (Significantly reduced)
                style: TextStyle(
                  color: HolographicTheme.secondaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                items: SynthParameter.values.map((parameter) {
                  return DropdownMenuItem(
                    value: parameter,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        parameter.displayName,
                        style: TextStyle(
                          color: HolographicTheme.secondaryEnergy,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onChanged?.call(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXYPad() {
    return GestureDetector(
      onPanStart: (details) {
        _updateTouchPosition(details.localPosition);
      },
      onPanUpdate: (details) {
        _updateTouchPosition(details.localPosition);
      },
      onPanEnd: (details) {
        setState(() {
          _isInteracting = false;
        });
      },
      child: Container(
        width: widget.width,
        height: widget.width, // Square pad
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.hoverTransparency), // Adjusted
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 3.0), // Adjusted
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _glowAnimation,
              _energyAnimation,
            ]),
            builder: (context, child) {
              return CustomPaint(
                painter: XYPadPainter(
                  touchPosition: _touchPosition,
                  isInteracting: _isInteracting,
                  glowIntensity: _glowAnimation.value,
                  energyPhase: _energyAnimation.value,
                  particles: _particles,
                  xParameter: widget.xParameter,
                  yParameter: widget.yParameter,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildValueDisplays() {
    return Row(
      children: [
        Expanded(
          child: _buildValueDisplay(
            widget.xParameter.displayName,
            _xValue,
            HolographicTheme.primaryEnergy,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildValueDisplay(
            widget.yParameter.displayName,
            _yValue,
            HolographicTheme.secondaryEnergy,
          ),
        ),
      ],
    );
  }

  Widget _buildValueDisplay(String label, double value, Color color) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(HolographicTheme.widgetTransparency), // Adjusted
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(HolographicTheme.widgetTransparency * 4.0), // Adjusted
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(HolographicTheme.widgetTransparency * 2.0), // Adjusted
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7), // Adjusted
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: color.withOpacity(0.6), // Adjusted
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _interactionController.dispose();
    _glowController.dispose();
    _energyController.dispose();
    super.dispose();
  }
}

// Energy particle for visual effects
class EnergyParticle {
  Offset position;
  Offset velocity;
  double life;
  
  EnergyParticle({
    required this.position,
    required this.velocity,
    required this.life,
  });
  
  void update() {
    position += velocity;
    life += 0.01;
    
    // Wrap around edges
    if (position.dx < 0 || position.dx > 1) velocity = Offset(-velocity.dx, velocity.dy);
    if (position.dy < 0 || position.dy > 1) velocity = Offset(velocity.dx, -velocity.dy);
    
    position = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );
  }
}

// Custom painter for the XY pad with energy effects
class XYPadPainter extends CustomPainter {
  final Offset touchPosition;
  final bool isInteracting;
  final double glowIntensity;
  final double energyPhase;
  final List<EnergyParticle> particles;
  final SynthParameter xParameter;
  final SynthParameter yParameter;

  XYPadPainter({
    required this.touchPosition,
    required this.isInteracting,
    required this.glowIntensity,
    required this.energyPhase,
    required this.particles,
    required this.xParameter,
    required this.yParameter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw energy particles
    for (var particle in particles) {
      particle.update();
      _drawEnergyParticle(canvas, size, particle);
    }
    
    // Draw grid lines
    _drawGrid(canvas, size);
    
    // Draw touch position
    if (isInteracting) {
      _drawTouchPoint(canvas, size);
      _drawInteractionRipples(canvas, size);
    }
    
    // Draw parameter indicators
    _drawParameterIndicators(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0 * glowIntensity) // Adjusted
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Vertical lines
    for (int i = 1; i < 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    
    // Horizontal lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawTouchPoint(Canvas canvas, Size size) {
    final center = Offset(
      touchPosition.dx * size.width,
      touchPosition.dy * size.height,
    );
    
    // Main touch point
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 8, paint);
    
    // Glow effect
    final glowPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 3.0) // Adjusted
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 20, glowPaint);
  }

  void _drawInteractionRipples(Canvas canvas, Size size) {
    final center = Offset(
      touchPosition.dx * size.width,
      touchPosition.dy * size.height,
    );
    
    // Animated ripples
    for (int i = 0; i < 3; i++) {
      final ripplePhase = (energyPhase * 3 + i) % 1.0;
      final rippleRadius = ripplePhase * 60;
      final rippleOpacity = (1.0 - ripplePhase) * 0.6;
      
      final ripplePaint = Paint()
        ..color = HolographicTheme.primaryEnergy.withOpacity(rippleOpacity)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(center, rippleRadius, ripplePaint);
    }
  }

  void _drawEnergyParticle(Canvas canvas, Size size, EnergyParticle particle) {
    final position = Offset(
      particle.position.dx * size.width,
      particle.position.dy * size.height,
    );
    
    final opacity = math.sin(particle.life * math.pi) * 0.5;
    
    final paint = Paint()
      ..color = HolographicTheme.secondaryEnergy.withOpacity(opacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(position, 2, paint);
  }

  void _drawParameterIndicators(Canvas canvas, Size size) {
    // X parameter indicator (bottom)
    final xPos = touchPosition.dx * size.width;
    final xPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.hoverTransparency) // Adjusted
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(xPos, size.height - 5),
      Offset(xPos, size.height),
      xPaint,
    );
    
    // Y parameter indicator (right)
    final yPos = touchPosition.dy * size.height;
    final yPaint = Paint()
      ..color = HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.hoverTransparency) // Adjusted
      ..strokeWidth = 2;
    
    canvas.drawLine(
      Offset(size.width - 5, yPos),
      Offset(size.width, yPos),
      yPaint,
    );
  }

  @override
  bool shouldRepaint(XYPadPainter oldDelegate) {
    return oldDelegate.touchPosition != touchPosition ||
           oldDelegate.isInteracting != isInteracting ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.energyPhase != energyPhase;
  }
}