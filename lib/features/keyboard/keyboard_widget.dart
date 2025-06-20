import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import 'dart:math' as math; // For math.sin, math.min, math.max
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel
import '../../core/ffi/native_audio_ffi_factory.dart';
import '../../ui/holographic/holographic_theme.dart';

// New imports for Keyboard Engine
import 'key_model.dart';
import 'keyboard_layout.dart';
import 'keyboard_layout_engine.dart';
import 'mpe_touch_handler.dart';
import '../../core/microtonal_defs.dart';
import 'keyboard_painter.dart';
import 'keyboard_theme.dart';

// Old MusicalScale definitions (to be removed/commented)
// enum MusicalScale { Chromatic, Major, MinorNatural, MinorHarmonic, MinorMelodic, PentatonicMajor, PentatonicMinor, Blues, Dorian, Mixolydian }
const List<String> rootNoteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']; // Still useful for root note selection
// final Map<MusicalScale, List<int>> scaleIntervals = { ... }; // No longer used directly here for scale logic


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

  late double _keyWidthFactor; // Controls visual zoom of keys
  late int _numVisibleWhiteKeysActual; // Determines how many white keys the layout is based on

  MicrotonalScale _selectedScale = MicrotonalScale.tet12; // Use new MicrotonalScale
  int _selectedRootNoteMidiOffset = 0; // For selecting root note for the scale
  // final Set<int> _notesInCurrentScale = {}; // Replaced by MicrotonalScale logic or painter logic

  final Set<int> _pressedKeys = {}; // Stores MIDI note numbers of pressed keys
  final Map<int, int> _activePointersToMidiNotes = {}; // Tracks active touch pointers
  final NativeAudioLibInterface _nativeAudioLib = createNativeAudioLib(); // Use interface
  late KeyboardLayoutEngine _layoutEngine;
  late MPETouchHandler _mpeTouchHandler;

  double _initialKeyWidthFactorForPinch = 1.0;
  ScaleUpdateDetails? _lastScaleDetails;
  double _octaveScrollAccumulator = 0.0;

  // Old constants for direct layout calculation (now handled by PianoLayout)
  // static const int notesInOctave = 12;
  // static const List<bool> _isBlackKeyMap = [...];
  // static const List<double> _blackKeyOffsets = [...];
  // static const double blackKeyWidthFactor = 0.65;
  // static const double blackKeyHeightFactor = 0.6;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _currentOctave = widget.initialOctave.clamp(widget.minOctave, widget.maxOctave);
    _keyWidthFactor = 1.0; // Initial visual zoom factor
    _numVisibleWhiteKeysActual = widget.numWhiteKeysToDisplay.clamp(7, 28);

    _layoutEngine = KeyboardLayoutEngine(
      layout: PianoLayout(),
      scale: _selectedScale,
      octaves: _currentOctave, // This might be interpreted as number of octaves to generate by PianoLayout
      keyboardSize: _currentSize, // Initial size, will be updated by LayoutBuilder
      startMidiNote: _currentOctave * 12, // Standard MIDI C note for the current octave
      numVisibleWhiteKeys: _numVisibleWhiteKeysActual,
    );
    _mpeTouchHandler = MPETouchHandler(layoutEngine: _layoutEngine); // Initialize MPE handler

    // _updateNotesInScale(); // Call this if it's still needed for visual scale highlighting by painter
                           // For now, its primary role of filtering notes is less relevant with MPE
                           // and a physical piano layout.
  }

  void _updateLayoutAndRefresh(Size newSize) {
    bool needsRebuild = false;
    if (_currentSize != newSize) {
      _currentSize = newSize;
      needsRebuild = true;
    }

    _layoutEngine.updateDimensions(
      newSize,
      newScale: _selectedScale,
      newOctaves: _currentOctave,
      newStartMidiNote: _currentOctave * 12,
      newNumVisibleWhiteKeys: _numVisibleWhiteKeysActual,
    );

    if (mounted && needsRebuild) { // Only setState if size actually changed or critical params
      setState(() {});
    }
  }

  // This method might be deprecated or its role changed.
  // Highlighting keys based on scale on a physical piano layout when using microtonal scales
  // needs careful consideration. For now, it mainly ensures layout is updated on scale change.
  void _updateNotesInScale() {
    _releaseAllNotes();
    if (_currentSize != Size.zero) { // Ensure _currentSize is initialized
        // This ensures the layout engine gets the new scale.
        // The painter would then need to use this scale info for highlighting if desired.
        _updateLayoutAndRefresh(_currentSize);
    }
    if(mounted) setState(() {});
  }

  // _onNoteOn and _onNoteOff are now conceptually superseded by MPETouchHandler for direct interaction.
  // However, we keep the core logic of updating _pressedKeys and SynthParametersModel,
  // which will be triggered by MPETouchHandler (or a similar mechanism) eventually.
  // For this refactor step, the Listener in _buildKeyboardArea will call MPETouchHandler,
  // and also perform these state updates temporarily.
  void _onNoteOn(int midiNote, int pointerId, double pressure) {
    // The old scale filtering logic is removed. Playability is assumed for physical keys.
    // Mapping to actual microtonal pitches is the audio engine's job based on this MIDI note + scale.
    if (midiNote > 127) return;

    if (!_pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      int currentVelocity = (_velocity * 127).round();
      model.noteOn(midiNote, currentVelocity);

      // Store active pointer
      _activePointersToMidiNotes[pointerId] = midiNote;

      // Send initial Poly AT
      int scaledPressure = (pressure.clamp(0.0, 1.0) * 127).round();
      _nativeAudioLib.sendPolyAftertouch(midiNote, scaledPressure);
      // print("PolyAT Initial: Note $midiNote, Pressure: $scaledPressure, Pointer: $pointerId");

      setState(() {
        _pressedKeys.add(midiNote);
      });
    }
  }

  // Updated to reflect it's now primarily for state management, not direct event handling
  void _onNoteOff(int midiNote, int pointerId) {
    // The keyMidiOffset logic is removed as midiNote is now directly from KeyModel.
    if (_activePointersToMidiNotes[pointerId] == midiNote || _pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOff(midiNote);
      // Send poly aftertouch of 0 when note is released
      _nativeAudioLib.sendPolyAftertouch(midiNote, 0);
      // print("PolyAT Zero: Note $midiNote, Pointer: $pointerId");
      setState(() {
        _pressedKeys.remove(midiNote);
      });
    }
    // Always remove the pointer from the active map
    _activePointersToMidiNotes.remove(pointerId);
  }

  void _releaseAllNotes() {
    final model = context.read<SynthParametersModel>();
    for (int note in _pressedKeys) {
      model.noteOff(note);
      _nativeAudioLib.sendPolyAftertouch(note, 0); // Pressure 0 on note off
    }
    setState(() {
      _pressedKeys.clear();
      _activePointersToMidiNotes.clear(); // Clear active pointers as well
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
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Root:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 9, glowIntensity: 0.2)),
          Container(
            height: 28,
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
      ),
    );
  }

  Widget _buildScaleSelector() {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Scale:', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 9, glowIntensity: 0.2)),
          Container(
            height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
           decoration: BoxDecoration(
            color: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<MicrotonalScale>( // Changed to MicrotonalScale
            value: _selectedScale,
            isDense: true,
            dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5),
            underline: Container(),
            icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.accentEnergy.withOpacity(0.9), size: 18),
            items: MicrotonalScale.availableScales.map((MicrotonalScale scale) { // Use availableScales
              return DropdownMenuItem<MicrotonalScale>(
                value: scale,
                child: Text(scale.name, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 11, glowIntensity: 0.3)),
              );
            }).toList(),
            onChanged: (MicrotonalScale? value) { // Changed to MicrotonalScale
              if (value != null) {
                setState(() { _selectedScale = value; });
                _updateNotesInScale(); // Will call _updateLayoutAndRefresh
                HapticFeedback.selectionClick();
              }
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildKeyboardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
          return const SizedBox.shrink();
        }

        // Ensure layout engine is updated with the latest size and parameters
        // Using WidgetsBinding to defer this call until after the current build cycle.
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && (_currentSize != constraints.biggest ||
                           _layoutEngine.keyboardSize != constraints.biggest ||
                           _layoutEngine.octaves != _currentOctave ||
                           _layoutEngine.scale != _selectedScale ||
                           _layoutEngine.numVisibleWhiteKeys != _numVisibleWhiteKeysActual ||
                           _layoutEngine.startMidiNote != _currentOctave * 12
                           )) {
                _updateLayoutAndRefresh(constraints.biggest);
            }
        });

        double totalLayoutWidth = (_layoutEngine.keyboardSize.width * _keyWidthFactor).clamp(constraints.minWidth, constraints.maxWidth * 5.0);
        if (_layoutEngine.keys.isNotEmpty) {
             double minX = double.infinity;
             double maxX = double.negativeInfinity;
             for(var key in _layoutEngine.keys) {
                 minX = math.min(minX, key.bounds.left);
                 maxX = math.max(maxX, key.bounds.right);
             }
             // Calculate actual width based on generated keys if they define the extent
             // This assumes keys are generated in a continuous block.
             // The painter will draw them relative to a 0,0 origin based on their bounds.
             // The SingleChildScrollView needs to know the total span of these bounds.
             totalLayoutWidth = (maxX - minX) * _keyWidthFactor;
         }


        return GestureDetector(
          onScaleStart: (details) {
            _initialKeyWidthFactorForPinch = _keyWidthFactor;
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
            _releaseAllNotes();
          },
          onScaleUpdate: (details) {
            if (details.pointerCount == 2) {
              setState(() {
                _keyWidthFactor = (_initialKeyWidthFactorForPinch * details.scale).clamp(0.3, 3.0);
                // The CustomPaint's size will be scaled by SingleChildScrollView's child Container.
                // The painter itself will draw keys based on their original model bounds.
                // The "zoom" is effectively how much of the full keyboard (if wider than view) is shown.
              });
              HapticFeedback.lightImpact();
            } else if (details.pointerCount >= 3 && _lastScaleDetails != null && _lastScaleDetails!.pointerCount >=3) {
                double dx = details.focalPointDelta.dx;
                _octaveScrollAccumulator += dx;
                double changeThreshold = _currentSize.width * 0.20;
                if (_octaveScrollAccumulator.abs() > changeThreshold) {
                  _releaseAllNotes();
                  if (_octaveScrollAccumulator > 0) { // Swipe right, decrease octave
                    if (_currentOctave > widget.minOctave) { setState(() { _currentOctave--; _updateLayoutAndRefresh(_currentSize);}); }
                  } else { // Swipe left, increase octave
                    if (_currentOctave < widget.maxOctave) { setState(() { _currentOctave++; _updateLayoutAndRefresh(_currentSize);}); }
                  }
                  _octaveScrollAccumulator = 0;
                  HapticFeedback.selectionClick();
                }
            }
            _lastScaleDetails = details;
          },
          onScaleEnd: (details) {
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
          },
          child: Listener(
            onPointerDown: (PointerDownEvent event) {
              // Adjust touch position by current scroll offset and keyWidthFactor (zoom)
              // This requires knowing the scroll offset if SingleChildScrollView is used.
              // For simplicity, if CustomPaint is child of SingleChildScrollView, localPosition is already correct for visible part.
              // The challenge is if the CustomPaint itself is larger than the viewport due to _keyWidthFactor.
              // Let's assume _keyWidthFactor is more for future use where painter might scale drawings.
              // For now, _layoutEngine.getKeyAtPosition expects coordinates in its own internal space.
              // If PianoLayout generates keys to fit keyboardSize, and keyboardSize is constraints.biggest,
              // then event.localPosition should be correct.
              final KeyModel? key = _layoutEngine.getKeyAtPosition(event.localPosition);
              if (key != null) {
                _mpeTouchHandler.handleTouchStart(event.pointer, event.localPosition, key, event.pressure);
                if (!_pressedKeys.contains(key.note)) {
                    _pressedKeys.add(key.note);
                    _activePointersToMidiNotes[event.pointer] = key.note;
                    _layoutEngine.setKeyPressed(key.note, true, overrideColor: HolographicTheme.glowColor);
                    if (mounted) setState(() {});
                }
              }
            },
            onPointerMove: (PointerMoveEvent event) {
              _mpeTouchHandler.handleTouchMove(event.pointer, event.localPosition, event.pressure);
            },
            onPointerUp: (PointerUpEvent event) {
              final MPETouch? endedTouch = _mpeTouchHandler.handleTouchEnd(event.pointer);
              if (endedTouch != null) {
                 _pressedKeys.remove(endedTouch.note);
                 _activePointersToMidiNotes.remove(event.pointer);
                  _layoutEngine.setKeyPressed(endedTouch.note, false);
                 if (mounted) setState(() {});
              } else {
                  if (_activePointersToMidiNotes.containsKey(event.pointer)) {
                      int noteToRemove = _activePointersToMidiNotes[event.pointer]!;
                      _pressedKeys.remove(noteToRemove);
                      _layoutEngine.setKeyPressed(noteToRemove, false);
                      _activePointersToMidiNotes.remove(event.pointer);
                       if (mounted) setState(() {});
                  }
              }
            },
            onPointerCancel: (PointerCancelEvent event) {
              final MPETouch? cancelledTouch = _mpeTouchHandler.handleTouchEnd(event.pointer);
               if (cancelledTouch != null) {
                 _pressedKeys.remove(cancelledTouch.note);
                 _activePointersToMidiNotes.remove(event.pointer);
                 _layoutEngine.setKeyPressed(cancelledTouch.note, false);
                 if (mounted) setState(() {});
              } else {
                  if (_activePointersToMidiNotes.containsKey(event.pointer)) {
                      int noteToRemove = _activePointersToMidiNotes[event.pointer]!;
                      _pressedKeys.remove(noteToRemove);
                      _layoutEngine.setKeyPressed(noteToRemove, false);
                      _activePointersToMidiNotes.remove(event.pointer);
                       if (mounted) setState(() {});
                  }
              }
            },
            child: SingleChildScrollView( // This scroll view handles the actual viewport for a potentially larger keyboard
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: CustomPaint(
                size: Size(totalLayoutWidth, constraints.maxHeight),
                painter: KeyboardPainter(
                  keys: _layoutEngine.keys,
                  theme: KeyboardTheme.holographic,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // _buildKey method is removed.
  /*
  Widget _buildKey({required KeyModel keyModel, required bool isPressed}) {
    ...
  }
  */

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