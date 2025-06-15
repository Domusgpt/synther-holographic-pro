import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math; // For black key positioning
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel
import '../../ui/holographic/holographic_theme.dart';

// --- Musical Scale Definitions ---
enum MusicalScale { Chromatic, Major, MinorNatural, MinorHarmonic, MinorMelodic, PentatonicMajor, PentatonicMinor, Blues, Dorian, Mixolydian }

const List<String> rootNoteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

final Map<MusicalScale, List<int>> scaleIntervals = {
  MusicalScale.Chromatic: [0,1,2,3,4,5,6,7,8,9,10,11],
  MusicalScale.Major: [0,2,4,5,7,9,11],
  MusicalScale.MinorNatural: [0,2,3,5,7,8,10],
  MusicalScale.MinorHarmonic: [0,2,3,5,7,8,11],
  MusicalScale.MinorMelodic: [0,2,3,5,7,9,11], // Ascending
  MusicalScale.PentatonicMajor: [0,2,4,7,9],
  MusicalScale.PentatonicMinor: [0,3,5,7,10],
  MusicalScale.Blues: [0,3,5,6,7,10],
  MusicalScale.Dorian: [0,2,3,5,7,9,10],
  MusicalScale.Mixolydian: [0,2,4,5,7,9,10],
};
// --- End Musical Scale Definitions ---


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
  late Size _currentSize;
  late int _currentOctave;
  double _velocity = 100.0 / 127.0;

  // New state variables for adjustable key size and range
  late double _keyWidthFactor;
  late int _numVisibleWhiteKeysActual;

  // State variables for scale and key selection
  MusicalScale _selectedScale = MusicalScale.Chromatic;
  int _selectedRootNoteMidiOffset = 0; // 0 for C, 1 for C#, etc.
  final Set<int> _notesInCurrentScale = {}; // Holds MIDI note offsets (0-11) for the current scale & key

  final Set<int> _pressedKeys = {};

  // Gesture-related state
  double _initialKeyWidthFactorForPinch = 1.0;
  // int _initialNumVisibleWhiteKeysForPinch = 14; // For scaling number of keys, if implemented
  ScaleUpdateDetails? _lastScaleDetails; // To detect horizontal pan during pinch for octave
  double _octaveScrollAccumulator = 0.0; // Accumulates horizontal drag for octave change

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
    _keyWidthFactor = 1.0;
    _numVisibleWhiteKeysActual = widget.numWhiteKeysToDisplay.clamp(7, 28);
    _updateNotesInScale(); // Initialize notes in scale
  }

  void _updateNotesInScale() {
    _notesInCurrentScale.clear();
    if (scaleIntervals.containsKey(_selectedScale)) {
      for (int interval in scaleIntervals[_selectedScale]!) {
        _notesInCurrentScale.add((_selectedRootNoteMidiOffset + interval) % 12);
      }
    }
    _releaseAllNotes(); // Release notes when scale changes
    if(mounted) setState(() {});
  }

  void _onNoteOn(int keyMidiOffset) {
    // keyMidiOffset is the chromatic index (0-11) relative to the start of the *displayed* keyboard's first C
    // For scale conformance, we need its chromatic value within any octave (0-11)
    int noteChromaticOffsetInKey = keyMidiOffset % 12;
    if (_selectedScale != MusicalScale.Chromatic && !_notesInCurrentScale.contains(noteChromaticOffsetInKey)) {
      // If note is not in scale (and not chromatic mode), do not play it.
      return;
    }

    final midiNote = (_currentOctave * notesInOctave) + keyMidiOffset;
    if (midiNote > 127) return;

    if (!_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOn(midiNote, (_velocity * 127).round());
      setState(() {
        _pressedKeys.add(midiNote);
      });
    }
  }

  void _onNoteOff(int keyMidiOffset) { // Parameter is now MIDI offset from C of the current octave
    final midiNote = (_currentOctave * notesInOctave) + keyMidiOffset;
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
          const SizedBox(width: 12),
          _buildRootNoteSelector(),
          const SizedBox(width: 8),
          _buildScaleSelector(),
          const Spacer(),
          _buildKeySizeSlider(),
          const SizedBox(width: 8),
          _buildKeyRangeSlider(),
          const SizedBox(width: 8),
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

  Widget _buildKeySizeSlider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Size:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 10, glowIntensity: 0.2)),
        Container(
          width: 70, height: 20,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbColor: HolographicTheme.accentEnergy,
              activeTrackColor: HolographicTheme.accentEnergy.withOpacity(0.7),
              inactiveTrackColor: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.5),
              overlayColor: HolographicTheme.accentEnergy.withOpacity(0.25),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              trackHeight: 2.0,
            ),
            child: Slider(
              value: _keyWidthFactor,
              min: 0.5, max: 2.0, divisions: 15, // 0.5x to 2.0x
              onChanged: (value) { setState(() { _keyWidthFactor = value; }); },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyRangeSlider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Range:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 10, glowIntensity: 0.2)),
        Container(
          width: 70, height: 20,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
               thumbColor: HolographicTheme.accentEnergy,
              activeTrackColor: HolographicTheme.accentEnergy.withOpacity(0.7),
              inactiveTrackColor: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.5),
              overlayColor: HolographicTheme.accentEnergy.withOpacity(0.25),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              trackHeight: 2.0,
            ),
            child: Slider(
              value: _numVisibleWhiteKeysActual.toDouble(),
              min: 7,  // 1 octave of white keys
              max: 28, // 4 octaves of white keys
              divisions: 21, // (28-7)
              label: "$_numVisibleWhiteKeysActual keys",
              onChanged: (value) {
                _releaseAllNotes();
                setState(() { _numVisibleWhiteKeysActual = value.round(); });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRootNoteSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Root:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 10, glowIntensity: 0.2)),
        Container(
          height: 30, // Consistent height with other dropdowns/sliders in header
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: _selectedRootNoteMidiOffset,
            isDense: true,
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5), // Adjusted for more translucency
            underline: Container(),
            icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.accentEnergy.withOpacity(0.9), size: 18),
            items: rootNoteNames.asMap().entries.map((entry) {
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(entry.value, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() { _selectedRootNoteMidiOffset = value; });
                _updateNotesInScale();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScaleSelector() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text('Scale:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 10, glowIntensity: 0.2)),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
           decoration: BoxDecoration(
            color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<MusicalScale>(
            value: _selectedScale,
            isDense: true,
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5), // Adjusted for more translucency
            underline: Container(),
            icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.accentEnergy.withOpacity(0.9), size: 18),
            items: MusicalScale.values.map((MusicalScale scale) {
              return DropdownMenuItem<MusicalScale>(
                value: scale,
                child: Text(scale.name, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
              );
            }).toList(),
            onChanged: (MusicalScale? value) {
              if (value != null) {
                setState(() { _selectedScale = value; });
                _updateNotesInScale();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink();
        }
        final double baseWhiteKeyWidth = constraints.maxWidth / _numVisibleWhiteKeysActual;
        final double actualWhiteKeyWidth = (baseWhiteKeyWidth * _keyWidthFactor).clamp(10.0, 100.0);

        final double whiteKeyHeight = constraints.maxHeight;
        final double blackKeyActualWidth = actualWhiteKeyWidth * blackKeyWidthFactor;
        final double blackKeyActualHeight = whiteKeyHeight * blackKeyHeightFactor;

        List<Widget> keyWidgets = [];

        // This array maps a white key index (0-6 for C to B) to its chromatic index (0-11)
        const List<int> whiteKeyChromaticIndex = [0, 2, 4, 5, 7, 9, 11];

        for (int i = 0; i < _numVisibleWhiteKeysActual; i++) {
          // Determine the note properties for this visual white key
          int octaveOffset = i ~/ 7; // How many full C-to-B octaves we've passed visually
          int whiteKeyIndexInVisualOctave = i % 7; // Which white key within the current visual C-to-B (0-6)

          // Chromatic index (0-11) for this white key relative to C
          int chromaticNoteIndex = whiteKeyChromaticIndex[whiteKeyIndexInVisualOctave];
          // Full MIDI offset from the start of the *displayed* keyboard range's C
          int keyMidiOffset = octaveOffset * notesInOctave + chromaticNoteIndex;

          final bool isPressed = _pressedKeys.contains((_currentOctave * notesInOctave) + keyMidiOffset);

          keyWidgets.add(
            Positioned(
              left: i * actualWhiteKeyWidth,
              top: 0,
              width: actualWhiteKeyWidth,
              height: whiteKeyHeight,
              child: _buildKey(
                isBlack: false,
                width: actualWhiteKeyWidth,
                height: whiteKeyHeight,
                keyMidiOffset: keyMidiOffset,
                isPressed: isPressed,
              ),
            ),
          );
        }

        // Draw black keys
        for (int i = 0; i < _numVisibleWhiteKeysActual -1; i++) {
            // Calculate the chromatic index of the current white key
            int currentWhiteVisualOctave = i ~/ 7;
            int currentWhiteVisualIndexInOctave = i % 7;
            int currentWhiteChromaticIndex = whiteKeyChromaticIndex[currentWhiteVisualIndexInOctave];
            int currentWhiteKeyMidiOffset = currentWhiteVisualOctave * notesInOctave + currentWhiteChromaticIndex;

            // A black key exists if the *next* chromatic note is black
            int potentialBlackKeyMidiOffset = currentWhiteKeyMidiOffset + 1;

            if (_isBlackKeyMap[potentialBlackKeyMidiOffset % notesInOctave]) {
                final bool isPressed = _pressedKeys.contains((_currentOctave * notesInOctave) + potentialBlackKeyMidiOffset);

                // Offset for black key is relative to the white key it's conceptually "after"
                // _blackKeyOffsets maps chromatic index to its visual offset factor
                double blackKeyVisualOffsetFactor = _blackKeyOffsets[potentialBlackKeyMidiOffset % notesInOctave];

                keyWidgets.add(
                    Positioned(
                    left: (i * actualWhiteKeyWidth) + (actualWhiteKeyWidth * blackKeyVisualOffsetFactor) - (blackKeyActualWidth * 0.1), // Fine tune centering
                    top: 0,
                    width: blackKeyActualWidth,
                    height: blackKeyActualHeight,
                    child: _buildKey(
                        isBlack: true,
                        width: blackKeyActualWidth,
                        height: blackKeyActualHeight,
                        keyMidiOffset: potentialBlackKeyMidiOffset,
                        isPressed: isPressed,
                    ),
                    ),
                );
            }
        }

        // Total width of all keys for the scroll view content
        final double totalKeysWidth = actualWhiteKeyWidth * _numVisibleWhiteKeysActual;

        return GestureDetector(
          onScaleStart: (details) {
            _initialKeyWidthFactorForPinch = _keyWidthFactor;
            // _initialNumVisibleWhiteKeysForPinch = _numVisibleWhiteKeysActual; // If scaling num keys
            _lastScaleDetails = null; // Reset for octave scroll detection
            _octaveScrollAccumulator = 0.0;
          },
          onScaleUpdate: (details) {
            // Use two fingers for key size (pinch-to-zoom)
            if (details.pointerCount == 2 || (details.pointerCount == 1 && _lastScaleDetails?.pointerCount == 2) ) { // Allow finishing pinch with one finger up
              if (details.scale != 1.0) {
                _releaseAllNotes();
                setState(() {
                  _keyWidthFactor = (_initialKeyWidthFactorForPinch * details.scale).clamp(0.3, 3.0); // Wider clamp
                });
              }
            }
            // Use three (or more) finger horizontal pan for octave scroll
            // This is experimental and might conflict with other gestures or be hard to trigger.
            // A two-finger horizontal pan might be more common but conflicts with pinch-zoom's panning aspect.
            else if (details.pointerCount >= 3) {
              if (_lastScaleDetails != null) {
                // Using focalPointDelta for smoother panning feel with multiple fingers
                double dx = details.focalPointDelta.dx;
                _octaveScrollAccumulator += dx;

                // Heuristic: Define a threshold for octave change
                // Adjust sensitivity based on key width for a more consistent feel
                double changeThreshold = actualWhiteKeyWidth * 3; // e.g., drag 3 white keys width to change octave

                if (_octaveScrollAccumulator > changeThreshold) {
                  if (_currentOctave < widget.maxOctave) {
                    _releaseAllNotes();
                    setState(() { _currentOctave++; });
                  }
                  _octaveScrollAccumulator = 0; // Reset accumulator
                } else if (_octaveScrollAccumulator < -changeThreshold) {
                  if (_currentOctave > widget.minOctave) {
                    _releaseAllNotes();
                    setState(() { _currentOctave--; });
                  }
                  _octaveScrollAccumulator = 0; // Reset accumulator
                }
              }
            }
            _lastScaleDetails = details; // Store details for next update
          },
          onScaleEnd: (details) {
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: _lastScaleDetails != null && _lastScaleDetails!.pointerCount > 1
                ? const NeverScrollableScrollPhysics() // Disable scroll during multi-finger gestures
                : const BouncingScrollPhysics(),
            child: Container(
              width: totalKeysWidth,
              height: constraints.maxHeight,
              child: Stack(children: keyWidgets),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKey({
    required bool isBlack,
    required double width,
    required double height,
    required int keyMidiOffset, // MIDI offset from C of the *displayed* keyboard base octave
    required bool isPressed,
  }) {
    int noteChromaticIndexInOctave = keyMidiOffset % 12;
    bool isNoteInScale = _selectedScale == MusicalScale.Chromatic || _notesInCurrentScale.contains(noteChromaticIndexInOctave);

    Color keyColor;
    Color borderColor;
    double keyOpacityFactor = 1.0;

    if (_selectedScale != MusicalScale.Chromatic && !isNoteInScale) {
      keyOpacityFactor = 0.3; // Dim out-of-scale keys
    }

    if (isBlack) {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.2 * keyOpacityFactor);
      borderColor = HolographicTheme.secondaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    } else {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.6 * keyOpacityFactor);
      borderColor = HolographicTheme.primaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    }

    if (_selectedScale != MusicalScale.Chromatic && isNoteInScale && !isPressed) {
      // Highlight in-scale keys if a scale is selected
      borderColor = HolographicTheme.accentEnergy.withOpacity(0.9 * keyOpacityFactor);
      keyColor = keyColor.withAlpha((keyColor.alpha * 1.2).clamp(0,255).toInt()); // Slightly brighter fill
    }


    BoxDecoration decoration = isPressed
        ? HolographicTheme.createHolographicBorder(
            energyColor: HolographicTheme.glowColor,
            intensity: 2.2,
            cornerRadius: isBlack ? 3 : 4,
            borderWidth: 1.8,
          ).copyWith(
            color: HolographicTheme.glowColor.withOpacity(HolographicTheme.activeTransparency * 1.8)
          )
        : BoxDecoration(
            color: keyColor, // Uses modified keyColor
            borderRadius: BorderRadius.circular(isBlack ? 3 : 4),
            border: Border.all(
              color: borderColor, // Uses modified borderColor
              width: 1.0,
            ),
             boxShadow: [
                BoxShadow(
                    color: borderColor.withOpacity(0.3 * keyOpacityFactor),
                    blurRadius: 3,
                    spreadRadius: 0.5,
                    offset: Offset(0,1.5)
                )
            ]
          );
    
    return Listener(
      onPointerDown: (_) {
        if (_selectedScale != MusicalScale.Chromatic && !isNoteInScale) return; // Prevent playing out-of-scale notes
        _onNoteOn(keyMidiOffset);
      },
      onPointerUp: (_) => _onNoteOff(keyMidiOffset),
      onPointerCancel: (_) => _onNoteOff(keyMidiOffset),
      child: Container(
        width: width,
        height: height,
        margin: isBlack ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 0.75), // Slightly increased gap
        decoration: decoration,
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