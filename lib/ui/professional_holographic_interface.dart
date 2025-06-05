// Main Professional Holographic Interface - Integrates all components over HyperAV
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/audio_engine.dart';
import '../services/firebase_service.dart';
// Removed hyperav_background - using embedded visualizer instead
import '../widgets/professional_xy_pad.dart';
import '../widgets/professional_knob_bank.dart';
import '../widgets/drum_pads_sequencer.dart';
import '../widgets/professional_sliders.dart';
import '../widgets/enhanced_llm_generator.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import '../core/holographic_theme.dart';

class ProfessionalHolographicInterface extends StatefulWidget {
  const ProfessionalHolographicInterface({Key? key}) : super(key: key);

  @override
  State<ProfessionalHolographicInterface> createState() => _ProfessionalHolographicInterfaceState();
}

class _ProfessionalHolographicInterfaceState extends State<ProfessionalHolographicInterface>
    with TickerProviderStateMixin {
  
  // Widget positions and states
  Offset _xyPadPosition = Offset(50, 100);
  Offset _knobBankPosition = Offset(400, 100);
  Offset _drumPadsPosition = Offset(50, 450);
  Offset _slidersPosition = Offset(700, 100);
  Offset _llmGeneratorPosition = Offset(50, 50);
  Offset _hyperavPosition = Offset(250, 300);
  
  bool _xyPadCollapsed = false;
  bool _knobBankCollapsed = false;
  bool _drumPadsCollapsed = false;
  bool _slidersCollapsed = false;
  bool _llmGeneratorCollapsed = false;
  bool _hyperavCollapsed = false;
  
  // XY Pad parameter assignments
  SynthParameter _xyPadXParameter = SynthParameter.filterCutoff;
  SynthParameter _xyPadYParameter = SynthParameter.filterResonance;
  
  // Current HyperAV settings
  String _currentGeometry = 'hypercube';
  String _currentProjection = 'perspective';
  
  late AnimationController _interfaceController;
  late Animation<double> _interfaceAnimation;

  @override
  void initState() {
    super.initState();
    
    _interfaceController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _interfaceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _interfaceController,
      curve: Curves.easeOut,
    ));
    
    // Animate interface in
    _interfaceController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Professional Holographic',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: HolographicTheme.primaryEnergy,
      ),
      home: Scaffold(
        body: AnimatedBuilder(
          animation: _interfaceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_interfaceAnimation.value * 0.2),
              child: Opacity(
                opacity: _interfaceAnimation.value,
                child: Stack(
                  children: [
                    // Professional Interface Components (HyperAV now embedded as component)
                    _buildInterfaceComponents(),
                    
                    // HyperAV Control Panel
                    _buildHyperAVControls(),
                    
                    // Clear Seas Solutions Branding
                    _buildBranding(),
                    
                    // Performance Monitor
                    _buildPerformanceMonitor(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInterfaceComponents() {
    return Stack(
      children: [
        // Enhanced LLM Preset Generator
        EnhancedLLMGenerator(
          position: _llmGeneratorPosition,
          isCollapsed: _llmGeneratorCollapsed,
          onPositionChanged: (position) {
            setState(() => _llmGeneratorPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _llmGeneratorCollapsed = !_llmGeneratorCollapsed);
          },
          onPresetGenerated: _handlePresetGenerated,
        ),
        
        // Professional XY Pad
        ProfessionalXYPad(
          width: 280,
          height: 280,
          position: _xyPadPosition,
          xParameter: _xyPadXParameter,
          yParameter: _xyPadYParameter,
          isCollapsed: _xyPadCollapsed,
          onPositionChanged: (position) {
            setState(() => _xyPadPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _xyPadCollapsed = !_xyPadCollapsed);
          },
          onXParameterChanged: (parameter) {
            setState(() => _xyPadXParameter = parameter);
          },
          onYParameterChanged: (parameter) {
            setState(() => _xyPadYParameter = parameter);
          },
          onValueChanged: _handleXYPadChange,
        ),
        
        // Professional Knob Bank
        ProfessionalKnobBank(
          position: _knobBankPosition,
          isCollapsed: _knobBankCollapsed,
          onPositionChanged: (position) {
            setState(() => _knobBankPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _knobBankCollapsed = !_knobBankCollapsed);
          },
          onParameterChanged: _handleParameterChange,
        ),
        
        // Drum Pads & Sequencer
        DrumPadsSequencer(
          position: _drumPadsPosition,
          isCollapsed: _drumPadsCollapsed,
          onPositionChanged: (position) {
            setState(() => _drumPadsPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _drumPadsCollapsed = !_drumPadsCollapsed);
          },
          onDrumHit: _handleDrumHit,
        ),
        
        // Professional Sliders
        ProfessionalSliders(
          position: _slidersPosition,
          isCollapsed: _slidersCollapsed,
          onPositionChanged: (position) {
            setState(() => _slidersPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _slidersCollapsed = !_slidersCollapsed);
          },
          onParameterChanged: _handleParameterChange,
        ),
        
        // Embedded HyperAV Visualizer
        EmbeddedHyperAVVisualizer(
          position: _hyperavPosition,
          isCollapsed: _hyperavCollapsed,
          width: 400,
          height: 250,
          onPositionChanged: (position) {
            setState(() => _hyperavPosition = position);
          },
          onToggleCollapse: () {
            setState(() => _hyperavCollapsed = !_hyperavCollapsed);
          },
        ),
      ],
    );
  }

  Widget _buildHyperAVControls() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.primaryEnergy.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HYPERAV CONTROL',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12),
            
            // Geometry selection
            Text(
              'GEOMETRY',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: ['hypercube', 'hypersphere', 'hypertetrahedron'].map((geometry) {
                return _buildControlButton(
                  geometry.toUpperCase(),
                  _currentGeometry == geometry,
                  () {
                    setState(() => _currentGeometry = geometry);
                  },
                );
              }).toList(),
            ),
            
            SizedBox(height: 12),
            
            // Projection selection
            Text(
              'PROJECTION',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: ['perspective', 'orthographic', 'stereographic'].map((projection) {
                return _buildControlButton(
                  projection.toUpperCase(),
                  _currentProjection == projection,
                  () {
                    setState(() => _currentProjection = projection);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
            ? HolographicTheme.primaryEnergy.withOpacity(0.3)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(isActive ? 0.8 : 0.4),
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: HolographicTheme.primaryEnergy.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: HolographicTheme.primaryEnergy.withOpacity(isActive ? 1.0 : 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HolographicTheme.primaryEnergy,
                    HolographicTheme.secondaryEnergy,
                    HolographicTheme.tertiaryEnergy,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CLEAR SEAS SOLUTIONS',
                  style: TextStyle(
                    color: HolographicTheme.tertiaryEnergy,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Synther Professional',
                  style: TextStyle(
                    color: HolographicTheme.tertiaryEnergy.withOpacity(0.8),
                    fontSize: 8,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMonitor() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Consumer2<AudioEngine, SynthParametersModel>(
        builder: (context, audioEngine, synthParams, child) {
          return Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      audioEngine.isInitialized ? Icons.check_circle : Icons.error_outline,
                      color: audioEngine.isInitialized 
                        ? HolographicTheme.secondaryEnergy 
                        : Colors.red,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AUDIO ENGINE',
                      style: TextStyle(
                        color: HolographicTheme.secondaryEnergy,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Latency: <10ms • 44.1kHz',
                  style: TextStyle(
                    color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Event handlers
  void _handleXYPadChange(double x, double y) {
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    
    // Apply X parameter
    switch (_xyPadXParameter) {
      case SynthParameter.filterCutoff:
        audioEngine.setFilterCutoff(x);
        synthParams.setFilterCutoff(x);
        break;
      case SynthParameter.filterResonance:
        audioEngine.setFilterResonance(x);
        synthParams.setFilterResonance(x);
        break;
      // Add more cases as needed
      default:
        break;
    }
    
    // Apply Y parameter
    switch (_xyPadYParameter) {
      case SynthParameter.filterCutoff:
        audioEngine.setFilterCutoff(y);
        synthParams.setFilterCutoff(y);
        break;
      case SynthParameter.filterResonance:
        audioEngine.setFilterResonance(y);
        synthParams.setFilterResonance(y);
        break;
      // Add more cases as needed
      default:
        break;
    }
  }

  void _handleParameterChange(String parameter, double value) {
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    
    switch (parameter) {
      case 'cutoff':
        audioEngine.setFilterCutoff(value);
        synthParams.setFilterCutoff(value);
        break;
      case 'resonance':
        audioEngine.setFilterResonance(value);
        synthParams.setFilterResonance(value);
        break;
      case 'reverb':
        audioEngine.setReverbMix(value);
        synthParams.setReverbMix(value);
        break;
      case 'volume':
        audioEngine.setMasterVolume(value);
        synthParams.setMasterVolume(value);
        break;
      // Add more parameter mappings
      default:
        break;
    }
  }

  void _handleDrumHit(String drumName) {
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    
    // Map drum names to MIDI notes or trigger samples
    switch (drumName) {
      case 'KICK':
        audioEngine.playNote(36, 1.0); // C2
        break;
      case 'SNARE':
        audioEngine.playNote(38, 1.0); // D2
        break;
      case 'HAT':
        audioEngine.playNote(42, 0.8); // F#2
        break;
      // Add more drum mappings
      default:
        break;
    }
  }

  void _handlePresetGenerated(Map<String, dynamic> preset) {
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    
    // Apply generated preset to synthesizer
    preset.forEach((key, value) {
      if (value is double) {
        _handleParameterChange(key, value);
      }
    });
  }

  @override
  void dispose() {
    _interfaceController.dispose();
    super.dispose();
  }
}