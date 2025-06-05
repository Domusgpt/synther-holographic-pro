import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as Math;
import 'core/synth_parameters.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';

/// Simple holographic interface that works immediately
class SimpleHolographicInterface extends StatefulWidget {
  const SimpleHolographicInterface({Key? key}) : super(key: key);
  
  @override
  State<SimpleHolographicInterface> createState() => _SimpleHolographicInterfaceState();
}

class _SimpleHolographicInterfaceState extends State<SimpleHolographicInterface> {
  double _xyX = 0.5;
  double _xyY = 0.5;
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Holographic',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Pure HyperAV visualizer background - NO OVERLAY!
            Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0, // Pure visualizer, no filters!
                showControls: false,
              ),
            ),
            
            // Floating holographic title
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF00FF), // Magenta energy
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF00FF).withOpacity(0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  'SYNTHER HOLOGRAPHIC',
                  style: TextStyle(
                    color: const Color(0xFFFF00FF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF00FF),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Holographic XY Pad
            Positioned(
              left: 50,
              top: 100,
              child: _buildHolographicXYPad(),
            ),
            
            // Holographic keyboard
            Positioned(
              left: 50,
              bottom: 50,
              right: 50,
              child: _buildHolographicKeyboard(),
            ),
            
            // Parameter controls
            Positioned(
              right: 50,
              top: 100,
              child: _buildParameterControls(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHolographicXYPad() {
    return Container(
      width: 300,
      height: 250,
      decoration: BoxDecoration(
        // Transparent center - shows visualizer
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00FFFF), // Cyan energy
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'XY PAD',
              style: TextStyle(
                color: const Color(0xFF00FFFF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00FFFF),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          
          // XY area
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final size = box.size;
                
                setState(() {
                  _xyX = (localPosition.dx / size.width).clamp(0.0, 1.0);
                  _xyY = (localPosition.dy / size.height).clamp(0.0, 1.0);
                });
                
                // Update synth parameters
                final synth = Provider.of<SynthParametersModel>(context, listen: false);
                synth.setFilterCutoff(20 + _xyX * 19980);
                synth.setFilterResonance(_xyY);
              },
              child: Stack(
                children: [
                  // Touch point
                  Positioned(
                    left: _xyX * 280 - 10,
                    top: _xyY * 180 - 10,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FFFF).withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FFFF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00FFFF),
                            blurRadius: 12,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHolographicKeyboard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFFF00), // Yellow energy
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFFF00).withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'KEYBOARD',
              style: TextStyle(
                color: const Color(0xFFFFFF00),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: const Color(0xFFFFFF00),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          
          // Keys
          Expanded(
            child: Row(
              children: List.generate(12, (index) {
                final isBlackKey = [1, 3, 6, 8, 10].contains(index % 12);
                final note = 60 + index; // C4 to B4
                
                if (isBlackKey) return const SizedBox();
                
                return Expanded(
                  child: GestureDetector(
                    onTapDown: (_) {
                      final synth = Provider.of<SynthParametersModel>(context, listen: false);
                      synth.noteOn(note, 100);
                    },
                    onTapUp: (_) {
                      final synth = Provider.of<SynthParametersModel>(context, listen: false);
                      synth.noteOff(note);
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: const Color(0xFFFFFF00).withOpacity(0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFFF00).withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          ['C', 'D', 'E', 'F', 'G', 'A', 'B'][index ~/ 2],
                          style: TextStyle(
                            color: const Color(0xFFFFFF00),
                            fontSize: 10,
                            shadows: [
                              Shadow(
                                color: const Color(0xFFFFFF00),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParameterControls() {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF0080), // Hot pink energy
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0080).withOpacity(0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Consumer<SynthParametersModel>(
        builder: (context, synth, child) {
          return Column(
            children: [
              // Title
              Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'PARAMETERS',
                  style: TextStyle(
                    color: const Color(0xFFFF0080),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFF0080),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Controls
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Filter Cutoff
                      _buildHolographicSlider(
                        'CUTOFF',
                        synth.filterCutoff / 20000,
                        (value) => synth.setFilterCutoff(value * 20000),
                        const Color(0xFFFF0080),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Filter Resonance
                      _buildHolographicSlider(
                        'RESONANCE',
                        synth.filterResonance,
                        (value) => synth.setFilterResonance(value),
                        const Color(0xFFFF0080),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Master Volume
                      _buildHolographicSlider(
                        'VOLUME',
                        synth.masterVolume,
                        (value) => synth.setMasterVolume(value),
                        const Color(0xFFFF0080),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildHolographicSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color energyColor,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: energyColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: energyColor,
                blurRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: energyColor,
            inactiveTrackColor: energyColor.withOpacity(0.3),
            thumbColor: energyColor,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            color: energyColor.withOpacity(0.8),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}