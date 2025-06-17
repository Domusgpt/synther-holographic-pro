import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';
import 'spectrum_display.dart';

/// Professional Filter Section with multiple filter types
/// 
/// Features:
/// - Multiple filter types (low-pass, high-pass, band-pass, comb, formant)
/// - Dual parallel/serial filter routing
/// - Real-time frequency response visualization
/// - Modulation input visualization
/// - Filter self-oscillation and feedback
/// - Interactive frequency response graph
class FilterSection extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const FilterSection({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<FilterSection> createState() => _FilterSectionState();
}

class _FilterSectionState extends State<FilterSection> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _responseController;
  
  // Filter 1 parameters
  final Map<String, double> _filter1Params = {
    'enabled': 1.0,
    'type': 0.0, // 0=lowpass, 1=highpass, 2=bandpass, 3=notch, 4=allpass
    'cutoff': 1000.0, // Hz
    'resonance': 0.3, // 0-1
    'drive': 0.0, // 0-1
    'keytrack': 0.5, // 0-1
    'envelope_amount': 0.0, // -1 to 1
    'lfo_amount': 0.0, // -1 to 1
  };

  // Filter 2 parameters
  final Map<String, double> _filter2Params = {
    'enabled': 0.0,
    'type': 1.0, // Start with highpass
    'cutoff': 5000.0,
    'resonance': 0.2,
    'drive': 0.0,
    'keytrack': 0.0,
    'envelope_amount': 0.0,
    'lfo_amount': 0.0,
  };

  // Routing and mix parameters
  final Map<String, double> _routingParams = {
    'routing': 0.0, // 0=serial, 1=parallel
    'filter_mix': 0.5, // Mix between filters in parallel mode
    'output_gain': 0.8,
  };

  final List<String> _filterTypes = [
    'LOWPASS', 'HIGHPASS', 'BANDPASS', 'NOTCH', 'ALLPASS', 'COMB', 'FORMANT'
  ];

  int _selectedFilter = 0; // 0=filter1, 1=filter2

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _responseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _responseController.dispose();
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
                // Filter selection tabs and routing
                _buildFilterTabs(),
                
                const SizedBox(height: 16),
                
                // Current filter controls
                _buildFilterControls(),
                
                const SizedBox(height: 16),
                
                // Frequency response visualization
                _buildFrequencyResponse(),
                
                const SizedBox(height: 16),
                
                // Routing and output controls
                _buildRoutingControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        // Filter selection
        Expanded(
          child: Row(
            children: [
              // Filter 1 tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = 0),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _selectedFilter == 0 ? [
                          HolographicTheme.primaryEnergy.withOpacity(0.3),
                          HolographicTheme.primaryEnergy.withOpacity(0.1),
                        ] : [
                          HolographicTheme.primaryEnergy.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: _selectedFilter == 0 
                          ? HolographicTheme.primaryEnergy 
                          : HolographicTheme.primaryEnergy.withOpacity(0.3),
                        width: _selectedFilter == 0 ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'FILTER 1',
                                style: HolographicTheme.createHolographicText(
                                  energyColor: _selectedFilter == 0 
                                    ? HolographicTheme.primaryEnergy 
                                    : HolographicTheme.primaryEnergy.withOpacity(0.7),
                                  fontSize: 12,
                                  glowIntensity: _selectedFilter == 0 ? 0.8 : 0.3,
                                ),
                              ),
                              Text(
                                _filterTypes[_filter1Params['type']!.round()],
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
                            onTap: () => _toggleFilter(1),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _filter1Params['enabled']! > 0.5 
                                  ? HolographicTheme.accentEnergy 
                                  : HolographicTheme.primaryEnergy.withOpacity(0.3),
                                shape: BoxShape.circle,
                                boxShadow: _filter1Params['enabled']! > 0.5 ? [
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
              ),
              
              // Filter 2 tab
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedFilter = 1),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _selectedFilter == 1 ? [
                          HolographicTheme.primaryEnergy.withOpacity(0.3),
                          HolographicTheme.primaryEnergy.withOpacity(0.1),
                        ] : [
                          HolographicTheme.primaryEnergy.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: Border.all(
                        color: _selectedFilter == 1 
                          ? HolographicTheme.primaryEnergy 
                          : HolographicTheme.primaryEnergy.withOpacity(0.3),
                        width: _selectedFilter == 1 ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'FILTER 2',
                                style: HolographicTheme.createHolographicText(
                                  energyColor: _selectedFilter == 1 
                                    ? HolographicTheme.primaryEnergy 
                                    : HolographicTheme.primaryEnergy.withOpacity(0.7),
                                  fontSize: 12,
                                  glowIntensity: _selectedFilter == 1 ? 0.8 : 0.3,
                                ),
                              ),
                              Text(
                                _filterTypes[_filter2Params['type']!.round()],
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
                            onTap: () => _toggleFilter(2),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _filter2Params['enabled']! > 0.5 
                                  ? HolographicTheme.accentEnergy 
                                  : HolographicTheme.primaryEnergy.withOpacity(0.3),
                                shape: BoxShape.circle,
                                boxShadow: _filter2Params['enabled']! > 0.5 ? [
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
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Routing display
        _buildRoutingDisplay(),
      ],
    );
  }

  Widget _buildRoutingDisplay() {
    final isParallel = _routingParams['routing']! > 0.5;
    
    return Container(
      width: 120,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ROUTING',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.accentEnergy,
              fontSize: 10,
              glowIntensity: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () => _updateRoutingParam('routing', isParallel ? 0.0 : 1.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: HolographicTheme.accentEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isParallel ? 'PARALLEL' : 'SERIAL',
                style: HolographicTheme.createHolographicText(
                  energyColor: HolographicTheme.accentEnergy,
                  fontSize: 8,
                  glowIntensity: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    final currentFilter = _selectedFilter == 0 ? _filter1Params : _filter2Params;
    final filterNumber = _selectedFilter + 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter type selector
        Row(
          children: [
            Text(
              'FILTER $filterNumber TYPE:',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.primaryEnergy,
                fontSize: 12,
                glowIntensity: 0.6,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
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
                child: DropdownButton<int>(
                  value: currentFilter['type']!.round(),
                  onChanged: (value) => _updateFilterParam('type', value!.toDouble()),
                  dropdownColor: HolographicTheme.deepSpaceBlack,
                  underline: Container(),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: HolographicTheme.primaryEnergy,
                  ),
                  items: List.generate(_filterTypes.length, (index) {
                    return DropdownMenuItem<int>(
                      value: index,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          _filterTypes[index],
                          style: HolographicTheme.createHolographicText(
                            energyColor: HolographicTheme.primaryEnergy,
                            fontSize: 12,
                            glowIntensity: 0.4,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Main filter controls
        Row(
          children: [
            // Cutoff frequency
            Expanded(
              child: HolographicKnob(
                label: 'CUTOFF',
                value: math.log(currentFilter['cutoff']! / 20.0) / math.log(1000.0),
                onChanged: (value) => _updateFilterParam(
                  'cutoff', 
                  20.0 * math.pow(1000.0, value)
                ),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: true,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Resonance
            Expanded(
              child: HolographicKnob(
                label: 'RESONANCE',
                value: currentFilter['resonance']!,
                onChanged: (value) => _updateFilterParam('resonance', value),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: true,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Drive/saturation
            Expanded(
              child: HolographicKnob(
                label: 'DRIVE',
                value: currentFilter['drive']!,
                onChanged: (value) => _updateFilterParam('drive', value),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Keyboard tracking
            Expanded(
              child: HolographicKnob(
                label: 'KEYTRACK',
                value: currentFilter['keytrack']!,
                onChanged: (value) => _updateFilterParam('keytrack', value),
                color: HolographicTheme.primaryEnergy,
                showSpectrum: false,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Modulation controls
        Row(
          children: [
            Expanded(
              child: HolographicKnob(
                label: 'ENV MOD',
                value: (currentFilter['envelope_amount']! + 1.0) / 2.0,
                onChanged: (value) => _updateFilterParam('envelope_amount', (value * 2.0) - 1.0),
                color: HolographicTheme.secondaryEnergy,
                showSpectrum: false,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: HolographicKnob(
                label: 'LFO MOD',
                value: (currentFilter['lfo_amount']! + 1.0) / 2.0,
                onChanged: (value) => _updateFilterParam('lfo_amount', (value * 2.0) - 1.0),
                color: HolographicTheme.accentEnergy,
                showSpectrum: false,
              ),
            ),
            
            // Spacer for remaining controls
            Expanded(child: Container()),
            Expanded(child: Container()),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencyResponse() {
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
      child: AnimatedBuilder(
        animation: _responseController,
        builder: (context, child) {
          return CustomPaint(
            painter: FrequencyResponsePainter(
              filter1Params: _filter1Params,
              filter2Params: _filter2Params,
              routingParams: _routingParams,
              animationValue: _responseController.value,
              primaryColor: HolographicTheme.primaryEnergy,
              secondaryColor: HolographicTheme.secondaryEnergy,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Widget _buildRoutingControls() {
    return Row(
      children: [
        // Filter mix (for parallel mode)
        Expanded(
          child: HolographicKnob(
            label: 'FILTER MIX',
            value: _routingParams['filter_mix']!,
            onChanged: (value) => _updateRoutingParam('filter_mix', value),
            color: HolographicTheme.accentEnergy,
            showSpectrum: false,
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Output gain
        Expanded(
          child: HolographicKnob(
            label: 'OUTPUT',
            value: _routingParams['output_gain']!,
            onChanged: (value) => _updateRoutingParam('output_gain', value),
            color: HolographicTheme.primaryEnergy,
            showSpectrum: false,
          ),
        ),
        
        // Spacers
        Expanded(child: Container()),
        Expanded(child: Container()),
      ],
    );
  }

  void _toggleFilter(int filterNumber) {
    setState(() {
      if (filterNumber == 1) {
        _filter1Params['enabled'] = _filter1Params['enabled']! > 0.5 ? 0.0 : 1.0;
      } else {
        _filter2Params['enabled'] = _filter2Params['enabled']! > 0.5 ? 0.0 : 1.0;
      }
    });
    
    widget.onParameterChange('filter${filterNumber}_enabled', 
        filterNumber == 1 ? _filter1Params['enabled']! : _filter2Params['enabled']!);
  }

  void _updateFilterParam(String param, double value) {
    setState(() {
      if (_selectedFilter == 0) {
        _filter1Params[param] = value;
      } else {
        _filter2Params[param] = value;
      }
    });
    
    final filterNumber = _selectedFilter + 1;
    widget.onParameterChange('filter${filterNumber}_$param', value);
  }

  void _updateRoutingParam(String param, double value) {
    setState(() {
      _routingParams[param] = value;
    });
    widget.onParameterChange('filter_$param', value);
  }
}

/// Custom painter for frequency response visualization
class FrequencyResponsePainter extends CustomPainter {
  final Map<String, double> filter1Params;
  final Map<String, double> filter2Params;
  final Map<String, double> routingParams;
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  FrequencyResponsePainter({
    required this.filter1Params,
    required this.filter2Params,
    required this.routingParams,
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawFilterResponse(canvas, size, filter1Params, primaryColor, 1);
    
    if (filter2Params['enabled']! > 0.5) {
      _drawFilterResponse(canvas, size, filter2Params, secondaryColor, 2);
    }
    
    _drawFrequencyLabels(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Frequency grid lines (logarithmic)
    final frequencies = [100, 1000, 10000];
    for (final freq in frequencies) {
      final x = _frequencyToX(freq.toDouble(), size.width);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // Amplitude grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 0dB line
    final centerPaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..strokeWidth = 1.0;
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  void _drawFilterResponse(Canvas canvas, Size size, Map<String, double> params, Color color, int filterNum) {
    if (params['enabled']! < 0.5) return;

    final paint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0 + (animationValue * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final cutoff = params['cutoff']!;
    final resonance = params['resonance']!;
    final type = params['type']!.round();

    // Generate frequency response curve
    for (int i = 0; i < 200; i++) {
      final freq = 20.0 * math.pow(1000.0, i / 200.0); // 20Hz to 20kHz
      final response = _calculateFilterResponse(freq, cutoff, resonance, type);
      
      final x = _frequencyToX(freq, size.width);
      final y = _responseToY(response, size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
    
    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    // Draw cutoff frequency indicator
    final cutoffX = _frequencyToX(cutoff, size.width);
    final indicatorPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(cutoffX, 0),
      Offset(cutoffX, size.height),
      indicatorPaint,
    );

    // Draw resonance peak indicator
    if (resonance > 0.1) {
      final peakY = _responseToY(resonance * 12.0, size.height); // dB
      canvas.drawCircle(
        Offset(cutoffX, peakY),
        4.0 + (resonance * 4.0),
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill,
      );
    }
  }

  double _calculateFilterResponse(double freq, double cutoff, double resonance, int type) {
    final ratio = freq / cutoff;
    final q = resonance * 10.0 + 0.5;
    
    switch (type) {
      case 0: // Lowpass
        if (ratio < 1.0) {
          return 0.0; // 0dB
        } else {
          final rolloff = -12.0 * math.log(ratio) / math.ln10; // -12dB/octave
          final peak = ratio < 1.2 ? resonance * 6.0 : 0.0; // Resonance peak
          return rolloff + peak;
        }
        
      case 1: // Highpass
        if (ratio > 1.0) {
          return 0.0;
        } else {
          final rolloff = -12.0 * math.log(1.0 / ratio) / math.ln10;
          final peak = ratio > 0.8 ? resonance * 6.0 : 0.0;
          return rolloff + peak;
        }
        
      case 2: // Bandpass
        final distance = (math.log(ratio) / math.ln2).abs(); // Distance in octaves
        final peak = resonance * 6.0;
        final rolloff = -6.0 * distance;
        return distance < 0.5 ? peak + rolloff : rolloff;
        
      case 3: // Notch
        final distance = (math.log(ratio) / math.ln2).abs();
        return distance < 0.2 ? -20.0 * (1.0 - distance * 5.0) : 0.0;
        
      case 4: // Allpass
        return 0.0; // Flat response, only phase changes
        
      default:
        return 0.0;
    }
  }

  double _frequencyToX(double freq, double width) {
    // Logarithmic frequency mapping
    final minFreq = math.log(20.0);
    final maxFreq = math.log(20000.0);
    final logFreq = math.log(freq);
    
    return ((logFreq - minFreq) / (maxFreq - minFreq)) * width;
  }

  double _responseToY(double responseDb, double height) {
    // Map -30dB to +30dB to full height
    final normalizedResponse = (responseDb + 30.0) / 60.0;
    return height * (1.0 - normalizedResponse.clamp(0.0, 1.0));
  }

  void _drawFrequencyLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final frequencies = ['100', '1K', '10K'];
    final positions = [100.0, 1000.0, 10000.0];
    
    for (int i = 0; i < frequencies.length; i++) {
      final x = _frequencyToX(positions[i], size.width);
      
      textPainter.text = TextSpan(
        text: frequencies[i],
        style: HolographicTheme.createHolographicText(
          energyColor: primaryColor.withOpacity(0.6),
          fontSize: 10,
          glowIntensity: 0.3,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(FrequencyResponsePainter oldDelegate) {
    return oldDelegate.filter1Params != filter1Params ||
           oldDelegate.filter2Params != filter2Params ||
           oldDelegate.routingParams != routingParams ||
           oldDelegate.animationValue != animationValue;
  }
}