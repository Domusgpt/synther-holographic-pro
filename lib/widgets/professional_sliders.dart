// Professional Adjustable Sliders with Parameter Assignment
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/hyperav_bridge.dart';
import '../core/holographic_theme.dart';
import 'professional_xy_pad.dart'; // For SynthParameter enum

class ProfessionalSliders extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Function(String, double)? onParameterChanged;

  const ProfessionalSliders({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onParameterChanged,
  }) : super(key: key);

  @override
  State<ProfessionalSliders> createState() => _ProfessionalSlidersState();
}

class _ProfessionalSlidersState extends State<ProfessionalSliders>
    with TickerProviderStateMixin {
  
  // Slider configurations
  List<SliderConfig> _sliders = [
    SliderConfig(
      id: 'mix',
      parameter: SynthParameter.oscillatorMix,
      value: 0.5,
      color: HolographicTheme.primaryEnergy,
    ),
    SliderConfig(
      id: 'tempo',
      parameter: SynthParameter.lfoRate,
      value: 0.6,
      color: HolographicTheme.secondaryEnergy,
    ),
    SliderConfig(
      id: 'mod',
      parameter: SynthParameter.modWheel,
      value: 0.3,
      color: HolographicTheme.tertiaryEnergy,
    ),
    SliderConfig(
      id: 'fx',
      parameter: SynthParameter.chorus,
      value: 0.4,
      color: HolographicTheme.primaryEnergy,
    ),
  ];

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  // Touch tracking for each slider
  Map<String, bool> _sliderTouching = {};

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
    
    // Initialize touch tracking
    for (final slider in _sliders) {
      _sliderTouching[slider.id] = false;
    }
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
            color: HolographicTheme.primaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.linear_scale,
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
        width: 80,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.primaryEnergy.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Sliders
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                child: _buildSlidersColumn(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: HolographicTheme.primaryEnergy.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'SLIDERS',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                shadows: [
                  Shadow(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                    blurRadius: 4.0,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Collapse button
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: HolographicTheme.primaryEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.primaryEnergy,
                size: 12,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildSlidersColumn() {
    return Column(
      children: _sliders.asMap().entries.map((entry) {
        final index = entry.key;
        final slider = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: _buildSlider(slider, index),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlider(SliderConfig slider, int index) {
    final isTouching = _sliderTouching[slider.id] ?? false;
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        final glowIntensity = _glowAnimation.value + (isTouching ? 0.5 : 0.0);
        
        return Column(
          children: [
            // Parameter dropdown
            Container(
              height: 25,
              width: double.infinity,
              decoration: BoxDecoration(
                color: slider.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: slider.color.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<SynthParameter>(
                  value: slider.parameter,
                  isExpanded: true,
                  dropdownColor: Colors.black.withOpacity(0.9),
                  style: TextStyle(
                    color: slider.color,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  items: SynthParameter.values.map((parameter) {
                    return DropdownMenuItem(
                      value: parameter,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          parameter.displayName,
                          style: TextStyle(
                            color: slider.color,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sliders[index] = slider.copyWith(parameter: value);
                      });
                    }
                  },
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // Slider track
            Expanded(
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _sliderTouching[slider.id] = true;
                  });
                  _updateSliderValue(slider.id, details.localPosition.dy);
                },
                onPanUpdate: (details) {
                  _updateSliderValue(slider.id, details.localPosition.dy);
                },
                onPanEnd: (details) {
                  setState(() {
                    _sliderTouching[slider.id] = false;
                  });
                },
                child: Container(
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: slider.color.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: slider.color.withOpacity(0.3 * glowIntensity),
                        blurRadius: 10 * glowIntensity,
                        spreadRadius: 2 * glowIntensity,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: SliderPainter(
                      value: slider.value,
                      color: slider.color,
                      glowIntensity: glowIntensity,
                      isTouching: isTouching,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // Value display
            Container(
              height: 20,
              width: double.infinity,
              decoration: BoxDecoration(
                color: slider.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: slider.color.withOpacity(0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '${(slider.value * 100).round()}',
                style: TextStyle(
                  color: slider.color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: slider.color.withOpacity(0.8),
                      blurRadius: 3.0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSliderValue(String sliderId, double localY) {
    final sliderIndex = _sliders.indexWhere((s) => s.id == sliderId);
    if (sliderIndex == -1) return;
    
    final slider = _sliders[sliderIndex];
    
    // Calculate new value (inverted because we want top to be 1.0)
    final sliderHeight = 200.0; // Approximate height
    final newValue = (1.0 - (localY / sliderHeight)).clamp(0.0, 1.0);
    
    setState(() {
      _sliders[sliderIndex] = slider.copyWith(value: newValue);
    });
    
    // Trigger callbacks
    widget.onParameterChanged?.call(slider.parameter.name.toLowerCase(), newValue);
    
    // Update HyperAV visualizer
    HyperAVBridge.instance.updateVisualizerParameter(
      slider.parameter.name.toLowerCase(),
      newValue,
    );
    
    // Haptic feedback
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
}

// Data class for slider configuration
class SliderConfig {
  final String id;
  final SynthParameter parameter;
  final double value;
  final Color color;

  const SliderConfig({
    required this.id,
    required this.parameter,
    required this.value,
    required this.color,
  });

  SliderConfig copyWith({
    String? id,
    SynthParameter? parameter,
    double? value,
    Color? color,
  }) {
    return SliderConfig(
      id: id ?? this.id,
      parameter: parameter ?? this.parameter,
      value: value ?? this.value,
      color: color ?? this.color,
    );
  }
}

// Custom painter for the slider with energy effects
class SliderPainter extends CustomPainter {
  final double value;
  final Color color;
  final double glowIntensity;
  final bool isTouching;

  SliderPainter({
    required this.value,
    required this.color,
    required this.glowIntensity,
    required this.isTouching,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw track
    canvas.drawLine(
      Offset(size.width / 2, 5),
      Offset(size.width / 2, size.height - 5),
      trackPaint,
    );
    
    // Draw filled section
    final fillPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    final fillStart = size.height - 5 - (size.height - 10) * value;
    canvas.drawLine(
      Offset(size.width / 2, fillStart),
      Offset(size.width / 2, size.height - 5),
      fillPaint,
    );
    
    // Draw thumb
    final thumbY = size.height - 5 - (size.height - 10) * value;
    final thumbPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, thumbY),
      isTouching ? 8 : 6,
      thumbPaint,
    );
    
    // Draw glow
    if (glowIntensity > 0.5) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4 * glowIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size.width / 2, thumbY),
        12 * glowIntensity,
        glowPaint,
      );
    }
    
    // Draw energy particles
    for (int i = 0; i < 3; i++) {
      final particleY = thumbY + math.sin((i * 2.0 + glowIntensity * 10)) * 8;
      final particlePaint = Paint()
        ..color = color.withOpacity(0.3 * glowIntensity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(size.width / 2 + (i - 1) * 6, particleY),
        1.5,
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(SliderPainter oldDelegate) {
    return oldDelegate.value != value ||
           oldDelegate.glowIntensity != glowIntensity ||
           oldDelegate.isTouching != isTouching;
  }
}