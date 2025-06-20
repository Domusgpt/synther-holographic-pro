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
                  )),
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

// --- Key/Scale Definitions ---
enum MusicalKey { C, Csharp, D, Dsharp, E, F, Fsharp, G, Gsharp, A, Asharp, B }

class KeyDefinition {
  final MusicalKey id;
  final String name;
  final int rootMidiOffset; // Offset from C
  const KeyDefinition(this.id, this.name, this.rootMidiOffset);
}

final List<KeyDefinition> availableKeys = [
  const KeyDefinition(MusicalKey.C, "C", 0),
  const KeyDefinition(MusicalKey.Csharp, "C#", 1),
  const KeyDefinition(MusicalKey.D, "D", 2),
  const KeyDefinition(MusicalKey.Dsharp, "D#", 3),
  const KeyDefinition(MusicalKey.E, "E", 4),
  const KeyDefinition(MusicalKey.F, "F", 5),
  const KeyDefinition(MusicalKey.Fsharp, "F#", 6),
  const KeyDefinition(MusicalKey.G, "G", 7),
  const KeyDefinition(MusicalKey.Gsharp, "G#", 8),
  const KeyDefinition(MusicalKey.A, "A", 9),
  const KeyDefinition(MusicalKey.Asharp, "A#", 10),
  const KeyDefinition(MusicalKey.B, "B", 11),
];

enum MusicalScaleType { Chromatic, Major, MinorNatural, PentatonicMajor }

class ScaleDefinition {
  final MusicalScaleType id;
  final String name;
  final List<int> intervals; // Semitones from the root
  const ScaleDefinition(this.id, this.name, this.intervals);
}

final List<ScaleDefinition> availableScales = [
  const ScaleDefinition(MusicalScaleType.Chromatic, "Chromatic", [0,1,2,3,4,5,6,7,8,9,10,11]),
  const ScaleDefinition(MusicalScaleType.Major, "Major", [0,2,4,5,7,9,11]),
  const ScaleDefinition(MusicalScaleType.MinorNatural, "Natural Minor", [0,2,3,5,7,8,10]),
  const ScaleDefinition(MusicalScaleType.PentatonicMajor, "Pentatonic Major", [0,2,4,7,9]),
];
// --- End Key/Scale Definitions ---

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
  // XYParameter? _selectedXParameter; // Removed, X-axis is now fixed to Pitch
  XYParameter? _selectedYParameter;
  int? _currentNote;

  MusicalKey? _selectedKeyId;
  MusicalScaleType? _selectedScaleId;
  
  // Control panel state
  bool _isSettingsExpanded = false;

  late final List<ParameterChoice> _complimentaryYParameters; // For Smart Y-Axis

  // Sub-pad state
  late final List<ParameterChoice> _subPadSelectableParameters;
  XYParameter? _selectedSubPadXParameter;
  XYParameter? _selectedSubPadYParameter;
  double _subPadX = 0.5;
  double _subPadY = 0.5;

  @override
  void initState() {
    super.initState();
    if (availableParameters.isNotEmpty) {
      // Define complimentary Y parameters
      List<XYParameter> complimentaryIds = [
        XYParameter.volume, XYParameter.cutoff, XYParameter.resonance,
        XYParameter.reverb, XYParameter.attack, XYParameter.decay
      ];
      _complimentaryYParameters = availableParameters.where((p) => complimentaryIds.contains(p.id)).toList();

      // Set default for _selectedYParameter using the complimentary list
      if (_complimentaryYParameters.isNotEmpty) {
        var defaultYChoice = _complimentaryYParameters.firstWhere(
          (p) => p.id == XYParameter.volume,
          orElse: () => _complimentaryYParameters[0]
        );
        _selectedYParameter = defaultYChoice.id;
      } else {
        // Fallback if complimentary list is somehow empty (e.g. volume not in availableParameters)
        // Try to find volume directly, or fallback to cutoff, or null.
        ParameterChoice? volParam;
        try {
          volParam = availableParameters.firstWhere((p) => p.id == XYParameter.volume);
        } catch (e) {
          volParam = null;
        }
        if (volParam != null) {
            _selectedYParameter = XYParameter.volume;
        } else if (availableParameters.where((p) => p.id != XYParameter.pitch).isNotEmpty) {
            _selectedYParameter = availableParameters.where((p) => p.id != XYParameter.pitch).first.id;
        } else {
            _selectedYParameter = null;
        }
      }

      _selectedKeyId = MusicalKey.C;
      _selectedScaleId = MusicalScaleType.Chromatic;

      // Initialize curated list for sub-pad parameters
      List<XYParameter> effectParameterIds = [
        XYParameter.reverb,
        XYParameter.cutoff,
        XYParameter.resonance,
        XYParameter.decay,
        XYParameter.volume,
      ];
      _subPadSelectableParameters = availableParameters.where((p) => effectParameterIds.contains(p.id)).toList();

      // Initialize sub-pad parameters using the curated list
      if (_subPadSelectableParameters.isNotEmpty) {
        _selectedSubPadXParameter = _subPadSelectableParameters[0].id;
        if (_subPadSelectableParameters.length > 1) {
          _selectedSubPadYParameter = _subPadSelectableParameters[1].id;
        } else {
          _selectedSubPadYParameter = _subPadSelectableParameters[0].id;
        }
      } else {
        _selectedSubPadXParameter = null;
        _selectedSubPadYParameter = null;
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

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF00FFFF).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00FFFF).withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with holographic styling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'XY PAD CONTROLS',
                style: TextStyle(
                  color: Color(0xFF00FFFF),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(
                      color: Color(0xFF00FFFF).withOpacity(0.8),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSettingsExpanded = false;
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF00FFFF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF00FFFF).withOpacity(0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    color: Color(0xFF00FFFF),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Key Selection with improved styling
          _buildControlRow(
            'KEY',
            DropdownButton<MusicalKey>(
              value: _selectedKeyId,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: TextStyle(color: Colors.white, fontSize: 12),
              underline: Container(
                height: 2,
                decoration: LinearGradient(
                  colors: [Color(0xFF00FFFF).withOpacity(0.6), Color(0xFF00FFFF).withOpacity(0.2)],
                ).createShader(Rect.fromLTWH(0, 0, 200, 2)) != null
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00FFFF).withOpacity(0.6), Color(0xFF00FFFF).withOpacity(0.2)],
                        ),
                      )
                    : BoxDecoration(color: Color(0xFF00FFFF).withOpacity(0.4)),
              ),
              items: availableKeys.map((KeyDefinition keyDef) {
                return DropdownMenuItem<MusicalKey>(
                  value: keyDef.id,
                  child: Text(keyDef.name, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (MusicalKey? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedKeyId = newValue;
                  });
                }
              },
            ),
          ),
          
          SizedBox(height: 8),
          
          // Scale Selection with improved styling
          _buildControlRow(
            'SCALE',
            DropdownButton<MusicalScaleType>(
              value: _selectedScaleId,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: TextStyle(color: Colors.white, fontSize: 12),
              underline: Container(
                height: 2,
                decoration: BoxDecoration(color: Color(0xFF00FFFF).withOpacity(0.4)),
              ),
              items: availableScales.map((ScaleDefinition scaleDef) {
                return DropdownMenuItem<MusicalScaleType>(
                  value: scaleDef.id,
                  child: Text(scaleDef.name, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (MusicalScaleType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedScaleId = newValue;
                  });
                }
              },
            ),
          ),
          
          SizedBox(height: 8),
          
          // Y-Axis Parameter Selection with improved styling
          _buildControlRow(
            'Y-AXIS',
            DropdownButton<XYParameter>(
              value: _selectedYParameter,
              isExpanded: true,
              dropdownColor: Colors.black.withOpacity(0.9),
              style: TextStyle(color: Colors.white, fontSize: 12),
              underline: Container(
                height: 2,
                decoration: BoxDecoration(color: Color(0xFF00FFFF).withOpacity(0.4)),
              ),
              items: _complimentaryYParameters.map((ParameterChoice choice) {
                return DropdownMenuItem<XYParameter>(
                  value: choice.id,
                  child: Text(choice.name, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (XYParameter? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedYParameter = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlRow(String label, Widget control) {
    return Row(
      children: [
        Container(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: control),
      ],
    );
  }

  List<int> _generateScaleNotes(KeyDefinition keyDef, ScaleDefinition scaleDef, double minPitchRange, double maxPitchRange) {
    List<int> notesInScale = [];
    int minNote = minPitchRange.round();
    int maxNote = maxPitchRange.round();

    if (scaleDef.id == MusicalScaleType.Chromatic) {
      for (int note = minNote; note <= maxNote; note++) {
        notesInScale.add(note);
      }
      return notesInScale;
    }

    for (int octave = 0; octave < 10; octave++) { // Iterate through octaves
      int currentOctaveRootNote = keyDef.rootMidiOffset + (12 * octave);
      for (int interval in scaleDef.intervals) {
        int note = currentOctaveRootNote + interval;
        if (note >= minNote && note <= maxNote && !notesInScale.contains(note)) {
          notesInScale.add(note);
        }
      }
    }
    notesInScale.sort();
    return notesInScale;
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
          // Header with collapsible settings button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'XY PAD',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSettingsExpanded = !_isSettingsExpanded;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isSettingsExpanded 
                          ? Color(0xFF00FFFF).withOpacity(0.3)
                          : Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Color(0xFF00FFFF).withOpacity(_isSettingsExpanded ? 0.8 : 0.4),
                        width: 2.0,
                      ),
                      boxShadow: _isSettingsExpanded ? [
                        BoxShadow(
                          color: Color(0xFF00FFFF).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ] : null,
                    ),
                    child: Icon(
                      _isSettingsExpanded ? Icons.keyboard_arrow_up : Icons.tune,
                      color: Color(0xFF00FFFF),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Collapsible settings panel
          if (_isSettingsExpanded) _buildSettingsPanel(),
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

                ParameterChoice? yChoice; // xChoice is no longer needed here as X is always pitch

                // X-axis is always pitch. Find its definition.
                final pitchParameterChoice = availableParameters.firstWhere((p) => p.id == XYParameter.pitch);

                if (_selectedYParameter != null) {
                  yChoice = availableParameters.firstWhere((p) => p.id == _selectedYParameter);
                }

                int? noteToPlay;
                double velocity = 0.8; // Default velocity

                // Determine note and velocity based on selections
                // X-axis (_xyX) is for pitch

                KeyDefinition? currentKey = _selectedKeyId != null ? availableKeys.firstWhere((k) => k.id == _selectedKeyId, orElse: () => availableKeys[0]) : availableKeys[0];
                ScaleDefinition? currentScale = _selectedScaleId != null ? availableScales.firstWhere((s) => s.id == _selectedScaleId, orElse: () => availableScales[0]) : availableScales[0];

                if (currentKey == null || currentScale == null) {
                  // Fallback or do nothing if key/scale not selected (should not happen due to initState)
                  noteToPlay = _mapValue(_xyX, pitchParameterChoice.minValue, pitchParameterChoice.maxValue, pitchParameterChoice.isLogScale).round();
                } else {
                  List<int> scaleNotes = _generateScaleNotes(currentKey, currentScale, pitchParameterChoice.minValue, pitchParameterChoice.maxValue);
                  if (scaleNotes.isNotEmpty) {
                    int noteIndex = (_xyX * (scaleNotes.length - 1)).round().clamp(0, scaleNotes.length - 1);
                    noteToPlay = scaleNotes[noteIndex];
                  } else {
                    // Fallback if scaleNotes is empty (e.g. range too small for any scale notes)
                    noteToPlay = pitchParameterChoice.minValue.round();
                  }
                }

                // Y-axis velocity logic for main pad
                if (yChoice?.id == XYParameter.volume) {
                  velocity = _mapValue(_xyY, yChoice!.minValue, yChoice!.maxValue, yChoice.isLogScale).clamp(0.0, 1.0);
                } else {
                  // For other Y-axis parameters, use a fixed default velocity
                  velocity = 0.8;
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

                // Handle other parameters (only Y-axis can be non-pitch now for the main pad)
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
                // X-axis of main pad is always pitch.
                if (true || _selectedYParameter == XYParameter.pitch) { // Condition simplifies to true
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
                    items: _subPadSelectableParameters.map((ParameterChoice choice) {
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
                    items: _subPadSelectableParameters.map((ParameterChoice choice) { // Corrected to use _subPadSelectableParameters
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
class KeyboardTabView extends StatefulWidget {
  final AudioEngine audioEngine;

  const KeyboardTabView({super.key, required this.audioEngine});

  @override
  State<KeyboardTabView> createState() => _KeyboardTabViewState();
}

class _KeyboardTabViewState extends State<KeyboardTabView> {
  static const int _minOctaveOffset = -2;
  static const int _maxOctaveOffset = 2;
  int _currentOctaveOffset = 0;

  bool _isThumbModeEnabled = false; // Added for Thumb Mode

  static const double _minKeyboardWidthFactor = 0.5;
  static const double _maxKeyboardWidthFactor = 1.5;
  double _keyboardWidthFactor = 1.0;

  void _octaveDown() {
    setState(() {
      if (_currentOctaveOffset > _minOctaveOffset) _currentOctaveOffset--;
    });
  }

  void _octaveUp() {
    setState(() {
      if (_currentOctaveOffset < _maxOctaveOffset) _currentOctaveOffset++;
    });
  }

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
            final note = 60 + index + (_currentOctaveOffset * 12);

            return Expanded(
              child: GestureDetector(
                onTapDown: (_) => widget.audioEngine.playNote(note, 0.8),
                onTapUp: (_) => widget.audioEngine.stopNote(note),
                onTapCancel: () => widget.audioEngine.stopNote(note),
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

  Widget _buildThumbKeyboard(BuildContext context, AudioEngine audioEngine) {
    final int baseNote = 60 + (_currentOctaveOffset * 12);
    final List<String> noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    // For a 2x6 grid, we only need the first 12 notes of an octave.
    // isBlackKeyPattern should correspond to these 12 notes.
    final List<bool> isBlackKeyPattern = [
      false, true, false, true, false, false, true, false, true, false, true, false
    ];

    List<Widget> keyRows = [];
    for (int rowIndex = 0; rowIndex < 6; rowIndex++) { // 6 rows
      List<Widget> rowKeys = [];
      for (int colIndex = 0; colIndex < 2; colIndex++) { // 2 keys per row
        int noteSequenceIndex = rowIndex * 2 + colIndex; // 0 to 11
        if (noteSequenceIndex >= 12) break; // Should not happen with 2x6 grid

        int midiNote = baseNote + noteSequenceIndex;
        String noteName = noteNames[noteSequenceIndex % 12]; // Use modulo for safety, though direct index is fine
        bool isBlack = isBlackKeyPattern[noteSequenceIndex % 12];

        rowKeys.add(
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => widget.audioEngine.playNote(midiNote, 0.8),
              onTapUp: (_) => widget.audioEngine.stopNote(midiNote),
              onTapCancel: () => widget.audioEngine.stopNote(midiNote),
              child: Container(
                height: 50, // Fixed height for thumb keys for now
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isBlack ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    noteName,
                    style: TextStyle(
                      color: isBlack ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      keyRows.add(Row(children: rowKeys));
    }

    return SizedBox(
      width: 220, // Fixed width for the thumb keyboard
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make the column wrap its content
        children: keyRows,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KEYBOARD INPUT',
                  style: TextStyle(
                    color: Color(0xFFFFFF00),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, color: _currentOctaveOffset > _minOctaveOffset ? Colors.white : Colors.grey[700]),
                      onPressed: _currentOctaveOffset > _minOctaveOffset ? _octaveDown : null,
                      tooltip: 'Octave Down',
                    ),
                    Text(
                      'Oct: ${_currentOctaveOffset >= 0 ? "+" : ""}$_currentOctaveOffset',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, color: _currentOctaveOffset < _maxOctaveOffset ? Colors.white : Colors.grey[700]),
                      onPressed: _currentOctaveOffset < _maxOctaveOffset ? _octaveUp : null,
                      tooltip: 'Octave Up',
                    ),
                  ],
                )
              ],
            ),
          ),
          // Keyboard Width Slider & Thumb Mode Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: Row(
              children: [
                if (!_isThumbModeEnabled) ...[
                  Text("Width: ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.amberAccent.withOpacity(0.7),
                        inactiveTrackColor: Colors.amberAccent.withOpacity(0.3),
                        thumbColor: Colors.amberAccent,
                        overlayColor: Colors.amberAccent.withAlpha(0x29),
                        trackHeight: 2.0,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 12.0),
                      ),
                      child: Slider(
                        value: _keyboardWidthFactor,
                        min: _minKeyboardWidthFactor,
                        max: _maxKeyboardWidthFactor,
                        divisions: 20, // (1.5 - 0.5) / 0.05 = 20
                        label: _keyboardWidthFactor.toStringAsFixed(2),
                        onChanged: (double newValue) {
                          setState(() {
                            _keyboardWidthFactor = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                ],
                if (_isThumbModeEnabled) Expanded(child: Container()), // Takes up space if width slider is hidden, to keep toggle right
                IconButton(
                  icon: Icon(_isThumbModeEnabled ? Icons.view_agenda_outlined : Icons.view_column_outlined, color: Colors.white),
                  tooltip: "Toggle Thumb Mode",
                  onPressed: () {
                    setState(() {
                      _isThumbModeEnabled = !_isThumbModeEnabled;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded( // Ensure piano keyboard section takes available space
            child: Center(
              child: _isThumbModeEnabled
                  ? _buildThumbKeyboard(context, widget.audioEngine)
                  : FractionallySizedBox(
                      widthFactor: _keyboardWidthFactor.clamp(_minKeyboardWidthFactor, _maxKeyboardWidthFactor),
                      child: _buildPianoKeyboard(context, widget.audioEngine),
                    ),
            ),
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