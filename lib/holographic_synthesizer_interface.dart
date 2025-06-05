import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as Math;
import 'core/synth_parameters.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'ui/widgets/holographic_xy_pad.dart' hide XYPadAssignment;
import 'ui/widgets/holographic_keyboard.dart';
import 'ui/holographic/holographic_widget.dart';
import 'ui/holographic/holographic_theme.dart';

/// Holographic professional synthesizer interface
/// Pure HyperAV visualizer background with floating holographic controls
class HolographicSynthesizerInterface extends StatefulWidget {
  const HolographicSynthesizerInterface({Key? key}) : super(key: key);
  
  @override
  State<HolographicSynthesizerInterface> createState() => _HolographicSynthesizerInterfaceState();
}

class _HolographicSynthesizerInterfaceState extends State<HolographicSynthesizerInterface> {
  // XY Pad state
  double _xyX = 0.5;
  double _xyY = 0.5;
  XYPadAssignment _xAssignment = XYPadAssignment.filterCutoff;
  XYPadAssignment _yAssignment = XYPadAssignment.filterResonance;
  ChromaticNote _rootNote = ChromaticNote.c;
  ScaleType _scaleType = ScaleType.chromatic;
  
  // Keyboard state
  int _octaveRange = 4;
  double _keyWidth = 40.0;
  bool _splitMode = false;
  
  // LLM Preset state
  String _llmPrompt = '';
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Holographic',
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Pure HyperAV Audio-Reactive Visualizer Background (NO OVERLAY!)
            Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0, // Full opacity - pure visualizer
                showControls: false,
              ),
            ),
            
            // Floating holographic widgets
            
            // XY Pad - Top left
            HolographicXYPad(
              x: _xyX,
              y: _xyY,
              xAssignment: _xAssignment,
              yAssignment: _yAssignment,
              rootNote: _rootNote,
              scaleType: _scaleType,
              energyColor: HolographicTheme.primaryEnergy,
              onPositionChanged: (position) {
                setState(() {
                  _xyX = position.dx;
                  _xyY = position.dy;
                });
                
                // Update synth parameters based on assignment
                final synth = Provider.of<SynthParametersModel>(context, listen: false);
                _applyXYPadMapping(synth, position);
              },
              onXAssignmentChanged: (assignment) {
                setState(() {
                  _xAssignment = assignment;
                });
              },
              onYAssignmentChanged: (assignment) {
                setState(() {
                  _yAssignment = assignment;
                });
              },
              onRootNoteChanged: (note) {
                setState(() {
                  _rootNote = note;
                });
              },
              onScaleTypeChanged: (scale) {
                setState(() {
                  _scaleType = scale;
                });
              },
            ),
            
            // Parameter Controls - Top right
            _buildParameterControls(),
            
            // Keyboard - Bottom
            HolographicKeyboard(
              octaveRange: _octaveRange,
              keyWidth: _keyWidth,
              splitMode: _splitMode,
              energyColor: HolographicTheme.secondaryEnergy,
              onNoteOn: (note) {
                final synth = Provider.of<SynthParametersModel>(context, listen: false);
                synth.noteOn(note, 100);
              },
              onNoteOff: (note) {
                final synth = Provider.of<SynthParametersModel>(context, listen: false);
                synth.noteOff(note);
              },
              onOctaveChanged: (octave) {
                setState(() {
                  _octaveRange = octave;
                });
              },
              onKeyWidthChanged: (width) {
                setState(() {
                  _keyWidth = width;
                });
              },
              onSplitModeChanged: (split) {
                setState(() {
                  _splitMode = split;
                });
              },
              onPitchBend: (value) {
                // TODO: Implement pitch bend
              },
              onModulation: (value) {
                // TODO: Implement modulation
              },
            ),
            
            // LLM Preset Generator - Top center
            _buildLLMPresetGenerator(),
            
            // Title overlay - Top left corner
            _buildTitle(),
          ],
        ),
      ),
    );
  }
  
  void _applyXYPadMapping(SynthParametersModel synth, Offset position) {
    // Apply X-axis mapping
    switch (_xAssignment) {
      case XYPadAssignment.filterCutoff:
        synth.setFilterCutoff(20.0 + (position.dx * 19980.0));
        break;
      case XYPadAssignment.filterResonance:
        synth.setFilterResonance(position.dx);
        break;
      case XYPadAssignment.oscillatorMix:
        // TODO: Implement oscillator mix
        break;
      case XYPadAssignment.reverbMix:
        synth.setReverbMix(position.dx);
        break;
      case XYPadAssignment.delayTime:
        synth.setDelayTime(0.01 + (position.dx * 1.99));
        break;
      case XYPadAssignment.lfoRate:
        // TODO: Implement LFO rate
        break;
      case XYPadAssignment.customMidiCC:
        // TODO: Implement custom MIDI CC
        break;
    }
    
    // Apply Y-axis mapping
    switch (_yAssignment) {
      case XYPadAssignment.filterCutoff:
        synth.setFilterCutoff(20.0 + (position.dy * 19980.0));
        break;
      case XYPadAssignment.filterResonance:
        synth.setFilterResonance(position.dy);
        break;
      case XYPadAssignment.oscillatorMix:
        // TODO: Implement oscillator mix
        break;
      case XYPadAssignment.reverbMix:
        synth.setReverbMix(position.dy);
        break;
      case XYPadAssignment.delayTime:
        synth.setDelayTime(0.01 + (position.dy * 1.99));
        break;
      case XYPadAssignment.lfoRate:
        // TODO: Implement LFO rate
        break;
      case XYPadAssignment.customMidiCC:
        // TODO: Implement custom MIDI CC
        break;
    }
  }
  
  Widget _buildParameterControls() {
    return HolographicWidget(
      title: 'PARAMETERS',
      energyColor: HolographicTheme.accentEnergy,
      child: Consumer<SynthParametersModel>(
        builder: (context, synth, child) {
          return Column(
            children: [
              // Filter controls
              _buildKnobRow([
                _buildHolographicKnob(
                  'CUTOFF',
                  synth.filterCutoff / 20000.0,
                  (value) => synth.setFilterCutoff(value * 20000.0),
                  HolographicTheme.primaryEnergy,
                ),
                _buildHolographicKnob(
                  'RESONANCE',
                  synth.filterResonance,
                  (value) => synth.setFilterResonance(value),
                  HolographicTheme.primaryEnergy,
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Envelope controls
              _buildKnobRow([
                _buildHolographicKnob(
                  'ATTACK',
                  synth.attackTime / 5.0,
                  (value) => synth.setAttackTime(value * 5.0),
                  HolographicTheme.secondaryEnergy,
                ),
                _buildHolographicKnob(
                  'RELEASE',
                  synth.releaseTime / 10.0,
                  (value) => synth.setReleaseTime(value * 10.0),
                  HolographicTheme.secondaryEnergy,
                ),
              ]),
              
              const SizedBox(height: 16),
              
              // Master volume
              _buildHolographicSlider(
                'VOLUME',
                synth.masterVolume,
                (value) => synth.setMasterVolume(value),
                HolographicTheme.warningEnergy,
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildKnobRow(List<Widget> knobs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: knobs,
    );
  }
  
  Widget _buildHolographicKnob(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color energyColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HolographicTheme.createHolographicText(
            energyColor: energyColor,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onPanUpdate: (details) {
            final delta = -details.delta.dy / 100.0;
            final newValue = (value + delta).clamp(0.0, 1.0);
            onChanged(newValue);
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: HolographicTheme.createHolographicBorder(
              energyColor: energyColor,
              cornerRadius: 25,
            ),
            child: CustomPaint(
              painter: _KnobPainter(value, energyColor),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: HolographicTheme.createHolographicText(
            energyColor: energyColor.withOpacity(0.8),
            fontSize: 8,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHolographicSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color energyColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: HolographicTheme.createHolographicText(
            energyColor: energyColor,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 80,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: energyColor,
                inactiveTrackColor: energyColor.withOpacity(0.3),
                thumbColor: energyColor,
                trackHeight: 4.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLLMPresetGenerator() {
    return HolographicWidget(
      title: 'LLM PRESET GENERATOR',
      energyColor: HolographicTheme.glowColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prompt input
          Container(
            height: 80,
            padding: const EdgeInsets.all(8),
            child: TextField(
              onChanged: (value) => _llmPrompt = value,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Describe your sound...\n\n"warm analog bass"\n"ethereal pad"',
                hintStyle: TextStyle(
                  color: HolographicTheme.glowColor.withOpacity(0.5),
                  fontSize: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HolographicTheme.glowColor.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HolographicTheme.glowColor.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: HolographicTheme.glowColor,
                  ),
                ),
              ),
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.glowColor,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Generate button
          ElevatedButton(
            onPressed: () => _generateLLMPreset(_llmPrompt),
            style: ElevatedButton.styleFrom(
              backgroundColor: HolographicTheme.glowColor.withOpacity(0.2),
              side: BorderSide(color: HolographicTheme.glowColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'GENERATE PRESET',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.glowColor,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTitle() {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: HolographicTheme.createHolographicBorder(
          energyColor: HolographicTheme.primaryEnergy,
          intensity: 1.5,
        ),
        child: Text(
          'SYNTHER HOLOGRAPHIC',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.primaryEnergy,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  void _generateLLMPreset(String description) {
    if (description.isEmpty) return;
    
    final synth = Provider.of<SynthParametersModel>(context, listen: false);
    
    // Simple local preset generation based on description
    if (description.toLowerCase().contains('bass')) {
      synth.setFilterCutoff(300);
      synth.setFilterResonance(0.8);
      synth.setAttackTime(0.01);
      synth.setReleaseTime(0.5);
    } else if (description.toLowerCase().contains('lead')) {
      synth.setFilterCutoff(2000);
      synth.setFilterResonance(0.6);
      synth.setAttackTime(0.01);
      synth.setReleaseTime(0.3);
    } else if (description.toLowerCase().contains('pad')) {
      synth.setFilterCutoff(800);
      synth.setFilterResonance(0.3);
      synth.setAttackTime(0.8);
      synth.setReleaseTime(1.5);
    } else {
      // Default warm sound
      synth.setFilterCutoff(1200);
      synth.setFilterResonance(0.4);
      synth.setAttackTime(0.1);
      synth.setReleaseTime(0.8);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated preset for: $description'),
        backgroundColor: HolographicTheme.glowColor.withOpacity(0.8),
      ),
    );
  }
}

/// Custom painter for holographic knobs
class _KnobPainter extends CustomPainter {
  final double value;
  final Color energyColor;
  
  _KnobPainter(this.value, this.energyColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    // Value indicator
    final angle = -2.4 + value * 4.8; // 270 degree range
    final indicatorEnd = Offset(
      center.dx + radius * 0.7 * Math.cos(angle),
      center.dy + radius * 0.7 * Math.sin(angle),
    );
    
    final paint = Paint()
      ..color = energyColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(center, indicatorEnd, paint);
    
    // Center dot
    final centerPaint = Paint()
      ..color = energyColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 3, centerPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}