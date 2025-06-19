import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/holographic_theme.dart';

/// Professional Spectrum Display with holographic visualization
/// 
/// Features:
/// - Real-time FFT spectrum analysis
/// - Multiple display modes (linear, logarithmic, mel scale)
/// - Peak hold and decay animation
/// - Frequency band highlighting
/// - Interactive frequency selection
/// - Vaporwave holographic aesthetic
class SpectrumDisplay extends StatefulWidget {
  final List<double> spectrumData;
  final Color color;
  final String? title;
  final double width;
  final double height;
  final bool showFrequencyLabels;
  final bool showPeakHold;
  final bool interactive;
  final Function(double frequency)? onFrequencySelected;

  const SpectrumDisplay({
    Key? key,
    required this.spectrumData,
    required this.color,
    this.title,
    this.width = 400,
    this.height = 200,
    this.showFrequencyLabels = true,
    this.showPeakHold = true,
    this.interactive = false,
    this.onFrequencySelected,
  }) : super(key: key);

  @override
  State<SpectrumDisplay> createState() => _SpectrumDisplayState();
}

class _SpectrumDisplayState extends State<SpectrumDisplay>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _peakController;
  
  List<double> _peakHoldValues = [];
  List<double> _peakDecayTimers = [];
  
  double? _selectedFrequency;
  bool _isHovering = false;
  
  final List<String> _frequencyLabels = [
    '20', '50', '100', '200', '500', '1K', '2K', '5K', '10K', '20K'
  ];

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _peakController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();
    
    _initializePeakHold();
  }

  @override
  void didUpdateWidget(SpectrumDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spectrumData.length != widget.spectrumData.length) {
      _initializePeakHold();
    }
    _updatePeakHold();
  }

  void _initializePeakHold() {
    _peakHoldValues = List.filled(widget.spectrumData.length, 0.0);
    _peakDecayTimers = List.filled(widget.spectrumData.length, 0.0);
  }

  void _updatePeakHold() {
    if (!widget.showPeakHold) return;
    
    for (int i = 0; i < widget.spectrumData.length && i < _peakHoldValues.length; i++) {
      final currentValue = widget.spectrumData[i];
      
      if (currentValue > _peakHoldValues[i]) {
        // New peak detected
        _peakHoldValues[i] = currentValue;
        _peakDecayTimers[i] = 1.0; // Reset decay timer
      } else {
        // Decay existing peak
        _peakDecayTimers[i] -= 0.02; // Decay rate
        if (_peakDecayTimers[i] <= 0) {
          _peakHoldValues[i] = math.max(0.0, _peakHoldValues[i] - 0.005);
          _peakDecayTimers[i] = 0.0;
        }
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _peakController.dispose();
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
          // Title
          if (widget.title != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.title!,
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.color,
                  fontSize: 12,
                  glowIntensity: 0.6,
                ),
              ),
            ),
          ],
          
          // Spectrum visualization
          Flexible(
            fit: FlexFit.loose,
            child: _buildSpectrumArea(),
          ),
          
          // Frequency labels
          if (widget.showFrequencyLabels) ...[
            const SizedBox(height: 4),
            _buildFrequencyLabels(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpectrumArea() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTapUp: widget.interactive ? _onTapUp : null,
        onPanUpdate: widget.interactive ? _onPanUpdate : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _peakController]),
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.color.withOpacity(0.05),
                    HolographicTheme.deepSpaceBlack.withOpacity(0.8),
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
                      painter: SpectrumPainter(
                        spectrumData: widget.spectrumData,
                        peakHoldData: _peakHoldValues,
                        color: widget.color,
                        pulseValue: _pulseController.value,
                        peakPulse: _peakController.value,
                        selectedFrequency: _selectedFrequency,
                        showPeakHold: widget.showPeakHold,
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

  Widget _buildFrequencyLabels() {
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _frequencyLabels.map((label) {
          return Text(
            label,
            style: HolographicTheme.createHolographicText(
              energyColor: widget.color.withOpacity(0.6),
              fontSize: 8,
              glowIntensity: 0.3,
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.interactive) return;
    
    final frequency = _getFrequencyFromPosition(details.localPosition);
    setState(() {
      _selectedFrequency = frequency;
    });
    widget.onFrequencySelected?.call(frequency);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.interactive) return;
    
    final frequency = _getFrequencyFromPosition(details.localPosition);
    setState(() {
      _selectedFrequency = frequency;
    });
    widget.onFrequencySelected?.call(frequency);
  }

  double _getFrequencyFromPosition(Offset position) {
    // Convert position to frequency (logarithmic scale)
    final normalizedX = (position.dx / widget.width).clamp(0.0, 1.0);
    
    // Logarithmic frequency mapping (20Hz to 20kHz)
    final minFreq = math.log(20.0);
    final maxFreq = math.log(20000.0);
    final logFreq = minFreq + (normalizedX * (maxFreq - minFreq));
    
    return math.exp(logFreq);
  }
}

/// Custom painter for spectrum visualization
class SpectrumPainter extends CustomPainter {
  final List<double> spectrumData;
  final List<double> peakHoldData;
  final Color color;
  final double pulseValue;
  final double peakPulse;
  final double? selectedFrequency;
  final bool showPeakHold;
  final bool isHovering;

  SpectrumPainter({
    required this.spectrumData,
    required this.peakHoldData,
    required this.color,
    required this.pulseValue,
    required this.peakPulse,
    this.selectedFrequency,
    required this.showPeakHold,
    required this.isHovering,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (spectrumData.isEmpty || size.width <= 0 || size.height <= 0) return;

    final paint = Paint();
    final path = Path();
    
    // Calculate bar width with bounds checking
    final barWidth = size.width / spectrumData.length;
    if (barWidth <= 0) return;
    
    final barSpacing = barWidth * 0.1;
    final actualBarWidth = (barWidth - barSpacing).clamp(0.1, barWidth);

    // Draw background grid
    _drawGrid(canvas, size);

    // Draw spectrum bars with bounds checking
    for (int i = 0; i < spectrumData.length; i++) {
      final x = i * barWidth + barSpacing / 2;
      
      // Ensure we have valid spectrum data
      if (i >= spectrumData.length) break;
      final rawValue = spectrumData[i];
      if (!rawValue.isFinite) continue;
      
      final normalizedValue = rawValue.clamp(0.0, 1.0);
      final barHeight = (normalizedValue * size.height * 0.9).clamp(0.0, size.height);
      
      // Skip if coordinates are invalid
      if (!x.isFinite || !barHeight.isFinite) continue;
      
      // Frequency-based color modulation with safety checks
      final freqRatio = (i / spectrumData.length).clamp(0.0, 1.0);
      final hslColor = HSLColor.fromColor(color);
      final hueValue = ((hslColor.hue + freqRatio * 60) % 360).clamp(0.0, 360.0);
      final modulatedColor = hslColor.withHue(hueValue).toColor();

      // Draw main spectrum bar
      _drawSpectrumBar(
        canvas,
        Offset(x, size.height),
        actualBarWidth,
        barHeight,
        modulatedColor,
        normalizedValue,
      );

      // Draw peak hold indicator
      if (showPeakHold && i < peakHoldData.length) {
        final peakHeight = peakHoldData[i] * size.height * 0.9;
        if (peakHeight > 0) {
          _drawPeakIndicator(
            canvas,
            Offset(x, size.height - peakHeight),
            actualBarWidth,
            modulatedColor,
          );
        }
      }
    }

    // Draw frequency selection indicator
    if (selectedFrequency != null) {
      _drawFrequencySelector(canvas, size);
    }

    // Draw holographic overlay effects
    _drawHolographicOverlay(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1 + (pulseValue * 0.05))
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines (dB levels)
    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Vertical grid lines (frequency bands)
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawSpectrumBar(
    Canvas canvas,
    Offset position,
    double width,
    double height,
    Color barColor,
    double intensity,
  ) {
    final paint = Paint();
    
    // Create gradient for the bar
    final gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        barColor.withOpacity(0.8),
        barColor.withOpacity(0.4),
        barColor.withOpacity(0.1),
      ],
      stops: const [0.0, 0.7, 1.0],
    );

    final rect = Rect.fromLTWH(
      position.dx,
      position.dy - height,
      width,
      height,
    );

    // Draw glow effect
    if (intensity > 0.1) {
      final glowPaint = Paint()
        ..color = barColor.withOpacity(intensity * 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.5);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(width * 0.1)),
        glowPaint,
      );
    }

    // Draw main bar
    paint.shader = gradient.createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(width * 0.1)),
      paint,
    );

    // Draw rim light
    final rimPaint = Paint()
      ..color = barColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(width * 0.1)),
      rimPaint,
    );
  }

  void _drawPeakIndicator(
    Canvas canvas,
    Offset position,
    double width,
    Color peakColor,
  ) {
    final paint = Paint()
      ..color = peakColor.withOpacity(0.8 + (peakPulse * 0.2))
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(
      position.dx,
      position.dy - 2,
      width,
      4,
    );

    // Draw peak hold line with glow
    final glowPaint = Paint()
      ..color = peakColor.withOpacity(0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      glowPaint,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      paint,
    );
  }

  void _drawFrequencySelector(Canvas canvas, Size size) {
    if (selectedFrequency == null) return;

    // Convert frequency to x position (logarithmic)
    final minFreq = math.log(20.0);
    final maxFreq = math.log(20000.0);
    final logFreq = math.log(selectedFrequency!);
    final normalizedX = ((logFreq - minFreq) / (maxFreq - minFreq)).clamp(0.0, 1.0);
    final x = normalizedX * size.width;

    final paint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw selection line
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      paint,
    );

    // Draw frequency label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${selectedFrequency!.round()}Hz',
        style: HolographicTheme.createHolographicText(
          energyColor: HolographicTheme.accentEnergy,
          fontSize: 10,
          glowIntensity: 0.6,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, 5),
    );
  }

  void _drawHolographicOverlay(Canvas canvas, Size size) {
    // Chromatic aberration effect
    if (isHovering) {
      final overlayPaint = Paint()
        ..color = color.withOpacity(0.05)
        ..blendMode = BlendMode.screen;

      // Red channel offset
      canvas.save();
      canvas.translate(1, 0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        overlayPaint..color = Colors.red.withOpacity(0.02),
      );
      canvas.restore();

      // Blue channel offset
      canvas.save();
      canvas.translate(-1, 0);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        overlayPaint..color = Colors.cyan.withOpacity(0.02),
      );
      canvas.restore();
    }

    // Scan line effect
    final scanLinePaint = Paint()
      ..color = color.withOpacity(0.1 + (pulseValue * 0.05))
      ..strokeWidth = 1.0;

    final scanLineY = size.height * (0.3 + pulseValue * 0.4);
    canvas.drawLine(
      Offset(0, scanLineY),
      Offset(size.width, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(SpectrumPainter oldDelegate) {
    return oldDelegate.spectrumData != spectrumData ||
           oldDelegate.peakHoldData != peakHoldData ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.peakPulse != peakPulse ||
           oldDelegate.selectedFrequency != selectedFrequency ||
           oldDelegate.isHovering != isHovering;
  }
}