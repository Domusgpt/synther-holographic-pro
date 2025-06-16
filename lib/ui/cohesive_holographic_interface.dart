// Cohesive Holographic Interface - Proper Design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/audio_engine.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import '../core/holographic_theme.dart';
import '../features/xy_pad/xy_pad_widget.dart';
import '../features/keyboard/keyboard_widget.dart';
import '../features/controls/pitch_bend_wheel_widget.dart';
import '../features/controls/modulation_wheel_widget.dart';

/// A cohesive, responsive holographic interface with proper visual hierarchy
class CohesiveHolographicInterface extends StatefulWidget {
  const CohesiveHolographicInterface({Key? key}) : super(key: key);

  @override
  State<CohesiveHolographicInterface> createState() => _CohesiveHolographicInterfaceState();
}

class _CohesiveHolographicInterfaceState extends State<CohesiveHolographicInterface>
    with TickerProviderStateMixin {
  
  // Component positions - responsive layout
  Offset _visualizerPosition = Offset(100, 100);
  Offset _xyPadPosition = Offset(50, 400); // Keep for XYPadWidget
  // Size _xyPadSize = Size(300, 300); // Handled by XYPadWidget's initialSize

  Offset _keyboardPosition = Offset(50, 600); // Example position
  Size _keyboardSize = Size(700, 150); // Example size

  Offset _pitchBendPosition = Offset(20, 400); // Example position
  Size _pitchBendSize = Size(60, 150);

  Offset _modWheelPosition = Offset(800, 400); // Example position
  Size _modWheelSize = Size(60, 150);
  
  // Component states
  bool _visualizerCollapsed = false;
  // bool _xyPadCollapsed = false; // Remove if not used by new XYPadWidget directly
  
  // XY Pad values _xyX, _xyY removed as XYPadWidget will manage its own state or use Provider
  
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Holographic Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: HolographicTheme.primaryEnergy,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Holographic background - full coverage
                _buildHolographicBackground(),
                
                // Main interface components
                _buildMainInterface(constraints),
                
                // Header overlay
                _buildHeader(),
              ],
            );
          }
        ),
      ),
    );
  }

  Widget _buildHolographicBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.black,
                HolographicTheme.primaryEnergy.withOpacity(0.05 * _backgroundAnimation.value),
                Colors.black,
                HolographicTheme.secondaryEnergy.withOpacity(0.03 * _backgroundAnimation.value),
                Colors.black,
              ],
            ),
          ),
          child: CustomPaint(
            painter: HolographicGridPainter(
              animation: _backgroundAnimation.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildMainInterface(BoxConstraints constraints) {
    double screenWidth = constraints.maxWidth;
    double screenHeight = constraints.maxHeight;
    
    return Stack(
      children: [
        // Central HyperAV Visualizer - Main Focus
        Positioned(
          left: _visualizerPosition.dx,
          top: _visualizerPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _visualizerPosition += details.delta;
                // Keep within bounds
                _visualizerPosition = Offset(
                  _visualizerPosition.dx.clamp(0, screenWidth - 600),
                  _visualizerPosition.dy.clamp(50, screenHeight - 400),
                );
              });
            },
            child: EmbeddedHyperAVVisualizer(
              position: _visualizerPosition,
              isCollapsed: _visualizerCollapsed,
              width: 600,
              height: 400,
              onPositionChanged: (position) {
                setState(() {
                  _visualizerPosition = position;
                });
              },
              onToggleCollapse: () {
                setState(() {
                  _visualizerCollapsed = !_visualizerCollapsed;
                });
              },
            ),
          ),
        ),
        
        // XYPadWidget
        Positioned(
          left: _xyPadPosition.dx,
          top: _xyPadPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _xyPadPosition += details.delta;
                // Add clamping logic for screen bounds
                _xyPadPosition = Offset(
                  _xyPadPosition.dx.clamp(0, screenWidth - 300), // Assuming 300 is width
                  _xyPadPosition.dy.clamp(50, screenHeight - 300), // Assuming 300 is height
                );
              });
            },
            child: XYPadWidget(
              initialSize: Size(300, 300), // Or use a state variable if resizable
            ),
          ),
        ),

        // VirtualKeyboardWidget
        Positioned(
          left: _keyboardPosition.dx,
          top: _keyboardPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _keyboardPosition += details.delta;
                _keyboardPosition = Offset(
                  _keyboardPosition.dx.clamp(0, screenWidth - _keyboardSize.width),
                  _keyboardPosition.dy.clamp(0, screenHeight - _keyboardSize.height),
                );
              });
            },
            child: VirtualKeyboardWidget(
              initialSize: _keyboardSize,
              // Pass other necessary parameters like min/max octave if needed
            ),
          ),
        ),

        // PitchBendWheelWidget
        Positioned(
          left: _pitchBendPosition.dx,
          top: _pitchBendPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _pitchBendPosition += details.delta;
                _pitchBendPosition = Offset(
                  _pitchBendPosition.dx.clamp(0, screenWidth - _pitchBendSize.width),
                  _pitchBendPosition.dy.clamp(0, screenHeight - _pitchBendSize.height),
                );
              });
            },
            child: PitchBendWheelWidget(
              size: _pitchBendSize,
            ),
          ),
        ),

        // ModulationWheelWidget
        Positioned(
          left: _modWheelPosition.dx,
          top: _modWheelPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _modWheelPosition += details.delta;
                _modWheelPosition = Offset(
                  _modWheelPosition.dx.clamp(0, screenWidth - _modWheelSize.width),
                  _modWheelPosition.dy.clamp(0, screenHeight - _modWheelSize.height),
                );
              });
            },
            child: ModulationWheelWidget(
              size: _modWheelSize,
            ),
          ),
        ),

        // Floating Parameter Controls
        _buildFloatingControls(constraints),
      ],
    );
  }

  Widget _buildFloatingControls(BoxConstraints constraints) {
    // TODO: Update these controls to use SynthParametersModel or similar
    // For now, using placeholder values or direct interaction if possible.
    // The original _xyX and _xyY are removed, so these knobs need new sources.
    final synthParams = Provider.of<SynthParametersModel>(context, listen: true);

    return Positioned(
      right: 20,
      top: 100,
      child: Column(
        children: [
          // Example: Reading from synthParams if available, otherwise placeholder
          _buildFloatingKnob('CUTOFF', synthParams.filterCutoff / 20000, Icons.tune),
          SizedBox(height: 20),
          _buildFloatingKnob('RESONANCE', synthParams.filterResonance, Icons.graphic_eq),
          SizedBox(height: 20),
          _buildFloatingKnob('VOLUME', synthParams.masterVolume, Icons.volume_up),
        ],
      ),
    );
  }

  Widget _buildFloatingKnob(String label, double value, IconData icon) {
    // Ensure value is not null and is within a typical 0.0-1.0 range for display
    // This might need adjustment based on actual parameter ranges
    double displayValue = value.clamp(0.0, 1.0);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
        border: Border.all(
          color: HolographicTheme.secondaryEnergy.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: HolographicTheme.secondaryEnergy,
            size: 20,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${(displayValue * 100).toInt()}%',
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Text(
            'SYNTHER HOLOGRAPHIC PRO',
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 4.0,
              shadows: [
                Shadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                  blurRadius: 15.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid painter for holographic background
class HolographicGridPainter extends CustomPainter {
  final double animation;

  HolographicGridPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.1 * animation)
      ..strokeWidth = 1;

    const double spacing = 80.0;

    // Draw perspective grid
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// XYPadGridPainter removed as it's part of the old _buildLargeXYPad