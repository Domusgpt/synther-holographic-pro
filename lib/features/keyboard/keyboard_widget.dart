import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math; // For black key positioning
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel
import '../../ui/holographic/holographic_theme.dart';


/// A widget that displays a piano keyboard for triggering notes, styled holographically.
class VirtualKeyboardWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged; // For future resizable frame
  final Function(bool)? onCollapsedChanged; // For collapse button interaction with frame

  final int minOctave;
  final int maxOctave;
  final int initialOctave; // The octave number for the first C key displayed
  final int numWhiteKeysToDisplay; // Determines the width of the keyboard visually

  const VirtualKeyboardWidget({
    Key? key,
    this.initialSize = const Size(600, 150),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
    this.minOctave = 0,
    this.maxOctave = 7,
    this.initialOctave = 3, // C3
    this.numWhiteKeysToDisplay = 14, // Roughly 2 octaves of white keys
  }) : super(key: key);

  @override
  State<VirtualKeyboardWidget> createState() => _VirtualKeyboardWidgetState();
}

class _VirtualKeyboardWidgetState extends State<VirtualKeyboardWidget> {
  late bool _isCollapsed;
  late Size _currentSize; // Actual size, can be changed by parent frame
  late int _currentOctave;
  double _velocity = 100.0 / 127.0; // Velocity (0.0 to 1.0)

  final Set<int> _pressedKeys = {}; // Tracks MIDI note numbers currently pressed

  // Key layout constants
  static const int notesInOctave = 12;
  static const List<bool> _isBlackKeyMap = [false, true, false, true, false, false, true, false, true, false, true, false]; // C, C#, D, D#, E, F, F#, G, G#, A, A#, B
  static const List<double> _blackKeyOffsets = [0.0, 0.60, 0.0, 0.70, 0.0, 0.0, 0.55, 0.0, 0.65, 0.0, 0.75, 0.0]; // Visual offset for black keys
  static const double blackKeyWidthFactor = 0.65;
  static const double blackKeyHeightFactor = 0.6;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _currentOctave = widget.initialOctave.clamp(widget.minOctave, widget.maxOctave);
  }

  void _onNoteOn(int keyIndexRelativeToOctaveStart) {
    final midiNote = (_currentOctave * notesInOctave) + keyIndexRelativeToOctaveStart;
    if (midiNote > 127) return;

    if (!_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOn(midiNote, (_velocity * 127).round());
      setState(() {
        _pressedKeys.add(midiNote);
      });
    }
  }

  void _onNoteOff(int keyIndexRelativeToOctaveStart) {
    final midiNote = (_currentOctave * notesInOctave) + keyIndexRelativeToOctaveStart;
    if (midiNote > 127) return;

    if (_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOff(midiNote);
      setState(() {
        _pressedKeys.remove(midiNote);
      });
    }
  }
  
  void _releaseAllNotes() {
    final model = context.read<SynthParametersModel>();
    for (int note in _pressedKeys) {
      model.noteOff(note);
    }
    setState(() {
      _pressedKeys.clear();
    });
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 1.8), // Slightly more opaque header
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.6), width: 1)),
      ),
      child: Row(
        children: [
          Text('VIRTUAL KEYBOARD', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
          const Spacer(),
          _buildOctaveControls(),
          const SizedBox(width: 10),
          _buildVelocitySlider(),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(_isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: HolographicTheme.primaryEnergy),
            onPressed: () {
              if (!_isCollapsed) _releaseAllNotes(); // Release notes when collapsing
              setState(() { _isCollapsed = !_isCollapsed; });
              widget.onCollapsedChanged?.call(_isCollapsed);
            },
            iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildOctaveControls() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: HolographicTheme.secondaryEnergy, size: 18),
          onPressed: _currentOctave > widget.minOctave ? () { _releaseAllNotes(); setState(() { _currentOctave--; }); } : null,
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30), splashRadius: 15,
        ),
        Text('OCT: $_currentOctave', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 11, glowIntensity: 0.3)),
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: HolographicTheme.secondaryEnergy, size: 18),
          onPressed: _currentOctave < widget.maxOctave ? () { _releaseAllNotes(); setState(() { _currentOctave++; }); } : null,
          padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 30, minHeight: 30), splashRadius: 15,
        ),
      ],
    );
  }

  Widget _buildVelocitySlider() {
    return Row(
      children: [
        Text('VEL:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
        SizedBox(
          width: 80,
          height: 20,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: HolographicTheme.accentEnergy,
              activeTrackColor: HolographicTheme.accentEnergy.withOpacity(0.7),
              inactiveTrackColor: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 2),
              overlayColor: HolographicTheme.accentEnergy.withOpacity(0.25),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
              trackHeight: 2.5,
            ),
            child: Slider(
              value: _velocity * 127.0,
              min: 0,
              max: 127,
              divisions: 127,
              onChanged: (value) {
                setState(() {
                  _velocity = value / 127.0;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink(); // Avoid division by zero if constraints are zero
        }
        final double whiteKeyWidth = constraints.maxWidth / widget.numWhiteKeysToDisplay;
        final double whiteKeyHeight = constraints.maxHeight;
        final double blackKeyActualWidth = whiteKeyWidth * blackKeyWidthFactor;
        final double blackKeyActualHeight = whiteKeyHeight * blackKeyHeightFactor;

        List<Widget> keyWidgets = [];

        // Draw white keys
        for (int i = 0; i < widget.numWhiteKeysToDisplay; i++) {
          int noteOffset = 0; // Calculate the actual note index in a chromatic scale from C
          int whiteKeyCounter = 0;
          for(int j=0; j < notesInOctave * 2 ; j++){ // Iterate over chromatic scale to find the i-th white key
              if(!_isBlackKeyMap[j % notesInOctave]){
                  if(whiteKeyCounter == i){
                      noteOffset = j;
                      break;
                  }
                  whiteKeyCounter++;
              }
          }
          // Adjust noteOffset for display across multiple visual octaves if numWhiteKeysToDisplay > 7
          noteOffset = noteOffset % notesInOctave;
          // This simple noteOffset calculation needs to be fixed for proper multi-octave display
          // For now, let's assume widget.numWhiteKeysToDisplay means keys within one or two octaves starting from C
          // A more robust way:
          int keyMidiIndex = 0;
          int countWhite = 0;
          for (int k = 0; k < notesInOctave * (widget.numWhiteKeysToDisplay ~/ 7 + 1) ; k++) {
              if (!_isBlackKeyMap[k % notesInOctave]) {
                  if (countWhite == i) {
                      keyMidiIndex = k;
                      break;
                  }
                  countWhite++;
              }
          }


          final midiNote = (_currentOctave * notesInOctave) + keyMidiIndex;
          final bool isPressed = _pressedKeys.contains(midiNote);

          keyWidgets.add(
            Positioned(
              left: i * whiteKeyWidth,
              top: 0,
              width: whiteKeyWidth,
              height: whiteKeyHeight,
              child: _buildKey(
                isBlack: false,
                width: whiteKeyWidth,
                height: whiteKeyHeight,
                noteIndexInOctave: keyMidiIndex, // This is the index relative to the start of the current octave view
                isPressed: isPressed,
              ),
            ),
          );
        }

        // Draw black keys
        int blackKeyCount = 0;
        for (int i = 0; i < widget.numWhiteKeysToDisplay -1; i++) { // -1 because black key is between white keys
            int whiteKeyMidiIndex = 0;
            int countWhite = 0;
            for (int k = 0; k < notesInOctave * (widget.numWhiteKeysToDisplay ~/ 7 + 1); k++) {
                if (!_isBlackKeyMap[k % notesInOctave]) {
                    if (countWhite == i) {
                        whiteKeyMidiIndex = k;
                        break;
                    }
                    countWhite++;
                }
            }

            // Check if a black key should follow this white key
            // The note index for the black key is whiteKeyMidiIndex + 1
            int blackKeyNoteIndex = (whiteKeyMidiIndex + 1);
            if (_isBlackKeyMap[blackKeyNoteIndex % notesInOctave]) {
                final midiNote = (_currentOctave * notesInOctave) + blackKeyNoteIndex;
                final bool isPressed = _pressedKeys.contains(midiNote);

                // Calculate visual offset: it's after the i-th white key
                // The offset is relative to the start of the white key it's "attached" to
                double blackKeyRelativeOffset = _blackKeyOffsets[blackKeyNoteIndex % notesInOctave];
                 // This needs to be based on the white key it's conceptually "after"
                double whiteKeyStartPosition = i * whiteKeyWidth;


                keyWidgets.add(
                    Positioned(
                    left: whiteKeyStartPosition + (whiteKeyWidth * blackKeyRelativeOffset) - (blackKeyActualWidth * 0.0), // Adjust centering
                    top: 0,
                    width: blackKeyActualWidth,
                    height: blackKeyActualHeight,
                    child: _buildKey(
                        isBlack: true,
                        width: blackKeyActualWidth,
                        height: blackKeyActualHeight,
                        noteIndexInOctave: blackKeyNoteIndex,
                        isPressed: isPressed,
                    ),
                    ),
                );
                blackKeyCount++;
            }
        }
        return Stack(children: keyWidgets);
      },
    );
  }

  Widget _buildKey({
    required bool isBlack,
    required double width,
    required double height,
    required int noteIndexInOctave, // Relative to the start of the displayed keyboard range
    required bool isPressed,
  }) {
    Color keyColor = isBlack
        ? HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.0)
        : HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.5);
    Color borderColor = isBlack ? HolographicTheme.secondaryEnergy : HolographicTheme.primaryEnergy;

    BoxDecoration decoration = isPressed
        ? HolographicTheme.createHolographicBorder(
            energyColor: HolographicTheme.glowColor,
            intensity: 2.0, // More intense glow when pressed
            cornerRadius: isBlack ? 2 : 3,
            borderWidth: 1.5,
          ).copyWith(
            color: HolographicTheme.glowColor.withOpacity(HolographicTheme.activeTransparency * 1.5)
          )
        : BoxDecoration(
            color: keyColor,
            borderRadius: BorderRadius.circular(isBlack ? 2 : 3),
            border: Border.all(
              color: borderColor.withOpacity(0.6),
              width: 0.8,
            ),
             boxShadow: [ // Subtle shadow for depth
                BoxShadow(
                    color: borderColor.withOpacity(0.25),
                    blurRadius: 2,
                    spreadRadius: -0.5,
                    offset: Offset(0,1)
                )
            ]
          );
    
    return Listener(
      onPointerDown: (_) => _onNoteOn(noteIndexInOctave),
      onPointerUp: (_) => _onNoteOff(noteIndexInOctave),
      onPointerCancel: (_) => _onNoteOff(noteIndexInOctave),
      child: Container(
        width: width,
        height: height,
        margin: isBlack ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 0.5),
        decoration: decoration,
        // Optionally, add note labels here if needed, styled with HolographicTheme.createHolographicText
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The main container for the keyboard, applying overall holographic border
    return Container(
      width: _isCollapsed ? 280 : _currentSize.width, // Fixed width when collapsed for controls
      height: _isCollapsed ? 40 : _currentSize.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: HolographicTheme.primaryEnergy,
        intensity: 0.6, // Slightly less intense border for the whole widget
        cornerRadius: 10,
      ).copyWith(
         color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.2), // Very transparent base
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 5.0), // Padding around keyboard area
                child: _buildKeyboardArea(),
              ),
            ),
        ],
      ),
    );
  }
}