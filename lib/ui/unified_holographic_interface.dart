import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/parameter_visualizer_bridge.dart';
import '../core/audio_reactive_controller.dart';
import '../widgets/seven_band_analyzer.dart';
import '../widgets/visual_system_controls.dart';
import '../widgets/synth_components/holographic_knob.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import 'holographic/holographic_theme.dart';

/// Unified Holographic Interface with Deep Audio-Visual Coupling
///
/// The 7-band analyzer runs headless in the background, driving:
/// - 4D rotations (XY, ZW, XW, YZ planes)
/// - Density expansion/contraction
/// - Color shifts and flashes
/// - Geometry morphing
/// - Chaos and glitch effects
/// - Perspective shifts
/// - Pattern complexity
///
/// Synth parameters also affect visuals:
/// - Filter cutoff → Line sharpness
/// - Resonance → Glitch intensity
/// - Envelope → Morph speed
/// - Reverb → Depth/density
/// - Delay → Rotation phasing
class UnifiedHolographicInterface extends StatefulWidget {
  const UnifiedHolographicInterface({Key? key}) : super(key: key);

  @override
  State<UnifiedHolographicInterface> createState() =>
      _UnifiedHolographicInterfaceState();
}

class _UnifiedHolographicInterfaceState
    extends State<UnifiedHolographicInterface> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late ParameterVisualizerBridge _visualBridge;
  late AudioReactiveController _audioReactiveController;

  bool _showAnalyzerOverlay = false; // Optional debug overlay

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _visualBridge = ParameterVisualizerBridge();

    // Initialize bridge when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBridge();
    });
  }

  void _initializeBridge() {
    _visualBridge.initialize(
      visualizerUpdateCallback: (param, value) {
        // This callback will be called when parameters update
        // In production, this would send to the WebGL visualizer
        debugPrint('Visualizer: $param = ${value.toStringAsFixed(2)}');
      },
      uiTintCallback: (param, color, value) {
        // Optional: Use for UI feedback based on parameter changes
      },
    );

    // Create audio-reactive controller
    _audioReactiveController = AudioReactiveController(_visualBridge);

    // Set initial synth parameters
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    _audioReactiveController.updateFromSynthParameters(synthParams);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _audioReactiveController.dispose();
    super.dispose();
  }

  void _onBandLevelsUpdate(List<double> levels) {
    // Feed band levels to audio-reactive controller
    _audioReactiveController.updateBandLevels(levels);

    // Also update from synth parameters for synth-to-visual mapping
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    _audioReactiveController.updateFromSynthParameters(synthParams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // HyperAV Visualizer Background (receives all audio-reactive parameters)
          const Positioned.fill(
            child: EmbeddedHyperAVVisualizer(),
          ),

          // Headless 7-band analyzer (invisible but running)
          SevenBandAnalyzer(
            headless: true,
            onBandLevelsUpdate: _onBandLevelsUpdate,
          ),

          // Main Interface Overlay (minimal, transparent)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top Bar: Logo and Master Controls
                  _buildTopBar(),

                  const SizedBox(height: 16),

                  // Main Content Area
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel: Visual System Controls
                        _buildLeftPanel(),

                        const SizedBox(width: 16),

                        // Center: Main Synth Controls
                        Expanded(
                          child: _buildCenterPanel(),
                        ),
                      ],
                    ),
                  ),

                  // Optional: Debug analyzer overlay (can be toggled)
                  if (_showAnalyzerOverlay) _buildAnalyzerOverlay(),
                ],
              ),
            ),
          ),

          // Toggle button for analyzer overlay
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: HolographicTheme.primaryEnergy.withOpacity(0.3),
              onPressed: () {
                setState(() {
                  _showAnalyzerOverlay = !_showAnalyzerOverlay;
                });
              },
              child: Icon(
                _showAnalyzerOverlay ? Icons.visibility_off : Icons.graphic_eq,
                color: HolographicTheme.primaryEnergy,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.primaryEnergy.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo with subtle pulse
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    HolographicTheme.primaryEnergy,
                    HolographicTheme.secondaryEnergy,
                  ],
                  stops: [
                    _pulseController.value * 0.5,
                    0.5 + (_pulseController.value * 0.5),
                  ],
                ).createShader(bounds),
                child: const Text(
                  'SYNTHER HOLOGRAPHIC PRO',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // Audio reactivity indicator
          Consumer<SynthParametersModel>(
            builder: (context, synthParams, _) {
              final energy = _audioReactiveController.totalEnergy;
              return Container(
                width: 60,
                height: 8,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: energy.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HolographicTheme.primaryEnergy,
                          HolographicTheme.secondaryEnergy,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Master Volume
          Consumer<SynthParametersModel>(
            builder: (context, synthParams, _) {
              return Row(
                children: [
                  Text(
                    'MASTER',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    height: 40,
                    child: HolographicKnob(
                      size: 40,
                      value: synthParams.masterVolume,
                      label: '',
                      onChanged: (value) {
                        synthParams.setMasterVolume(value);
                        _audioReactiveController.updateFromSynthParameters(synthParams);
                      },
                      min: 0.0,
                      max: 1.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(
                      synthParams.isMasterMuted
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: synthParams.isMasterMuted
                          ? HolographicTheme.secondaryEnergy
                          : HolographicTheme.primaryEnergy,
                    ),
                    onPressed: () {
                      synthParams.setMasterMuted(!synthParams.isMasterMuted);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VISUAL ESSENCE',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.primaryEnergy,
              fontSize: 12,
              glowIntensity: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          // Visual System Controls
          const VisualSystemControls(),

          const SizedBox(height: 16),

          // Spectral analysis readout
          Expanded(
            child: _buildSpectralReadout(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectralReadout() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: HolographicTheme.secondaryEnergy.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SONIC ANALYSIS',
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _audioReactiveController,
              builder: (context, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildReadoutRow(
                      'ENERGY',
                      _audioReactiveController.totalEnergy,
                      HolographicTheme.primaryEnergy,
                    ),
                    _buildReadoutRow(
                      'BRIGHTNESS',
                      _audioReactiveController.spectralCentroid,
                      HolographicTheme.secondaryEnergy,
                    ),
                    _buildReadoutRow(
                      'FLUX',
                      _audioReactiveController.spectralFlux,
                      HolographicTheme.accentEnergy,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadoutRow(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 8,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCenterPanel() {
    return Consumer<SynthParametersModel>(
      builder: (context, synthParams, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYNTHESIZER CONTROLS',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.primaryEnergy,
                  fontSize: 14,
                  glowIntensity: 0.6,
                ),
              ),
              const SizedBox(height: 16),

              // Filter Section
              _buildFilterSection(synthParams),

              const SizedBox(height: 16),

              // Envelope Section
              _buildEnvelopeSection(synthParams),

              const SizedBox(height: 16),

              // Effects Section
              _buildEffectsSection(synthParams),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyzerOverlay() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: SevenBandAnalyzer(
        width: double.infinity,
        height: 80,
        showLabels: true,
        showPeakHold: true,
        onBandLevelsUpdate: _onBandLevelsUpdate,
      ),
    );
  }

  Widget _buildFilterSection(SynthParametersModel synthParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FILTER → VISUAL SHARPNESS',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  HolographicKnob(
                    size: 60,
                    value: (synthParams.filterCutoff - 20) / 19980,
                    label: 'CUTOFF',
                    onChanged: (value) {
                      final cutoff = 20 + (value * 19980);
                      synthParams.setFilterCutoff(cutoff);
                      _audioReactiveController.updateFromSynthParameters(synthParams);
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                  Text(
                    '${synthParams.filterCutoff.round()} Hz',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  HolographicKnob(
                    size: 60,
                    value: synthParams.filterResonance,
                    label: 'RESONANCE',
                    onChanged: (value) {
                      synthParams.setFilterResonance(value);
                      _audioReactiveController.updateFromSynthParameters(synthParams);
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                  Text(
                    '${(synthParams.filterResonance * 100).round()}%',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvelopeSection(SynthParametersModel synthParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ENVELOPE → MORPH SPEED',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildEnvelopeKnob(
                synthParams,
                'A',
                synthParams.attackTime,
                (v) {
                  synthParams.setAttackTime(v);
                  _audioReactiveController.updateFromSynthParameters(synthParams);
                },
                0.001,
                5.0,
                '${(synthParams.attackTime * 1000).round()} ms',
              ),
            ),
            Expanded(
              child: _buildEnvelopeKnob(
                synthParams,
                'D',
                synthParams.decayTime,
                (v) {
                  synthParams.setDecayTime(v);
                  _audioReactiveController.updateFromSynthParameters(synthParams);
                },
                0.001,
                5.0,
                '${(synthParams.decayTime * 1000).round()} ms',
              ),
            ),
            Expanded(
              child: _buildEnvelopeKnob(
                synthParams,
                'S',
                synthParams.sustainLevel,
                (v) {
                  synthParams.setSustainLevel(v);
                  _audioReactiveController.updateFromSynthParameters(synthParams);
                },
                0.0,
                1.0,
                '${(synthParams.sustainLevel * 100).round()}%',
              ),
            ),
            Expanded(
              child: _buildEnvelopeKnob(
                synthParams,
                'R',
                synthParams.releaseTime,
                (v) {
                  synthParams.setReleaseTime(v);
                  _audioReactiveController.updateFromSynthParameters(synthParams);
                },
                0.001,
                10.0,
                '${(synthParams.releaseTime * 1000).round()} ms',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnvelopeKnob(
    SynthParametersModel synthParams,
    String label,
    double value,
    Function(double) onChanged,
    double min,
    double max,
    String displayValue,
  ) {
    return Column(
      children: [
        HolographicKnob(
          size: 50,
          value: (value - min) / (max - min),
          label: label,
          onChanged: (normalized) {
            final actualValue = min + (normalized * (max - min));
            onChanged(actualValue);
          },
          min: 0.0,
          max: 1.0,
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: TextStyle(
            color: HolographicTheme.primaryEnergy.withOpacity(0.6),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsSection(SynthParametersModel synthParams) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EFFECTS → DEPTH & SPACE',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  HolographicKnob(
                    size: 50,
                    value: synthParams.reverbMix,
                    label: 'REVERB',
                    onChanged: (value) {
                      synthParams.setReverbMix(value);
                      _audioReactiveController.updateFromSynthParameters(synthParams);
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                  Text(
                    '${(synthParams.reverbMix * 100).round()}%',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  HolographicKnob(
                    size: 50,
                    value: (synthParams.delayTime - 0.01) / 1.99,
                    label: 'DELAY',
                    onChanged: (value) {
                      final delayTime = 0.01 + (value * 1.99);
                      synthParams.setDelayTime(delayTime);
                      _audioReactiveController.updateFromSynthParameters(synthParams);
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                  Text(
                    '${(synthParams.delayTime * 1000).round()} ms',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  HolographicKnob(
                    size: 50,
                    value: synthParams.delayFeedback,
                    label: 'FEEDBACK',
                    onChanged: (value) {
                      synthParams.setDelayFeedback(value);
                      _audioReactiveController.updateFromSynthParameters(synthParams);
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                  Text(
                    '${(synthParams.delayFeedback * 100).round()}%',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
