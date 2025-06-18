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
  final Color accentColor;

  XYPadPainter(this.x, this.y, {this.accentColor = const Color(0xFF00FFFF)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = this.accentColor.withOpacity(0.2)
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
      ..color = this.accentColor
      ..style = PaintingStyle.fill;

    final cursorX = x * size.width;
    final cursorY = (1 - y) * size.height;
    
    canvas.drawCircle(Offset(cursorX, cursorY), 8, cursorPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- XY Pad Parameter Selection Data Structures ---
enum XYParameter { cutoff, resonance, attack, decay, reverb, volume, pitch }

class ParameterChoice {
  final XYParameter id;
  final String name;
  final double minValue;
  final double maxValue;
  final bool isLogScale;

  const ParameterChoice({
    required this.id,
    required this.name,
    required this.minValue,
    required this.maxValue,
    this.isLogScale = false,
  });
}

final List<ParameterChoice> availableParameters = [
  const ParameterChoice(id: XYParameter.pitch, name: 'Pitch (Note)', minValue: 36, maxValue: 84), // C2 to C6 MIDI notes
  const ParameterChoice(id: XYParameter.cutoff, name: 'Filter Cutoff', minValue: 20, maxValue: 20000, isLogScale: true),
  const ParameterChoice(id: XYParameter.resonance, name: 'Filter Resonance', minValue: 0.0, maxValue: 1.0),
  const ParameterChoice(id: XYParameter.attack, name: 'Envelope Attack', minValue: 0.001, maxValue: 5.0, isLogScale: true),
  const ParameterChoice(id: XYParameter.decay, name: 'Envelope Decay', minValue: 0.001, maxValue: 5.0, isLogScale: true),
  const ParameterChoice(id: XYParameter.reverb, name: 'Reverb Amount', minValue: 0.0, maxValue: 1.0),
  const ParameterChoice(id: XYParameter.volume, name: 'Overall Volume', minValue: 0.0, maxValue: 1.0),
];
// --- End XY Pad Parameter Selection Data Structures ---

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
  XYParameter? _selectedXParameter;
  XYParameter? _selectedYParameter;
  int? _currentNote;

  // Sub-pad state
  XYParameter? _selectedSubPadXParameter;
  XYParameter? _selectedSubPadYParameter;
  double _subPadX = 0.5;
  double _subPadY = 0.5;

  @override
  void initState() {
    super.initState();
    if (availableParameters.isNotEmpty) {
      _selectedXParameter = XYParameter.pitch; // Default X to Pitch
      _selectedYParameter = XYParameter.cutoff; // Default Y to Cutoff

      // Initialize sub-pad parameters (excluding pitch)
      final nonPitchParams = availableParameters.where((p) => p.id != XYParameter.pitch).toList();
      if (nonPitchParams.isNotEmpty) {
        _selectedSubPadXParameter = nonPitchParams[0].id; // Default to first non-pitch
        if (nonPitchParams.length > 1) {
          _selectedSubPadYParameter = nonPitchParams[1].id; // Default to second non-pitch
        } else {
          _selectedSubPadYParameter = nonPitchParams[0].id;
        }
      }
    }
  }

  double _mapValue(double normalizedValue, double min, double max, bool isLog) {
    if (isLog) {
      if (min <= 0) return min; // Avoid log(0) or log(negative)
      return min * exp(normalizedValue * log(max / min));
    } else {
      return min + normalizedValue * (max - min);
    }
  }

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
              'XY PAD', // Simplified title
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
              ),
            ),
          ),
          // X-Axis Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Text('X-Axis: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: DropdownButton<XYParameter>(
                    value: _selectedXParameter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    style: TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Color(0xFF00FFFF).withOpacity(0.5)),
                    items: availableParameters.map((ParameterChoice choice) {
                      return DropdownMenuItem<XYParameter>(
                        value: choice.id,
                        child: Text(choice.name, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (XYParameter? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedXParameter = newValue;
                          // TODO: Add logic to update AudioEngine or internal mapping if needed
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Y-Axis Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Text('Y-Axis: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: DropdownButton<XYParameter>(
                    value: _selectedYParameter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    style: TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Color(0xFF00FFFF).withOpacity(0.5)),
                    items: availableParameters.map((ParameterChoice choice) {
                      return DropdownMenuItem<XYParameter>(
                        value: choice.id,
                        child: Text(choice.name, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (XYParameter? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedYParameter = newValue;
                          // TODO: Add logic to update AudioEngine or internal mapping if needed
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10), // Spacer before the pad
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

                ParameterChoice? xChoice;
                ParameterChoice? yChoice;

                if (_selectedXParameter != null) {
                  xChoice = availableParameters.firstWhere((p) => p.id == _selectedXParameter);
                }
                if (_selectedYParameter != null) {
                  yChoice = availableParameters.firstWhere((p) => p.id == _selectedYParameter);
                }

                int? noteToPlay;
                double velocity = 0.8; // Default velocity

                // Determine note and velocity based on selections
                if (xChoice?.id == XYParameter.pitch) {
                  noteToPlay = _mapValue(_xyX, xChoice!.minValue, xChoice!.maxValue, xChoice.isLogScale).round();
                  if (yChoice?.id != XYParameter.pitch) { // Y is some other param or unassigned
                    velocity = _xyY; // Use _xyY directly as normalized velocity 0-1
                  } else {
                    // Both X and Y are pitch - this case should ideally be prevented by UI logic
                    // For now, let X be pitch, Y be fixed velocity
                  }
                } else if (yChoice?.id == XYParameter.pitch) {
                  noteToPlay = _mapValue(_xyY, yChoice!.minValue, yChoice!.maxValue, yChoice.isLogScale).round();
                  // X is some other param or unassigned
                  velocity = _xyX; // Use _xyX directly as normalized velocity 0-1
                }

                // Play note if applicable
                if (noteToPlay != null) {
                  if (noteToPlay != _currentNote) {
                    if (_currentNote != null) {
                       // Using stopAllNotes before playing new for simplicity
                       // Ideally, would be widget.audioEngine.stopNote(_currentNote!);
                       widget.audioEngine.stopAllNotes();
                    }
                    _currentNote = noteToPlay;
                    widget.audioEngine.playNote(_currentNote!, velocity.clamp(0.0, 1.0));
                  } else {
                    // Note is the same, could potentially update velocity if it's mapped and changed
                    // widget.audioEngine.updateNoteVelocity(_currentNote!, velocity.clamp(0.0,1.0)); (if exists)
                  }
                }

                // Handle other parameters
                if (xChoice != null && xChoice.id != XYParameter.pitch) {
                  final value = _mapValue(_xyX, xChoice.minValue, xChoice.maxValue, xChoice.isLogScale);
                  switch (xChoice.id) {
                    case XYParameter.cutoff: widget.audioEngine.setFilterCutoff(value); break;
                    case XYParameter.resonance: widget.audioEngine.setFilterResonance(value); break;
                    case XYParameter.attack: widget.audioEngine.setAttack(value); break;
                    case XYParameter.decay: widget.audioEngine.setDecay(value); break;
                    case XYParameter.reverb: widget.audioEngine.setReverb(value); break;
                    case XYParameter.volume: widget.audioEngine.setVolume(value); break;
                    case XYParameter.pitch: break; // Already handled
                  }
                }
                if (yChoice != null && yChoice.id != XYParameter.pitch) {
                  final value = _mapValue(_xyY, yChoice.minValue, yChoice.maxValue, yChoice.isLogScale);
                  switch (yChoice.id) {
                    case XYParameter.cutoff: widget.audioEngine.setFilterCutoff(value); break;
                    case XYParameter.resonance: widget.audioEngine.setFilterResonance(value); break;
                    case XYParameter.attack: widget.audioEngine.setAttack(value); break;
                    case XYParameter.decay: widget.audioEngine.setDecay(value); break;
                    case XYParameter.reverb: widget.audioEngine.setReverb(value); break;
                    case XYParameter.volume: widget.audioEngine.setVolume(value); break;
                    case XYParameter.pitch: break; // Already handled
                  }
                }
              },
              onPanEnd: (details) {
                // if (_currentNote != null) {
                //   widget.audioEngine.stopNote(_currentNote!);
                //  _currentNote = null;
                // }
                // Simpler: stop all notes on pan end if a note was potentially being controlled by the pad.
                if (_selectedXParameter == XYParameter.pitch || _selectedYParameter == XYParameter.pitch) {
                   widget.audioEngine.stopAllNotes();
                  _currentNote = null;
                }
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
          // Other placeholders (Sub-pad area)
          Divider(color: Colors.grey[700]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Sub XY Pad', style: TextStyle(color: Colors.white, fontSize: 16))
          ),
          // Sub-Pad X-Axis Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Text('X-Sub: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: DropdownButton<XYParameter>(
                    value: _selectedSubPadXParameter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    style: TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Colors.greenAccent.withOpacity(0.5)),
                    items: availableParameters
                        .where((p) => p.id != XYParameter.pitch)
                        .map((ParameterChoice choice) {
                      return DropdownMenuItem<XYParameter>(
                        value: choice.id,
                        child: Text(choice.name, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (XYParameter? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSubPadXParameter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          // Sub-Pad Y-Axis Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Text('Y-Sub: ', style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: DropdownButton<XYParameter>(
                    value: _selectedSubPadYParameter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[850],
                    style: TextStyle(color: Colors.white),
                    underline: Container(height: 1, color: Colors.greenAccent.withOpacity(0.5)),
                    items: availableParameters
                        .where((p) => p.id != XYParameter.pitch)
                        .map((ParameterChoice choice) {
                      return DropdownMenuItem<XYParameter>(
                        value: choice.id,
                        child: Text(choice.name, style: TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (XYParameter? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSubPadYParameter = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          SizedBox(
            height: 120, // Or other desired height
            width: 200,  // Or other desired width, or make it expand
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final size = box.size;

                setState(() {
                  _subPadX = (localPosition.dx / size.width).clamp(0.0, 1.0);
                  _subPadY = 1.0 - (localPosition.dy / size.height).clamp(0.0, 1.0);
                });

                ParameterChoice? subXChoice;
                ParameterChoice? subYChoice;

                if (_selectedSubPadXParameter != null) {
                  subXChoice = availableParameters.firstWhere((p) => p.id == _selectedSubPadXParameter);
                }
                if (_selectedSubPadYParameter != null) {
                  subYChoice = availableParameters.firstWhere((p) => p.id == _selectedSubPadYParameter);
                }

                if (subXChoice != null) {
                  final value = _mapValue(_subPadX, subXChoice.minValue, subXChoice.maxValue, subXChoice.isLogScale);
                  // Apply to audio engine (no pitch)
                  switch (subXChoice.id) {
                    case XYParameter.cutoff: widget.audioEngine.setFilterCutoff(value); break;
                    case XYParameter.resonance: widget.audioEngine.setFilterResonance(value); break;
                    case XYParameter.attack: widget.audioEngine.setAttack(value); break;
                    case XYParameter.decay: widget.audioEngine.setDecay(value); break;
                    case XYParameter.reverb: widget.audioEngine.setReverb(value); break;
                    case XYParameter.volume: widget.audioEngine.setVolume(value); break;
                    case XYParameter.pitch: break; // Should not happen due to filtering
                  }
                }
                if (subYChoice != null) {
                  final value = _mapValue(_subPadY, subYChoice.minValue, subYChoice.maxValue, subYChoice.isLogScale);
                  // Apply to audio engine (no pitch)
                   switch (subYChoice.id) {
                    case XYParameter.cutoff: widget.audioEngine.setFilterCutoff(value); break;
                    case XYParameter.resonance: widget.audioEngine.setFilterResonance(value); break;
                    case XYParameter.attack: widget.audioEngine.setAttack(value); break;
                    case XYParameter.decay: widget.audioEngine.setDecay(value); break;
                    case XYParameter.reverb: widget.audioEngine.setReverb(value); break;
                    case XYParameter.volume: widget.audioEngine.setVolume(value); break;
                    case XYParameter.pitch: break; // Should not happen
                  }
                }
              },
              child: LayoutBuilder(builder: (context, constraints) {
                return CustomPaint(
                  painter: XYPadPainter(_subPadX, _subPadY, accentColor: Colors.greenAccent),
                  size: constraints.biggest,
                );
              }),
            ),
          ),
          SizedBox(height: 10), // Final spacing if needed
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