import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../core/audio_engine.dart';
import '../visualizer/hypercube_visualizer.dart';

class ProfessionalSynthesizerInterface extends StatefulWidget {
  const ProfessionalSynthesizerInterface({super.key});

  @override
  State<ProfessionalSynthesizerInterface> createState() => _ProfessionalSynthesizerInterfaceState();
}

class _ProfessionalSynthesizerInterfaceState extends State<ProfessionalSynthesizerInterface>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late TabController _tabController;
  
  // Parameter state
  double _cutoff = 1000.0;
  double _resonance = 0.5;
  double _attack = 0.01;
  double _decay = 0.3;
  double _sustain = 0.7;
  double _release = 0.5;
  double _volume = 0.75;
  double _reverb = 0.3;
  
  // LLM preset prompt
  String _llmPrompt = '';
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _initializeAudioEngine();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeAudioEngine() async {
    final audioEngine = context.read<AudioEngine>();
    await audioEngine.init();
    
    // Set initial parameters
    await audioEngine.setFilterCutoff(_cutoff);
    await audioEngine.setFilterResonance(_resonance);
    await audioEngine.setAttack(_attack);
    await audioEngine.setDecay(_decay);
    await audioEngine.setReverb(_reverb);
    await audioEngine.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 4D Polytopal Projection Visualizer Background
          Positioned.fill(
            child: Consumer<AudioEngine>(
              builder: (context, audioEngine, child) {
                return HypercubeVisualizer(
                  audioEngine: audioEngine,
                );
              },
            ),
          ),
          
          // Professional Synthesizer Interface
          Positioned.fill(
            child: Consumer<AudioEngine>(
              builder: (context, audioEngine, child) {
                return Column(
                  children: [
                    Expanded(
                      flex: 1, // Temporary flex
                      child: _buildLLMPresetInterface(),
                    ),
                    Expanded(
                      flex: 2, // Adjusted flex
                      child: _buildParameterControls(audioEngine),
                    ),
                    // Add TabBar
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.touch_app), text: "XY Pad"),
                        Tab(icon: Icon(Icons.keyboard), text: "Keyboard"),
                      ],
                    ),
                    // Add TabBarView
                    Expanded(
                      flex: 3, // Temporary flex, this will be the main content area
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          XYPadTabView(audioEngine: audioEngine),
                          KeyboardTabView(audioEngine: audioEngine),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Title Overlay
          Positioned(
            top: 40,
            left: 20,
            child: _buildTitle(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFF00FFFF).withOpacity(0.5 + 0.5 * _glowController.value),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF00FFFF).withOpacity(0.3 * _glowController.value),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Text(
            'SYNTHER PROFESSIONAL',
            style: TextStyle(
              color: Color(0xFF00FFFF),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              letterSpacing: 3,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildLLMPresetInterface() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFF00FF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'LLM PRESET GENERATOR',
              style: TextStyle(
                color: Color(0xFFFF00FF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Prompt input
                  Expanded(
                    child: TextField(
                      onChanged: (value) => _llmPrompt = value,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Describe the sound you want...\n\n"warm analog bass"\n"ethereal pad with reverb"\n"aggressive lead synth"',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFFF00FF).withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFFF00FF).withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFFFF00FF)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _generateLLMPreset(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF00FF).withOpacity(0.2),
                        side: BorderSide(color: Color(0xFFFF00FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'GENERATE PRESET',
                        style: TextStyle(color: Color(0xFFFF00FF)),
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
  
  Widget _buildParameterControls(AudioEngine audioEngine) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF00FF00).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Existing Keyboard Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'ADJUSTABLE PARAMETERS',
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Filter controls
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildKnob(
                          'CUTOFF',
                          _cutoff,
                          20.0,
                          20000.0,
                          (value) {
                            setState(() => _cutoff = value);
                            audioEngine.setFilterCutoff(value);
                          },
                          Color(0xFF00FFFF),
                        ),
                      ),
                      Expanded(
                        child: _buildKnob(
                          'RESONANCE',
                          _resonance,
                          0.0,
                          1.0,
                          (value) {
                            setState(() => _resonance = value);
                            audioEngine.setFilterResonance(value);
                          },
                          Color(0xFF00FFFF),
                        ),
                      ),
                    ],
                  )),
                  
                  // Envelope controls
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildKnob(
                          'ATTACK',
                          _attack,
                          0.001,
                          5.0,
                          (value) {
                            setState(() => _attack = value);
                            audioEngine.setAttack(value);
                          },
                          Color(0xFFFF00FF),
                        ),
                      ),
                      Expanded(
                        child: _buildKnob(
                          'DECAY',
                          _decay,
                          0.001,
                          5.0,
                          (value) {
                            setState(() => _decay = value);
                            audioEngine.setDecay(value);
                          },
                          Color(0xFFFF00FF),
                        ),
                      ),
                    ],
                  )),
                  
                  // Volume and Reverb sliders
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSlider(
                          'VOLUME',
                          _volume,
                          0.0,
                          1.0,
                          (value) {
                            setState(() => _volume = value);
                            audioEngine.setVolume(value);
                          },
                          Color(0xFF00FF00),
                        ),
                      ),
                      Expanded(
                        child: _buildSlider(
                          'REVERB',
                          _reverb,
                          0.0,
                          1.0,
                          (value) {
                            setState(() => _reverb = value);
                            audioEngine.setReverb(value);
                          },
                          Color(0xFF00FF00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Add these placeholders:
          Text('X-Axis Parameter: [Pitch] (selectable TBD)', style: TextStyle(color: Colors.white70)),
          Text('Y-Axis Parameter: [Effect] (selectable TBD)', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Text('Sub-pad / Mini-Keyboard / Mini-Effect Pad Area:', style: TextStyle(color: Colors.white70)),
          Placeholder(fallbackHeight: 50),
        ],
      ),
    );
  }
  
  Widget _buildKnob(String label, double value, double min, double max,
                   ValueChanged<double> onChanged, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onPanUpdate: (details) {
            final delta = -details.delta.dy / 100.0;
            final newValue = (value + delta * (max - min)).clamp(min, max);
            onChanged(newValue);
          },
          child: CustomPaint(
            painter: KnobPainter(value, min, max, color),
            size: const Size(60, 60),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
        ),
      ],
    );
  }
  
  Widget _buildSlider(String label, double value, double min, double max,
                     ValueChanged<double> onChanged, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.3),
            thumbColor: color,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10),
        ),
      ],
    );
  }
  
  void _generateLLMPreset() {
    // Simulate LLM preset generation
    if (_llmPrompt.isEmpty) return;
    
    final random = Random();
    setState(() {
      _cutoff = 200 + random.nextDouble() * 8000;
      _resonance = random.nextDouble();
      _attack = random.nextDouble() * 2;
      _decay = 0.1 + random.nextDouble() * 2;
      _reverb = random.nextDouble() * 0.8;
    });
    
    // Apply to audio engine
    // Ensure AudioEngine is accessible here, e.g. via Provider if needed, or pass as parameter.
    // For now, assuming it's accessible via context.read if this method stays in _ProfessionalSynthesizerInterfaceState
    // If _generateLLMPreset is moved or relies on AudioEngine from a different context, this needs adjustment.
    final audioEngine = context.read<AudioEngine>();
    audioEngine.setFilterCutoff(_cutoff);
    audioEngine.setFilterResonance(_resonance);
    audioEngine.setAttack(_attack);
    audioEngine.setDecay(_decay);
    audioEngine.setReverb(_reverb);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated preset for: "$_llmPrompt"'),
        backgroundColor: Color(0xFFFF00FF).withOpacity(0.8),
      ),
    );
  }
}

class XYPadPainter extends CustomPainter {
  final double x;
  final double y;
  
  XYPadPainter(this.x, this.y);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FFFF).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    // Draw grid
    for (int i = 0; i <= 10; i++) {
      final dx = size.width * i / 10;
      final dy = size.height * i / 10;
      
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
    
    // Draw cursor
    final cursorPaint = Paint()
      ..color = Color(0xFF00FFFF)
      ..style = PaintingStyle.fill;
    
    final cursorX = x * size.width;
    final cursorY = (1 - y) * size.height;
    
    canvas.drawCircle(Offset(cursorX, cursorY), 8, cursorPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// TabView Widgets

// XYPadTabView Widget
class XYPadTabView extends StatefulWidget {
  final AudioEngine audioEngine;

  const XYPadTabView({super.key, required this.audioEngine});

  @override
  State<XYPadTabView> createState() => _XYPadTabViewState();
}

class _XYPadTabViewState extends State<XYPadTabView> {
  double _xyX = 0.5;
  double _xyY = 0.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFF00FFFF).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'XY PAD - PITCH/NOTE CONTROL',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final size = box.size;

                setState(() {
                  _xyX = (localPosition.dx / size.width).clamp(0.0, 1.0);
                  _xyY = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
                });

                // Map XY to musical parameters
                final note = 48 + (_xyX * 36).round(); // C3 to C6
                final velocity = _xyY * 0.8 + 0.2; // 0.2 to 1.0

                widget.audioEngine.playNote(note, velocity);
              },
              onPanEnd: (details) {
                widget.audioEngine.stopAllNotes();
              },
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      painter: XYPadPainter(_xyX, _xyY),
                      size: Size(
                        constraints.maxWidth,
                        constraints.maxHeight.isFinite ? constraints.maxHeight : 300,
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// KeyboardTabView Widget
class KeyboardTabView extends StatelessWidget {
  final AudioEngine audioEngine;

  const KeyboardTabView({super.key, required this.audioEngine});

  static String _getNoteLabel(int index) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return notes[index % 12];
  }

  Widget _buildPianoKeyboard(BuildContext context, AudioEngine audioEngine) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Expanded( // Ensure Row takes available space if parent constrains it
        child: Row(
          children: List.generate(12, (index) {
            final isBlackKey = [1, 3, 6, 8, 10].contains(index % 12);
            final note = 60 + index; // C4 to B4

            return Expanded(
              child: GestureDetector(
                onTapDown: (_) => audioEngine.playNote(note, 0.8),
                onTapUp: (_) => audioEngine.stopNote(note),
                onTapCancel: () => audioEngine.stopNote(note),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isBlackKey ? Colors.black : Colors.white,
                    border: Border.all(color: Color(0xFFFFFF00).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      _getNoteLabel(index),
                      style: TextStyle(
                        color: isBlackKey ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFFFFF00).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'KEYBOARD INPUT',
              style: TextStyle(
                color: Color(0xFFFFFF00),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded( // Ensure piano keyboard section takes available space
            child: _buildPianoKeyboard(context, audioEngine),
          ),
          // Placeholders for advanced features
          SizedBox(height: 10),
          Text('Pitch/Mod Wheel Area:', style: TextStyle(color: Colors.white70)),
          Placeholder(fallbackHeight: 50, fallbackWidth: 100),
          SizedBox(height: 10),
          Text('Contextual Controls Area (from main panel):', style: TextStyle(color: Colors.white70)),
          Placeholder(fallbackHeight: 50),
          SizedBox(height: 10),
          Text('Ergonomic Adjustment Controls Area:', style: TextStyle(color: Colors.white70)),
          Placeholder(fallbackHeight: 30),
          SizedBox(height: 10),
          Text('Sub-pad Area:', style: TextStyle(color: Colors.white70)),
          Placeholder(fallbackHeight: 50),
        ],
      ),
    );
  }
}

class KnobPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color color;
  
  KnobPainter(this.value, this.min, this.max, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Background circle
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    
    // Border circle
    final borderPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Value indicator
    final normalizedValue = (value - min) / (max - min);
    final angle = -pi * 0.75 + normalizedValue * pi * 1.5;
    
    final indicatorPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    final startX = center.dx + cos(angle) * (radius - 8);
    final startY = center.dy + sin(angle) * (radius - 8);
    final endX = center.dx + cos(angle) * radius;
    final endY = center.dy + sin(angle) * radius;
    
    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), indicatorPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}