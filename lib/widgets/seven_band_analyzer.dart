import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../ui/holographic/holographic_theme.dart';

/// 7-Band Audio Analyzer with Fixed Frequency Bands
///
/// Fixed bands:
/// - Sub Bass: 20-60 Hz
/// - Bass: 60-250 Hz
/// - Low Mids: 250-500 Hz
/// - Mids: 500-2000 Hz
/// - High Mids: 2000-4000 Hz
/// - Presence: 4000-6000 Hz
/// - Brilliance: 6000-20000 Hz
///
/// Can run headless (headless: true) for background audio analysis
/// without rendering any UI components.
class SevenBandAnalyzer extends StatefulWidget {
  final double width;
  final double height;
  final bool showLabels;
  final bool showPeakHold;
  final bool headless; // Run without UI rendering
  final Color? primaryColor;
  final Color? secondaryColor;
  final Function(List<double>)? onBandLevelsUpdate;

  const SevenBandAnalyzer({
    Key? key,
    this.width = 300,
    this.height = 120,
    this.showLabels = true,
    this.showPeakHold = true,
    this.headless = false,
    this.primaryColor,
    this.secondaryColor,
    this.onBandLevelsUpdate,
  }) : super(key: key);

  @override
  State<SevenBandAnalyzer> createState() => _SevenBandAnalyzerState();
}

class _SevenBandAnalyzerState extends State<SevenBandAnalyzer>
    with SingleTickerProviderStateMixin {

  // Band definitions
  static const List<String> _bandNames = [
    'SUB',
    'BASS',
    'L-MID',
    'MID',
    'H-MID',
    'PRES',
    'BRIL'
  ];

  static const List<String> _bandRanges = [
    '20-60',
    '60-250',
    '250-500',
    '500-2k',
    '2k-4k',
    '4k-6k',
    '6k-20k'
  ];

  // Current levels for each band (0.0 to 1.0)
  final List<double> _bandLevels = List.filled(7, 0.0);

  // Peak hold levels
  final List<double> _peakLevels = List.filled(7, 0.0);
  final List<DateTime> _peakTimes = List.generate(7, (_) => DateTime.now());

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    )..repeat();

    _animationController.addListener(_updateLevels);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateLevels() {
    // Simulate audio reactivity - in production, this would read from audio engine
    setState(() {
      for (int i = 0; i < 7; i++) {
        // Simulate different frequency response for each band
        final frequency = math.pow(2.0, i).toDouble();
        final level = (math.sin(DateTime.now().millisecondsSinceEpoch / (200.0 * frequency)) + 1.0) / 2.0;

        // Apply decay to make it more realistic
        final targetLevel = level * 0.8;
        _bandLevels[i] = _bandLevels[i] * 0.7 + targetLevel * 0.3;

        // Update peak hold
        if (_bandLevels[i] > _peakLevels[i]) {
          _peakLevels[i] = _bandLevels[i];
          _peakTimes[i] = DateTime.now();
        } else {
          // Decay peak hold after 2 seconds
          final timeSincePeak = DateTime.now().difference(_peakTimes[i]).inMilliseconds;
          if (timeSincePeak > 2000) {
            _peakLevels[i] = math.max(0.0, _peakLevels[i] - 0.01);
          }
        }
      }

      // Notify parent of level changes
      widget.onBandLevelsUpdate?.call(_bandLevels);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Headless mode: return invisible widget but keep analysis running
    if (widget.headless) {
      return const SizedBox.shrink();
    }

    final primaryColor = widget.primaryColor ?? HolographicTheme.primaryEnergy;
    final secondaryColor = widget.secondaryColor ?? HolographicTheme.secondaryEnergy;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primaryColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Band bars
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (index) {
                  return _buildBandBar(
                    index: index,
                    level: _bandLevels[index],
                    peakLevel: _peakLevels[index],
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                  );
                }),
              ),
            ),

            // Labels
            if (widget.showLabels) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  return _buildBandLabel(index);
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBandBar({
    required int index,
    required double level,
    required double peakLevel,
    required Color primaryColor,
    required Color secondaryColor,
  }) {
    // Color gradient based on frequency band
    final bandColor = Color.lerp(
      primaryColor,
      secondaryColor,
      index / 6.0,
    )!;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Background track
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Level bar
            FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: level.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      bandColor,
                      bandColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: bandColor.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),

            // Peak hold indicator
            if (widget.showPeakHold && peakLevel > 0.0)
              Positioned(
                bottom: (widget.height - 40) * peakLevel,
                left: 0,
                right: 0,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: secondaryColor.withOpacity(0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandLabel(int index) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _bandNames[index],
            style: TextStyle(
              color: HolographicTheme.primaryEnergy.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            _bandRanges[index],
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.6),
              fontSize: 7,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
