// Cohesive Holographic Interface - Proper Design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/audio_engine.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import '../core/holographic_theme.dart';

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
  Offset _xyPadPosition = Offset(50, 400);
  
  // Component states
  bool _visualizerCollapsed = false;
  bool _xyPadCollapsed = false;
  
  // XY Pad values
  double _xyX = 0.5;
  double _xyY = 0.5;
  
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
        
        // Large XY Pad - Resizable Border Only
        Positioned(
          left: _xyPadPosition.dx,
          top: _xyPadPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _xyPadPosition += details.delta;
                // Keep within bounds
                _xyPadPosition = Offset(
                  _xyPadPosition.dx.clamp(0, screenWidth - 300),
                  _xyPadPosition.dy.clamp(50, screenHeight - 300),
                );
              });
            },
            child: _buildLargeXYPad(),
          ),
        ),
        
        // Floating Parameter Controls
        _buildFloatingControls(constraints),
      ],
    );
  }

  Widget _buildLargeXYPad() {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.primaryEnergy.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: HolographicTheme.primaryEnergy.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 15),
                Icon(
                  Icons.control_camera,
                  color: HolographicTheme.primaryEnergy,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'XY CONTROL PAD',
                  style: TextStyle(
                    color: HolographicTheme.primaryEnergy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                Spacer(),
                // Resize handle
                Icon(
                  Icons.open_in_full,
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  size: 16,
                ),
                SizedBox(width: 10),
              ],
            ),
          ),
          
          // XY Control area - Interactive
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                RenderBox box = context.findRenderObject() as RenderBox;
                Offset localPosition = box.globalToLocal(details.globalPosition);
                setState(() {
                  _xyX = (localPosition.dx / 300).clamp(0.0, 1.0);
                  _xyY = 1.0 - (localPosition.dy / 260).clamp(0.0, 1.0); // Invert Y
                });
                
                // Update audio engine
                final audioEngine = Provider.of<AudioEngine>(context, listen: false);
                audioEngine.setFilterCutoff(_xyX * 20000);
                audioEngine.setFilterResonance(_xyY);
              },
              child: Container(
                margin: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid lines
                    CustomPaint(
                      painter: XYPadGridPainter(),
                      size: Size.infinite,
                    ),
                    
                    // Control point
                    Positioned(
                      left: (_xyX * 280) - 10,
                      top: ((1.0 - _xyY) * 240) - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: HolographicTheme.primaryEnergy,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingControls(BoxConstraints constraints) {
    return Positioned(
      right: 20,
      top: 100,
      child: Column(
        children: [
          _buildFloatingKnob('CUTOFF', _xyX, Icons.tune),
          SizedBox(height: 20),
          _buildFloatingKnob('RESONANCE', _xyY, Icons.graphic_eq),
          SizedBox(height: 20),
          _buildFloatingKnob('VOLUME', 0.7, Icons.volume_up),
        ],
      ),
    );
  }

  Widget _buildFloatingKnob(String label, double value, IconData icon) {
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
            '${(value * 100).toInt()}%',
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

/// XY Pad grid painter
class XYPadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // Draw grid lines
    for (int i = 1; i < 5; i++) {
      double x = (size.width / 5) * i;
      double y = (size.height / 5) * i;
      
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}