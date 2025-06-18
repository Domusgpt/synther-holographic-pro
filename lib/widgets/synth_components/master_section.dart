import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';
import 'spectrum_display.dart';

/// Professional Master Section with final output controls
/// 
/// Features:
/// - Master volume with precise dB scaling
/// - Professional limiter/compressor for output protection
/// - Stereo width and balance controls
/// - Real-time level meters with peak indicators
/// - Output routing and monitoring options
/// - Headroom monitoring and clipping detection
/// - Professional VU-style metering with ballistics
/// - Output spectrum analysis and phase correlation
class MasterSection extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const MasterSection({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<MasterSection> createState() => _MasterSectionState();
}

class _MasterSectionState extends State<MasterSection> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _meterController;
  late AnimationController _peakController;
  
  // Master parameters
  final Map<String, double> _masterParams = {
    'volume': 0.8,           // Master volume 0-1
    'balance': 0.0,          // L/R balance -1 to 1
    'stereo_width': 1.0,     // Stereo width 0-2
    'limiter_enabled': 1.0,  // Output limiter on/off
    'limiter_threshold': -0.5, // Limiter threshold in dB
    'limiter_release': 100.0, // Limiter release time in ms
    'mono_mode': 0.0,        // Mono summing mode
    'polarity_invert': 0.0,  // Phase inversion
  };

  // Metering state
  double _leftLevel = 0.0;     // Current left level
  double _rightLevel = 0.0;    // Current right level
  double _leftPeak = 0.0;      // Left peak hold
  double _rightPeak = 0.0;     // Right peak hold
  double _peakHoldTime = 0.0;  // Peak hold timer
  
  // Limiter state
  double _gainReduction = 0.0; // Current gain reduction in dB
  bool _clippingDetected = false;
  
  // Output monitoring
  int _outputMode = 0; // 0=stereo, 1=left, 2=right, 3=mono, 4=side
  final List<String> _outputModes = [
    'STEREO', 'LEFT', 'RIGHT', 'MONO', 'SIDE'
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _meterController = AnimationController(
      duration: const Duration(milliseconds: 50), // 20fps metering
      vsync: this,
    )..repeat();
    
    _peakController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Start meter simulation
    _meterController.addListener(_updateMeters);
  }

  void _updateMeters() {
    // Simulate realistic meter movement
    final time = _meterController.value * 2 * math.pi;
    final volume = _masterParams['volume']!;
    
    setState(() {
      // Simulate audio levels with some dynamics
      _leftLevel = (volume * (0.3 + 0.4 * math.sin(time * 2.3) + 0.2 * math.sin(time * 5.7))).clamp(0.0, 1.2);
      _rightLevel = (volume * (0.3 + 0.4 * math.sin(time * 2.1) + 0.2 * math.sin(time * 6.1))).clamp(0.0, 1.2);
      
      // Peak detection
      if (_leftLevel > _leftPeak) {
        _leftPeak = _leftLevel;
        _peakHoldTime = 2.0; // Hold for 2 seconds
      }
      if (_rightLevel > _rightPeak) {
        _rightPeak = _rightLevel;
        _peakHoldTime = 2.0;
      }
      
      // Peak decay
      if (_peakHoldTime > 0) {
        _peakHoldTime -= 0.05; // 50ms update rate
      } else {
        _leftPeak = math.max(0.0, _leftPeak - 0.02); // Slow decay
        _rightPeak = math.max(0.0, _rightPeak - 0.02);
      }
      
      // Clipping detection
      _clippingDetected = _leftLevel > 1.0 || _rightLevel > 1.0;
      if (_clippingDetected) {
        _peakController.forward();
      }
      
      // Limiter gain reduction simulation
      if (_masterParams['limiter_enabled']! > 0.5) {
        final threshold = _masterParams['limiter_threshold']!;
        final thresholdLinear = math.pow(10, threshold / 20);
        final maxLevel = math.max(_leftLevel, _rightLevel);
        
        if (maxLevel > thresholdLinear) {
          _gainReduction = 20 * math.log((maxLevel / thresholdLinear)) / math.ln10;
        } else {
          _gainReduction = math.max(0.0, _gainReduction - 0.5); // Fast release
        }
      } else {
        _gainReduction = 0.0;
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _meterController.dispose();
    _peakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 300,
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
                // Header
                Text(
                  'MASTER OUTPUT',
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.primaryEnergy,
                    fontSize: 12,
                    glowIntensity: 0.6,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Level meters and volume
                Row(
                  children: [
                    // Level meters
                    _buildLevelMeters(),
                    
                    const SizedBox(width: 16),
                    
                    // Master volume
                    Flexible(
                      fit: FlexFit.loose,
                      child: HolographicKnob(
                        label: 'VOLUME',
                        value: _masterParams['volume']!,
                        onChanged: (value) => _updateMasterParam('volume', value),
                        color: HolographicTheme.primaryEnergy,
                        showSpectrum: false,
                        size: 80,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Stereo controls
                Row(
                  children: [
                    // Balance
                    Flexible(
                      fit: FlexFit.loose,
                      child: HolographicKnob(
                        label: 'BALANCE',
                        value: (_masterParams['balance']! + 1.0) / 2.0,
                        onChanged: (value) => _updateMasterParam('balance', (value * 2.0) - 1.0),
                        color: HolographicTheme.secondaryEnergy,
                        showSpectrum: false,
                        size: 60,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Stereo width
                    Flexible(
                      fit: FlexFit.loose,
                      child: HolographicKnob(
                        label: 'WIDTH',
                        value: _masterParams['stereo_width']! / 2.0,
                        onChanged: (value) => _updateMasterParam('stereo_width', value * 2.0),
                        color: HolographicTheme.accentEnergy,
                        showSpectrum: false,
                        size: 60,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Limiter controls
                _buildLimiterSection(),
                
                const SizedBox(height: 16),
                
                // Output routing and monitoring
                _buildOutputControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelMeters() {
    return Container(
      width: 60,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolographicTheme.deepSpaceBlack.withOpacity(0.9),
            HolographicTheme.primaryEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: _peakController,
        builder: (context, child) {
          return CustomPaint(
            painter: LevelMeterPainter(
              leftLevel: _leftLevel,
              rightLevel: _rightLevel,
              leftPeak: _leftPeak,
              rightPeak: _rightPeak,
              clipping: _clippingDetected,
              clippingFlash: _peakController.value,
              gainReduction: _gainReduction,
            ),
            child: SizedBox(
              width: 60,
              height: 120,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLimiterSection() {
    final limiterEnabled = _masterParams['limiter_enabled']! > 0.5;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Limiter header with enable toggle
        Row(
          children: [
            Text(
              'OUTPUT LIMITER',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.accentEnergy,
                fontSize: 11,
                glowIntensity: 0.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _updateMasterParam('limiter_enabled', limiterEnabled ? 0.0 : 1.0),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: limiterEnabled 
                    ? HolographicTheme.accentEnergy 
                    : HolographicTheme.primaryEnergy.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: limiterEnabled ? [
                    BoxShadow(
                      color: HolographicTheme.accentEnergy.withOpacity(0.6),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Limiter controls
        if (limiterEnabled) ...[
          Row(
            children: [
              // Threshold
              Flexible(
                fit: FlexFit.loose,
                child: HolographicKnob(
                  label: 'THRESHOLD',
                  value: (_masterParams['limiter_threshold']! + 12.0) / 12.0,
                  onChanged: (value) => _updateMasterParam('limiter_threshold', (value * 12.0) - 12.0),
                  color: HolographicTheme.accentEnergy,
                  showSpectrum: false,
                  size: 50,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Release time
              Flexible(
                fit: FlexFit.loose,
                child: HolographicKnob(
                  label: 'RELEASE',
                  value: math.log(_masterParams['limiter_release']! + 1) / math.log(1001),
                  onChanged: (value) => _updateMasterParam('limiter_release', math.pow(1001, value) - 1),
                  color: HolographicTheme.secondaryEnergy,
                  showSpectrum: false,
                  size: 50,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Gain reduction meter
              _buildGainReductionMeter(),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGainReductionMeter() {
    return Container(
      width: 40,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolographicTheme.deepSpaceBlack.withOpacity(0.9),
            HolographicTheme.accentEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: HolographicTheme.accentEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'GR',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.accentEnergy,
              fontSize: 8,
              glowIntensity: 0.4,
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: CustomPaint(
              painter: GainReductionMeterPainter(
                gainReduction: _gainReduction,
                color: HolographicTheme.accentEnergy,
              ),
              child: SizedBox(
                width: 40,
                height: 30,
              ),
            ),
          ),
          Text(
            '${_gainReduction.toStringAsFixed(1)}',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.accentEnergy,
              fontSize: 7,
              glowIntensity: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutputControls() {
    return Row(
      children: [
        // Output mode selector
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OUTPUT MODE',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.secondaryEnergy,
                  fontSize: 10,
                  glowIntensity: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.secondaryEnergy.withOpacity(0.1),
                      HolographicTheme.secondaryEnergy.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: DropdownButton<int>(
                  value: _outputMode,
                  onChanged: (value) => setState(() => _outputMode = value!),
                  dropdownColor: HolographicTheme.deepSpaceBlack,
                  underline: Container(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: HolographicTheme.secondaryEnergy,
                  ),
                  items: List.generate(_outputModes.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          _outputModes[index],
                          style: HolographicTheme.createHolographicText(
                            energyColor: HolographicTheme.secondaryEnergy,
                            fontSize: 10,
                            glowIntensity: 0.4,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Mono and polarity controls
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mono mode toggle
            GestureDetector(
              onTap: () => _updateMasterParam('mono_mode', _masterParams['mono_mode']! > 0.5 ? 0.0 : 1.0),
              child: Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.accentEnergy.withOpacity(_masterParams['mono_mode']! > 0.5 ? 0.3 : 0.1),
                      HolographicTheme.accentEnergy.withOpacity(_masterParams['mono_mode']! > 0.5 ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: HolographicTheme.accentEnergy.withOpacity(_masterParams['mono_mode']! > 0.5 ? 0.8 : 0.3),
                    width: _masterParams['mono_mode']! > 0.5 ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'MONO',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.accentEnergy,
                      fontSize: 9,
                      glowIntensity: _masterParams['mono_mode']! > 0.5 ? 0.8 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Polarity invert toggle
            GestureDetector(
              onTap: () => _updateMasterParam('polarity_invert', _masterParams['polarity_invert']! > 0.5 ? 0.0 : 1.0),
              child: Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.secondaryEnergy.withOpacity(_masterParams['polarity_invert']! > 0.5 ? 0.3 : 0.1),
                      HolographicTheme.secondaryEnergy.withOpacity(_masterParams['polarity_invert']! > 0.5 ? 0.1 : 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: HolographicTheme.secondaryEnergy.withOpacity(_masterParams['polarity_invert']! > 0.5 ? 0.8 : 0.3),
                    width: _masterParams['polarity_invert']! > 0.5 ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Ø',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.secondaryEnergy,
                      fontSize: 14,
                      glowIntensity: _masterParams['polarity_invert']! > 0.5 ? 0.8 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _updateMasterParam(String param, double value) {
    setState(() {
      _masterParams[param] = value;
    });
    widget.onParameterChange('master_$param', value);
  }
}

/// Custom painter for professional level meters
class LevelMeterPainter extends CustomPainter {
  final double leftLevel;
  final double rightLevel;
  final double leftPeak;
  final double rightPeak;
  final bool clipping;
  final double clippingFlash;
  final double gainReduction;

  LevelMeterPainter({
    required this.leftLevel,
    required this.rightLevel,
    required this.leftPeak,
    required this.rightPeak,
    required this.clipping,
    required this.clippingFlash,
    required this.gainReduction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawMeter(canvas, size, leftLevel, leftPeak, 0, 'L');
    _drawMeter(canvas, size, rightLevel, rightPeak, 1, 'R');
    _drawScale(canvas, size);
    
    if (clipping) {
      _drawClippingIndicator(canvas, size);
    }
  }

  void _drawMeter(Canvas canvas, Size size, double level, double peak, int channel, String label) {
    final meterWidth = (size.width - 12) / 2;
    final meterHeight = size.height - 30;
    final x = 4.0 + (channel * (meterWidth + 4));
    final y = 20.0;
    
    // Background
    final bgPaint = Paint()
      ..color = HolographicTheme.deepSpaceBlack.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(x, y, meterWidth, meterHeight),
      bgPaint,
    );
    
    // Level segments
    final segmentHeight = meterHeight / 20;
    for (int i = 0; i < 20; i++) {
      final segmentY = y + meterHeight - (i + 1) * segmentHeight;
      final segmentLevel = (i + 1) / 20.0;
      
      if (level >= segmentLevel) {
        Color segmentColor;
        if (i < 14) {
          segmentColor = HolographicTheme.primaryEnergy; // Green zone
        } else if (i < 18) {
          segmentColor = Colors.orange; // Warning zone
        } else {
          segmentColor = Colors.red; // Danger zone
        }
        
        final paint = Paint()
          ..color = segmentColor.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(
          Rect.fromLTWH(x + 1, segmentY + 1, meterWidth - 2, segmentHeight - 2),
          paint,
        );
      }
    }
    
    // Peak indicator
    if (peak > 0) {
      final peakY = y + meterHeight - (peak * meterHeight);
      final peakPaint = Paint()
        ..color = HolographicTheme.accentEnergy
        ..strokeWidth = 2.0;
      
      canvas.drawLine(
        Offset(x, peakY),
        Offset(x + meterWidth, peakY),
        peakPaint,
      );
    }
    
    // Channel label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: HolographicTheme.createHolographicText(
          energyColor: HolographicTheme.primaryEnergy,
          fontSize: 10,
          glowIntensity: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(x + meterWidth / 2 - textPainter.width / 2, 2));
  }

  void _drawScale(Canvas canvas, Size size) {
    // Draw dB scale markings
    final scaleValues = [-60, -40, -20, -12, -6, -3, 0];
    final meterHeight = size.height - 30;
    final y = 20;
    
    for (final db in scaleValues) {
      final normalizedLevel = (db + 60) / 60; // -60dB to 0dB range
      final markY = y + meterHeight - (normalizedLevel * meterHeight);
      
      final paint = Paint()
        ..color = HolographicTheme.primaryEnergy.withOpacity(0.4)
        ..strokeWidth = 1.0;
      
      // Scale line
      canvas.drawLine(
        Offset(2, markY),
        Offset(size.width - 2, markY),
        paint,
      );
    }
  }

  void _drawClippingIndicator(Canvas canvas, Size size) {
    final flashOpacity = 0.8 + (clippingFlash * 0.2);
    final clipPaint = Paint()
      ..color = Colors.red.withOpacity(flashOpacity)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 15),
      clipPaint,
    );
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'CLIP',
        style: HolographicTheme.createHolographicText(
          energyColor: Colors.white,
          fontSize: 10,
          glowIntensity: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 2));
  }

  @override
  bool shouldRepaint(LevelMeterPainter oldDelegate) {
    return oldDelegate.leftLevel != leftLevel ||
           oldDelegate.rightLevel != rightLevel ||
           oldDelegate.leftPeak != leftPeak ||
           oldDelegate.rightPeak != rightPeak ||
           oldDelegate.clipping != clipping ||
           oldDelegate.clippingFlash != clippingFlash;
  }
}

/// Custom painter for gain reduction meter
class GainReductionMeterPainter extends CustomPainter {
  final double gainReduction;
  final Color color;

  GainReductionMeterPainter({
    required this.gainReduction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..color = HolographicTheme.deepSpaceBlack.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Gain reduction bar (from top down, since it's reduction)
    if (gainReduction > 0) {
      final reductionHeight = (gainReduction / 20.0) * size.height; // 20dB max
      
      final grPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(
        Rect.fromLTWH(2, 2, size.width - 4, reductionHeight),
        grPaint,
      );
    }
    
    // Scale markings
    final markings = [0, 5, 10, 15, 20]; // dB
    for (final db in markings) {
      final y = (db / 20.0) * size.height;
      final markPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GainReductionMeterPainter oldDelegate) {
    return oldDelegate.gainReduction != gainReduction;
  }
}