import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'ui/holographic/holographic_theme.dart';

/// TRUE TRANSPARENT HOLOGRAPHIC INTERFACE
/// Pure visualizer background with ONLY energy borders - NO solid fills
class TrueTransparentSynth extends StatefulWidget {
  const TrueTransparentSynth({Key? key}) : super(key: key);
  
  @override
  State<TrueTransparentSynth> createState() => _TrueTransparentSynthState();
}

class _TrueTransparentSynthState extends State<TrueTransparentSynth> {
  double _xyX = 0.5;
  double _xyY = 0.5;
  Set<int> _pressedKeys = {};

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther True Transparent',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Pure HyperAV Visualizer Background - UNMOLESTED
            Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0,
                showControls: false,
              ),
            ),
            
            // XY Pad - BORDER ONLY, visualizer shows through
            Positioned(
              left: 50,
              top: 100,
              child: _buildTransparentXYPad(),
            ),
            
            // Controls - TRANSPARENT with energy borders
            Positioned(
              right: 50,
              top: 100,
              child: _buildTransparentControls(),
            ),
            
            // Keyboard - TRANSPARENT keys with energy outlines
            Positioned(
              left: 50,
              bottom: 50,
              child: _buildTransparentKeyboard(),
            ),
            
            // AI Preset - TRANSPARENT header
            Positioned(
              top: 20,
              left: 50,
              right: 50,
              child: _buildTransparentPresetBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransparentXYPad() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            // NO BACKGROUND - completely transparent for visualizer
            color: Colors.transparent,
            border: Border.all(
              color: HolographicTheme.primaryEnergy,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              // XY Control Area
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _xyX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                      _xyY = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
                    });
                    model.setXYPad(_xyX, _xyY);
                  },
                  child: CustomPaint(
                    painter: TransparentXYPainter(_xyX, _xyY),
                    size: Size.infinite,
                  ),
                ),
              ),
              // Parameter label
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: HolographicTheme.secondaryEnergy),
                  ),
                  child: Text(
                    'X: Filter | Y: Resonance',
                    style: TextStyle(
                      color: HolographicTheme.secondaryEnergy,
                      fontSize: 10,
                      shadows: [
                        Shadow(
                          color: HolographicTheme.secondaryEnergy,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransparentControls() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Container(
          width: 280,
          height: 400,
          decoration: BoxDecoration(
            // TRANSPARENT background
            color: Colors.transparent,
            border: Border.all(
              color: HolographicTheme.secondaryEnergy,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Title
                Text(
                  'SYNTH CONTROLS',
                  style: TextStyle(
                    color: HolographicTheme.secondaryEnergy,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: HolographicTheme.secondaryEnergy,
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Filter Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEnergyKnob('CUTOFF', model.filterCutoff / 20000, 
                        (value) => model.setFilterCutoff(value * 20000)),
                    _buildEnergyKnob('RESONANCE', model.filterResonance, 
                        (value) => model.setFilterResonance(value)),
                  ],
                ),
                SizedBox(height: 24),
                
                // Envelope Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEnergyKnob('ATTACK', model.attackTime, 
                        (value) => model.setAttackTime(value)),
                    _buildEnergyKnob('RELEASE', model.releaseTime, 
                        (value) => model.setReleaseTime(value)),
                  ],
                ),
                SizedBox(height: 24),
                
                // Effects Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildEnergyKnob('REVERB', model.reverbMix, 
                        (value) => model.setReverbMix(value)),
                    _buildEnergyKnob('VOLUME', model.masterVolume, 
                        (value) => model.setMasterVolume(value)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnergyKnob(String label, double value, Function(double) onChanged) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: HolographicTheme.primaryEnergy,
            fontSize: 10,
            shadows: [
              Shadow(
                color: HolographicTheme.primaryEnergy,
                blurRadius: 4,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onPanUpdate: (details) {
            final newValue = (value - details.delta.dy * 0.01).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // TRANSPARENT center
              color: Colors.transparent,
              border: Border.all(
                color: HolographicTheme.primaryEnergy,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: EnergyKnobPainter(value, HolographicTheme.primaryEnergy),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${(value * 100).round()}%',
          style: TextStyle(
            color: HolographicTheme.primaryEnergy.withOpacity(0.8),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildTransparentKeyboard() {
    final whiteKeys = [0, 2, 4, 5, 7, 9, 11];
    
    return Container(
      width: 600,
      height: 100,
      decoration: BoxDecoration(
        // TRANSPARENT background
        color: Colors.transparent,
        border: Border.all(
          color: HolographicTheme.primaryEnergy,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.primaryEnergy.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: whiteKeys.map((note) {
            final midiNote = 4 * 12 + note; // Octave 4
            final isPressed = _pressedKeys.contains(midiNote);
            
            return Expanded(
              child: GestureDetector(
                onTapDown: (_) => _pressKey(midiNote),
                onTapUp: (_) => _releaseKey(midiNote),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    // TRANSPARENT keys
                    color: isPressed 
                        ? HolographicTheme.primaryEnergy.withOpacity(0.3)
                        : Colors.transparent,
                    border: Border.all(
                      color: isPressed 
                          ? HolographicTheme.primaryEnergy 
                          : HolographicTheme.primaryEnergy.withOpacity(0.6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isPressed 
                        ? [
                            BoxShadow(
                              color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransparentPresetBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        // TRANSPARENT background
        color: Colors.transparent,
        border: Border.all(
          color: HolographicTheme.primaryEnergy,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.primaryEnergy.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              'SYNTHER HOLOGRAPHIC',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: HolographicTheme.primaryEnergy,
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            Spacer(),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Describe sound...',
                  hintStyle: TextStyle(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                style: TextStyle(color: HolographicTheme.primaryEnergy),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement LLM preset generation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: HolographicTheme.primaryEnergy,
                side: BorderSide(color: HolographicTheme.primaryEnergy, width: 2),
                shadowColor: HolographicTheme.primaryEnergy.withOpacity(0.5),
                elevation: 8,
              ),
              child: Text('GENERATE'),
            ),
          ],
        ),
      ),
    );
  }

  void _pressKey(int midiNote) {
    setState(() => _pressedKeys.add(midiNote));
    // Trigger note on with audio engine
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    audioEngine.noteOn(midiNote, 100); // velocity 100
  }

  void _releaseKey(int midiNote) {
    setState(() => _pressedKeys.remove(midiNote));
    // Trigger note off with audio engine
    final audioEngine = Provider.of<AudioEngine>(context, listen: false);
    audioEngine.noteOff(midiNote);
  }
}

class TransparentXYPainter extends CustomPainter {
  final double x, y;
  
  TransparentXYPainter(this.x, this.y);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Draw crosshairs - very faint so visualizer shows through
    final centerX = size.width * x;
    final centerY = size.height * (1 - y);
    
    // Vertical line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint,
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
    
    // Center dot with energy glow
    final centerPaint = Paint()
      ..color = HolographicTheme.primaryEnergy
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      6,
      centerPaint,
    );
    
    // Outer glow ring
    final glowPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      glowPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnergyKnobPainter extends CustomPainter {
  final double value;
  final Color color;
  
  EnergyKnobPainter(this.value, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (value * 270) * (Math.pi / 180);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -135 * (Math.pi / 180),
      sweepAngle,
      false,
      valuePaint,
    );
    
    // Draw indicator dot
    final angle = -135 + (value * 270);
    final radians = angle * (Math.pi / 180);
    final indicatorPos = Offset(
      center.dx + (radius - 8) * Math.cos(radians),
      center.dy + (radius - 8) * Math.sin(radians),
    );
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorPos, 3, dotPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}