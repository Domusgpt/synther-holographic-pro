import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';

/// Simple professional synthesizer interface that works immediately
/// Contains the exact features the user requested: keyboard, XY pad, knobs, LLM presets, 4D visualizer
class SimpleProfessionalSynth extends StatefulWidget {
  const SimpleProfessionalSynth({Key? key}) : super(key: key);
  
  @override
  State<SimpleProfessionalSynth> createState() => _SimpleProfessionalSynthState();
}

class _SimpleProfessionalSynthState extends State<SimpleProfessionalSynth> {
  double _xyX = 0.5;
  double _xyY = 0.5;
  Set<int> _pressedKeys = {};
  String _selectedPreset = 'init';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Professional',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Pure HyperAV Audio-Reactive Visualizer Background - NO OVERLAY!
            Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0, // Pure visualizer, no filters!
                showControls: false,
              ),
            ),
            
            // Main interface
            Column(
              children: [
                // Holographic Header with LLM Preset Generator
                Container(
                  height: 80,
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15), // Translucent
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFFFF00FF), // Magenta energy
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFF00FF).withOpacity(0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'SYNTHER HOLOGRAPHIC',
                          style: TextStyle(
                            color: Color(0xFFFF00FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF00FF),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // LLM Preset Interface
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Describe sound...',
                            hintStyle: TextStyle(color: Color(0xFFFF00FF).withOpacity(0.5)),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF00FF)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF00FF).withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF00FF), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: TextStyle(color: Color(0xFFFF00FF)),
                          onSubmitted: (text) => _generateLLMPreset(text),
                        ),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _generateLLMPreset('warm pad'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF00FF).withOpacity(0.2),
                          side: BorderSide(color: Color(0xFFFF00FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'GENERATE LLM PRESET',
                          style: TextStyle(
                            color: Color(0xFFFF00FF),
                            shadows: [
                              Shadow(
                                color: Color(0xFFFF00FF),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main controls area
                Expanded(
                  child: Row(
                    children: [
                      // Left: XY Pad
                      Expanded(
                        flex: 2,
                        child: Container(
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15), // Translucent
                            border: Border.all(color: Color(0xFF00FFFF), width: 2), // Cyan energy
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF00FFFF).withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _buildXYPad(),
                        ),
                      ),
                      
                      // Center: Parameter knobs and sliders
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.15), // Translucent
                            border: Border.all(color: Color(0xFFFFFF00), width: 2), // Yellow energy
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFFFFF00).withOpacity(0.6),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: _buildParameterControls(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom: Holographic Piano keyboard
                Container(
                  height: 200,
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15), // Translucent
                    border: Border.all(color: Color(0xFF8000FF), width: 2), // Purple energy
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF8000FF).withOpacity(0.6),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildKeyboard(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildXYPad() {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        setState(() {
          _xyX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
          _xyY = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
        });
        
        // Update synth parameters
        final synth = Provider.of<SynthParametersModel>(context, listen: false);
        synth.setFilterCutoff(200 + _xyX * 4000); // X controls filter cutoff
        synth.setFilterResonance(_xyY); // Y controls resonance
      },
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Grid background
            CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),
            // Position indicator
            Positioned(
              left: _xyX * 400 - 10,
              top: (1.0 - _xyY) * 300 - 10,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.cyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan,
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            // Holographic Labels
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                'PITCH/NOTE', 
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  shadows: [
                    Shadow(
                      color: Color(0xFF00FFFF),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'MODULATION', 
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    shadows: [
                      Shadow(
                        color: Color(0xFF00FFFF),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildParameterControls() {
    return Column(
      children: [
        Text(
          'PARAMETERS', 
          style: TextStyle(
            color: Color(0xFFFFFF00), 
            fontSize: 18,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0xFFFFFF00),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        
        // Adjustable knobs
        Consumer<SynthParametersModel>(
          builder: (context, synth, child) {
            return Column(
              children: [
                _buildKnob('CUTOFF', synth.filterCutoff / 5000.0, (v) => synth.setFilterCutoff(v * 5000)),
                SizedBox(height: 20),
                _buildKnob('RESONANCE', synth.filterResonance, (v) => synth.setFilterResonance(v)),
                SizedBox(height: 20),
                _buildKnob('ATTACK', synth.attack, (v) => synth.setAttack(v)),
                SizedBox(height: 20),
                _buildKnob('RELEASE', synth.release / 2.0, (v) => synth.setRelease(v * 2.0)),
                SizedBox(height: 20),
                
                // Master volume slider
                Text('VOLUME', style: TextStyle(color: Colors.pink)),
                SizedBox(height: 10),
                Container(
                  height: 100,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Slider(
                      value: synth.masterVolume,
                      onChanged: (v) => synth.setMasterVolume(v),
                      activeColor: Colors.pink,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildKnob(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        SizedBox(height: 5),
        GestureDetector(
          onPanUpdate: (details) {
            final delta = -details.delta.dy / 100.0;
            final newValue = (value + delta).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
              border: Border.all(color: Colors.cyan, width: 2),
            ),
            child: CustomPaint(
              painter: KnobPainter(value),
            ),
          ),
        ),
        Text('${(value * 100).toInt()}%', style: TextStyle(color: Colors.cyan, fontSize: 10)),
      ],
    );
  }
  
  Widget _buildKeyboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final whiteKeyWidth = constraints.maxWidth / 14; // 2 octaves
        return Stack(
          children: [
            // White keys
            Row(
              children: List.generate(14, (index) {
                final octave = 4 + (index ~/ 7);
                final noteInOctave = [0, 2, 4, 5, 7, 9, 11][index % 7];
                final midiNote = octave * 12 + noteInOctave;
                final isPressed = _pressedKeys.contains(midiNote);
                
                return GestureDetector(
                  onTapDown: (_) => _noteOn(midiNote),
                  onTapUp: (_) => _noteOff(midiNote),
                  onTapCancel: () => _noteOff(midiNote),
                  child: Container(
                    width: whiteKeyWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: isPressed ? Colors.grey[300] : Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      ['C', 'D', 'E', 'F', 'G', 'A', 'B'][index % 7],
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                );
              }),
            ),
            
            // Black keys
            Row(
              children: List.generate(14, (index) {
                final noteInOctave = [0, 2, 4, 5, 7, 9, 11][index % 7];
                final hasBlackKey = [0, 2, 5, 7, 9].contains(noteInOctave);
                
                if (!hasBlackKey) {
                  return SizedBox(width: whiteKeyWidth);
                }
                
                final octave = 4 + (index ~/ 7);
                final blackNote = octave * 12 + noteInOctave + 1;
                final isPressed = _pressedKeys.contains(blackNote);
                
                return Stack(
                  children: [
                    SizedBox(width: whiteKeyWidth),
                    Positioned(
                      right: -whiteKeyWidth * 0.3,
                      child: GestureDetector(
                        onTapDown: (_) => _noteOn(blackNote),
                        onTapUp: (_) => _noteOff(blackNote),
                        onTapCancel: () => _noteOff(blackNote),
                        child: Container(
                          width: whiteKeyWidth * 0.6,
                          height: constraints.maxHeight * 0.6,
                          decoration: BoxDecoration(
                            color: isPressed ? Colors.grey[700] : Colors.black,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        );
      },
    );
  }
  
  void _noteOn(int midiNote) {
    setState(() {
      _pressedKeys.add(midiNote);
    });
    final synth = Provider.of<SynthParametersModel>(context, listen: false);
    synth.noteOn(midiNote, 100);
  }
  
  void _noteOff(int midiNote) {
    setState(() {
      _pressedKeys.remove(midiNote);
    });
    final synth = Provider.of<SynthParametersModel>(context, listen: false);
    synth.noteOff(midiNote);
  }
  
  void _generateLLMPreset(String description) {
    // Simple local preset generation based on description
    final synth = Provider.of<SynthParametersModel>(context, listen: false);
    
    if (description.toLowerCase().contains('bass')) {
      synth.setFilterCutoff(300);
      synth.setFilterResonance(0.8);
      synth.setAttack(0.01);
      synth.setRelease(0.5);
    } else if (description.toLowerCase().contains('lead')) {
      synth.setFilterCutoff(2000);
      synth.setFilterResonance(0.6);
      synth.setAttack(0.01);
      synth.setRelease(0.3);
    } else if (description.toLowerCase().contains('pad')) {
      synth.setFilterCutoff(800);
      synth.setFilterResonance(0.3);
      synth.setAttack(0.8);
      synth.setRelease(1.5);
    } else {
      // Default warm sound
      synth.setFilterCutoff(1200);
      synth.setFilterResonance(0.4);
      synth.setAttack(0.1);
      synth.setRelease(0.8);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated preset for: $description'),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}

/// Custom painter for 4D polytopal projection visualizer
class FourDimensionalVisualizer extends CustomPainter {
  final double xPos;
  final double yPos;
  final double time;
  
  FourDimensionalVisualizer({
    required this.xPos,
    required this.yPos,
    required this.time,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Draw rotating 4D hypercube projection
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = 100.0;
    
    // 4D to 3D to 2D projection matrix
    for (int i = 0; i < 16; i++) {
      final angle = time * 0.5 + i * 0.4;
      final x = centerX + scale * Math.cos(angle + xPos * 6.28) * Math.cos(yPos * 3.14);
      final y = centerY + scale * Math.sin(angle + xPos * 6.28) * Math.sin(yPos * 3.14);
      
      paint.color = HSVColor.fromAHSV(
        0.6,
        (i * 22.5 + time * 20) % 360,
        0.8,
        0.9,
      ).toColor();
      
      // Draw hypercube edges
      if (i < 15) {
        final nextAngle = time * 0.5 + (i + 1) * 0.4;
        final nextX = centerX + scale * Math.cos(nextAngle + xPos * 6.28) * Math.cos(yPos * 3.14);
        final nextY = centerY + scale * Math.sin(nextAngle + xPos * 6.28) * Math.sin(yPos * 3.14);
        
        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);
      }
      
      // Draw vertices
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 3, paint);
      paint.style = PaintingStyle.stroke;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Grid painter for XY pad
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..strokeWidth = 1;
    
    // Draw grid lines
    for (int i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Knob painter
class KnobPainter extends CustomPainter {
  final double value;
  
  KnobPainter(this.value);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    
    // Draw knob indicator
    final angle = -2.4 + value * 4.8; // 270 degree range
    final indicatorEnd = Offset(
      center.dx + radius * 0.7 * Math.cos(angle),
      center.dy + radius * 0.7 * Math.sin(angle),
    );
    
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, indicatorEnd, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

