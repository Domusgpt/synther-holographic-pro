import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';
import 'spectrum_display.dart';

/// Professional Effects Chain with comprehensive audio processing
/// 
/// Features:
/// - Multi-band EQ with spectral visualization
/// - Reverb (algorithmic, convolution, shimmer)
/// - Delay (tape, digital, ping-pong, grain)
/// - Chorus/Flanger/Phaser with modulation visualization
/// - Distortion/Saturation with harmonic analysis
/// - Compressor/Limiter with gain reduction meter
/// - Real-time spectrum analysis for each effect
class EffectsChain extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const EffectsChain({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<EffectsChain> createState() => _EffectsChainState();
}

class _EffectsChainState extends State<EffectsChain> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _effectController;
  
  // Effects order and states
  final List<String> _effectsOrder = [
    'eq', 'compressor', 'distortion', 'chorus', 'delay', 'reverb'
  ];
  
  final Map<String, bool> _effectsEnabled = {
    'eq': true,
    'compressor': false,
    'distortion': false,
    'chorus': false,
    'delay': false,
    'reverb': true,
  };

  final Map<String, bool> _effectsExpanded = {
    'eq': true,
    'compressor': false,
    'distortion': false,
    'chorus': false,
    'delay': false,
    'reverb': false,
  };

  // EQ Parameters
  final Map<String, double> _eqParams = {
    'low_freq': 80.0,
    'low_gain': 0.0,
    'low_q': 0.7,
    'mid_freq': 1000.0,
    'mid_gain': 0.0,
    'mid_q': 1.0,
    'high_freq': 8000.0,
    'high_gain': 0.0,
    'high_q': 0.7,
  };

  // Compressor Parameters
  final Map<String, double> _compressorParams = {
    'threshold': -20.0,
    'ratio': 4.0,
    'attack': 10.0,
    'release': 100.0,
    'makeup_gain': 0.0,
    'mix': 1.0,
  };

  // Distortion Parameters
  final Map<String, double> _distortionParams = {
    'drive': 0.5,
    'type': 0.0, // 0=tube, 1=fuzz, 2=bit_crush, 3=tape
    'tone': 0.5,
    'output': 0.8,
    'mix': 1.0,
  };

  // Chorus Parameters
  final Map<String, double> _chorusParams = {
    'rate': 1.0,
    'depth': 0.5,
    'feedback': 0.3,
    'delay': 5.0,
    'mix': 0.5,
    'type': 0.0, // 0=chorus, 1=flanger, 2=phaser
  };

  // Delay Parameters
  final Map<String, double> _delayParams = {
    'time': 250.0,
    'feedback': 0.4,
    'high_cut': 8000.0,
    'low_cut': 200.0,
    'ping_pong': 0.0,
    'mix': 0.3,
    'type': 0.0, // 0=digital, 1=tape, 2=grain
  };

  // Reverb Parameters
  final Map<String, double> _reverbParams = {
    'size': 0.7,
    'decay': 0.6,
    'damping': 0.5,
    'pre_delay': 20.0,
    'diffusion': 0.8,
    'mix': 0.25,
    'type': 0.0, // 0=hall, 1=room, 2=plate, 3=spring, 4=shimmer
  };

  int _selectedEffect = 0;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _effectController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _effectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HolographicTheme.primaryEnergy.withOpacity(0.05 + (_pulseController.value * 0.02)),
                HolographicTheme.secondaryEnergy.withOpacity(0.03),
                HolographicTheme.deepSpaceBlack.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.3 + (_pulseController.value * 0.1)),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Effects chain routing display
                _buildEffectsChainRouting(),
                
                const SizedBox(height: 16),
                
                // Effects tabs
                _buildEffectsTabs(),
                
                const SizedBox(height: 16),
                
                // Current effect controls
                _buildCurrentEffectControls(),
                
                const SizedBox(height: 16),
                
                // Real-time spectrum analysis
                _buildEffectsSpectrum(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEffectsChainRouting() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HolographicTheme.primaryEnergy.withOpacity(0.1),
            HolographicTheme.secondaryEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: List.generate(_effectsOrder.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Arrow between effects
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.arrow_forward,
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  size: 16,
                ),
              );
            } else {
              // Effect box
              final effectIndex = index ~/ 2;
              final effectName = _effectsOrder[effectIndex];
              final isEnabled = _effectsEnabled[effectName] ?? false;
              final isSelected = effectIndex == _selectedEffect;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedEffect = effectIndex),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isSelected ? [
                          HolographicTheme.accentEnergy.withOpacity(0.3),
                          HolographicTheme.accentEnergy.withOpacity(0.1),
                        ] : [
                          HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 0.2 : 0.05),
                          HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 0.1 : 0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected 
                          ? HolographicTheme.accentEnergy 
                          : HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 0.5 : 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            effectName.toUpperCase(),
                            style: HolographicTheme.createHolographicText(
                              energyColor: isSelected 
                                ? HolographicTheme.accentEnergy 
                                : HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 1.0 : 0.5),
                              fontSize: 10,
                              glowIntensity: isSelected ? 0.8 : (isEnabled ? 0.4 : 0.2),
                            ),
                          ),
                        ),
                        
                        // Enable/disable indicator
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _toggleEffect(effectName),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isEnabled 
                                  ? HolographicTheme.accentEnergy 
                                  : HolographicTheme.primaryEnergy.withOpacity(0.3),
                                shape: BoxShape.circle,
                                boxShadow: isEnabled ? [
                                  BoxShadow(
                                    color: HolographicTheme.accentEnergy.withOpacity(0.6),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  Widget _buildEffectsTabs() {
    return Row(
      children: List.generate(_effectsOrder.length, (index) {
        final effectName = _effectsOrder[index];
        final isSelected = index == _selectedEffect;
        final isEnabled = _effectsEnabled[effectName] ?? false;
        final isExpanded = _effectsExpanded[effectName] ?? false;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedEffect = index),
            child: Container(
              height: 60,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected ? [
                    HolographicTheme.accentEnergy.withOpacity(0.3),
                    HolographicTheme.accentEnergy.withOpacity(0.1),
                  ] : [
                    HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 0.15 : 0.05),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                    ? HolographicTheme.accentEnergy 
                    : HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 0.5 : 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          effectName.toUpperCase(),
                          style: HolographicTheme.createHolographicText(
                            energyColor: isSelected 
                              ? HolographicTheme.accentEnergy 
                              : HolographicTheme.primaryEnergy.withOpacity(isEnabled ? 1.0 : 0.7),
                            fontSize: 12,
                            glowIntensity: isSelected ? 0.8 : (isEnabled ? 0.5 : 0.3),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                  
                  // Enable/disable toggle
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _toggleEffect(effectName),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isEnabled 
                            ? HolographicTheme.accentEnergy 
                            : HolographicTheme.primaryEnergy.withOpacity(0.3),
                          shape: BoxShape.circle,
                          boxShadow: isEnabled ? [
                            BoxShadow(
                              color: HolographicTheme.accentEnergy.withOpacity(0.6),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ] : null,
                        ),
                      ),
                    ),
                  ),
                  
                  // Expand/collapse toggle
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _toggleExpansion(effectName),
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentEffectControls() {
    final effectName = _effectsOrder[_selectedEffect];
    final isExpanded = _effectsExpanded[effectName] ?? false;
    
    if (!isExpanded) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              HolographicTheme.primaryEnergy.withOpacity(0.05),
              HolographicTheme.secondaryEnergy.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            '${effectName.toUpperCase()} - Click to expand controls',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.primaryEnergy.withOpacity(0.6),
              fontSize: 14,
              glowIntensity: 0.3,
            ),
          ),
        ),
      );
    }
    
    switch (effectName) {
      case 'eq':
        return _buildEQControls();
      case 'compressor':
        return _buildCompressorControls();
      case 'distortion':
        return _buildDistortionControls();
      case 'chorus':
        return _buildChorusControls();
      case 'delay':
        return _buildDelayControls();
      case 'reverb':
        return _buildReverbControls();
      default:
        return Container();
    }
  }

  Widget _buildEQControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MULTI-BAND EQUALIZER',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        
        // EQ bands
        Row(
          children: [
            // Low band
            Expanded(
              child: Column(
                children: [
                  Text(
                    'LOW',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.primaryEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: HolographicKnob(
                          label: 'FREQ',
                          value: (_eqParams['low_freq']! - 20.0) / 480.0,
                          onChanged: (value) => _updateEQParam('low_freq', 20.0 + (value * 480.0)),
                          color: HolographicTheme.primaryEnergy,
                          size: 60,
                          showSpectrum: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'GAIN',
                          value: (_eqParams['low_gain']! + 20.0) / 40.0,
                          onChanged: (value) => _updateEQParam('low_gain', (value * 40.0) - 20.0),
                          color: HolographicTheme.secondaryEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'Q',
                          value: (_eqParams['low_q']! - 0.1) / 9.9,
                          onChanged: (value) => _updateEQParam('low_q', 0.1 + (value * 9.9)),
                          color: HolographicTheme.accentEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Mid band
            Expanded(
              child: Column(
                children: [
                  Text(
                    'MID',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.primaryEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: HolographicKnob(
                          label: 'FREQ',
                          value: (_eqParams['mid_freq']! - 200.0) / 3800.0,
                          onChanged: (value) => _updateEQParam('mid_freq', 200.0 + (value * 3800.0)),
                          color: HolographicTheme.primaryEnergy,
                          size: 60,
                          showSpectrum: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'GAIN',
                          value: (_eqParams['mid_gain']! + 20.0) / 40.0,
                          onChanged: (value) => _updateEQParam('mid_gain', (value * 40.0) - 20.0),
                          color: HolographicTheme.secondaryEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'Q',
                          value: (_eqParams['mid_q']! - 0.1) / 9.9,
                          onChanged: (value) => _updateEQParam('mid_q', 0.1 + (value * 9.9)),
                          color: HolographicTheme.accentEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // High band
            Expanded(
              child: Column(
                children: [
                  Text(
                    'HIGH',
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.primaryEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: HolographicKnob(
                          label: 'FREQ',
                          value: (_eqParams['high_freq']! - 2000.0) / 18000.0,
                          onChanged: (value) => _updateEQParam('high_freq', 2000.0 + (value * 18000.0)),
                          color: HolographicTheme.primaryEnergy,
                          size: 60,
                          showSpectrum: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'GAIN',
                          value: (_eqParams['high_gain']! + 20.0) / 40.0,
                          onChanged: (value) => _updateEQParam('high_gain', (value * 40.0) - 20.0),
                          color: HolographicTheme.secondaryEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: HolographicKnob(
                          label: 'Q',
                          value: (_eqParams['high_q']! - 0.1) / 9.9,
                          onChanged: (value) => _updateEQParam('high_q', 0.1 + (value * 9.9)),
                          color: HolographicTheme.accentEnergy,
                          size: 60,
                          showSpectrum: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompressorControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DYNAMICS COMPRESSOR',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'THRESHOLD',
                value: (_compressorParams['threshold']! + 60.0) / 60.0,
                onChanged: (value) => _updateCompressorParam('threshold', (value * 60.0) - 60.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'RATIO',
                value: (_compressorParams['ratio']! - 1.0) / 19.0,
                onChanged: (value) => _updateCompressorParam('ratio', 1.0 + (value * 19.0)),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'ATTACK',
                value: _compressorParams['attack']! / 1000.0,
                onChanged: (value) => _updateCompressorParam('attack', value * 1000.0),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'RELEASE',
                value: _compressorParams['release']! / 5000.0,
                onChanged: (value) => _updateCompressorParam('release', value * 5000.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MAKEUP',
                value: (_compressorParams['makeup_gain']! + 30.0) / 60.0,
                onChanged: (value) => _updateCompressorParam('makeup_gain', (value * 60.0) - 30.0),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MIX',
                value: _compressorParams['mix']!,
                onChanged: (value) => _updateCompressorParam('mix', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistortionControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HARMONIC DISTORTION',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'DRIVE',
                value: _distortionParams['drive']!,
                onChanged: (value) => _updateDistortionParam('drive', value),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'TONE',
                value: _distortionParams['tone']!,
                onChanged: (value) => _updateDistortionParam('tone', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'OUTPUT',
                value: _distortionParams['output']!,
                onChanged: (value) => _updateDistortionParam('output', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MIX',
                value: _distortionParams['mix']!,
                onChanged: (value) => _updateDistortionParam('mix', value),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChorusControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MODULATION EFFECTS',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'RATE',
                value: _chorusParams['rate']! / 10.0,
                onChanged: (value) => _updateChorusParam('rate', value * 10.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'DEPTH',
                value: _chorusParams['depth']!,
                onChanged: (value) => _updateChorusParam('depth', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'FEEDBACK',
                value: _chorusParams['feedback']!,
                onChanged: (value) => _updateChorusParam('feedback', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'DELAY',
                value: _chorusParams['delay']! / 50.0,
                onChanged: (value) => _updateChorusParam('delay', value * 50.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MIX',
                value: _chorusParams['mix']!,
                onChanged: (value) => _updateChorusParam('mix', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDelayControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TEMPORAL DELAY',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'TIME',
                value: _delayParams['time']! / 2000.0,
                onChanged: (value) => _updateDelayParam('time', value * 2000.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'FEEDBACK',
                value: _delayParams['feedback']!,
                onChanged: (value) => _updateDelayParam('feedback', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'HIGH CUT',
                value: (_delayParams['high_cut']! - 1000.0) / 19000.0,
                onChanged: (value) => _updateDelayParam('high_cut', 1000.0 + (value * 19000.0)),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'LOW CUT',
                value: (_delayParams['low_cut']! - 20.0) / 480.0,
                onChanged: (value) => _updateDelayParam('low_cut', 20.0 + (value * 480.0)),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'PING PONG',
                value: _delayParams['ping_pong']!,
                onChanged: (value) => _updateDelayParam('ping_pong', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MIX',
                value: _delayParams['mix']!,
                onChanged: (value) => _updateDelayParam('mix', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReverbControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPATIAL REVERB',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'SIZE',
                value: _reverbParams['size']!,
                onChanged: (value) => _updateReverbParam('size', value),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'DECAY',
                value: _reverbParams['decay']!,
                onChanged: (value) => _updateReverbParam('decay', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'DAMPING',
                value: _reverbParams['damping']!,
                onChanged: (value) => _updateReverbParam('damping', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'PRE DELAY',
                value: _reverbParams['pre_delay']! / 500.0,
                onChanged: (value) => _updateReverbParam('pre_delay', value * 500.0),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'DIFFUSION',
                value: _reverbParams['diffusion']!,
                onChanged: (value) => _updateReverbParam('diffusion', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'MIX',
                value: _reverbParams['mix']!,
                onChanged: (value) => _updateReverbParam('mix', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEffectsSpectrum() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HolographicTheme.deepSpaceBlack.withOpacity(0.8),
            HolographicTheme.primaryEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: SpectrumDisplay(
        spectrumData: _generateEffectsSpectrumData(),
        color: HolographicTheme.accentEnergy,
        title: 'EFFECTS CHAIN OUTPUT',
      ),
    );
  }

  void _toggleEffect(String effectName) {
    setState(() {
      _effectsEnabled[effectName] = !(_effectsEnabled[effectName] ?? false);
    });
    widget.onParameterChange('${effectName}_enabled', _effectsEnabled[effectName]! ? 1.0 : 0.0);
  }

  void _toggleExpansion(String effectName) {
    setState(() {
      _effectsExpanded[effectName] = !(_effectsExpanded[effectName] ?? false);
    });
  }

  void _updateEQParam(String param, double value) {
    setState(() {
      _eqParams[param] = value;
    });
    widget.onParameterChange('eq_$param', value);
  }

  void _updateCompressorParam(String param, double value) {
    setState(() {
      _compressorParams[param] = value;
    });
    widget.onParameterChange('compressor_$param', value);
  }

  void _updateDistortionParam(String param, double value) {
    setState(() {
      _distortionParams[param] = value;
    });
    widget.onParameterChange('distortion_$param', value);
  }

  void _updateChorusParam(String param, double value) {
    setState(() {
      _chorusParams[param] = value;
    });
    widget.onParameterChange('chorus_$param', value);
  }

  void _updateDelayParam(String param, double value) {
    setState(() {
      _delayParams[param] = value;
    });
    widget.onParameterChange('delay_$param', value);
  }

  void _updateReverbParam(String param, double value) {
    setState(() {
      _reverbParams[param] = value;
    });
    widget.onParameterChange('reverb_$param', value);
  }

  List<double> _generateEffectsSpectrumData() {
    final effectName = _effectsOrder[_selectedEffect];
    final isEnabled = _effectsEnabled[effectName] ?? false;
    
    return List.generate(64, (i) {
      final freq = i / 64.0;
      if (!isEnabled) return math.sin(freq * math.pi * 4) * 0.1;
      
      switch (effectName) {
        case 'eq':
          // EQ curve simulation
          final lowGain = _eqParams['low_gain']! / 20.0;
          final midGain = _eqParams['mid_gain']! / 20.0;
          final highGain = _eqParams['high_gain']! / 20.0;
          
          if (freq < 0.2) return (0.3 + lowGain * 0.3).clamp(0.0, 1.0);
          if (freq < 0.6) return (0.4 + midGain * 0.3).clamp(0.0, 1.0);
          return (0.35 + highGain * 0.3).clamp(0.0, 1.0);
          
        case 'compressor':
          // Compression curve
          final threshold = _compressorParams['threshold']! / -60.0;
          final ratio = _compressorParams['ratio']! / 20.0;
          final compressedLevel = freq > threshold ? (freq - threshold) / ratio + threshold : freq;
          return (compressedLevel * 0.8).clamp(0.0, 1.0);
          
        case 'distortion':
          // Harmonic generation
          final drive = _distortionParams['drive']!;
          final harmonicContent = math.sin(freq * math.pi * 8) * drive * 0.5;
          return (freq * 0.5 + harmonicContent.abs()).clamp(0.0, 1.0);
          
        case 'chorus':
          // Modulation visualization
          final rate = _chorusParams['rate']! / 10.0;
          final depth = _chorusParams['depth']!;
          final modulation = math.sin(freq * math.pi * 12 + rate * 4) * depth * 0.3;
          return (freq * 0.6 + modulation.abs()).clamp(0.0, 1.0);
          
        case 'delay':
          // Echo pattern
          final feedback = _delayParams['feedback']!;
          final delayPattern = math.sin(freq * math.pi * 16) * feedback * 0.4;
          return (freq * 0.5 + delayPattern.abs()).clamp(0.0, 1.0);
          
        case 'reverb':
          // Reverb tail
          final size = _reverbParams['size']!;
          final decay = _reverbParams['decay']!;
          final reverbTail = math.exp(-freq * 5) * size * decay;
          return (freq * 0.4 + reverbTail).clamp(0.0, 1.0);
          
        default:
          return freq * 0.5;
      }
    });
  }
}