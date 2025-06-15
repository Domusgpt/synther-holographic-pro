import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../holographic/holographic_widget.dart';
import '../holographic/holographic_theme.dart';

/// Individual key that can be moved independently
class SplitKey {
  final int midiNote;
  final String noteName;
  final bool isBlackKey;
  Offset position;
  Size size;
  bool isPressed;
  double velocity;
  
  SplitKey({
    required this.midiNote,
    required this.noteName,
    required this.isBlackKey,
    required this.position,
    required this.size,
    this.isPressed = false,
    this.velocity = 0.0,
  });
}

/// Holographic keyboard with split keys, octave selection, and bendwheels
class HolographicKeyboard extends StatefulWidget {
  final int octaveRange;
  final double keyWidth;
  final bool splitMode;
  final ValueChanged<int>? onNoteOn;
  final ValueChanged<int>? onNoteOff;
  final ValueChanged<double>? onPitchBend;
  final ValueChanged<double>? onModulation;
  final ValueChanged<int>? onOctaveChanged;
  final ValueChanged<double>? onKeyWidthChanged;
  final ValueChanged<bool>? onSplitModeChanged;
  final Color energyColor;
  
  const HolographicKeyboard({
    Key? key,
    this.octaveRange = 4,
    this.keyWidth = 40.0,
    this.splitMode = false,
    this.onNoteOn,
    this.onNoteOff,
    this.onPitchBend,
    this.onModulation,
    this.onOctaveChanged,
    this.onKeyWidthChanged,
    this.onSplitModeChanged,
    this.energyColor = HolographicTheme.secondaryEnergy,
  }) : super(key: key);
  
  @override
  State<HolographicKeyboard> createState() => _HolographicKeyboardState();
}

class _HolographicKeyboardState extends State<HolographicKeyboard>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  List<SplitKey> _keys = [];
  double _pitchBendValue = 0.0;
  double _modulationValue = 0.0;
  Set<int> _pressedKeys = {};
  
  // Bendwheel positions
  Offset _pitchWheelPosition = const Offset(20, 100);
  Offset _modWheelPosition = const Offset(60, 100);
  
  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
    
    _generateKeys();
  }
  
  @override
  void didUpdateWidget(HolographicKeyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.octaveRange != widget.octaveRange ||
        oldWidget.keyWidth != widget.keyWidth) {
      _generateKeys();
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  void _generateKeys() {
    _keys.clear();
    
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const blackKeyPattern = [false, true, false, true, false, false, true, false, true, false, true, false];
    
    double whiteKeyOffset = 0;
    
    for (int octave = 0; octave < 2; octave++) {
      for (int note = 0; note < 12; note++) {
        final midiNote = (widget.octaveRange * 12) + (octave * 12) + note;
        final noteName = noteNames[note] + (widget.octaveRange + octave).toString();
        final isBlackKey = blackKeyPattern[note];
        
        if (isBlackKey) {
          // Black key - positioned between white keys
          _keys.add(SplitKey(
            midiNote: midiNote,
            noteName: noteName,
            isBlackKey: true,
            position: Offset(
              whiteKeyOffset - (widget.keyWidth * 0.3),
              0,
            ),
            size: Size(widget.keyWidth * 0.6, 80),
          ));
        } else {
          // White key
          _keys.add(SplitKey(
            midiNote: midiNote,
            noteName: noteName,
            isBlackKey: false,
            position: Offset(whiteKeyOffset, 0),
            size: Size(widget.keyWidth, 120),
          ));
          whiteKeyOffset += widget.keyWidth;
        }
      }
    }
  }
  
  void _onKeyPressed(SplitKey key, double velocity) {
    setState(() {
      key.isPressed = true;
      key.velocity = velocity; // Store the actual velocity
      _pressedKeys.add(key.midiNote);
    });
    // Call onNoteOn with the calculated velocity
    widget.onNoteOn?.call(key.midiNote, velocity);
  }
  
  void _onKeyReleased(SplitKey key) {
    setState(() {
      key.isPressed = false;
      key.velocity = 0.0;
      _pressedKeys.remove(key.midiNote);
    });
    widget.onNoteOff?.call(key.midiNote);
  }
  
  void _onKeyDragged(SplitKey key, Offset delta) {
    if (widget.splitMode) {
      setState(() {
        key.position += delta;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return HolographicWidget(
      title: 'KEYBOARD',
      energyColor: widget.energyColor,
      minWidth: 400,
      minHeight: 200,
      child: Column(
        children: [
          // Control panel
          _buildControlPanel(),
          
          // Keyboard area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  // Keys
                  ..._keys.map((key) => _buildKey(key)),
                  
                  // Pitch bend wheel
                  _buildPitchWheel(),
                  
                  // Modulation wheel
                  _buildModWheel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Octave selector
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OCTAVE',
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              HolographicDropdown<int>(
                value: widget.octaveRange,
                hint: 'Octave',
                energyColor: widget.energyColor,
                items: List.generate(11, (index) {
                  final octave = index - 1;
                  return DropdownMenuItem(
                    value: octave,
                    child: Text(
                      'C$octave',
                      style: HolographicTheme.createHolographicText(
                        energyColor: widget.energyColor,
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    widget.onOctaveChanged?.call(value);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Key width slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEY WIDTH',
                  style: HolographicTheme.createHolographicText(
                    energyColor: widget.energyColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.energyColor,
                    inactiveTrackColor: widget.energyColor.withOpacity(0.3),
                    thumbColor: widget.energyColor,
                    trackHeight: 2.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.0,
                    ),
                  ),
                  child: Slider(
                    value: widget.keyWidth,
                    min: 20.0,
                    max: 80.0,
                    onChanged: (value) {
                      widget.onKeyWidthChanged?.call(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Split mode toggle
          Column(
            children: [
              Text(
                'SPLIT MODE',
                style: HolographicTheme.createHolographicText(
                  energyColor: widget.energyColor,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  widget.onSplitModeChanged?.call(!widget.splitMode);
                },
                child: Container(
                  width: 40,
                  height: 20,
                  decoration: HolographicTheme.createHolographicBorder(
                    energyColor: widget.energyColor,
                    intensity: widget.splitMode ? 1.5 : 0.7,
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    alignment: widget.splitMode 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: widget.energyColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          HolographicTheme.createEnergyGlow(
                            color: widget.energyColor,
                            radius: 4.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildKey(SplitKey key) {
    return Positioned(
      left: key.position.dx,
      top: key.position.dy,
      // Use a Builder to get the correct RenderBox for the key to calculate local Y position accurately
      // relative to the key itself, not just the GestureDetector.
      // However, GestureDetector's onTapDown details.localPosition is already relative to the GestureDetector.
      // If the GestureDetector is the same size as the key, this is fine.
      child: GestureDetector(
        onTapDown: (details) {
          // Ensure key.size.height is not zero to avoid division by zero.
          if (key.size.height == 0) return;

          final keyHeight = key.size.height;
          // Clamp localPosition.dy to be within the key's bounds (0 to keyHeight)
          final localDy = details.localPosition.dy.clamp(0.0, keyHeight);

          // Normalize Y position: 0.0 at the top of the key, 1.0 at the bottom.
          final normalizedY = localDy / keyHeight;

          // Velocity: higher Y (further down the key) = higher velocity.
          // Map [0.0, 1.0] to [0.2, 1.0] (minVelocity 0.2, range 0.8)
          final calculatedVelocity = (normalizedY * 0.8) + 0.2;

          // Pass calculated velocity, ensuring it's clamped between 0.1 and 1.0
          _onKeyPressed(key, calculatedVelocity.clamp(0.1, 1.0));
        },
        onTapUp: (_) => _onKeyReleased(key),
        onTapCancel: () => _onKeyReleased(key),
        onPanUpdate: widget.splitMode 
            ? (details) => _onKeyDragged(key, details.delta)
            : null,
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            final glowIntensity = key.isPressed 
                ? 2.0 
                : _glowAnimation.value;
            
            return Container(
              width: key.size.width,
              height: key.size.height,
              decoration: BoxDecoration(
                color: key.isBlackKey 
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.energyColor.withOpacity(
                    key.isPressed ? 1.0 : 0.6,
                  ),
                  width: key.isPressed ? 2.0 : 1.0,
                ),
                boxShadow: [
                  HolographicTheme.createEnergyGlow(
                    color: widget.energyColor,
                    intensity: glowIntensity,
                    radius: key.isPressed ? 12.0 : 6.0,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Key label
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Text(
                      key.noteName,
                      textAlign: TextAlign.center,
                      style: HolographicTheme.createHolographicText(
                        energyColor: key.isBlackKey 
                            ? widget.energyColor 
                            : widget.energyColor.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  
                  // Velocity indicator
                  if (key.isPressed)
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: widget.energyColor,
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            HolographicTheme.createEnergyGlow(
                              color: widget.energyColor,
                              radius: 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Drag handle for split mode
                  if (widget.splitMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.drag_indicator,
                        color: widget.energyColor.withOpacity(0.5),
                        size: 12,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildPitchWheel() {
    return Positioned(
      left: _pitchWheelPosition.dx,
      top: _pitchWheelPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _pitchWheelPosition += details.delta;
            _pitchBendValue = (_pitchWheelPosition.dy - 100) / 50;
            _pitchBendValue = _pitchBendValue.clamp(-1.0, 1.0);
          });
          widget.onPitchBend?.call(_pitchBendValue);
        },
        child: Container(
          width: 30,
          height: 100,
          decoration: HolographicTheme.createHolographicBorder(
            energyColor: HolographicTheme.warningEnergy,
            cornerRadius: 15,
          ),
          child: Stack(
            children: [
              // Background track
              Positioned(
                left: 10,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 10,
                  decoration: BoxDecoration(
                    color: HolographicTheme.warningEnergy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              
              // Thumb
              Positioned(
                left: 5,
                top: 45 + (_pitchBendValue * 20),
                child: Container(
                  width: 20,
                  height: 10,
                  decoration: BoxDecoration(
                    color: HolographicTheme.warningEnergy,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      HolographicTheme.createEnergyGlow(
                        color: HolographicTheme.warningEnergy,
                        radius: 4.0,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Label
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Text(
                  'PITCH',
                  textAlign: TextAlign.center,
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.warningEnergy,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildModWheel() {
    return Positioned(
      left: _modWheelPosition.dx,
      top: _modWheelPosition.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _modWheelPosition += details.delta;
            _modulationValue = (100 - _modWheelPosition.dy) / 100;
            _modulationValue = _modulationValue.clamp(0.0, 1.0);
          });
          widget.onModulation?.call(_modulationValue);
        },
        child: Container(
          width: 30,
          height: 100,
          decoration: HolographicTheme.createHolographicBorder(
            energyColor: HolographicTheme.successEnergy,
            cornerRadius: 15,
          ),
          child: Stack(
            children: [
              // Background track
              Positioned(
                left: 10,
                top: 10,
                bottom: 10,
                child: Container(
                  width: 10,
                  decoration: BoxDecoration(
                    color: HolographicTheme.successEnergy.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              
              // Thumb
              Positioned(
                left: 5,
                top: 80 - (_modulationValue * 70),
                child: Container(
                  width: 20,
                  height: 10,
                  decoration: BoxDecoration(
                    color: HolographicTheme.successEnergy,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      HolographicTheme.createEnergyGlow(
                        color: HolographicTheme.successEnergy,
                        radius: 4.0,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Label
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Text(
                  'MOD',
                  textAlign: TextAlign.center,
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.successEnergy,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}