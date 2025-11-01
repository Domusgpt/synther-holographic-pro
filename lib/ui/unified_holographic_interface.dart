import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../core/synth_parameters.dart';
import '../core/parameter_visualizer_bridge.dart';
import '../core/audio_reactive_controller.dart';
import '../widgets/seven_band_analyzer.dart';
import '../widgets/visual_system_controls.dart';
import '../widgets/synth_components/holographic_knob.dart';
import '../widgets/embedded_hyperav_visualizer.dart';
import 'holographic/holographic_theme.dart';
import 'audio_reactive_ui_effects.dart';

/// Unified Holographic Interface with Deep Audio-Visual Coupling
///
/// Audio information is conveyed through elegant visual effects:
/// - Knob halos pulse with their frequency bands
/// - Panels glow based on energy levels
/// - Color temperature shifts with spectral centroid
/// - Particles spawn on flux peaks
/// - Borders shimmer on transients
/// - Everything breathes with the music
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

  bool _showAnalyzerOverlay = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _visualBridge = ParameterVisualizerBridge();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBridge();
    });
  }

  void _initializeBridge() {
    _visualBridge.initialize(
      visualizerUpdateCallback: (param, value) {
        debugPrint('Visualizer: $param = ${value.toStringAsFixed(2)}');
      },
      uiTintCallback: (param, color, value) {},
    );

    _audioReactiveController = AudioReactiveController(_visualBridge);

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
    _audioReactiveController.updateBandLevels(levels);

    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    _audioReactiveController.updateFromSynthParameters(synthParams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // HyperAV Visualizer Background
          const Positioned.fill(
            child: EmbeddedHyperAVVisualizer(),
          ),

          // Energy particles overlay
          Positioned.fill(
            child: EnergyParticles(
              audioController: _audioReactiveController,
            ),
          ),

          // Headless 7-band analyzer
          SevenBandAnalyzer(
            headless: true,
            onBandLevelsUpdate: _onBandLevelsUpdate,
          ),

          // Main Interface with audio-reactive effects
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLeftPanel(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCenterPanel(),
                        ),
                      ],
                    ),
                  ),
                  if (_showAnalyzerOverlay) _buildAnalyzerOverlay(),
                ],
              ),
            ),
          ),

          // Toggle button for debug analyzer
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
    return AudioReactiveUIEffects(
      audioController: _audioReactiveController,
      effectType: 'panel',
      child: Container(
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
            // Logo with pulsing gradient
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

            // Subtle energy indicator (no numbers, just visual breathing)
            AnimatedBuilder(
              animation: _audioReactiveController,
              builder: (context, _) {
                final energy = _audioReactiveController.totalEnergy;
                return Container(
                  width: 60,
                  height: 8,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
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
                                color: HolographicTheme.primaryEnergy.withOpacity(energy * 0.6),
                                blurRadius: 8 + (energy * 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Master Volume with audio-reactive glow
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
                      child: AudioReactiveKnob(
                        audioController: _audioReactiveController,
                        responsiveBands: [0, 1, 2, 3, 4, 5, 6], // All bands
                        size: 40,
                        knob: HolographicKnob(
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
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(
                        synthParams.isMasterMuted ? Icons.volume_off : Icons.volume_up,
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
      ),
    );
  }

  Widget _buildLeftPanel() {
    return AudioReactiveUIEffects(
      audioController: _audioReactiveController,
      effectType: 'panel',
      child: Container(
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

            // Elegant visual feedback (replaces numeric readout)
            Expanded(
              child: _buildVisualEssenceDisplay(),
            ),
          ],
        ),
      ),
    );
  }

  /// Elegant visual essence display - no numbers, just beauty
  Widget _buildVisualEssenceDisplay() {
    return AnimatedBuilder(
      animation: _audioReactiveController,
      builder: (context, _) {
        final energy = _audioReactiveController.totalEnergy;
        final centroid = _audioReactiveController.spectralCentroid;
        final flux = _audioReactiveController.spectralFlux;

        // Color shifts based on spectral centroid
        final essenceColor = Color.lerp(
          HolographicTheme.secondaryEnergy, // Warm (bass-heavy)
          HolographicTheme.accentEnergy,    // Cool (treble-heavy)
          centroid,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                essenceColor.withOpacity(energy * 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: essenceColor.withOpacity(0.3 + (flux * 0.4)),
              width: 1 + (energy * 2),
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(150, 150),
              painter: SonicEssencePainter(
                energy: energy,
                centroid: centroid,
                flux: flux,
                audioController: _audioReactiveController,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterPanel() {
    return Consumer<SynthParametersModel>(
      builder: (context, synthParams, _) {
        return AudioReactiveUIEffects(
          audioController: _audioReactiveController,
          effectType: 'panel',
          child: Container(
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

                _buildFilterSection(synthParams),
                const SizedBox(height: 16),
                _buildEnvelopeSection(synthParams),
                const SizedBox(height: 16),
                _buildEffectsSection(synthParams),
              ],
            ),
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
                  AudioReactiveKnob(
                    audioController: _audioReactiveController,
                    responsiveBands: [2, 3], // Low-mids and mids
                    size: 60,
                    knob: HolographicKnob(
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
                  AudioReactiveKnob(
                    audioController: _audioReactiveController,
                    responsiveBands: [4, 5], // High-mids and presence
                    size: 60,
                    knob: HolographicKnob(
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
                [1, 2], // Bass and low-mids
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
                [2, 3], // Low-mids and mids
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
                [3, 4], // Mids and high-mids
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
                [4, 5], // High-mids and presence
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
    List<int> responsiveBands,
  ) {
    return Column(
      children: [
        AudioReactiveKnob(
          audioController: _audioReactiveController,
          responsiveBands: responsiveBands,
          size: 50,
          knob: HolographicKnob(
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
                  AudioReactiveKnob(
                    audioController: _audioReactiveController,
                    responsiveBands: [0, 1], // Sub-bass and bass
                    size: 50,
                    knob: HolographicKnob(
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
                  AudioReactiveKnob(
                    audioController: _audioReactiveController,
                    responsiveBands: [3, 4], // Mids and high-mids
                    size: 50,
                    knob: HolographicKnob(
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
                  AudioReactiveKnob(
                    audioController: _audioReactiveController,
                    responsiveBands: [5, 6], // Presence and brilliance
                    size: 50,
                    knob: HolographicKnob(
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

/// Painter for the sonic essence visualization
class SonicEssencePainter extends CustomPainter {
  final double energy;
  final double centroid;
  final double flux;
  final AudioReactiveController audioController;

  SonicEssencePainter({
    required this.energy,
    required this.centroid,
    required this.flux,
    required this.audioController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.stroke;

    // Draw frequency band orbits
    final bands = audioController.bandLevels;
    for (int i = 0; i < bands.length; i++) {
      final radius = 20.0 + (i * 10.0);
      final bandEnergy = bands[i];

      // Color based on frequency
      Color bandColor;
      if (i <= 1) {
        bandColor = HolographicTheme.secondaryEnergy; // Bass
      } else if (i <= 3) {
        bandColor = HolographicTheme.primaryEnergy; // Mids
      } else {
        bandColor = HolographicTheme.accentEnergy; // Highs
      }

      paint.color = bandColor.withOpacity(0.3 + (bandEnergy * 0.5));
      paint.strokeWidth = 1 + (bandEnergy * 3);

      canvas.drawCircle(center, radius * (1.0 + bandEnergy * 0.2), paint);
    }

    // Draw central energy core
    if (energy > 0.1) {
      final corePaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          20 * (1.0 + energy),
          [
            HolographicTheme.primaryEnergy.withOpacity(energy),
            Colors.transparent,
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, 20 * (1.0 + energy), corePaint);
    }
  }

  @override
  bool shouldRepaint(SonicEssencePainter oldDelegate) => true;
}
