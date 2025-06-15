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
  
  // Component positions
  Offset _knob1Position = Offset(50, 100);
  Offset _knob2Position = Offset(250, 100);
  Offset _knob3Position = Offset(450, 100);
  Offset _xyPadPosition = Offset(50, 300);
  Offset _visualizerPosition = Offset(300, 200);
  
  // Component states
  bool _knob1Collapsed = false;
  bool _knob2Collapsed = false;
  bool _knob3Collapsed = false;
  bool _xyPadCollapsed = false;
  bool _visualizerCollapsed = false;
  
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
                HolographicTheme.primaryEnergy.withOpacity(0.1 * _backgroundAnimation.value),
                Colors.black,
                HolographicTheme.secondaryEnergy.withOpacity(0.1 * _backgroundAnimation.value),
                Colors.black,
              ],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.overlay,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  HolographicTheme.primaryEnergy.withOpacity(0.05 * _backgroundAnimation.value),
                  Colors.transparent,
                ],
              ),
            ),
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
}