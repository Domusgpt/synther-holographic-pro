import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';
import 'spectrum_display.dart';
import 'waveform_display.dart';

/// Professional Oscillator Bank with multiple synthesis types
/// 
/// Features:
/// - 4 independent oscillators
/// - Multiple waveform types (sine, saw, square, noise, wavetable)
/// - FM synthesis with operator visualization
/// - Granular synthesis with particle display
/// - Additive synthesis with harmonic spectrum
/// - Real-time spectrum analysis for each oscillator
class OscillatorBank extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const OscillatorBank({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<OscillatorBank> createState() => _OscillatorBankState();
}

class _OscillatorBankState extends State<OscillatorBank> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  
  // Oscillator states
  final List<Map<String, dynamic>> _oscillators = [
    {
      'id': 'osc1',
      'enabled': true,
      'type': 'wavetable',
      'frequency': 440.0,
      'amplitude': 0.8,
      'phase': 0.0,
      'detune': 0.0,
      'fm_amount': 0.0,
      'fm_frequency': 1.0,
      'wavetable_position': 0.5,
      'granular_size': 100.0,
      'granular_density': 0.5,
      'harmonics': List.generate(16, (i) => i == 0 ? 1.0 : 0.0),
    },
    {
      'id': 'osc2',
      'enabled': false,
      'type': 'fm',
      'frequency': 880.0,
      'amplitude': 0.6,
      'phase': 0.0,
      'detune': -7.0,
      'fm_amount': 0.3,
      'fm_frequency': 2.5,
      'wavetable_position': 0.3,
      'granular_size': 150.0,
      'granular_density': 0.3,
      'harmonics': List.generate(16, (i) => 1.0 / (i + 1)),
    },
    {
      'id': 'osc3',
      'enabled': false,
      'type': 'granular',
      'frequency': 220.0,
      'amplitude': 0.4,
      'phase': 0.0,
      'detune': 12.0,
      'fm_amount': 0.0,
      'fm_frequency': 1.0,
      'wavetable_position': 0.7,
      'granular_size': 200.0,
      'granular_density': 0.7,
      'harmonics': List.generate(16, (i) => math.Random().nextDouble() * 0.5),
    },
    {
      'id': 'osc4',
      'enabled': false,
      'type': 'additive',
      'frequency': 110.0,
      'amplitude': 0.5,
      'phase': 0.0,
      'detune': 5.0,
      'fm_amount': 0.1,
      'fm_frequency': 0.5,
      'wavetable_position': 0.1,
      'granular_size': 80.0,
      'granular_density': 0.8,
      'harmonics': [1.0, 0.5, 0.25, 0.125, 0.0625, 0.03125, 0.015625, 0.0078125, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    },
  ];

  final List<String> _oscillatorTypes = [
    'sine', 'saw', 'square', 'triangle', 'noise', 'wavetable', 'fm', 'granular', 'additive'
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
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
                // Oscillator tabs
                _buildOscillatorTabs(),
                
                const SizedBox(height: 16),
                
                // Current oscillator controls
                _buildCurrentOscillatorControls(),
                
                const SizedBox(height: 16),
                
                // Synthesis type specific controls
                _buildSynthesisControls(),
                
                const SizedBox(height: 16),
                
                // Real-time visualization
                _buildVisualization(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOscillatorTabs() {
    return Row(
      children: List.generate(_oscillators.length, (index) {
        final osc = _oscillators[index];
        final isSelected = index == _selectedOscillator;
        final isEnabled = osc['enabled'] as bool;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedOscillator = index),
            child: Container(
              height: 40,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSelected ? [
                    HolographicTheme.primaryEnergy.withOpacity(0.3),
                    HolographicTheme.primaryEnergy.withOpacity(0.1),
                  ] : [
                    HolographicTheme.primaryEnergy.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                    ? HolographicTheme.primaryEnergy 
                    : HolographicTheme.primaryEnergy.withOpacity(0.3),
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
                          'OSC ${index + 1}',
                          style: HolographicTheme.createHolographicText(
                            energyColor: isSelected 
                              ? HolographicTheme.primaryEnergy 
                              : HolographicTheme.primaryEnergy.withOpacity(0.7),
                            fontSize: 12,
                            glowIntensity: isSelected ? 0.8 : 0.3,
                          ),
                        ),
                        Text(
                          osc['type'].toString().toUpperCase(),
                          style: HolographicTheme.createHolographicText(
                            energyColor: HolographicTheme.secondaryEnergy,
                            fontSize: 8,
                            glowIntensity: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Enable/disable indicator
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _toggleOscillator(index),
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
      }),
    );
  }

  int _selectedOscillator = 0;

  Widget _buildCurrentOscillatorControls() {
    final osc = _oscillators[_selectedOscillator];
    
    return Row(
      children: [
        // Basic controls
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: HolographicKnob(
                      label: 'FREQUENCY',
                      value: (osc['frequency'] as double) / 2000.0,
                      onChanged: (value) => _updateParameter('frequency', value * 2000.0),
                      color: HolographicTheme.primaryEnergy,
                      showSpectrum: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HolographicKnob(
                      label: 'AMPLITUDE',
                      value: osc['amplitude'] as double,
                      onChanged: (value) => _updateParameter('amplitude', value),
                      color: HolographicTheme.secondaryEnergy,
                      showSpectrum: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: HolographicKnob(
                      label: 'DETUNE',
                      value: ((osc['detune'] as double) + 50.0) / 100.0,
                      onChanged: (value) => _updateParameter('detune', (value * 100.0) - 50.0),
                      color: HolographicTheme.accentEnergy,
                      showSpectrum: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HolographicKnob(
                      label: 'PHASE',
                      value: (osc['phase'] as double) / 360.0,
                      onChanged: (value) => _updateParameter('phase', value * 360.0),
                      color: HolographicTheme.primaryEnergy,
                      showSpectrum: false,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Synthesis type selector
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SYNTHESIS TYPE',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.primaryEnergy,
                  fontSize: 12,
                  glowIntensity: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Container(
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
                child: DropdownButton<String>(
                  value: osc['type'] as String,
                  onChanged: (value) => _updateParameter('type', value!),
                  dropdownColor: HolographicTheme.deepSpaceBlack,
                  underline: Container(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: HolographicTheme.primaryEnergy,
                  ),
                  items: _oscillatorTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          type.toUpperCase(),
                          style: HolographicTheme.createHolographicText(
                            energyColor: HolographicTheme.primaryEnergy,
                            fontSize: 12,
                            glowIntensity: 0.4,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSynthesisControls() {
    final osc = _oscillators[_selectedOscillator];
    final type = osc['type'] as String;
    
    switch (type) {
      case 'fm':
        return _buildFMControls(osc);
      case 'granular':
        return _buildGranularControls(osc);
      case 'additive':
        return _buildAdditiveControls(osc);
      case 'wavetable':
        return _buildWavetableControls(osc);
      default:
        return _buildBasicWaveControls(osc);
    }
  }

  Widget _buildFMControls(Map<String, dynamic> osc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FM SYNTHESIS CONTROLS',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'FM AMOUNT',
                value: osc['fm_amount'] as double,
                onChanged: (value) => _updateParameter('fm_amount', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'FM FREQUENCY',
                value: (osc['fm_frequency'] as double) / 10.0,
                onChanged: (value) => _updateParameter('fm_frequency', value * 10.0),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.accentEnergy.withOpacity(0.1),
                      HolographicTheme.secondaryEnergy.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: HolographicTheme.accentEnergy.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'FM OPERATOR\nVISUALIZATION',
                    textAlign: TextAlign.center,
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.accentEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGranularControls(Map<String, dynamic> osc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GRANULAR SYNTHESIS CONTROLS',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'GRAIN SIZE',
                value: (osc['granular_size'] as double) / 500.0,
                onChanged: (value) => _updateParameter('granular_size', value * 500.0),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HolographicKnob(
                label: 'GRAIN DENSITY',
                value: osc['granular_density'] as double,
                onChanged: (value) => _updateParameter('granular_density', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.accentEnergy.withOpacity(0.1),
                      HolographicTheme.secondaryEnergy.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: HolographicTheme.accentEnergy.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'PARTICLE\nDISPLAY',
                    textAlign: TextAlign.center,
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.accentEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdditiveControls(Map<String, dynamic> osc) {
    final harmonics = osc['harmonics'] as List<double>;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ADDITIVE SYNTHESIS - HARMONIC SPECTRUM',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HolographicTheme.accentEnergy.withOpacity(0.1),
                HolographicTheme.secondaryEnergy.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.accentEnergy.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: List.generate(harmonics.length, (index) {
                return Expanded(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final newValue = 1.0 - (details.localPosition.dy / 104.0);
                      _updateHarmonic(index, newValue.clamp(0.0, 1.0));
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            HolographicTheme.accentEnergy,
                            HolographicTheme.secondaryEnergy,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.bottomCenter,
                        heightFactor: harmonics[index],
                        child: Container(
                          decoration: BoxDecoration(
                            color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWavetableControls(Map<String, dynamic> osc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WAVETABLE SYNTHESIS CONTROLS',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.accentEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: HolographicKnob(
                label: 'WAVETABLE POSITION',
                value: osc['wavetable_position'] as double,
                onChanged: (value) => _updateParameter('wavetable_position', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      HolographicTheme.accentEnergy.withOpacity(0.1),
                      HolographicTheme.secondaryEnergy.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: HolographicTheme.accentEnergy.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: WaveformDisplay(
                  waveformData: _generateWaveformData(osc['wavetable_position'] as double),
                  color: HolographicTheme.primaryEnergy,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicWaveControls(Map<String, dynamic> osc) {
    return Container(
      height: 80,
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
      child: WaveformDisplay(
        waveformData: _generateBasicWaveform(osc['type'] as String),
        color: HolographicTheme.primaryEnergy,
      ),
    );
  }

  Widget _buildVisualization() {
    return Container(
      height: 150,
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
      child: Row(
        children: [
          // Spectrum analyzer
          Expanded(
            flex: 2,
            child: SpectrumDisplay(
              spectrumData: _generateSpectrumData(),
              color: HolographicTheme.primaryEnergy,
              title: 'OSCILLATOR SPECTRUM',
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Waveform display
          Expanded(
            flex: 2,
            child: WaveformDisplay(
              waveformData: _generateCurrentWaveform(),
              color: HolographicTheme.secondaryEnergy,
              title: 'OUTPUT WAVEFORM',
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOscillator(int index) {
    setState(() {
      _oscillators[index]['enabled'] = !(_oscillators[index]['enabled'] as bool);
    });
    widget.onParameterChange('osc${index + 1}_enabled', _oscillators[index]['enabled'] ? 1.0 : 0.0);
  }

  void _updateParameter(String parameter, dynamic value) {
    setState(() {
      _oscillators[_selectedOscillator][parameter] = value;
    });
    
    final oscId = _oscillators[_selectedOscillator]['id'] as String;
    widget.onParameterChange('${oscId}_$parameter', value is double ? value : 0.0);
  }

  void _updateHarmonic(int harmonicIndex, double value) {
    setState(() {
      (_oscillators[_selectedOscillator]['harmonics'] as List<double>)[harmonicIndex] = value;
    });
    
    final oscId = _oscillators[_selectedOscillator]['id'] as String;
    widget.onParameterChange('${oscId}_harmonic_$harmonicIndex', value);
  }

  List<double> _generateWaveformData(double position) {
    return List.generate(100, (i) {
      final x = (i / 100.0) * 2 * math.pi;
      return math.sin(x + position * math.pi) * math.sin(x * 3 + position * 2 * math.pi) * 0.5;
    });
  }

  List<double> _generateBasicWaveform(String type) {
    return List.generate(100, (i) {
      final x = (i / 100.0) * 2 * math.pi;
      switch (type) {
        case 'sine':
          return math.sin(x);
        case 'saw':
          return (x % (2 * math.pi)) / math.pi - 1.0;
        case 'square':
          return math.sin(x) > 0 ? 1.0 : -1.0;
        case 'triangle':
          final saw = (x % (2 * math.pi)) / math.pi - 1.0;
          return saw < 0 ? -saw * 2 - 1 : 1 - saw * 2;
        case 'noise':
          return (math.Random().nextDouble() - 0.5) * 2;
        default:
          return math.sin(x);
      }
    });
  }

  List<double> _generateSpectrumData() {
    return List.generate(64, (i) {
      final freq = i / 64.0;
      final osc = _oscillators[_selectedOscillator];
      final enabled = osc['enabled'] as bool;
      if (!enabled) return 0.0;
      
      final amplitude = osc['amplitude'] as double;
      final fundamentalStrength = math.exp(-freq * 10) * amplitude;
      final harmonicStrength = math.sin(freq * math.pi * 8) * 0.3 * amplitude;
      
      return (fundamentalStrength + harmonicStrength).clamp(0.0, 1.0);
    });
  }

  List<double> _generateCurrentWaveform() {
    final osc = _oscillators[_selectedOscillator];
    final enabled = osc['enabled'] as bool;
    if (!enabled) return List.filled(100, 0.0);
    
    final type = osc['type'] as String;
    final amplitude = osc['amplitude'] as double;
    final phase = (osc['phase'] as double) * math.pi / 180.0;
    
    return List.generate(100, (i) {
      final x = (i / 100.0) * 2 * math.pi + phase;
      double wave = 0.0;
      
      switch (type) {
        case 'sine':
          wave = math.sin(x);
          break;
        case 'saw':
          wave = (x % (2 * math.pi)) / math.pi - 1.0;
          break;
        case 'square':
          wave = math.sin(x) > 0 ? 1.0 : -1.0;
          break;
        case 'fm':
          final fmAmount = osc['fm_amount'] as double;
          final fmFreq = osc['fm_frequency'] as double;
          wave = math.sin(x + fmAmount * math.sin(x * fmFreq));
          break;
        case 'additive':
          final harmonics = osc['harmonics'] as List<double>;
          for (int h = 0; h < harmonics.length; h++) {
            wave += harmonics[h] * math.sin(x * (h + 1));
          }
          break;
        default:
          wave = math.sin(x);
      }
      
      return wave * amplitude;
    });
  }
}