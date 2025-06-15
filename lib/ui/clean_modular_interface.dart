// Clean Modular Holographic Interface - Guaranteed Working
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/audio_engine.dart';
import '../ui/widgets/holographic_assignable_knob.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import '../core/holographic_theme.dart';

/// A clean, working modular interface with draggable components
class CleanModularInterface extends StatefulWidget {
  const CleanModularInterface({Key? key}) : super(key: key);

  @override
  State<CleanModularInterface> createState() => _CleanModularInterfaceState();
}

class _CleanModularInterfaceState extends State<CleanModularInterface>
    with TickerProviderStateMixin {
  
  // Component positions - Better spread across screen
  Offset _knob1Position = Offset(80, 120);
  Offset _knob2Position = Offset(350, 120);
  Offset _knob3Position = Offset(620, 120);
  Offset _knob4Position = Offset(80, 350);
  Offset _knob5Position = Offset(350, 350);
  Offset _xyPadPosition = Offset(80, 500);
  Offset _visualizerPosition = Offset(450, 300);
  Offset _sequencerPosition = Offset(850, 120);
  
  // Component states
  bool _knob1Collapsed = false;
  bool _knob2Collapsed = false;
  bool _knob3Collapsed = false;
  bool _knob4Collapsed = false;
  bool _knob5Collapsed = false;
  bool _xyPadCollapsed = false;
  bool _visualizerCollapsed = false;
  bool _sequencerCollapsed = false;
  
  late AnimationController _backgroundController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: Duration(seconds: 3),
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
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Animated holographic background
            _buildHolographicBackground(),
            
            // Modular draggable components
            _buildModularComponents(),
            
            // Header with title
            _buildHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                HolographicTheme.primaryEnergy.withOpacity(0.15 * _backgroundAnimation.value),
                Colors.black,
                HolographicTheme.secondaryEnergy.withOpacity(0.15 * _backgroundAnimation.value),
                Colors.black,
                HolographicTheme.tertiaryEnergy.withOpacity(0.1 * _backgroundAnimation.value),
                Colors.black,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Radial gradient overlay
              Container(
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.overlay,
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.transparent,
                      HolographicTheme.primaryEnergy.withOpacity(0.08 * _backgroundAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Grid pattern overlay
              CustomPaint(
                painter: HolographicGridPainter(
                  opacity: 0.1 * _backgroundAnimation.value,
                  primaryColor: HolographicTheme.primaryEnergy,
                  secondaryColor: HolographicTheme.secondaryEnergy,
                ),
                size: Size.infinite,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            'SYNTHER HOLOGRAPHIC PRO',
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3.0,
              shadows: [
                Shadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                  blurRadius: 10.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModularComponents() {
    return Stack(
      children: [
        // Knob 1 - Filter Cutoff
        Positioned(
          left: _knob1Position.dx,
          top: _knob1Position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _knob1Position += details.delta;
              });
            },
            child: HolographicAssignableKnob(
              initialParameter: SynthParameterType.filterCutoff,
              audioEngine: Provider.of<AudioEngine>(context, listen: false),
              onEnergyColorChange: (color) {
                // Color change callback
              },
            ),
          ),
        ),
        
        // Knob 2 - Reverb Mix
        Positioned(
          left: _knob2Position.dx,
          top: _knob2Position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _knob2Position += details.delta;
              });
            },
            child: HolographicAssignableKnob(
              initialParameter: SynthParameterType.reverbMix,
              audioEngine: Provider.of<AudioEngine>(context, listen: false),
              onEnergyColorChange: (color) {
                // Color change callback
              },
            ),
          ),
        ),
        
        // Knob 3 - Master Volume
        Positioned(
          left: _knob3Position.dx,
          top: _knob3Position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _knob3Position += details.delta;
              });
            },
            child: HolographicAssignableKnob(
              initialParameter: SynthParameterType.masterVolume,
              audioEngine: Provider.of<AudioEngine>(context, listen: false),
              onEnergyColorChange: (color) {
                // Color change callback
              },
            ),
          ),
        ),
        
        // Knob 4 - Attack Time
        Positioned(
          left: _knob4Position.dx,
          top: _knob4Position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _knob4Position += details.delta;
              });
            },
            child: HolographicAssignableKnob(
              initialParameter: SynthParameterType.attackTime,
              audioEngine: Provider.of<AudioEngine>(context, listen: false),
              onEnergyColorChange: (color) {
                // Color change callback
              },
            ),
          ),
        ),
        
        // Knob 5 - Decay Time
        Positioned(
          left: _knob5Position.dx,
          top: _knob5Position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _knob5Position += details.delta;
              });
            },
            child: HolographicAssignableKnob(
              initialParameter: SynthParameterType.decayTime,
              audioEngine: Provider.of<AudioEngine>(context, listen: false),
              onEnergyColorChange: (color) {
                // Color change callback
              },
            ),
          ),
        ),
        
        // XY Pad
        Positioned(
          left: _xyPadPosition.dx,
          top: _xyPadPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _xyPadPosition += details.delta;
              });
            },
            child: _buildXYPad(),
          ),
        ),
        
        // HyperAV Visualizer
        EmbeddedHyperAVVisualizer(
          position: _visualizerPosition,
          isCollapsed: _visualizerCollapsed,
          width: 350,
          height: 200,
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
        
        // Drum Sequencer
        Positioned(
          left: _sequencerPosition.dx,
          top: _sequencerPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _sequencerPosition += details.delta;
              });
            },
            child: _buildDrumSequencer(),
          ),
        ),
      ],
    );
  }

  Widget _buildXYPad() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title bar
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: HolographicTheme.primaryEnergy.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Center(
              child: Text(
                'XY PAD',
                style: TextStyle(
                  color: HolographicTheme.primaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          
          // XY Control area
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.control_camera,
                  color: HolographicTheme.primaryEnergy.withOpacity(0.7),
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrumSequencer() {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title bar
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
            ),
            child: Center(
              child: Text(
                'DRUM SEQUENCER',
                style: TextStyle(
                  color: HolographicTheme.tertiaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          
          // Sequencer grid
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: 32,
                itemBuilder: (context, index) {
                  bool isActive = index % 3 == 0; // Some pattern for demo
                  return Container(
                    decoration: BoxDecoration(
                      color: isActive 
                        ? HolographicTheme.tertiaryEnergy.withOpacity(0.6)
                        : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: HolographicTheme.tertiaryEnergy.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for holographic grid background
class HolographicGridPainter extends CustomPainter {
  final double opacity;
  final Color primaryColor;
  final Color secondaryColor;

  HolographicGridPainter({
    required this.opacity,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = primaryColor.withOpacity(opacity)
      ..strokeWidth = 1;

    final paint2 = Paint()
      ..color = secondaryColor.withOpacity(opacity * 0.5)
      ..strokeWidth = 0.5;

    const double spacing = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        x % (spacing * 2) == 0 ? paint1 : paint2,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        y % (spacing * 2) == 0 ? paint1 : paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}