import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/holographic_theme.dart';

/// Professional Waveform Display with holographic visualization
/// 
/// Features:
/// - Real-time waveform visualization
/// - Multiple display modes (oscilloscope, envelope follower)
/// - Phase correlation display for stereo signals
/// - Trigger modes (auto, rising edge, falling edge)
/// - Zoom and time base controls
/// - Vaporwave holographic aesthetic with scan lines
class WaveformDisplay extends StatefulWidget {
  final List<double> waveformData;
  final Color color;
  final String? title;
  final double width;
  final double height;
  final bool showGrid;
  final bool showTrigger;
  final bool stereoMode;
  final List<double>? rightChannelData;
  final Function(double time)? onTimeSelected;

  const WaveformDisplay({
    Key? key,
    required this.waveformData,
    required this.color,
    this.title,
    this.width = 400,
    this.height = 150,
    this.showGrid = true,
    this.showTrigger = false,
    this.stereoMode = false,
    this.rightChannelData,
    this.onTimeSelected,
  }) : super(key: key);

  @override
  State<WaveformDisplay> createState() => _WaveformDisplayState();
}

class _WaveformDisplayState extends State<WaveformDisplay>
    with TickerProviderStateMixin {
  
  late AnimationController _scanController;
  late AnimationController _pulseController;
  
  double _timeBase = 1.0; // Time scale factor
  double _amplitude = 1.0; // Amplitude scale factor
  double _triggerLevel = 0.0; // Trigger threshold
  double? _selectedTime;
  bool _isHovering = false;
  
  // Trigger modes
  final List<String> _triggerModes = ['AUTO', 'RISING', 'FALLING', 'MANUAL'];
  int _selectedTriggerMode = 0;
  
  // Display modes
  final List<String> _displayModes = ['SCOPE', 'ENVELOPE', 'XY', 'PHASE'];
  int _selectedDisplayMode = 0;

  @override
  void initState() {
    super.initState();
    
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and controls
          if (widget.title != null || widget.showTrigger) ...[
            _buildHeader(),
            const SizedBox(height: 8),
          ],
          
          // Main waveform display
          Flexible(
            fit: FlexFit.loose,
            child: _buildWaveformArea(),
          ),
          
          // Bottom controls
          if (widget.showTrigger) ...[
            const SizedBox(height: 4),
            _buildBottomControls(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Title
        if (widget.title != null) ...[
          Text(
            widget.title!,
            style: HolographicTheme.createHolographicText(
              energyColor: widget.color,
              fontSize: 12,
              glowIntensity: 0.6,
            ),
          ),
          const Spacer(),
        ],
        
        // Display mode selector
        if (widget.showTrigger) ...[
          _buildModeSelector(),
        ],
      ],
    );
  }

  Widget _buildModeSelector() {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color.withOpacity(0.1),
            widget.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_displayModes.length, (index) {
          final isSelected = index == _selectedDisplayMode;
          return GestureDetector(
            onTap: () => setState(() => _selectedDisplayMode = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                  ? widget.color.withOpacity(0.2) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _displayModes[index],
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.color.withOpacity(isSelected ? 1.0 : 0.6),
                  fontSize: 8,
                  glowIntensity: isSelected ? 0.5 : 0.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWaveformArea() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapUp: _onTapUp,
        onPanUpdate: _onPanUpdate,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scanController, _pulseController]),
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HolographicTheme.deepSpaceBlack.withOpacity(0.9),
                    widget.color.withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.color.withOpacity(0.3 + (_isHovering ? 0.2 : 0.0)),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      painter: WaveformPainter(
                        waveformData: widget.waveformData,
                        rightChannelData: widget.rightChannelData,
                        color: widget.color,
                        scanValue: _scanController.value,
                        pulseValue: _pulseController.value,
                        timeBase: _timeBase,
                        amplitude: _amplitude,
                        triggerLevel: _triggerLevel,
                        selectedTime: _selectedTime,
                        showGrid: widget.showGrid,
                        stereoMode: widget.stereoMode,
                        displayMode: _selectedDisplayMode,
                        isHovering: _isHovering,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        // Time base control
        _buildControlKnob(
          'TIME',
          _timeBase,
          (value) => setState(() => _timeBase = value * 2.0),
          widget.color.withOpacity(0.7),
        ),
        
        const SizedBox(width: 12),
        
        // Amplitude control
        _buildControlKnob(
          'AMP',
          _amplitude,
          (value) => setState(() => _amplitude = value * 2.0),
          widget.color.withOpacity(0.7),
        ),
        
        const SizedBox(width: 12),
        
        // Trigger level control
        _buildControlKnob(
          'TRIG',
          (_triggerLevel + 1.0) / 2.0,
          (value) => setState(() => _triggerLevel = (value * 2.0) - 1.0),
          HolographicTheme.accentEnergy.withOpacity(0.7),
        ),
        
        const Spacer(),
        
        // Trigger mode selector
        _buildTriggerModeSelector(),
      ],
    );
  }

  Widget _buildControlKnob(String label, double value, ValueChanged<double> onChanged, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HolographicTheme.createHolographicText(
            energyColor: color,
            fontSize: 8,
            glowIntensity: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onPanUpdate: (details) {
            final delta = -details.delta.dy / 100.0;
            final newValue = (value + delta).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Transform.rotate(
              angle: (value * 270.0 - 135.0) * math.pi / 180.0,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.8),
                ),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerModeSelector() {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HolographicTheme.accentEnergy.withOpacity(0.1),
            HolographicTheme.accentEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: HolographicTheme.accentEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_triggerModes.length, (index) {
          final isSelected = index == _selectedTriggerMode;
          return GestureDetector(
            onTap: () => setState(() => _selectedTriggerMode = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                  ? HolographicTheme.accentEnergy.withOpacity(0.2) 
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                _triggerModes[index],
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.accentEnergy.withOpacity(isSelected ? 1.0 : 0.6),
                  fontSize: 7,
                  glowIntensity: isSelected ? 0.4 : 0.2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final time = _getTimeFromPosition(details.localPosition);
    setState(() {
      _selectedTime = time;
    });
    widget.onTimeSelected?.call(time);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final time = _getTimeFromPosition(details.localPosition);
    setState(() {
      _selectedTime = time;
    });
    widget.onTimeSelected?.call(time);
  }

  double _getTimeFromPosition(Offset position) {
    final normalizedX = (position.dx / widget.width).clamp(0.0, 1.0);
    return normalizedX * _timeBase;
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final List<double>? rightChannelData;
  final Color color;
  final double scanValue;
  final double pulseValue;
  final double timeBase;
  final double amplitude;
  final double triggerLevel;
  final double? selectedTime;
  final bool showGrid;
  final bool stereoMode;
  final int displayMode;
  final bool isHovering;

  WaveformPainter({
    required this.waveformData,
    this.rightChannelData,
    required this.color,
    required this.scanValue,
    required this.pulseValue,
    required this.timeBase,
    required this.amplitude,
    required this.triggerLevel,
    this.selectedTime,
    required this.showGrid,
    required this.stereoMode,
    required this.displayMode,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    // Draw background grid
    if (showGrid) {
      _drawGrid(canvas, size);
    }

    // Draw waveform based on display mode
    switch (displayMode) {
      case 0: // SCOPE
        _drawOscilloscope(canvas, size);
        break;
      case 1: // ENVELOPE
        _drawEnvelope(canvas, size);
        break;
      case 2: // XY
        _drawXYMode(canvas, size);
        break;
      case 3: // PHASE
        _drawPhaseMode(canvas, size);
        break;
    }

    // Draw trigger level indicator
    _drawTriggerLevel(canvas, size);

    // Draw time selection indicator
    if (selectedTime != null) {
      _drawTimeSelector(canvas, size);
    }

    // Draw scan line effect
    _drawScanLine(canvas, size);

    // Draw holographic effects
    _drawHolographicEffects(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1 + (pulseValue * 0.03))
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines (amplitude)
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical grid lines (time)
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Center line
    final centerPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  void _drawOscilloscope(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    
    // Draw left channel (or mono)
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / (waveformData.length - 1)) * size.width;
      final y = centerY - (waveformData[i] * amplitude * centerY * 0.8);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw right channel if stereo
    if (stereoMode && rightChannelData != null) {
      final rightPath = Path();
      final rightPaint = Paint()
        ..color = color.withGreen((color.green * 0.6).round())
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < rightChannelData!.length; i++) {
        final x = (i / (rightChannelData!.length - 1)) * size.width;
        final y = centerY - (rightChannelData![i] * amplitude * centerY * 0.8);
        
        if (i == 0) {
          rightPath.moveTo(x, y);
        } else {
          rightPath.lineTo(x, y);
        }
      }

      canvas.drawPath(rightPath, rightPaint);
    }
  }

  void _drawEnvelope(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerY = size.height / 2;
    
    // Create envelope by connecting peaks
    path.moveTo(0, centerY);
    
    for (int i = 0; i < waveformData.length; i++) {
      final x = (i / (waveformData.length - 1)) * size.width;
      final envelope = waveformData[i].abs() * amplitude;
      final y = centerY - (envelope * centerY * 0.8);
      
      path.lineTo(x, y);
    }
    
    // Complete the envelope shape
    for (int i = waveformData.length - 1; i >= 0; i--) {
      final x = (i / (waveformData.length - 1)) * size.width;
      final envelope = waveformData[i].abs() * amplitude;
      final y = centerY + (envelope * centerY * 0.8);
      
      path.lineTo(x, y);
    }
    
    path.close();
    
    // Draw gradient fill
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withOpacity(0.4),
        color.withOpacity(0.1),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);
    
    // Draw outline
    final outlinePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, outlinePaint);
  }

  void _drawXYMode(Canvas canvas, Size size) {
    if (!stereoMode || rightChannelData == null) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Plot X-Y correlation
    for (int i = 0; i < math.min(waveformData.length, rightChannelData!.length); i++) {
      final x = centerX + (waveformData[i] * amplitude * centerX * 0.8);
      final y = centerY - (rightChannelData![i] * amplitude * centerY * 0.8);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw with varying opacity based on intensity
    final intensityPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
    
    canvas.drawPath(path, intensityPaint);
    canvas.drawPath(path, paint);
  }

  void _drawPhaseMode(Canvas canvas, Size size) {
    // Phase correlation meter
    if (!stereoMode || rightChannelData == null) return;
    
    double correlation = 0.0;
    for (int i = 0; i < math.min(waveformData.length, rightChannelData!.length); i++) {
      correlation += waveformData[i] * rightChannelData![i];
    }
    correlation /= waveformData.length;
    
    // Draw phase meter
    final meterRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: 20,
    );
    
    // Background
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(meterRect, const Radius.circular(10)),
      bgPaint,
    );
    
    // Correlation indicator
    final correlationX = meterRect.left + (meterRect.width * (correlation + 1.0) / 2.0);
    final indicatorPaint = Paint()
      ..color = correlation > 0 ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(correlationX, meterRect.center.dy),
      8,
      indicatorPaint,
    );
    
    // Labels
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Left label
    textPainter.text = TextSpan(
      text: 'L',
      style: HolographicTheme.createHolographicText(
        energyColor: color,
        fontSize: 12,
        glowIntensity: 0.4,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(meterRect.left - 20, meterRect.center.dy - 6));
    
    // Right label
    textPainter.text = TextSpan(
      text: 'R',
      style: HolographicTheme.createHolographicText(
        energyColor: color,
        fontSize: 12,
        glowIntensity: 0.4,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(meterRect.right + 5, meterRect.center.dy - 6));
  }

  void _drawTriggerLevel(Canvas canvas, Size size) {
    final triggerY = size.height / 2 - (triggerLevel * size.height / 2);
    
    final triggerPaint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Dashed line
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0.0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, triggerY),
        Offset(math.min(startX + dashWidth, size.width), triggerY),
        triggerPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  void _drawTimeSelector(Canvas canvas, Size size) {
    final x = (selectedTime! / timeBase) * size.width;
    
    final selectorPaint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.8)
      ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      selectorPaint,
    );
  }

  void _drawScanLine(Canvas canvas, Size size) {
    final scanX = scanValue * size.width;
    
    final scanPaint = Paint()
      ..color = color.withOpacity(0.3 + (pulseValue * 0.2))
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(scanX, 0),
      Offset(scanX, size.height),
      scanPaint,
    );
  }

  void _drawHolographicEffects(Canvas canvas, Size size) {
    // Chromatic aberration when hovering
    if (isHovering) {
      final overlayPaint = Paint()
        ..blendMode = BlendMode.screen;

      // Red channel offset
      overlayPaint.color = Colors.red.withOpacity(0.02);
      canvas.save();
      canvas.translate(1, 0);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
      canvas.restore();

      // Blue channel offset  
      overlayPaint.color = Colors.cyan.withOpacity(0.02);
      canvas.save();
      canvas.translate(-1, 0);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), overlayPaint);
      canvas.restore();
    }

    // Scan line effect
    final scanLinePaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.2 + i * 0.3 + pulseValue * 0.1);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        scanLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
           oldDelegate.rightChannelData != rightChannelData ||
           oldDelegate.scanValue != scanValue ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.timeBase != timeBase ||
           oldDelegate.amplitude != amplitude ||
           oldDelegate.triggerLevel != triggerLevel ||
           oldDelegate.selectedTime != selectedTime ||
           oldDelegate.displayMode != displayMode ||
           oldDelegate.isHovering != isHovering;
  }
}