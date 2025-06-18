import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';
import 'waveform_display.dart';

/// Professional LFO Section with multiple low-frequency oscillators
/// 
/// Features:
/// - Multiple independent LFO generators
/// - Various waveform types (sine, triangle, square, saw, noise, sample & hold)
/// - Tempo sync with host/internal clock
/// - Phase relationships and synchronization
/// - Real-time waveform visualization
/// - Modulation amount and destination routing
/// - One-shot and loop modes
class LFOSection extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const LFOSection({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<LFOSection> createState() => _LFOSectionState();
}

class _LFOSectionState extends State<LFOSection> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _lfo1Controller;
  late AnimationController _lfo2Controller;
  late AnimationController _lfo3Controller;
  
  // LFO generators
  final List<Map<String, double>> _lfos = [
    {
      'enabled': 1.0,
      'waveform': 0.0, // 0=sine, 1=triangle, 2=square, 3=saw, 4=noise, 5=s&h
      'frequency': 2.0, // Hz (0.01 - 100 Hz)
      'phase': 0.0, // 0-360 degrees
      'amplitude': 0.8, // 0-1
      'offset': 0.0, // -1 to 1
      'sync': 0.0, // 0=free, 1=tempo sync
      'sync_rate': 4.0, // Note divisions (1/16 to 4 bars)
      'retrigger': 1.0, // Retrigger on note on
      'one_shot': 0.0, // One shot mode
    },
    {
      'enabled': 1.0,
      'waveform': 1.0, // Triangle
      'frequency': 0.5,
      'phase': 90.0, // 90 degrees out of phase with LFO1
      'amplitude': 0.6,
      'offset': 0.0,
      'sync': 0.0,
      'sync_rate': 8.0,
      'retrigger': 0.0,
      'one_shot': 0.0,
    },
    {
      'enabled': 0.0,
      'waveform': 5.0, // Sample & hold
      'frequency': 8.0,
      'phase': 0.0,
      'amplitude': 1.0,
      'offset': 0.0,
      'sync': 1.0,
      'sync_rate': 16.0,
      'retrigger': 1.0,
      'one_shot': 0.0,
    },
  ];

  final List<String> _lfoNames = ['LFO 1', 'LFO 2', 'LFO 3'];
  final List<Color> _lfoColors = [
    HolographicTheme.primaryEnergy,
    HolographicTheme.secondaryEnergy,
    HolographicTheme.accentEnergy,
  ];

  final List<String> _waveformNames = [
    'SINE', 'TRIANGLE', 'SQUARE', 'SAW', 'NOISE', 'S&H'
  ];

  final List<String> _syncRates = [
    '1/32', '1/16', '1/8', '1/4', '1/2', '1', '2', '4'
  ];

  int _selectedLFO = 0;
  double _tempoSync = 120.0; // BPM for sync calculations

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    // Initialize LFO animation controllers with different frequencies
    _lfo1Controller = AnimationController(
      duration: Duration(milliseconds: (1000 / _lfos[0]['frequency']!).round()),
      vsync: this,
    )..repeat();
    
    _lfo2Controller = AnimationController(
      duration: Duration(milliseconds: (1000 / _lfos[1]['frequency']!).round()),
      vsync: this,
    )..repeat();
    
    _lfo3Controller = AnimationController(
      duration: Duration(milliseconds: (1000 / _lfos[2]['frequency']!).round()),
      vsync: this,
    )..repeat();
    
    // Start with phase offsets
    _lfo2Controller.animateTo(_lfos[1]['phase']! / 360.0);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lfo1Controller.dispose();
    _lfo2Controller.dispose();
    _lfo3Controller.dispose();
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LFO selection tabs
                _buildLFOTabs(),
                
                const SizedBox(height: 16),
                
                // LFO waveform visualization
                _buildLFOVisualizer(),
                
                const SizedBox(height: 16),
                
                // Main LFO controls
                _buildLFOControls(),
                
                const SizedBox(height: 12),
                
                // Sync and phase controls
                _buildSyncControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLFOTabs() {
    return Row(
      children: [
        // LFO selection tabs
        Flexible(
          fit: FlexFit.loose,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_lfos.length, (index) {
              final isSelected = index == _selectedLFO;
              final isEnabled = _lfos[index]['enabled']! > 0.5;
              final lfoColor = _lfoColors[index];
              
              return Flexible(
                fit: FlexFit.loose,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLFO = index),
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isSelected ? [
                          lfoColor.withOpacity(0.3),
                          lfoColor.withOpacity(0.1),
                        ] : [
                          lfoColor.withOpacity(isEnabled ? 0.15 : 0.05),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                          ? lfoColor 
                          : lfoColor.withOpacity(isEnabled ? 0.5 : 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _lfoNames[index],
                                style: HolographicTheme.createHolographicText(
                                  energyColor: isSelected 
                                    ? lfoColor 
                                    : lfoColor.withOpacity(isEnabled ? 1.0 : 0.7),
                                  fontSize: 11,
                                  glowIntensity: isSelected ? 0.8 : (isEnabled ? 0.5 : 0.3),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _waveformNames[_lfos[index]['waveform']!.round()],
                                style: HolographicTheme.createHolographicText(
                                  energyColor: HolographicTheme.secondaryEnergy.withOpacity(0.6),
                                  fontSize: 8,
                                  glowIntensity: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Enable/disable toggle
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _toggleLFO(index),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isEnabled 
                                  ? HolographicTheme.accentEnergy 
                                  : lfoColor.withOpacity(0.3),
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
                        
                        // Sync indicator
                        if (_lfos[index]['sync']! > 0.5)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: HolographicTheme.accentEnergy,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Global sync tempo display
        Container(
          width: 80,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HolographicTheme.accentEnergy.withOpacity(0.1),
                HolographicTheme.accentEnergy.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.accentEnergy.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TEMPO',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.accentEnergy,
                  fontSize: 8,
                  glowIntensity: 0.4,
                ),
              ),
              Text(
                '${_tempoSync.round()} BPM',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.accentEnergy,
                  fontSize: 12,
                  glowIntensity: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLFOVisualizer() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolographicTheme.deepSpaceBlack.withOpacity(0.9),
            _lfoColors[_selectedLFO].withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _lfoColors[_selectedLFO].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_lfo1Controller, _lfo2Controller, _lfo3Controller]),
        builder: (context, child) {
          return WaveformDisplay(
            waveformData: _generateLFOWaveform(),
            color: _lfoColors[_selectedLFO],
            title: '${_lfoNames[_selectedLFO]} WAVEFORM',
            showGrid: true,
            showTrigger: false,
          );
        },
      ),
    );
  }

  Widget _buildLFOControls() {
    final currentLFO = _lfos[_selectedLFO];
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: Waveform, Frequency, Amplitude
        Row(
          children: [
            // Waveform selector
            Flexible(
              fit: FlexFit.loose,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAVEFORM',
                    style: HolographicTheme.createHolographicText(
                      energyColor: _lfoColors[_selectedLFO],
                      fontSize: 10,
                      glowIntensity: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _lfoColors[_selectedLFO].withOpacity(0.1),
                          _lfoColors[_selectedLFO].withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _lfoColors[_selectedLFO].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: DropdownButton<int>(
                      value: currentLFO['waveform']!.round(),
                      onChanged: (value) => _updateLFOParam('waveform', value!.toDouble()),
                      dropdownColor: HolographicTheme.deepSpaceBlack,
                      underline: Container(),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: _lfoColors[_selectedLFO],
                      ),
                      items: List.generate(_waveformNames.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              _waveformNames[index],
                              style: HolographicTheme.createHolographicText(
                                energyColor: _lfoColors[_selectedLFO],
                                fontSize: 12,
                                glowIntensity: 0.4,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Frequency
            Flexible(
              fit: FlexFit.loose,
              child: HolographicKnob(
                label: 'FREQUENCY',
                value: math.log(currentLFO['frequency']! * 100 + 1) / math.log(10001),
                onChanged: (value) => _updateLFOParam(
                  'frequency', 
                  (math.pow(10001, value) - 1) / 100
                ),
                color: _lfoColors[_selectedLFO],
                showSpectrum: true,
                size: 70,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Amplitude
            Flexible(
              fit: FlexFit.loose,
              child: HolographicKnob(
                label: 'AMPLITUDE',
                value: currentLFO['amplitude']!,
                onChanged: (value) => _updateLFOParam('amplitude', value),
                color: _lfoColors[_selectedLFO],
                showSpectrum: false,
                size: 70,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Bottom row: Phase, Offset
        Row(
          children: [
            // Phase
            Flexible(
              fit: FlexFit.loose,
              child: HolographicKnob(
                label: 'PHASE',
                value: currentLFO['phase']! / 360.0,
                onChanged: (value) => _updateLFOParam('phase', value * 360.0),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
                size: 60,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Offset
            Flexible(
              fit: FlexFit.loose,
              child: HolographicKnob(
                label: 'OFFSET',
                value: (currentLFO['offset']! + 1.0) / 2.0,
                onChanged: (value) => _updateLFOParam('offset', (value * 2.0) - 1.0),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
                size: 60,
              ),
            ),
            
            // Spacers
            Flexible(fit: FlexFit.loose, child: Container()),
            Flexible(fit: FlexFit.loose, child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncControls() {
    final currentLFO = _lfos[_selectedLFO];
    final isSync = currentLFO['sync']! > 0.5;
    
    return Row(
      children: [
        // Sync toggle
        GestureDetector(
          onTap: () => _updateLFOParam('sync', isSync ? 0.0 : 1.0),
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HolographicTheme.accentEnergy.withOpacity(isSync ? 0.3 : 0.1),
                  HolographicTheme.accentEnergy.withOpacity(isSync ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: HolographicTheme.accentEnergy.withOpacity(isSync ? 0.8 : 0.3),
                width: isSync ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'SYNC',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.accentEnergy,
                  fontSize: 12,
                  glowIntensity: isSync ? 0.8 : 0.4,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Sync rate (only visible when sync is on)
        if (isSync) ...[
          Flexible(
            fit: FlexFit.loose,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SYNC RATE',
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.accentEnergy,
                    fontSize: 10,
                    glowIntensity: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        HolographicTheme.accentEnergy.withOpacity(0.1),
                        HolographicTheme.accentEnergy.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HolographicTheme.accentEnergy.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButton<int>(
                    value: currentLFO['sync_rate']!.round(),
                    onChanged: (value) => _updateLFOParam('sync_rate', value!.toDouble()),
                    dropdownColor: HolographicTheme.deepSpaceBlack,
                    underline: Container(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: HolographicTheme.accentEnergy,
                    ),
                    items: List.generate(_syncRates.length, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            _syncRates[index],
                            style: HolographicTheme.createHolographicText(
                              energyColor: HolographicTheme.accentEnergy,
                              fontSize: 12,
                              glowIntensity: 0.4,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(width: 12),
        
        // Retrigger toggle
        GestureDetector(
          onTap: () => _updateLFOParam('retrigger', currentLFO['retrigger']! > 0.5 ? 0.0 : 1.0),
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _lfoColors[_selectedLFO].withOpacity(currentLFO['retrigger']! > 0.5 ? 0.3 : 0.1),
                  _lfoColors[_selectedLFO].withOpacity(currentLFO['retrigger']! > 0.5 ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _lfoColors[_selectedLFO].withOpacity(currentLFO['retrigger']! > 0.5 ? 0.8 : 0.3),
                width: currentLFO['retrigger']! > 0.5 ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'RETRIG',
                style: HolographicTheme.createHolographicText(
                  energyColor: _lfoColors[_selectedLFO],
                  fontSize: 10,
                  glowIntensity: currentLFO['retrigger']! > 0.5 ? 0.8 : 0.4,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // One shot toggle
        GestureDetector(
          onTap: () => _updateLFOParam('one_shot', currentLFO['one_shot']! > 0.5 ? 0.0 : 1.0),
          child: Container(
            width: 80,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HolographicTheme.secondaryEnergy.withOpacity(currentLFO['one_shot']! > 0.5 ? 0.3 : 0.1),
                  HolographicTheme.secondaryEnergy.withOpacity(currentLFO['one_shot']! > 0.5 ? 0.1 : 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: HolographicTheme.secondaryEnergy.withOpacity(currentLFO['one_shot']! > 0.5 ? 0.8 : 0.3),
                width: currentLFO['one_shot']! > 0.5 ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                'ONE SHOT',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.secondaryEnergy,
                  fontSize: 9,
                  glowIntensity: currentLFO['one_shot']! > 0.5 ? 0.8 : 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<double> _generateLFOWaveform() {
    final currentLFO = _lfos[_selectedLFO];
    final waveform = currentLFO['waveform']!.round();
    final amplitude = currentLFO['amplitude']!;
    final offset = currentLFO['offset']!;
    final phase = (currentLFO['phase']! / 360.0) * 2 * math.pi;
    
    // Get current animation value based on selected LFO
    late AnimationController controller;
    switch (_selectedLFO) {
      case 0:
        controller = _lfo1Controller;
        break;
      case 1:
        controller = _lfo2Controller;
        break;
      case 2:
        controller = _lfo3Controller;
        break;
    }
    
    final animationPhase = controller.value * 2 * math.pi;
    
    return List.generate(100, (i) {
      final x = (i / 100.0) * 2 * math.pi + phase;
      double value = 0.0;
      
      switch (waveform) {
        case 0: // Sine
          value = math.sin(x);
          break;
        case 1: // Triangle
          value = (2.0 / math.pi) * math.asin(math.sin(x));
          break;
        case 2: // Square
          value = math.sin(x) > 0 ? 1.0 : -1.0;
          break;
        case 3: // Saw
          value = (x % (2 * math.pi)) / math.pi - 1.0;
          break;
        case 4: // Noise
          value = (math.Random().nextDouble() - 0.5) * 2;
          break;
        case 5: // Sample & Hold
          final step = ((x / (math.pi / 4)).floor());
          value = (math.sin(step) > 0 ? 1.0 : -1.0) * (0.5 + math.Random().nextDouble() * 0.5);
          break;
      }
      
      return (value * amplitude + offset).clamp(-1.0, 1.0);
    });
  }

  void _toggleLFO(int lfoIndex) {
    setState(() {
      _lfos[lfoIndex]['enabled'] = _lfos[lfoIndex]['enabled']! > 0.5 ? 0.0 : 1.0;
    });
    
    widget.onParameterChange('lfo_${lfoIndex}_enabled', _lfos[lfoIndex]['enabled']!);
  }

  void _updateLFOParam(String param, double value) {
    setState(() {
      _lfos[_selectedLFO][param] = value;
    });
    
    // Update animation controller frequency if frequency changed
    if (param == 'frequency') {
      final newDuration = Duration(milliseconds: (1000 / value).round().clamp(50, 10000));
      switch (_selectedLFO) {
        case 0:
          _lfo1Controller.duration = newDuration;
          break;
        case 1:
          _lfo2Controller.duration = newDuration;
          break;
        case 2:
          _lfo3Controller.duration = newDuration;
          break;
      }
    }
    
    widget.onParameterChange('lfo_${_selectedLFO}_$param', value);
  }
}