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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize professional systems
  await _initializeProfessionalSystems();
  
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
                  child: VaporwaveInterface(),
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
class MorphParameterPanel extends StatelessWidget {
  final AudioEngine audioEngine;
  final MorphUIVisualizerBridge visualizerBridge;
  
  const MorphParameterPanel({
    Key? key,
    required this.audioEngine,
    required this.visualizerBridge,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // The MorphParameterPanel is typically given a space by its parent Positioned widget.
    // We'll use a Stack to allow HolographicWidgets to float.
    // A Container with a fixed height might be needed if the Stack is not constrained by its parent.
    // For now, assuming the parent Positioned provides sufficient constraints.
    return SizedBox( // Explicitly give MorphParameterPanel a height, useful for Stack
      height: 300, // Example height, adjust as needed
      child: Stack(
        children: [
          HolographicWidget(
            title: synthParameterTypeToString(SynthParameterType.filterCutoff),
            initialPosition: const Offset(0, 0), // Relative to Stack
            initialSize: const Size(180, 220),   // Smaller size for individual knob
            isDraggable: true,
            isResizable: true,
            isCollapsible: true,
            child: Padding( // Add padding inside HolographicWidget if needed
              padding: const EdgeInsets.all(8.0),
              child: HolographicAssignableKnob(
                  audioEngine: audioEngine,
                  initialParameter: SynthParameterType.filterCutoff,
                  onAssignmentChanged: (type, value) {
                    _updateAudioParameter(type, value, audioEngine, visualizerBridge);
                  },
                  onValueUpdated: (type, value) {
                    _updateAudioParameter(type, value, audioEngine, visualizerBridge);
                  },
                ),
            ),
          ),

          HolographicWidget(
            title: synthParameterTypeToString(SynthParameterType.filterResonance),
            initialPosition: const Offset(200, 0), // Positioned to the right
            initialSize: const Size(180, 220),    // Smaller size
            isDraggable: true,
            isResizable: true,
            isCollapsible: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HolographicAssignableKnob(
                  audioEngine: audioEngine,
                  initialParameter: SynthParameterType.filterResonance,
                  onAssignmentChanged: (type, value) {
                    _updateAudioParameter(type, value, audioEngine, visualizerBridge);
                  },
                  onValueUpdated: (type, value) {
                    _updateAudioParameter(type, value, audioEngine, visualizerBridge);
                  },
                ),
            ),
          ),

          HolographicWidget(
            title: "XY Pad",
            initialPosition: const Offset(400, 0), // Positioned further to the right
            initialSize: const Size(300, 220),     // Larger for XY pad
            isDraggable: true,
            isResizable: true,
            isCollapsible: true,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: HolographicXYPad(
                  xLabel: 'Attack',
                  yLabel: 'Decay',
                  xValue: audioEngine.attackTime,
                  yValue: audioEngine.decayTime,
                  onChanged: (x, y) {
                    audioEngine.setAttackTime(x * 5);
                    audioEngine.setDecayTime(y * 5);
                    visualizerBridge.animateParameters({
                      'attack': x,
                      'decay': y,
                    });
                  },
                  enableMorphEffects: true, // This prop might need to be part of HolographicXYPad
                ),
            ),
          ),
        ],
      ),
    );
  }

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
        engine.setDecayTime(value * 5); // Example: Max 5s
        paramName = 'decay';
        break;
    }
    if (paramName != 'unknown') {
      bridge.animateParameter(paramName, value);
    }
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