import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import 'dart:math' as math; // For black key positioning
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel
import '../../core/ffi/native_audio_ffi.dart'; // Import for NativeAudioLib
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
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  final int minOctave;
  final int maxOctave;
  final int initialOctave;
  final int numWhiteKeysToDisplay;

  const VirtualKeyboardWidget({
    Key? key,
    this.initialSize = const Size(600, 150),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
    this.minOctave = 0,
    this.maxOctave = 7,
    this.initialOctave = 3,
    this.numWhiteKeysToDisplay = 14,
  }) : super(key: key);

  @override
  State<VirtualKeyboardWidget> createState() => _VirtualKeyboardWidgetState();
}

class _VirtualKeyboardWidgetState extends State<VirtualKeyboardWidget> {
  late bool _isCollapsed;
  late Size _currentSize;
  late int _currentOctave;
  double _velocity = 100.0 / 127.0;

  late double _keyWidthFactor;
  late int _numVisibleWhiteKeysActual;

  MusicalScale _selectedScale = MusicalScale.Chromatic;
  int _selectedRootNoteMidiOffset = 0;
  final Set<int> _notesInCurrentScale = {};

  final Set<int> _pressedKeys = {};
  final NativeAudioLib _nativeAudioLib = NativeAudioLib(); // Instance of FFI bridge

  double _initialKeyWidthFactorForPinch = 1.0;
  ScaleUpdateDetails? _lastScaleDetails;
  double _octaveScrollAccumulator = 0.0;

  static const int notesInOctave = 12;
  static const List<bool> _isBlackKeyMap = [false, true, false, true, false, false, true, false, true, false, true, false];
  static const List<double> _blackKeyOffsets = [0.0, 0.60, 0.0, 0.70, 0.0, 0.0, 0.55, 0.0, 0.65, 0.0, 0.75, 0.0];
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
    _updateNotesInScale();
  }

  void _updateNotesInScale() {
    _notesInCurrentScale.clear();
    if (scaleIntervals.containsKey(_selectedScale)) {
      for (int interval in scaleIntervals[_selectedScale]!) {
        _notesInCurrentScale.add((_selectedRootNoteMidiOffset + interval) % 12);
      }
    }
    _releaseAllNotes();
    if(mounted) setState(() {});
  }

  void _onNoteOn(int keyMidiOffset) {
    int noteChromaticOffsetInKey = keyMidiOffset % 12;
    if (_selectedScale != MusicalScale.Chromatic && !_notesInCurrentScale.contains(noteChromaticOffsetInKey)) {
      return;
    }

    final midiNote = (_currentOctave * notesInOctave) + keyMidiOffset;
    if (midiNote > 127) return;

    if (!_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      int currentVelocity = (_velocity * 127).round();
      model.noteOn(midiNote, currentVelocity);

      // Placeholder for Polyphonic Aftertouch: Send a fixed aftertouch value shortly after note-on for testing.
      // In a real scenario, this would come from continuous pressure data from Listener.onPointerMove or similar.
      // TODO: Remove this placeholder and implement actual aftertouch gesture detection.
      Future.delayed(const Duration(milliseconds: 150), () { // Delay slightly more
        if (_pressedKeys.contains(midiNote)) { // Check if key is still pressed
          int placeholderPressure = 80; // Example pressure value 0-127
          print("Keyboard: Sending Polyphonic Aftertouch for note $midiNote with pressure $placeholderPressure (placeholder call)");
          _nativeAudioLib.sendPolyAftertouch(midiNote, placeholderPressure);

          // Example of varying pressure for testing:
          // Future.delayed(const Duration(milliseconds: 300), () {
          //   if (_pressedKeys.contains(midiNote)) {
          //     _nativeAudioLib.sendPolyAftertouch(midiNote, 120);
          //      print("Keyboard: Poly AT $midiNote updated to 120");
          //   }
          // });
        }
      });

      setState(() {
        _pressedKeys.add(midiNote);
      });
    }
  }

  void _onNoteOff(int keyMidiOffset) {
    final midiNote = (_currentOctave * notesInOctave) + keyMidiOffset;
    if (midiNote > 127) return;

    if (_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOff(midiNote);
      // Also send poly aftertouch of 0 when note is released
      // print("Keyboard: Sending Polyphonic Aftertouch for note $midiNote with pressure 0 (note-off)");
      // _nativeAudioLib.sendPolyAftertouch(midiNote, 0); // Pressure 0 on note off
      setState(() {
        _pressedKeys.remove(midiNote);
      });
    }
  }

  void _releaseAllNotes() {
    final model = context.read<SynthParametersModel>();
    for (int note in _pressedKeys) {
      model.noteOff(note);
      // _nativeAudioLib.sendPolyAftertouch(note, 0); // Pressure 0 on note off
    }
    setState(() {
      _pressedKeys.clear();
    });
  }

  // ... (rest of the _build methods remain the same as current version)
  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 1.8),
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
              if (!_isCollapsed) _releaseAllNotes();
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
              min: 0.5, max: 2.0, divisions: 15,
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
              min: 7,
              max: 28,
              divisions: 21,
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
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          decoration: BoxDecoration(
            color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int>(
            value: _selectedRootNoteMidiOffset,
            isDense: true,
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5),
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
                HapticFeedback.selectionClick();
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
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5),
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
                HapticFeedback.selectionClick();
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
        const List<int> whiteKeyChromaticIndex = [0, 2, 4, 5, 7, 9, 11];

        for (int i = 0; i < _numVisibleWhiteKeysActual; i++) {
          int octaveOffset = i ~/ 7;
          int whiteKeyIndexInVisualOctave = i % 7;
          int chromaticNoteIndex = whiteKeyChromaticIndex[whiteKeyIndexInVisualOctave];
          int keyMidiOffset = octaveOffset * notesInOctave + chromaticNoteIndex;
          final bool isPressed = _pressedKeys.contains((_currentOctave * notesInOctave) + keyMidiOffset);
          keyWidgets.add(
            Positioned(
              left: i * actualWhiteKeyWidth, top: 0, width: actualWhiteKeyWidth, height: whiteKeyHeight,
              child: _buildKey(isBlack: false, width: actualWhiteKeyWidth, height: whiteKeyHeight, keyMidiOffset: keyMidiOffset, isPressed: isPressed,),
            ),
          );
        }

        for (int i = 0; i < _numVisibleWhiteKeysActual -1; i++) {
            int currentWhiteVisualOctave = i ~/ 7;
            int currentWhiteVisualIndexInOctave = i % 7;
            int currentWhiteChromaticIndex = whiteKeyChromaticIndex[currentWhiteVisualIndexInOctave];
            int currentWhiteKeyMidiOffset = currentWhiteVisualOctave * notesInOctave + currentWhiteChromaticIndex;
            int potentialBlackKeyMidiOffset = currentWhiteKeyMidiOffset + 1;

            if (_isBlackKeyMap[potentialBlackKeyMidiOffset % notesInOctave]) {
                final bool isPressed = _pressedKeys.contains((_currentOctave * notesInOctave) + potentialBlackKeyMidiOffset);
                double blackKeyVisualOffsetFactor = _blackKeyOffsets[potentialBlackKeyMidiOffset % notesInOctave];
                keyWidgets.add(
                    Positioned(
                    left: (i * actualWhiteKeyWidth) + (actualWhiteKeyWidth * blackKeyVisualOffsetFactor) - (blackKeyActualWidth * 0.1),
                    top: 0, width: blackKeyActualWidth, height: blackKeyActualHeight,
                    child: _buildKey(isBlack: true, width: blackKeyActualWidth, height: blackKeyActualHeight, keyMidiOffset: potentialBlackKeyMidiOffset, isPressed: isPressed,),
                    ),
                );
            }
        }
        final double totalKeysWidth = actualWhiteKeyWidth * _numVisibleWhiteKeysActual;
        return GestureDetector(
          onScaleStart: (details) {
            _initialKeyWidthFactorForPinch = _keyWidthFactor;
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
          },
          onScaleUpdate: (details) {
            if (details.pointerCount == 2 || (details.pointerCount == 1 && _lastScaleDetails?.pointerCount == 2) ) {
              if (details.scale != 1.0) {
                _releaseAllNotes();
                setState(() { _keyWidthFactor = (_initialKeyWidthFactorForPinch * details.scale).clamp(0.3, 3.0); });
                HapticFeedback.lightImpact();
              }
            }
            else if (details.pointerCount >= 3) {
              if (_lastScaleDetails != null) {
                double dx = details.focalPointDelta.dx;
                _octaveScrollAccumulator += dx;
                double changeThreshold = actualWhiteKeyWidth * 3;
                if (_octaveScrollAccumulator > changeThreshold) {
                  if (_currentOctave < widget.maxOctave) { _releaseAllNotes(); setState(() { _currentOctave++; }); HapticFeedback.selectionClick(); }
                  _octaveScrollAccumulator = 0;
                } else if (_octaveScrollAccumulator < -changeThreshold) {
                  if (_currentOctave > widget.minOctave) { _releaseAllNotes(); setState(() { _currentOctave--; }); HapticFeedback.selectionClick(); }
                  _octaveScrollAccumulator = 0;
                }
              }
            }
            _lastScaleDetails = details;
          },
          onScaleEnd: (details) {
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: _lastScaleDetails != null && _lastScaleDetails!.pointerCount > 1
                ? const NeverScrollableScrollPhysics()
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
    required int keyMidiOffset,
    required bool isPressed,
  }) {
    int noteChromaticIndexInOctave = keyMidiOffset % 12;
    bool isNoteInScale = _selectedScale == MusicalScale.Chromatic || _notesInCurrentScale.contains(noteChromaticIndexInOctave);
    Color keyColor;
    Color borderColor;
    double keyOpacityFactor = 1.0;

    if (_selectedScale != MusicalScale.Chromatic && !isNoteInScale) {
      keyOpacityFactor = 0.3;
    }

    if (isBlack) {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.2 * keyOpacityFactor);
      borderColor = HolographicTheme.secondaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    } else {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.6 * keyOpacityFactor);
      borderColor = HolographicTheme.primaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    }

    if (_selectedScale != MusicalScale.Chromatic && isNoteInScale && !isPressed) {
      borderColor = HolographicTheme.accentEnergy.withOpacity(0.9 * keyOpacityFactor);
      keyColor = keyColor.withAlpha((keyColor.alpha * 1.2).clamp(0,255).toInt());
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
            color: keyColor,
            borderRadius: BorderRadius.circular(isBlack ? 3 : 4),
            border: Border.all(color: borderColor, width: 1.0,),
             boxShadow: [ BoxShadow( color: borderColor.withOpacity(0.3 * keyOpacityFactor), blurRadius: 3, spreadRadius: 0.5, offset: Offset(0,1.5) ) ]
          );
    
    return Listener(
      onPointerDown: (_) {
        if (_selectedScale != MusicalScale.Chromatic && !isNoteInScale) return;
        _onNoteOn(keyMidiOffset);
      },
      onPointerUp: (_) => _onNoteOff(keyMidiOffset),
      onPointerCancel: (_) => _onNoteOff(keyMidiOffset),
      child: Container(
        width: width,
        height: height,
        margin: isBlack ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 0.75),
        decoration: decoration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _isCollapsed ? 280 : _currentSize.width,
      height: _isCollapsed ? 40 : _currentSize.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: HolographicTheme.primaryEnergy,
        intensity: 0.6,
        cornerRadius: 10,
      ).copyWith(
         color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.2),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5.0, 2.0, 5.0, 5.0),
                child: _buildKeyboardArea(),
              ),
            ),
        ],
      ),
    );
  }
}