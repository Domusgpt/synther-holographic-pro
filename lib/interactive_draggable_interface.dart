import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'core/audio_engine.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'ui/holographic/holographic_theme.dart';
import 'services/firebase_service.dart';

/// INTERACTIVE DRAGGABLE HOLOGRAPHIC INTERFACE
/// Professional synthesizer with full interaction, dragging, and resizing
class InteractiveDraggableSynth extends StatefulWidget {
  const InteractiveDraggableSynth({Key? key}) : super(key: key);
  
  @override
  State<InteractiveDraggableSynth> createState() => _InteractiveDraggableSynthState();
}

class _InteractiveDraggableSynthState extends State<InteractiveDraggableSynth> {
  // XY Pad state
  double _xyX = 0.5;
  double _xyY = 0.5;
  
  // Keyboard state
  Set<int> _pressedKeys = {};
  int _octave = 4;
  
  // Panel positions and sizes (draggable/resizable)
  Offset _xyPadPosition = Offset(50, 120);
  Size _xyPadSize = Size(280, 280);
  
  Offset _keyboardPosition = Offset(50, 450);
  Size _keyboardSize = Size(600, 120);
  
  Offset _controlsPosition = Offset(380, 120);
  Size _controlsSize = Size(300, 380);
  
  Offset _presetPosition = Offset(50, 50);
  Size _presetSize = Size(700, 60);
  
  // Collapsed states
  bool _xyPadCollapsed = false;
  bool _keyboardCollapsed = false;
  bool _controlsCollapsed = false;
  bool _presetCollapsed = false;
  
  // AI preset generation state
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Interactive Professional',
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
            
            // Draggable XY Pad
            _buildDraggablePanel(
              position: _xyPadPosition,
              size: _xyPadSize,
              isCollapsed: _xyPadCollapsed,
              title: 'XY CONTROL PAD',
              onPositionChanged: (pos) => setState(() => _xyPadPosition = pos),
              onSizeChanged: (size) => setState(() => _xyPadSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _xyPadCollapsed = collapsed),
              child: _buildInteractiveXYPad(),
            ),
            
            // Draggable Controls
            _buildDraggablePanel(
              position: _controlsPosition,
              size: _controlsSize,
              isCollapsed: _controlsCollapsed,
              title: 'SYNTH CONTROLS',
              onPositionChanged: (pos) => setState(() => _controlsPosition = pos),
              onSizeChanged: (size) => setState(() => _controlsSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _controlsCollapsed = collapsed),
              child: _buildInteractiveControls(),
            ),
            
            // Draggable Keyboard
            _buildDraggablePanel(
              position: _keyboardPosition,
              size: _keyboardSize,
              isCollapsed: _keyboardCollapsed,
              title: 'HOLOGRAPHIC KEYBOARD',
              onPositionChanged: (pos) => setState(() => _keyboardPosition = pos),
              onSizeChanged: (size) => setState(() => _keyboardSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _keyboardCollapsed = collapsed),
              child: _buildInteractiveKeyboard(),
            ),
            
            // Draggable Preset Bar
            _buildDraggablePanel(
              position: _presetPosition,
              size: _presetSize,
              isCollapsed: _presetCollapsed,
              title: 'AI PRESET GENERATOR',
              onPositionChanged: (pos) => setState(() => _presetPosition = pos),
              onSizeChanged: (size) => setState(() => _presetSize = size),
              onCollapsedChanged: (collapsed) => setState(() => _presetCollapsed = collapsed),
              child: _buildInteractivePresetBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePanel({
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
      child: Container(
        width: isCollapsed ? 250 : size.width,
        height: isCollapsed ? 40 : size.height,
        child: Stack(
          children: [
            // Main panel
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: HolographicTheme.primaryEnergy,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Draggable header
                  GestureDetector(
                    onPanUpdate: (details) {
                      onPositionChanged(Offset(
                        position.dx + details.delta.dx,
                        position.dy + details.delta.dy,
                      ));
                    },
                    child: Container(
                      height: 40,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        border: Border(
                          bottom: BorderSide(
                            color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.drag_indicator,
                              color: HolographicTheme.primaryEnergy,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: HolographicTheme.primaryEnergy,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: HolographicTheme.primaryEnergy,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onCollapsedChanged(!isCollapsed),
                              child: Icon(
                                isCollapsed ? Icons.expand_more : Icons.expand_less,
                                color: HolographicTheme.primaryEnergy,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Content area
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
            // Resize handle (bottom-right corner)
            if (!isCollapsed)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    onSizeChanged(Size(
                      (size.width + details.delta.dx).clamp(200, 800),
                      (size.height + details.delta.dy).clamp(150, 600),
                    ));
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(12)),
                    ),
                    child: Icon(
                      Icons.crop_free,
                      color: HolographicTheme.secondaryEnergy,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveXYPad() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              // Interactive XY area
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _xyX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                      _xyY = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
                    });
                    // Update synthesis parameters
                    model.setXYPad(_xyX, _xyY);
                  },
                  onTapDown: (details) {
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    setState(() {
                      _xyX = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                      _xyY = 1.0 - (localPosition.dy / box.size.height).clamp(0.0, 1.0);
                    });
                    model.setXYPad(_xyX, _xyY);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: InteractiveXYPainter(_xyX, _xyY),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
              // Parameter display
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
                    'X: ${(_xyX * 100).round()}% | Y: ${(_xyY * 100).round()}%',
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

  Widget _buildInteractiveControls() {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        return SingleChildScrollView(
          child: Column(
            children: [
              // Filter Controls
              Text(
                'FILTER',
                style: TextStyle(
                  color: HolographicTheme.secondaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: HolographicTheme.secondaryEnergy,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInteractiveKnob('CUTOFF', model.filterCutoff / 20000, 
                      (value) => model.setFilterCutoff(value * 20000)),
                  _buildInteractiveKnob('RESONANCE', model.filterResonance, 
                      (value) => model.setFilterResonance(value)),
                ],
              ),
              SizedBox(height: 20),
              
              // Envelope Controls
              Text(
                'ENVELOPE',
                style: TextStyle(
                  color: HolographicTheme.secondaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: HolographicTheme.secondaryEnergy,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInteractiveKnob('ATTACK', model.attackTime, 
                      (value) => model.setAttackTime(value)),
                  _buildInteractiveKnob('RELEASE', model.releaseTime, 
                      (value) => model.setReleaseTime(value)),
                ],
              ),
              SizedBox(height: 20),
              
              // Effects Controls
              Text(
                'EFFECTS',
                style: TextStyle(
                  color: HolographicTheme.secondaryEnergy,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: HolographicTheme.secondaryEnergy,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInteractiveKnob('REVERB', model.reverbMix, 
                      (value) => model.setReverbMix(value)),
                  _buildInteractiveKnob('VOLUME', model.masterVolume, 
                      (value) => model.setMasterVolume(value)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveKnob(String label, double value, Function(double) onChanged) {
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
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              border: Border.all(
                color: HolographicTheme.primaryEnergy,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: CustomPaint(
              painter: InteractiveKnobPainter(value, HolographicTheme.primaryEnergy),
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

  Widget _buildInteractiveKeyboard() {
    final whiteKeys = [0, 2, 4, 5, 7, 9, 11];
    
    return Column(
      children: [
        // Octave selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('OCT:', style: TextStyle(color: HolographicTheme.primaryEnergy, fontSize: 12)),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _octave = (_octave - 1).clamp(0, 8)),
              child: Icon(Icons.remove, color: HolographicTheme.primaryEnergy, size: 20),
            ),
            SizedBox(width: 8),
            Text('$_octave', style: TextStyle(color: HolographicTheme.primaryEnergy, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _octave = (_octave + 1).clamp(0, 8)),
              child: Icon(Icons.add, color: HolographicTheme.primaryEnergy, size: 20),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Piano keys
        Expanded(
          child: Row(
            children: whiteKeys.map((note) {
              final midiNote = _octave * 12 + note;
              final isPressed = _pressedKeys.contains(midiNote);
              
              return Expanded(
                child: GestureDetector(
                  onTapDown: (_) => _pressKey(midiNote),
                  onTapUp: (_) => _releaseKey(midiNote),
                  onTapCancel: () => _releaseKey(midiNote),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
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
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        ['C', 'D', 'E', 'F', 'G', 'A', 'B'][whiteKeys.indexOf(note)],
                        style: TextStyle(
                          color: HolographicTheme.primaryEnergy.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractivePresetBar() {
    final TextEditingController _controller = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Row(
          children: [
            Text(
              'AI PRESET GENERATOR',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: HolographicTheme.primaryEnergy,
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Describe your sound (e.g., "warm analog bass with filter sweep")...',
                  hintStyle: TextStyle(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                    fontSize: 12,
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: TextStyle(color: HolographicTheme.primaryEnergy, fontSize: 12),
                onSubmitted: (value) => _generateAIPreset(value),
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton(
              onPressed: _isGenerating ? null : () => _generateAIPreset(_controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: HolographicTheme.primaryEnergy,
                side: BorderSide(color: HolographicTheme.primaryEnergy, width: 2),
                shadowColor: HolographicTheme.primaryEnergy.withOpacity(0.5),
                elevation: 8,
              ),
              child: _isGenerating 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: HolographicTheme.primaryEnergy,
                      strokeWidth: 2,
                    ),
                  )
                : Text('GENERATE AI', style: TextStyle(fontSize: 10)),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _generateAIPreset(String description) async {
    if (description.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe the sound you want to create'),
          backgroundColor: HolographicTheme.primaryEnergy.withOpacity(0.8),
        ),
      );
      return;
    }
    
    setState(() => _isGenerating = true);
    
    try {
      final firebaseService = context.read<FirebaseService?>();
      final synthModel = Provider.of<SynthParametersModel>(context, listen: false);
      
      if (firebaseService == null) {
        throw Exception('Firebase not initialized');
      }
      
      // Generate AI preset using Firebase Cloud Functions
      final aiParameters = await firebaseService.generateAIPreset(description);
      
      if (aiParameters != null) {
        // Apply AI-generated parameters to synthesizer
        synthModel.loadParameters(aiParameters);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎵 AI preset generated and applied!'),
            backgroundColor: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Show save dialog
        _showSavePresetDialog(description, aiParameters);
      } else {
        throw Exception('Failed to generate preset');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate AI preset: ${e.toString()}'),
          backgroundColor: Colors.red.withOpacity(0.8),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }
  
  void _showSavePresetDialog(String description, SynthParameters parameters) {
    final TextEditingController nameController = TextEditingController();
    nameController.text = description.length > 30 
        ? description.substring(0, 30) + '...' 
        : description;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: Text(
            'Save AI Preset',
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              shadows: [Shadow(color: HolographicTheme.primaryEnergy, blurRadius: 4)],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Preset Name',
                  labelStyle: TextStyle(color: HolographicTheme.primaryEnergy.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: HolographicTheme.primaryEnergy, width: 2),
                  ),
                ),
                style: TextStyle(color: HolographicTheme.primaryEnergy),
              ),
              SizedBox(height: 16),
              Text(
                'Description: $description',
                style: TextStyle(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: HolographicTheme.primaryEnergy.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: () async {
                await _savePreset(nameController.text, description, parameters);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HolographicTheme.primaryEnergy.withOpacity(0.2),
                foregroundColor: HolographicTheme.primaryEnergy,
                side: BorderSide(color: HolographicTheme.primaryEnergy),
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _savePreset(String name, String description, SynthParameters parameters) async {
    try {
      final firebaseService = context.read<FirebaseService?>();
      
      if (firebaseService == null) {
        throw Exception('Firebase not initialized');
      }
      
      final presetId = await firebaseService.savePreset(
        name: name,
        description: description,
        parameters: parameters,
        isPublic: false, // Private by default
        tags: _extractTags(description),
      );
      
      if (presetId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Preset saved successfully!'),
            backgroundColor: HolographicTheme.secondaryEnergy.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preset: ${e.toString()}'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
    }
  }
  
  List<String> _extractTags(String description) {
    final words = description.toLowerCase().split(' ');
    final musicTerms = ['bass', 'lead', 'pad', 'arp', 'drum', 'ambient', 'house', 'techno', 'trance', 'dubstep'];
    return words.where((word) => musicTerms.contains(word)).toList();
  }

  void _pressKey(int midiNote) {
    setState(() => _pressedKeys.add(midiNote));
    // Connect to audio engine
    try {
      final audioEngine = Provider.of<AudioEngine>(context, listen: false);
      audioEngine.noteOn(midiNote, 100);
    } catch (e) {
      print('Audio engine not available: $e');
    }
  }

  void _releaseKey(int midiNote) {
    setState(() => _pressedKeys.remove(midiNote));
    try {
      final audioEngine = Provider.of<AudioEngine>(context, listen: false);
      audioEngine.noteOff(midiNote);
    } catch (e) {
      print('Audio engine not available: $e');
    }
  }
}

class InteractiveXYPainter extends CustomPainter {
  final double x, y;
  
  InteractiveXYPainter(this.x, this.y);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid lines
    final gridPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.2)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    // Vertical grid lines
    for (int i = 1; i < 4; i++) {
      final x = size.width * (i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    // Horizontal grid lines
    for (int i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Current position lines
    final positionPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final centerX = size.width * x;
    final centerY = size.height * (1 - y);
    
    // Position lines
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), positionPaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), positionPaint);
    
    // Center control point
    final centerPaint = Paint()
      ..color = HolographicTheme.primaryEnergy
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(centerX, centerY), 8, centerPaint);
    
    // Glow ring
    final glowPaint = Paint()
      ..color = HolographicTheme.primaryEnergy.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(Offset(centerX, centerY), 15, glowPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class InteractiveKnobPainter extends CustomPainter {
  final double value;
  final Color color;
  
  InteractiveKnobPainter(this.value, this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    
    // Background arc
    final bgPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Value arc
    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = (value * 270) * (Math.pi / 180);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -135 * (Math.pi / 180),
      sweepAngle,
      false,
      valuePaint,
    );
    
    // Indicator dot
    final angle = -135 + (value * 270);
    final radians = angle * (Math.pi / 180);
    final indicatorPos = Offset(
      center.dx + (radius - 10) * Math.cos(radians),
      center.dy + (radius - 10) * Math.sin(radians),
    );
    
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(indicatorPos, 4, dotPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}