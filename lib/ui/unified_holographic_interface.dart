import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/parameter_visualizer_bridge.dart';
import '../widgets/seven_band_analyzer.dart';
import '../widgets/visual_system_controls.dart';
import '../widgets/synth_components/holographic_knob.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import 'holographic/holographic_theme.dart';

/// Unified Holographic Interface
///
/// Clean, modern interface that:
/// - Always shows 7-band audio reactivity
/// - Uses toggle controls for system type and geometry
/// - Connects visual parameters directly to synthesizer state
/// - Removes legacy draggable complexity
class UnifiedHolographicInterface extends StatefulWidget {
  const UnifiedHolographicInterface({Key? key}) : super(key: key);

  @override
  State<UnifiedHolographicInterface> createState() =>
      _UnifiedHolographicInterfaceState();
}

class _UnifiedHolographicInterfaceState
    extends State<UnifiedHolographicInterface> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late ParameterVisualizerBridge _bridge;

  // 7-band levels for audio-reactive visualization
  List<double> _bandLevels = List.filled(7, 0.0);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _bridge = ParameterVisualizerBridge();

    // Initialize bridge when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBridge();
    });
  }

  void _initializeBridge() {
    _bridge.initialize(
      visualizerUpdateCallback: (param, value) {
        // This callback will be called when parameters update
        debugPrint('Visualizer parameter updated: $param = $value');
      },
      uiTintCallback: (param, color, value) {
        // This callback can be used for UI feedback
        debugPrint('UI tint: $param = $value');
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onBandLevelsUpdate(List<double> levels) {
    setState(() {
      _bandLevels = levels;
    });

    // Map band levels to visualizer parameters for audio-reactivity
    if (_bridge.isConnected) {
      // Map bass to pattern intensity
      _bridge.updateParameter('patternIntensity', 0.5 + (_bandLevels[1] * 1.5));

      // Map mids to rotation speed
      _bridge.updateParameter('rotationSpeed', _bandLevels[3] * 2.0);

      // Map highs to glitch intensity
      _bridge.updateParameter('glitchIntensity', _bandLevels[5] * 0.15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // HyperAV Visualizer Background (always visible)
          const Positioned.fill(
            child: EmbeddedHyperAVVisualizer(),
          ),

          // Main Interface Overlay
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
                        // Left Panel: Visual System Controls & Analyzer
                        _buildLeftPanel(),

                        const SizedBox(width: 16),

                        // Center: Main Synth Controls
                        Expanded(
                          child: _buildCenterPanel(),
                        ),

                        const SizedBox(width: 16),

                        // Right Panel: Additional Controls
                        _buildRightPanel(),
                      ],
                    ),
                  ),

                  // Bottom: 7-Band Analyzer (Always Visible)
                  _buildBottomAnalyzer(),
                ],
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
          // Logo
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                HolographicTheme.primaryEnergy,
                HolographicTheme.secondaryEnergy,
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
          ),

          const Spacer(),

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
                      onChanged: synthParams.setMasterVolume,
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
          // Visual System Controls
          const VisualSystemControls(),

          const SizedBox(height: 16),

          // Vertical 7-Band Analyzer
          Expanded(
            child: SevenBandAnalyzer(
              width: 196,
              height: double.infinity,
              showLabels: true,
              showPeakHold: true,
              onBandLevelsUpdate: _onBandLevelsUpdate,
            ),
          ),
        ],
      ),
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

  Widget _buildRightPanel() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRESET & AUTOMATION',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.secondaryEnergy,
              fontSize: 12,
              glowIntensity: 0.6,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Text(
                'Preset controls will appear here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAnalyzer() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: SevenBandAnalyzer(
        width: double.infinity,
        height: 100,
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
          'FILTER',
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
                      _bridge.updateParameter('filterCutoff', value);
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
                      _bridge.updateParameter('filterResonance', value);
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
          'ENVELOPE (ADSR)',
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
                  _bridge.updateParameter('attackTime', v / 5.0);
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
                synthParams.setDecayTime,
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
                synthParams.setSustainLevel,
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
                synthParams.setReleaseTime,
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
          'EFFECTS',
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
                      _bridge.updateParameter('reverbMix', value);
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
                      _bridge.updateParameter('delayMix', value);
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
                    onChanged: synthParams.setDelayFeedback,
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
