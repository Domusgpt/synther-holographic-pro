import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'ui/holographic/holographic_theme.dart';

/// Complete holographic professional synthesizer interface
/// Pure HyperAV visualizer background with fully transparent, draggable, resizable UI elements
class HolographicProfessionalSynth extends StatefulWidget {
  const HolographicProfessionalSynth({Key? key}) : super(key: key);
  
  @override
  State<HolographicProfessionalSynth> createState() => _HolographicProfessionalSynthState();
}

class _HolographicProfessionalSynthState extends State<HolographicProfessionalSynth> {
  // XY Pad state
  double _xyX = 0.5;
  double _xyY = 0.5;
  
  // Keyboard state
  Set<int> _pressedKeys = {};
  int _octave = 4;
  
  // UI element positions and sizes (draggable/resizable)
  Offset _xyPadPosition = Offset(50, 100);
  Size _xyPadSize = Size(300, 300);
  
  Offset _keyboardPosition = Offset(50, 450);
  Size _keyboardSize = Size(600, 120);
  
  Offset _controlsPosition = Offset(400, 100);
  Size _controlsSize = Size(350, 400);
  
  Offset _presetPosition = Offset(50, 50);
  Size _presetSize = Size(700, 80);
  
  // Collapsed states
  bool _xyPadCollapsed = false;
  bool _keyboardCollapsed = false;
  bool _controlsCollapsed = false;
  bool _presetCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Holographic Professional',
      theme: ThemeData.dark().copyWith(
        primaryColor: HolographicTheme.primaryEnergy,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Pure HyperAV Audio-Reactive Visualizer Background - UNMOLESTED!
            Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0, // Pure visualizer, completely unmolested
                showControls: false,
              ),
            ),
            
            // LLM Preset Generator (draggable)
            _buildDraggableWidget(
              position: _presetPosition,
              size: _presetSize,
              isCollapsed: _presetCollapsed,
              title: 'AI PRESET GENERATOR',
              onPositionChanged: (pos) => setState(() => _presetPosition = pos),
              onSizeChanged: (size) => setState(() => _presetSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _presetCollapsed = collapsed),
              child: _buildPresetGenerator(),
            ),
            
            // XY Pad (draggable/resizable) - JUST THE BORDER AS REQUESTED
            _buildDraggableWidget(
              position: _xyPadPosition,
              size: _xyPadSize,
              isCollapsed: _xyPadCollapsed,
              title: 'XY CONTROL PAD',
              onPositionChanged: (pos) => setState(() => _xyPadPosition = pos),
              onSizeChanged: (size) => setState(() => _xyPadSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _xyPadCollapsed = collapsed),
              child: _buildHolographicXYPad(),
            ),
            
            // Virtual Keyboard (draggable/resizable)
            _buildDraggableWidget(
              position: _keyboardPosition,
              size: _keyboardSize,
              isCollapsed: _keyboardCollapsed,
              title: 'HOLOGRAPHIC KEYBOARD',
              onPositionChanged: (pos) => setState(() => _keyboardPosition = pos),
              onSizeChanged: (size) => setState(() => _keyboardSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _keyboardCollapsed = collapsed),
              child: _buildHolographicKeyboard(),
            ),
            
            // Control Panel (draggable/resizable)
            _buildDraggableWidget(
              position: _controlsPosition,
              size: _controlsSize,
              isCollapsed: _controlsCollapsed,
              title: 'SYNTH CONTROLS',
              onPositionChanged: (pos) => setState(() => _controlsPosition = pos),
              onSizeChanged: (size) => setState(() => _controlsSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _controlsCollapsed = collapsed),
              child: _buildControlPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableWidget({
    required Offset position,
    required Size size,
    required bool isCollapsed,
    required String title,
    required Function(Offset) onPositionChanged,
    required Function(Size) onSizeChanged,
    required Function(bool) onCollapsedChanged,
    required Widget child,
  }) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          onPositionChanged(Offset(
            position.dx + details.delta.dx,
            position.dy + details.delta.dy,
          ));
        },
        child: Container(
          width: isCollapsed ? 200 : size.width,
          height: isCollapsed ? 40 : size.height,
          decoration: BoxDecoration(
            // COMPLETELY TRANSPARENT - visualizer shows through
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HolographicTheme.primaryEnergy,
              width: 3,
            ),
            boxShadow: HolographicTheme.createEnergyGlow(
              color: HolographicTheme.primaryEnergy,
              intensity: 1.0,
            ),
          ),
          child: Column(
            children: [
              // Header with title and controls
              Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                  border: Border(
                    bottom: BorderSide(
                      color: HolographicTheme.primaryEnergy,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Drag handle
                    Icon(
                      Icons.drag_indicator,
                      color: HolographicTheme.primaryEnergy,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    // Title
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: HolographicTheme.primaryEnergy,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          shadows: HolographicTheme.textGlow(HolographicTheme.primaryEnergy),
                        ),
                      ),
                    ),
                    // Collapse button
                    GestureDetector(
                      onTap: () => onCollapsedChanged(!isCollapsed),
                      child: Icon(
                        isCollapsed ? Icons.expand_more : Icons.expand_less,
                        color: HolographicTheme.primaryEnergy,
                        size: 16,
                      ),
                    ),
                    // Resize handle
                    if (!isCollapsed)
                      GestureDetector(
                        onPanUpdate: (details) {
                          onSizeChanged(Size(
                            (size.width + details.delta.dx).clamp(100, 800),
                            (size.height + details.delta.dy).clamp(100, 600),
                          ));
                        },
                        child: Icon(
                          Icons.crop_free,
                          color: HolographicTheme.secondaryEnergy,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
              // Content
              if (!isCollapsed)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: child,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetGenerator() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Describe your sound (e.g., "ethereal pad with crystal resonance")...',
              hintStyle: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HolographicTheme.primaryEnergy),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: HolographicTheme.primaryEnergy, width: 2),
              ),
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
            backgroundColor: HolographicTheme.primaryEnergy.withOpacity(0.2),
            foregroundColor: HolographicTheme.primaryEnergy,
            side: BorderSide(color: HolographicTheme.primaryEnergy),
          ),
          child: Text('GENERATE'),
        ),
      ],
    );
  }

  Widget _buildHolographicXYPad() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // XY Pad - JUST THE BORDER as requested, visualizer shows through
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  // NO BACKGROUND - completely transparent to show visualizer
                  border: Border.all(
                    color: HolographicTheme.primaryEnergy,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: HolographicTheme.createEnergyGlow(
                    color: HolographicTheme.primaryEnergy,
                    intensity: 1.0,
                  ),
                ),
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
                    painter: XYPadPainter(_xyX, _xyY),
                    size: Size.infinite,
                  ),
                ),
              ),
              // Parameter assignment dropdowns
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: HolographicTheme.secondaryEnergy),
                  ),
                  child: Text(
                    'X: Filter Cutoff | Y: Resonance',
                    style: TextStyle(
                      color: HolographicTheme.secondaryEnergy,
                      fontSize: 10,
                      shadows: HolographicTheme.textGlow(HolographicTheme.secondaryEnergy),
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

  Widget _buildHolographicKeyboard() {
    return Container(
      height: double.infinity,
      child: Row(
        children: [
          // Octave selector
          Container(
            width: 60,
            padding: EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OCT',
                  style: TextStyle(
                    color: HolographicTheme.primaryEnergy,
                    fontSize: 10,
                    shadows: HolographicTheme.textGlow(HolographicTheme.primaryEnergy),
                  ),
                ),
                SizedBox(height: 4),
                GestureDetector(
                  onTap: () => setState(() => _octave = (_octave + 1).clamp(0, 8)),
                  child: Icon(Icons.keyboard_arrow_up, color: HolographicTheme.primaryEnergy),
                ),
                Text(
                  _octave.toString(),
                  style: TextStyle(
                    color: HolographicTheme.primaryEnergy,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _octave = (_octave - 1).clamp(0, 8)),
                  child: Icon(Icons.keyboard_arrow_down, color: HolographicTheme.primaryEnergy),
                ),
              ],
            ),
          ),
          // Piano keys
          Expanded(
            child: _buildPianoKeys(),
          ),
          // Bend wheels
          Container(
            width: 60,
            padding: EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(child: _buildBendWheel('PITCH', true)),
                SizedBox(height: 8),
                Expanded(child: _buildBendWheel('MOD', false)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPianoKeys() {
    final whiteKeys = [0, 2, 4, 5, 7, 9, 11]; // C, D, E, F, G, A, B
    final blackKeys = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
    
    return Stack(
      children: [
        // White keys
        Row(
          children: whiteKeys.map((note) {
            final midiNote = _octave * 12 + note;
            final isPressed = _pressedKeys.contains(midiNote);
            
            return Expanded(
              child: GestureDetector(
                onTapDown: (_) => _pressKey(midiNote),
                onTapUp: (_) => _releaseKey(midiNote),
                child: Container(
                  margin: EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isPressed 
                        ? HolographicTheme.primaryEnergy.withOpacity(0.2)
                        : Colors.transparent,
                    border: Border.all(
                      color: isPressed 
                          ? HolographicTheme.primaryEnergy 
                          : HolographicTheme.primaryEnergy.withOpacity(0.6),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: isPressed 
                        ? HolographicTheme.createEnergyGlow(
                            color: HolographicTheme.primaryEnergy,
                            intensity: 1.0,
                          )
                        : [],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Black keys
        Positioned.fill(
          child: Row(
            children: [
              for (int i = 0; i < whiteKeys.length - 1; i++) ...[
                Expanded(flex: 1, child: SizedBox()),
                if (blackKeys.contains(whiteKeys[i] + 1))
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 60,
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTapDown: (_) => _pressKey(_octave * 12 + whiteKeys[i] + 1),
                        onTapUp: (_) => _releaseKey(_octave * 12 + whiteKeys[i] + 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _pressedKeys.contains(_octave * 12 + whiteKeys[i] + 1)
                                ? HolographicTheme.secondaryEnergy.withOpacity(0.3)
                                : Colors.transparent,
                            border: Border.all(
                              color: HolographicTheme.secondaryEnergy,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _pressedKeys.contains(_octave * 12 + whiteKeys[i] + 1)
                                ? HolographicTheme.createEnergyGlow(
                                    color: HolographicTheme.secondaryEnergy,
                                    intensity: 0.8,
                                  )
                                : [],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(flex: 1, child: SizedBox()),
              ],
              Expanded(flex: 1, child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBendWheel(String label, bool isPitch) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: HolographicTheme.secondaryEnergy, width: 2),
        borderRadius: BorderRadius.circular(4),
        color: Colors.transparent,
        boxShadow: HolographicTheme.createEnergyGlow(
          color: HolographicTheme.secondaryEnergy,
          intensity: 0.5,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(4),
            child: Text(
              label,
              style: TextStyle(
                color: HolographicTheme.secondaryEnergy,
                fontSize: 8,
                shadows: HolographicTheme.textGlow(HolographicTheme.secondaryEnergy),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HolographicTheme.secondaryEnergy.withOpacity(0.1),
                    HolographicTheme.secondaryEnergy.withOpacity(0.3),
                    HolographicTheme.secondaryEnergy.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Container(
          padding: EdgeInsets.all(8),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Filter section
                _buildControlSection('FILTER', [
                  _buildHolographicKnob('CUTOFF', model.filterCutoff / 20000, 
                      (value) => model.setFilterCutoff(value * 20000)),
                  _buildHolographicKnob('RESONANCE', model.filterResonance, 
                      (value) => model.setFilterResonance(value)),
                ]),
                SizedBox(height: 12),
                
                // Envelope section
                _buildControlSection('ENVELOPE', [
                  _buildHolographicKnob('ATTACK', model.attackTime, 
                      (value) => model.setAttackTime(value)),
                  _buildHolographicKnob('RELEASE', model.releaseTime, 
                      (value) => model.setReleaseTime(value)),
                ]),
                SizedBox(height: 12),
                
                // Effects section
                _buildControlSection('EFFECTS', [
                  _buildHolographicKnob('REVERB', model.reverbMix, 
                      (value) => model.setReverbMix(value)),
                  _buildHolographicKnob('VOLUME', model.masterVolume, 
                      (value) => model.setMasterVolume(value)),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlSection(String title, List<Widget> controls) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: HolographicTheme.secondaryEnergy, width: 1),
        borderRadius: BorderRadius.circular(6),
        color: Colors.transparent,
        boxShadow: HolographicTheme.createEnergyGlow(
          color: HolographicTheme.secondaryEnergy,
          intensity: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: HolographicTheme.textGlow(HolographicTheme.secondaryEnergy),
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: controls,
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicKnob(String label, double value, Function(double) onChanged) {
    return Container(
      width: 80,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              fontSize: 10,
              shadows: HolographicTheme.textGlow(HolographicTheme.primaryEnergy),
            ),
          ),
          SizedBox(height: 4),
          GestureDetector(
            onPanUpdate: (details) {
              final newValue = (value - details.delta.dy * 0.01).clamp(0.0, 1.0);
              onChanged(newValue);
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: HolographicTheme.primaryEnergy, width: 2),
                color: Colors.transparent,
                boxShadow: HolographicTheme.createEnergyGlow(
                  color: HolographicTheme.primaryEnergy,
                  intensity: 0.8,
                ),
              ),
              child: CustomPaint(
                painter: KnobPainter(value, HolographicTheme.primaryEnergy),
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
      ),
    );
  }

  void _pressKey(int midiNote) {
    setState(() => _pressedKeys.add(midiNote));
    // TODO: Trigger note on
  }

  void _releaseKey(int midiNote) {
    setState(() => _pressedKeys.remove(midiNote));
    // TODO: Trigger note off
  }
}

class XYPadPainter extends CustomPainter {
  final double x, y;
  
  XYPadPainter(this.x, this.y);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = HolographicTheme.primaryEnergy
      ..style = PaintingStyle.fill;
    
    // Draw crosshairs
    final centerX = size.width * x;
    final centerY = size.height * (1 - y);
    
    // Vertical line
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, size.height),
      paint..strokeWidth = 1..style = PaintingStyle.stroke..color = HolographicTheme.primaryEnergy.withOpacity(0.3),
    );
    
    // Horizontal line
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint..color = HolographicTheme.primaryEnergy.withOpacity(0.3),
    );
    
    // Center dot with glow
    canvas.drawCircle(
      Offset(centerX, centerY),
      8,
      paint..style = PaintingStyle.fill..color = HolographicTheme.primaryEnergy,
    );
    
    canvas.drawCircle(
      Offset(centerX, centerY),
      12,
      paint..style = PaintingStyle.stroke..strokeWidth = 2..color = HolographicTheme.primaryEnergy.withOpacity(0.5),
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class KnobPainter extends CustomPainter {
  final double value;
  final Color color;
  
  KnobPainter(this.value, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    
    // Draw arc background
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Draw value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (value * 270) * (Math.pi / 180); // 270 degrees max
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -135 * (Math.pi / 180), // Start at -135 degrees
      sweepAngle,
      false,
      valuePaint,
    );
    
    // Draw indicator line
    final angle = -135 + (value * 270);
    final radians = angle * (Math.pi / 180);
    final indicatorEnd = Offset(
      center.dx + (radius - 10) * Math.cos(radians),
      center.dy + (radius - 10) * Math.sin(radians),
    );
    
    canvas.drawLine(
      center,
      indicatorEnd,
      Paint()..color = color..strokeWidth = 2,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}