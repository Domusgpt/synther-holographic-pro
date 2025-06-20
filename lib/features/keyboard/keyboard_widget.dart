import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import 'dart:math' as math; // For black key positioning
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel and MicrotonalScale
import '../../core/ffi/native_audio_ffi_factory.dart'; // Import for NativeAudioLib factory
import '../../ui/holographic/holographic_theme.dart';

// Import new keyboard layout classes
import 'key_model.dart';
import 'keyboard_layout.dart';
import 'keyboard_layout_engine.dart';
import 'mpe_touch_handler.dart'; // Import MPE Touch Handler
import '../../core/microtonal_defs.dart'; // Import MicrotonalScale definitions
import 'keyboard_painter.dart'; // Import KeyboardPainter
import 'keyboard_theme.dart'; // Import KeyboardTheme


// --- Musical Scale Definitions (To be deprecated or moved if MicrotonalScale is fully adopted) ---
// For now, _selectedScale will be of type MusicalScale, and KeyboardLayoutEngine will adapt.
// enum MusicalScale { Chromatic, Major, MinorNatural, MinorHarmonic, MinorMelodic, PentatonicMajor, PentatonicMinor, Blues, Dorian, Mixolydian } // Commented out

const List<String> rootNoteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']; // Retain for root note selection

// final Map<MusicalScale, List<int>> scaleIntervals = { // Commented out
//   MusicalScale.Chromatic: [0,1,2,3,4,5,6,7,8,9,10,11],
//   MusicalScale.Major: [0,2,4,5,7,9,11],
//   MusicalScale.MinorNatural: [0,2,3,5,7,8,10],
//   MusicalScale.MinorHarmonic: [0,2,3,5,7,8,11],
//   MusicalScale.MinorMelodic: [0,2,3,5,7,9,11], // Ascending
//   MusicalScale.PentatonicMajor: [0,2,4,7,9],
//   MusicalScale.PentatonicMinor: [0,3,5,7,10],
//   MusicalScale.Blues: [0,3,5,6,7,10],
//   MusicalScale.Dorian: [0,2,3,5,7,9,10],
//   MusicalScale.Mixolydian: [0,2,4,5,7,9,10],
// };
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

  late double _keyWidthFactor; // Will be managed by engine or passed to it
  late int _numVisibleWhiteKeysActual;

  MicrotonalScale _selectedScale = MicrotonalScale.tet12; // Updated to MicrotonalScale
  int _selectedRootNoteMidiOffset = 0; // Remains for selecting root note for the scale
  // final Set<int> _notesInCurrentScale = {}; // This logic will be simplified or removed for now

  final Set<int> _pressedKeys = {}; // Stores MIDI note numbers
  final Map<int, int> _activePointersToMidiNotes = {}; // Map pointerId to midiNote
  final NativeAudioLib _nativeAudioLib = createNativeAudioLib();
  final MPETouchHandler _mpeTouchHandler = MPETouchHandler(); // Add MPE Touch Handler instance

  late KeyboardLayoutEngine _layoutEngine;

  double _initialKeyWidthFactorForPinch = 1.0; // This might be deprecated if zoom is handled by engine
  ScaleUpdateDetails? _lastScaleDetails;
  double _octaveScrollAccumulator = 0.0;

  // static const int notesInOctave = 12; // Now part of scale or layout logic
  // static const List<bool> _isBlackKeyMap = [false, true, false, true, false, false, true, false, true, false, true, false]; // Handled by PianoLayout
  // static const List<double> _blackKeyOffsets = [0.0, 0.60, 0.0, 0.70, 0.0, 0.0, 0.55, 0.0, 0.65, 0.0, 0.75, 0.0]; // Handled by PianoLayout
  // static const double blackKeyWidthFactor = 0.65; // Handled by PianoLayout
  // static const double blackKeyHeightFactor = 0.6; // Handled by PianoLayout

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _currentOctave = widget.initialOctave.clamp(widget.minOctave, widget.maxOctave);
    // _keyWidthFactor = 1.0; // Deprecated, will be handled by engine or its sizing
    _numVisibleWhiteKeysActual = widget.numWhiteKeysToDisplay.clamp(7, 28);

    // Initialize Layout Engine
    // Note: keyboardSize will be properly set in LayoutBuilder for the first time.
    // Using widget.initialSize for a temporary valid Size.
    _layoutEngine = KeyboardLayoutEngine(
      layout: PianoLayout(),
      scale: _selectedScale, // Now correctly typed
      octaves: _currentOctave,
      keyboardSize: widget.initialSize, // Initial temporary size
      startMidiNote: _currentOctave * 12,
      numVisibleWhiteKeys: _numVisibleWhiteKeysActual,
    );

    // _updateNotesInScale(); // Commented out: Highlighting logic needs rework for MicrotonalScale
                           // The physical layout is piano-based; scale defines tuning/labels.
  }

  void _updateLayoutAndRefresh(Size newSize) {
    bool needsRebuild = false;
    if (_currentSize != newSize) {
      _currentSize = newSize;
      needsRebuild = true;
    }
    // Add other checks if layout-affecting parameters changed, e.g., _selectedScale, _currentOctave
    // For now, we assume these are passed directly to updateDimensions.

    _layoutEngine.updateDimensions(
      newSize, // Pass the new size directly
      newScale: _selectedScale, // Pass current scale
      newOctaves: _currentOctave, // Pass current octave
      newStartMidiNote: _currentOctave * 12,
      newNumVisibleWhiteKeys: _numVisibleWhiteKeysActual,
    );

    if (needsRebuild && mounted) { // Or if any other critical param changed
      setState(() {});
    }
  }

  // This method's role changes. With MicrotonalScale, the scale definition itself
  // dictates what notes are "in the scale". For a standard piano physical layout,
  // all keys are "playable" but will map to microtonal pitches based on the scale
  // and root note. Highlighting might be based on whether a physical key corresponds
  // to a primary degree of the scale, or removed altogether for microtonal setups
  // where every key is a distinct microtonal step.
  // For now, commenting out its content as it's tightly coupled to the old MusicalScale enum.
  void _updateNotesInScale() {
    // _notesInCurrentScale.clear();
    // List<int>? intervals = scaleIntervals[_selectedScale]; // This would need to use MicrotonalScale
    // if (intervals != null) {
    //   for (int interval in intervals) {
    //     _notesInCurrentScale.add((_selectedRootNoteMidiOffset + interval) % 12);
    //   }
    // }
    _releaseAllNotes();

    // With MicrotonalScale, the layout engine should ideally get the scale
    // to potentially adjust key labels or active states if the layout supports it.
    // Calling _updateLayoutAndRefresh here ensures the engine is aware of scale changes.
    if (_currentSize != Size.zero) { // Ensure _currentSize is initialized
        _updateLayoutAndRefresh(_currentSize);
    }

    if(mounted) setState(() {});
  }

  // Updated signature
  void _onNoteOn(int midiNote, int pointerId, double pressure) {
    // Scale/Root note filtering is now more complex with microtonal scales
    // The physical key pressed (midiNote if it were 12-TET) needs to be mapped
    // to the actual microtonal note based on _selectedScale and _selectedRootNoteMidiOffset.
    // For now, we'll assume the PianoLayout still generates keys with standard MIDI note numbers
    // and the microtonal aspect is handled by the audio engine based on these + scale info.
    // Visual highlighting of "in-scale" keys on a 12-key layout for a microtonal scale needs thought.
    // For this step, we'll bypass the old _notesInCurrentScale check.

    // int noteChromaticOffset = midiNote % 12;
    // if (_selectedScale.id != 'tet12' && !_notesInCurrentScale.contains(noteChromaticOffset)) {
    //   return;
    // }

    if (midiNote > 127) return;

    if (!_pressedKeys.contains(midiNote)) {
      // Update KeyModel state via LayoutEngine
      _layoutEngine.setKeyPressed(midiNote, true, overrideColor: HolographicTheme.glowColor);

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

  // Updated signature
  void _onNoteOff(int midiNote, int pointerId) {
    if (_activePointersToMidiNotes[pointerId] == midiNote || _pressedKeys.contains(midiNote)) {
      final model = context.read<SynthParametersModel>();
      model.noteOff(midiNote);
      _nativeAudioLib.sendPolyAftertouch(midiNote, 0);

      // Update KeyModel state via LayoutEngine
      _layoutEngine.setKeyPressed(midiNote, false);

      setState(() {
        _pressedKeys.remove(midiNote);
      });
    }
    _activePointersToMidiNotes.remove(pointerId);
  }

  void _releaseAllNotes() {
    final model = context.read<SynthParametersModel>();
    for (int note in _pressedKeys) {
      model.noteOff(note);
      _nativeAudioLib.sendPolyAftertouch(note, 0);
       _layoutEngine.setKeyPressed(note, false);
    }
    setState(() {
      _pressedKeys.clear();
      _activePointersToMidiNotes.clear();
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
                _updateNotesInScale(); // This will now call _updateLayoutAndRefresh
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

        // Update layout engine if size or other parameters changed
        // This might be better in a post-frame callback or if driven by parameter changes explicitly
        if (_currentSize != constraints.biggest ||
            _layoutEngine.keyboardSize != constraints.biggest ||
            _layoutEngine.octaves != _currentOctave || // Example check
            _layoutEngine.scale != _selectedScale) { // Example check

            // Schedule update after build to avoid setState during build issues.
            WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) { // Check if still mounted before calling setState
                    _updateLayoutAndRefresh(constraints.biggest);
                 }
            });
        }

        // The PianoLayout's generateKeys now uses keyboardSize.width / numVisibleWhiteKeys.
        // The actual rendered width if _keyWidthFactor modifies individual key widths might differ.
        // For CustomPaint, we want the painter to draw the keys at their calculated sizes from _layoutEngine.keys
        // The _keyWidthFactor should be applied *inside* the painter if we want visual zoom,
        // or the keyboardSize given to the engine should be pre-scaled.
        // For now, let's assume _layoutEngine.keys have bounds appropriate for _currentSize without _keyWidthFactor,
        // and _keyWidthFactor is for the scrollable area's total width if it exceeds constraints.

        double totalLayoutWidth = _currentSize.width * _keyWidthFactor; // Conceptual total width for scrolling
         if (_layoutEngine.keys.isNotEmpty) {
            double minX = double.infinity;
            double maxX = double.negativeInfinity;
            for(var key in _layoutEngine.keys) {
                minX = math.min(minX, key.bounds.left);
                maxX = math.max(maxX, key.bounds.right);
            }
            // If keyWidthFactor is for zooming the visual appearance of keys,
            // it should be passed to the painter or applied during key generation.
            // If it's for how much of a larger virtual keyboard is shown,
            // then the keyboardSize passed to engine should be constraints.biggest * _keyWidthFactor (for width).
            // Let's assume for now PianoLayout generates for the given keyboardSize, and we scale that container.
            totalLayoutWidth = (_layoutEngine.keyboardSize.width * _keyWidthFactor).clamp(constraints.minWidth, constraints.maxWidth * 3);

        }


        return GestureDetector(
          onScaleStart: (details) {
            _initialKeyWidthFactorForPinch = _keyWidthFactor;
            _lastScaleDetails = null;
            _octaveScrollAccumulator = 0.0;
            _releaseAllNotes(); // Release notes on gesture start to avoid stuck notes
          },
          onScaleUpdate: (details) {
            if (details.pointerCount == 2) {
              setState(() {
                _keyWidthFactor = (_initialKeyWidthFactorForPinch * details.scale).clamp(0.5, 3.0);
                // No need to call _updateLayoutAndRefresh here if painter handles visual scaling
                // or if the key bounds are considered relative to a zoomable canvas.
                // For CustomPaint, if keys are generated once, painter needs to scale.
                // If keys are regenerated on zoom, then _updateLayoutAndRefresh.
                // Let's assume painter will use keyWidthFactor for now if needed, or we adjust generateKeys.
              });
              HapticFeedback.lightImpact();
            } else if (details.pointerCount >= 3 && _lastScaleDetails != null && _lastScaleDetails!.pointerCount >=3) {
                double dx = details.focalPointDelta.dx;
                _octaveScrollAccumulator += dx;
                double changeThreshold = _currentSize.width * 0.25;
                if (_octaveScrollAccumulator.abs() > changeThreshold) {
                  _releaseAllNotes();
                  if (_octaveScrollAccumulator > 0) {
                    if (_currentOctave < widget.maxOctave) { setState(() { _currentOctave++; _updateLayoutAndRefresh(_currentSize);}); }
                  } else {
                    if (_currentOctave > widget.minOctave) { setState(() { _currentOctave--; _updateLayoutAndRefresh(_currentSize);}); }
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
          child: Listener( // Listener for individual key presses, move, release
            onPointerDown: (PointerDownEvent event) {
              final KeyModel? key = _layoutEngine.getKeyAtPosition(event.localPosition / _keyWidthFactor); // Adjust position by zoom
              if (key != null) {
                // TODO: Determine if note is "in scale" for visual feedback or playability if desired
                // For now, allowing all physical keys to be interactive
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(), // Or NeverScrollable if zoom handles all interaction
              child: CustomPaint(
                size: Size(totalLayoutWidth, constraints.maxHeight), // Painter draws on this canvas size
                painter: KeyboardPainter(
                  keys: _layoutEngine.keys, // Keys with bounds relative to a non-zoomed layout
                  theme: KeyboardTheme.holographic, // Hardcode for now
                  // keyWidthFactor: _keyWidthFactor, // Pass zoom factor to painter
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKey({required KeyModel keyModel, required bool isPressed}) {
    int noteChromaticIndexInOctave = keyModel.note % 12; // Relative to C
    // The concept of "isNoteInScale" for highlighting a standard 12-key piano
    // based on a microtonal scale is complex. For now, we simplify:
    // If it's 12-TET, all keys are part of the "scale".
    // For other microtonal scales, this visual highlighting might be misleading on a piano layout.
    // We can keep a simplified version or remove it. Let's simplify for now.
    bool isNoteConceptuallyInScale = true; // Assume all physical keys are playable
    // If _selectedScale.id != 'tet12', one might implement logic to see if keyModel.note
    // closely aligns with a primary degree of the _selectedScale for highlighting.
    // For now, this is simplified. The old _notesInCurrentScale logic is mostly removed.

    Color keyColor;
    Color borderColor;
    double keyOpacityFactor = 1.0;

    // Assuming isNoteInScale logic will be adapted for MicrotonalScale if complex highlighting is needed.
    // For now, direct replacement might simplify or alter highlighting behavior.
    if (_selectedScale != MicrotonalScale.tet12 && !isNoteInScale) {
      keyOpacityFactor = 0.3;
    }

    if (isBlack) {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 2.2 * keyOpacityFactor);
      borderColor = HolographicTheme.secondaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    } else {
      keyColor = HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.6 * keyOpacityFactor);
      borderColor = HolographicTheme.primaryEnergy.withOpacity(0.7 * keyOpacityFactor);
    }

    // Assuming isNoteInScale logic will be adapted for MicrotonalScale if complex highlighting is needed.
    if (_selectedScale != MicrotonalScale.tet12 && isNoteInScale && !isPressed) {
      borderColor = HolographicTheme.accentEnergy.withOpacity(0.9 * keyOpacityFactor);
      keyColor = keyColor.withAlpha((keyColor.alpha * 1.2).clamp(0,255).toInt());
    }

    BoxDecoration decoration = isPressed
        ? HolographicTheme.createHolographicBorder(
            energyColor: keyModel.overrideColor ?? HolographicTheme.glowColor, // Use overrideColor if available
            intensity: 2.2,
            cornerRadius: keyModel.isBlack ? 3 : 4,
            borderWidth: 1.8,
          ).copyWith(
            color: (keyModel.overrideColor ?? HolographicTheme.glowColor).withOpacity(HolographicTheme.activeTransparency * 1.8)
          )
        : BoxDecoration(
            color: keyColor,
            borderRadius: BorderRadius.circular(keyModel.isBlack ? 3 : 4),
            border: Border.all(color: borderColor, width: 1.0,),
             boxShadow: [ BoxShadow( color: borderColor.withOpacity(0.3 * keyOpacityFactor), blurRadius: 3, spreadRadius: 0.5, offset: Offset(0,1.5) ) ]
          );
    
    return Listener(
      onPointerDown: (PointerDownEvent event) {
        // if (_selectedScale.id != 'tet12' && !isNoteConceptuallyInScale) return; // Adjusted condition
        // The above check is tricky; for now, allow all physical keys to be pressed.
        // The audio engine would handle mapping to the correct microtonal pitch.
        _mpeTouchHandler.handleTouchStart(event.pointer, event.localPosition, keyModel, event.pressure);

        if (!_pressedKeys.contains(keyModel.note)) {
            _pressedKeys.add(keyModel.note);
            _activePointersToMidiNotes[event.pointer] = keyModel.note;
             _layoutEngine.setKeyPressed(keyModel.note, true, overrideColor: HolographicTheme.glowColor);
            if (mounted) setState(() {});
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        // Integrate MPE Touch Move
        _mpeTouchHandler.handleTouchMove(event.pointer, event.localPosition, event.pressure);
        // Direct PolyAT call is now conceptually handled by MPETouchHandler
        // final int? midiNote = _activePointersToMidiNotes[event.pointer];
        // if (midiNote != null && _pressedKeys.contains(midiNote)) {
        //   double pressure = event.pressure.clamp(0.0, 1.0);
        //   int scaledPressure = (pressure * 127).round();
        //   _nativeAudioLib.sendPolyAftertouch(midiNote, scaledPressure);
        // }
      },
      onPointerUp: (PointerUpEvent event) {
        // Integrate MPE Touch End
        final MPETouch? endedTouch = _mpeTouchHandler.handleTouchEnd(event.pointer);
        // _onNoteOff(keyModel.note, event.pointer); // Direct call conceptually handled by MPETouchHandler

        if (endedTouch != null) { // Or use keyModel.note if endedTouch is null but pointer matches
           _pressedKeys.remove(endedTouch.note);
           _activePointersToMidiNotes.remove(event.pointer);
            _layoutEngine.setKeyPressed(endedTouch.note, false);
           if (mounted) setState(() {});
        } else { // Fallback if touch was not found by MPE handler but pointer up happens
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
        // Integrate MPE Touch End
        final MPETouch? cancelledTouch = _mpeTouchHandler.handleTouchEnd(event.pointer);
        // _onNoteOff(keyModel.note, event.pointer); // Direct call conceptually handled by MPETouchHandler

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
      child: Container(
        // Width and height are now derived from keyModel.bounds in the Positioned widget
        margin: keyModel.isBlack ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 0.75),
        decoration: decoration,
        // child: keyModel.label != null ? Center(child: Text(keyModel.label!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 8))) : null, // Optional: Draw label
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