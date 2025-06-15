// SYNTHER UNIFIED - PROFESSIONAL IMPLEMENTATION
// Combines all best implementations into one cohesive app

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Professional Audio Engine
import 'core/audio_engine.dart';
import 'core/web_audio_backend.dart';

// Revolutionary Morph UI System
import 'design_system/design_system.dart';
import 'design_system/components/components.dart';
import 'design_system/layout/morph_layout_manager.dart';

// Holographic UI Components
import 'ui/holographic_widgets.dart'; // Contains HolographicXYPad
import 'ui/holographic/holographic_widget.dart'; // Import for HolographicWidget itself
import 'ui/vaporwave_interface.dart';
import 'ui/widgets/holographic_assignable_knob.dart';

// Advanced Features
import 'features/llm_presets/llm_preset_service.dart';
import 'features/visualizer_bridge/morph_ui_visualizer_bridge.dart';
import 'features/premium/premium_manager.dart';

// HyperAV Visualizer Integration
import 'visualizer/hypercube_visualizer.dart';

// Services
import 'services/midi_mapping_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize professional systems
  await _initializeProfessionalSystems();

  // Initialize MIDI Mapping Service and load mappings
  await MidiMappingService.instance.loadMappings();
  // The service constructor also attempts a sync load, this ensures async completion.
  
  runApp(SyntherUnifiedApp());
}

Future<void> _initializeProfessionalSystems() async {
  // Request audio permissions
  await SystemChannels.platform.invokeMethod('requestAudioPermissions');
  
  // Initialize professional audio engine
  await AudioEngine.initialize();
  
  // Initialize LLM preset system
  await LLMPresetService.initialize();
  
  // Initialize premium features
  await PremiumManager.initialize();
}

class SyntherUnifiedApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Professional Audio
        ChangeNotifierProvider(create: (_) => AudioEngine()),
        
        // Visualizer Bridge
        ChangeNotifierProvider(create: (_) => MorphUIVisualizerBridge()),
        
        // Layout Management
        ChangeNotifierProvider(create: (_) => MorphLayoutManager()),
        
        // Premium Features
        ChangeNotifierProvider(create: (_) => PremiumManager()),
        
        // LLM Presets
        ChangeNotifierProvider(create: (_) => LLMPresetService()),
      ],
      child: MaterialApp(
        title: 'Synther Professional',
        debugShowCheckedModeBanner: false,
        theme: SyntherTheme.professional,
        home: SyntherUnifiedInterface(),
      ),
    );
  }
}

class SyntherUnifiedInterface extends StatefulWidget {
  @override
  _SyntherUnifiedInterfaceState createState() => _SyntherUnifiedInterfaceState();
}

class _SyntherUnifiedInterfaceState extends State<SyntherUnifiedInterface> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<MorphLayoutManager>(
        builder: (context, layoutManager, child) {
          // Use Morph UI layout management with holographic aesthetics
          return MorphLayoutContainer(
            layoutPreset: layoutManager.currentPreset,
            child: Stack(
              children: [
                // HyperAV 4D Visualizer Background
                Positioned.fill(
                  child: HypercubeVisualizer(
                    audioEngine: context.watch<AudioEngine>(),
                  ),
                ),
                
                // Glassmorphic UI Overlay
                Positioned.fill(
                  child: VaporwaveInterface(
                    onPolyAftertouch: (data) {
                      context.read<AudioEngine>().polyAftertouch(data.note, data.value);
                    },
                  ),
                ),
                
                // Professional Parameter Controls
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: MorphParameterPanel(
                    audioEngine: context.watch<AudioEngine>(),
                    visualizerBridge: context.watch<MorphUIVisualizerBridge>(),
                  ),
                ),
                
                // LLM Preset Generation
                Positioned(
                  top: 60,
                  right: 20,
                  child: LLMPresetButton(
                    onPresetGenerated: (preset) {
                      context.read<AudioEngine>().loadPreset(preset);
                      context.read<MorphUIVisualizerBridge>().animatePresetTransition(preset);
                    },
                  ),
                ),
                
                // Layout Management Controls
                Positioned(
                  top: 60,
                  left: 20,
                  child: MorphLayoutSelector(
                    onLayoutChanged: (preset) {
                      context.read<MorphLayoutManager>().setPreset(preset);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Unified Parameter Panel - Combines Morph UI with Holographic aesthetics
class MorphParameterPanel extends StatefulWidget {
  final AudioEngine audioEngine;
  final MorphUIVisualizerBridge visualizerBridge;
  
  const MorphParameterPanel({
    Key? key,
    required this.audioEngine,
    required this.visualizerBridge,
  }) : super(key: key);

  @override
  _MorphParameterPanelState createState() => _MorphParameterPanelState();
}

class _MorphParameterPanelState extends State<MorphParameterPanel> {
  final GlobalKey<_HolographicWidgetState> _xyPadHolographicWidgetKey = GlobalKey<_HolographicWidgetState>();
  final GlobalKey<_HolographicWidgetState> _knob1HolographicWidgetKey = GlobalKey<_HolographicWidgetState>();
  final GlobalKey<_HolographicWidgetState> _knob2HolographicWidgetKey = GlobalKey<_HolographicWidgetState>();

  static const Size _compactXYPadSize = Size(220, 90);
  static const Size _defaultExpandedXYPadSize = Size(320, 280);
  
  static const Size _compactKnobSize = Size(150, 130);
  static const Size _defaultExpandedKnobSize = Size(180, 240);

  Color _knob1EnergyColor = HolographicTheme.primaryEnergy;
  Color _knob2EnergyColor = HolographicTheme.secondaryEnergy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350, // Adjusted height to better accommodate potentially overlapping widgets
      child: Stack(
        clipBehavior: Clip.none, // Allow widgets to be dragged partially out if needed
        children: [
          HolographicWidget(
            key: _knob1HolographicWidgetKey,
            title: synthParameterTypeToString(SynthParameterType.filterCutoff),
            energyColor: _knob1EnergyColor,
            initialPosition: const Offset(10, 10),
            initialSize: _compactKnobSize,
            defaultExpandedSize: _defaultExpandedKnobSize, // Pass default expanded size
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HolographicAssignableKnob(
                  audioEngine: widget.audioEngine,
                  initialParameter: SynthParameterType.filterCutoff,
                  onAssignmentChanged: (type, value) {
                    _updateAudioParameter(type, value, widget.audioEngine, widget.visualizerBridge);
                  },
                  onValueUpdated: (type, value) {
                    _updateAudioParameter(type, value, widget.audioEngine, widget.visualizerBridge);
                  },
                  onInteractionStart: () => _knob1HolographicWidgetKey.currentState?.expandToDefault(),
                  onInteractionEnd: () => _knob1HolographicWidgetKey.currentState?.contractTo(_compactKnobSize),
                  onEnergyColorChange: (newColor) {
                    if (_knob1EnergyColor != newColor) setState(() => _knob1EnergyColor = newColor);
                  },
                ),
            ),
          ),

          HolographicWidget(
            key: _knob2HolographicWidgetKey,
            title: synthParameterTypeToString(SynthParameterType.filterResonance),
            energyColor: _knob2EnergyColor,
            initialPosition: const Offset(170, 10), // Adjusted position
            initialSize: _compactKnobSize,
            defaultExpandedSize: _defaultExpandedKnobSize, // Pass default expanded size
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HolographicAssignableKnob(
                  audioEngine: widget.audioEngine,
                  initialParameter: SynthParameterType.filterResonance,
                  onAssignmentChanged: (type, value) {
                    _updateAudioParameter(type, value, widget.audioEngine, widget.visualizerBridge);
                  },
                  onValueUpdated: (type, value) {
                    _updateAudioParameter(type, value, widget.audioEngine, widget.visualizerBridge);
                  },
                  onInteractionStart: () => _knob2HolographicWidgetKey.currentState?.expandToDefault(),
                  onInteractionEnd: () => _knob2HolographicWidgetKey.currentState?.contractTo(_compactKnobSize),
                  onEnergyColorChange: (newColor) {
                    if (_knob2EnergyColor != newColor) setState(() => _knob2EnergyColor = newColor);
                  },
                ),
            ),
          ),

          HolographicWidget(
            key: _xyPadHolographicWidgetKey,
            title: "XY Pad / Pitch",
            initialPosition: const Offset(330, 10), // Adjusted position
            initialSize: _compactXYPadSize,
            defaultExpandedSize: _defaultExpandedXYPadSize, // Pass default expanded size
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HolographicXYPad(
                  x: 0.5,
                  y: 0.5,
                  onPositionChanged: (offset) {
                    // Y-axis handling needs clarification based on XYPad's yAssignment.
                    // For now, if yAssignment is filterResonance (example):
                    // This assumes XYPad doesn't handle its own Y-axis audio changes.
                    // A more robust solution would involve XYPad handling its assigned Y-axis param internally
                    // or using a state provider to communicate the Y-axis assignment.
                    // if (widget.yAssignment == XYPadAssignment.filterResonance) { // This check belongs inside XYPad or via provider
                    //   widget.audioEngine.setFilterResonance(offset.dy);
                    //   widget.visualizerBridge.animateParameter('resonance', offset.dy);
                    // }
                  },
                  onPitchChanged: (note) {
                    debugPrint("MorphParameterPanel: Pitch Changed to MIDI Note $note");
                    // widget.audioEngine.playDebugPitch(note); // Example
                  },
                  onInteractionStart: () => _xyPadHolographicWidgetKey.currentState?.expandToDefault(),
                  onInteractionEnd: () => _xyPadHolographicWidgetKey.currentState?.contractTo(_compactXYPadSize),
                  xAssignment: XYPadAssignment.pitch,
                  yAssignment: XYPadAssignment.filterResonance, // Example default
                  rootNote: ChromaticNote.c,
                  scaleType: ScaleType.chromatic,
                ),
            ),
          ),
        ],
      ),
    );
  }

  // This method is now part of _MorphParameterPanelState
  void _updateAudioParameter(
      SynthParameterType type,
      double value,
      AudioEngine engine,
      MorphUIVisualizerBridge bridge) {
    String paramName = 'unknown';
    switch (type) {
      case SynthParameterType.filterCutoff:
        engine.setFilterCutoff(value * 20000); // Assuming 0-1 from knob
        paramName = 'cutoff';
        break;
      case SynthParameterType.filterResonance:
        engine.setFilterResonance(value);
        paramName = 'resonance';
        break;
      case SynthParameterType.oscLfoRate:
        // engine.setLfoRate(value * 20); // Example: Max 20Hz
        paramName = 'lforate';
        break;
      case SynthParameterType.oscPulseWidth:
        // engine.setPulseWidth(value);
        paramName = 'pulsewidth';
        break;
      case SynthParameterType.reverbMix:
        engine.setReverbMix(value);
        paramName = 'reverbmix';
        break;
      case SynthParameterType.delayFeedback:
        // engine.setDelayFeedback(value);
        paramName = 'delayfeedback';
        break;
      case SynthParameterType.attackTime:
        engine.setAttackTime(value * 5); // Example: Max 5s
        paramName = 'attack';
        break;
      case SynthParameterType.decayTime:
        engine.setDecayTime(value * 5);
        paramName = 'decay';
        break;
      case SynthParameterType.masterVolume:
         engine.setMasterVolume(value);
         paramName = 'volume';
         break;
    }
    if (paramName != 'unknown') {
      bridge.animateParameter(paramName, value);
    }
  }
}

// Example of a simple state provider for XYPad assignments if needed for dynamic Y-axis handling
// This is conceptual and would need to be properly implemented and provided.
class HolographicXYPadStateProvider with ChangeNotifier {
  XYPadAssignment _xAssignment = XYPadAssignment.pitch;
  XYPadAssignment _yAssignment = XYPadAssignment.filterResonance;

  XYPadAssignment get xAssignment => _xAssignment;
  XYPadAssignment get yAssignment => _yAssignment;

  void setXAssignment(XYPadAssignment assignment) {
    _xAssignment = assignment;
    notifyListeners();
  }

  void setYAssignment(XYPadAssignment assignment) {
    _yAssignment = assignment;
    notifyListeners();
  }
}

// Unified Theme - Combines all design systems
class SyntherTheme {
  static ThemeData get professional => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.black,
    primarySwatch: Colors.cyan,
    
    // Morph UI Typography
    textTheme: MorphTypography.neonText,
    
    // Holographic Color Scheme
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF00FFFF), // Cyan
      secondary: const Color(0xFFFF00FF), // Magenta  
      tertiary: const Color(0xFFFFFF00), // Yellow
      surface: Colors.black.withOpacity(0.1),
    ),
    
    // Glassmorphic Extensions
    extensions: [
      GlassmorphicTheme(),
      HolographicTheme(),
      NeonEffectsTheme(),
    ],
  );
}