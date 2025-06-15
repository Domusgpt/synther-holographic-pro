import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart'; // For HolographicDropdown styling
import 'package:synther_app/ui/holographic/holographic_widget.dart';
import 'package:synther_app/features/shared_controls/control_knob_widget.dart';
import 'package:synther_app/core/audio_engine.dart'; // Corrected import
import 'dart:async'; // For Timer
import 'package:synther_app/ui/holographic/holographic_theme.dart'; // For HolographicTheme colors
// import 'package:synther_app/features/visualizer_bridge/morph_ui_visualizer_bridge.dart'; // If needed

/// Enum for assignable synthesizer parameters.
enum SynthParameterType {
  filterCutoff,
  filterResonance,
  oscLfoRate,
  oscPulseWidth,
  reverbMix,
  delayFeedback,
  attackTime,
  decayTime,
  masterVolume, // Added masterVolume
  // Add more parameters as needed
}

// Helper to get a display string for the enum
String synthParameterTypeToString(SynthParameterType param) {
  switch (param) {
    case SynthParameterType.filterCutoff:
      return 'Cutoff';
    case SynthParameterType.filterResonance:
      return 'Resonance';
    case SynthParameterType.oscLfoRate:
      return 'LFO Rate';
    case SynthParameterType.oscPulseWidth:
      return 'Pulse Width';
    case SynthParameterType.reverbMix:
      return 'Reverb';
    case SynthParameterType.delayFeedback:
      return 'Delay Fbk';
    case SynthParameterType.attackTime:
      return 'Attack';
    case SynthParameterType.decayTime:
      return 'Decay';
    case SynthParameterType.masterVolume:
      return 'Master Volume';
    default:
      // Attempt to format from enum name
      String name = param.toString().split('.').last;
      name = name.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}').trim();
      return name.replaceFirst(name[0], name[0].toUpperCase());
  }
}

// Basic Holographic Dropdown (can be expanded and moved to a separate file later)
class HolographicDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  final String? hintText;

  const HolographicDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 50, // Adjust height as needed
      borderRadius: 8,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.15),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFF00FFFF).withOpacity(0.3),
          const Color(0xFFFF00FF).withOpacity(0.3),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          dropdownColor: Colors.black.withOpacity(0.85),
          style: const TextStyle(
            color: Color(0xFF00FFFF), // Cyan accent
            fontSize: 14,
          ),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00FFFF)),
          hint: hintText != null ? Text(hintText!, style: TextStyle(color: Color(0xFF00FFFF).withOpacity(0.7))) : null,
        ),
      ),
    );
  }
}

/// A holographic knob that can be assigned to control various [SynthParameterType]s.
///
/// This widget features:
/// - A dropdown ([HolographicDropdown]) to select the synthesizer parameter.
/// - A [ControlKnob] to adjust the value of the selected parameter.
/// - Visual feedback for value changes (a brief scaling animation of the value text).
/// - A MIDI Learn button:
///   - Toggles a "learn mode" for the knob.
///   - When active, UI indicates "Learning..." and the button icon changes.
///   - A dialog prompts the user to simulate MIDI CC input by typing a CC number.
///   - If a CC is "captured", it's mapped to the currently selected [SynthParameterType]
///     via [MidiMappingService].
///   - The current MIDI mapping (e.g., "MIDI: CC 74") is displayed below the learn button.
/// - **Dynamic Sizing:** Utilizes `onInteractionStart` and `onInteractionEnd` callbacks to signal
///   its parent [HolographicWidget] to expand on interaction and contract after a delay.
/// - **Dynamic Energy Color:** Changes its parent [HolographicWidget]'s energy color based on the
///   selected [SynthParameterType] via the `onEnergyColorChange` callback. A predefined
///   `_parameterEnergyColors` map defines these color associations.
/// - Wrapped in a [HolographicWidget] to be draggable, resizable, and collapsible.
class HolographicAssignableKnob extends StatefulWidget {
  final SynthParameterType initialParameter;
  final AudioEngine audioEngine;
  final Function(SynthParameterType type, double value)? onAssignmentChanged;
  final Function(SynthParameterType type, double value)? onValueUpdated;
  final VoidCallback? onInteractionStart;
  final VoidCallback? onInteractionEnd;
  final ValueChanged<Color>? onEnergyColorChange;

  const HolographicAssignableKnob({
    super.key,
    this.initialParameter = SynthParameterType.filterCutoff,
    required this.audioEngine,
    this.onAssignmentChanged,
    this.onValueUpdated,
    this.onInteractionStart,
    this.onInteractionEnd,
    this.onEnergyColorChange,
  });

  @override
  State<HolographicAssignableKnob> createState() => _HolographicAssignableKnobState();
}

// import 'package:synther_app/services/midi_mapping_service.dart'; // Already imported below

class _HolographicAssignableKnobState extends State<HolographicAssignableKnob> with TickerProviderStateMixin {
  late SynthParameterType _selectedParameter;
  late double _currentValue;
  bool _isLearningMidi = false;
  MidiCcIdentifier? _currentMapping;
  Timer? _compactTimer; // For dynamic sizing

  late AnimationController _valueFeedbackController;
  late Animation<double> _valueFeedbackAnimation;

  @override
  void initState() {
    super.initState();
    _selectedParameter = widget.initialParameter;
    _currentValue = _getParameterValueFromAudioEngine(_selectedParameter);
    _loadCurrentMapping();
    _notifyEnergyColorChange(); // Notify initial color

    _valueFeedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _valueFeedbackAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _valueFeedbackController, curve: Curves.easeOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAssignmentChanged?.call(_selectedParameter, _currentValue);
    });
  }

  @override
  void dispose() {
    _valueFeedbackController.dispose();
    _compactTimer?.cancel();
    super.dispose();
  }

  static final Map<SynthParameterType, Color> _parameterEnergyColors = {
    SynthParameterType.filterCutoff: HolographicTheme.primaryEnergy,
    SynthParameterType.filterResonance: HolographicTheme.secondaryEnergy,
    SynthParameterType.attackTime: HolographicTheme.accentEnergy,
    SynthParameterType.decayTime: Colors.orangeAccent,
    SynthParameterType.masterVolume: Colors.lightGreenAccent,
    SynthParameterType.reverbMix: Colors.blueAccent,
    SynthParameterType.delayFeedback: Colors.purpleAccent,
    SynthParameterType.oscLfoRate: Colors.tealAccent,
    SynthParameterType.oscPulseWidth: Colors.pinkAccent,
    // Add all SynthParameterType values here
  };

  void _notifyEnergyColorChange() {
    final color = _parameterEnergyColors[_selectedParameter] ?? HolographicTheme.primaryEnergy;
    widget.onEnergyColorChange?.call(color);
  }

  void _handleInteractionStart() {
    _compactTimer?.cancel();
    widget.onInteractionStart?.call();
  }

  void _handleInteractionEnd() {
    _compactTimer?.cancel();
    _compactTimer = Timer(const Duration(seconds: 3), () {
      widget.onInteractionEnd?.call();
    });
  }

  void _triggerValueFeedback() {
    _valueFeedbackController.forward().then((_) => _valueFeedbackController.reverse());
  }

  void _loadCurrentMapping() {
    setState(() {
      _currentMapping = MidiMappingService.instance.getCcForParameter(_selectedParameter);
    });
  }

  double _getParameterValueFromAudioEngine(SynthParameterType param) {
    // This method maps SynthParameterType to actual AudioEngine getter methods.
    // Assumes normalized values (0.0-1.0) for UI representation where applicable.
    // Placeholders remain for parameters not yet fully integrated with AudioEngine.
    switch (param) {
      case SynthParameterType.filterCutoff:
        return widget.audioEngine.filterCutoff / 20000; // Assuming max is 20000
      case SynthParameterType.filterResonance:
        return widget.audioEngine.filterResonance; // Assuming 0-1 range
      case SynthParameterType.oscLfoRate:
        // return widget.audioEngine.lfoRate / 20; // Assuming max LFO rate is 20 Hz
        return 0.3; // Placeholder
      case SynthParameterType.oscPulseWidth:
        // return widget.audioEngine.pulseWidth; // Assuming 0-1 range
        return 0.5; // Placeholder
      case SynthParameterType.reverbMix:
        return widget.audioEngine.reverbMix; // Assuming 0-1 range
      case SynthParameterType.delayFeedback:
        // return widget.audioEngine.delayFeedback; // Assuming 0-1 range
        return 0.4; // Placeholder
      case SynthParameterType.attackTime:
        return widget.audioEngine.attackTime / 5; // Assuming max 5s
      case SynthParameterType.decayTime:
        return widget.audioEngine.decayTime / 5; // Assuming max 5s
      case SynthParameterType.masterVolume:
        return widget.audioEngine.masterVolume; // Assuming 0-1 range
      default:
        return 0.5;
    }
  }

  void _updateAudioEngineParameter(SynthParameterType param, double value) {
    // This method maps SynthParameterType and a normalized UI value to actual AudioEngine setter methods.
    // Placeholders remain for parameters not yet fully integrated with AudioEngine.
    switch (param) {
      case SynthParameterType.filterCutoff:
        widget.audioEngine.setFilterCutoff(value * 20000);
        break;
      case SynthParameterType.filterResonance:
        widget.audioEngine.setFilterResonance(value);
        break;
      case SynthParameterType.oscLfoRate:
        // widget.audioEngine.setLfoRate(value * 20);
        break;
      case SynthParameterType.oscPulseWidth:
        // widget.audioEngine.setPulseWidth(value);
        break;
      case SynthParameterType.reverbMix:
        widget.audioEngine.setReverbMix(value);
        break;
      case SynthParameterType.delayFeedback:
        // widget.audioEngine.setDelayFeedback(value);
        break;
      case SynthParameterType.attackTime:
        widget.audioEngine.setAttackTime(value * 5);
        break;
      case SynthParameterType.decayTime:
        widget.audioEngine.setDecayTime(value * 5);
        break;
      case SynthParameterType.masterVolume:
        widget.audioEngine.setMasterVolume(value);
        break;
    }
    // widget.visualizerBridge?.animateParameter(synthParameterTypeToString(param).toLowerCase(), value);
  }

  @override
  Widget build(BuildContext context) {
    return HolographicWidget(
      title: synthParameterTypeToString(_selectedParameter), // Dynamic title based on selected param
      childPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure controls are spaced out
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: HolographicDropdown<SynthParameterType>(
              value: _selectedParameter,
              items: SynthParameterType.values.map((SynthParameterType value) {
                return DropdownMenuItem<SynthParameterType>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(synthParameterTypeToString(value)),
                  ),
                );
              }).toList(),
              onChanged: (SynthParameterType? newValue) {
                if (newValue != null && newValue != _selectedParameter) {
                  setState(() {
                    _selectedParameter = newValue;
                    _currentValue = _getParameterValueFromAudioEngine(newValue);
                    _updateAudioEngineParameter(_selectedParameter, _currentValue);
                    _loadCurrentMapping();
                    _triggerValueFeedback();
                    _notifyEnergyColorChange(); // Update color on parameter change
                  });
                  widget.onAssignmentChanged?.call(newValue, _currentValue);
                }
              },
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector( // Wrap ControlKnob to detect tap for interaction start
                  onTapDown: (_) => _handleInteractionStart(),
                  // ControlKnob itself doesn't have onDragStart/End, so onChanged is main trigger
                  child: ControlKnob(
                      value: _currentValue,
                      size: 110,
                      thumbColor: const Color(0xFF00FFFF),
                      trackColor: Colors.white.withOpacity(0.2),
                      onChanged: (double newValue) {
                        _handleInteractionStart(); // Consider interaction started
                        setState(() { _currentValue = newValue; });
                        _updateAudioEngineParameter(_selectedParameter, newValue);
                        widget.onValueUpdated?.call(_selectedParameter, newValue);
                        _triggerValueFeedback();
                        _handleInteractionEnd(); // Reset timer on each change
                      },
                    ),
                ),
                SizedBox(height: 8),
                ScaleTransition(
                  scale: _valueFeedbackAnimation,
                  child: Text(
                    (_currentValue * 100).toStringAsFixed(1) + '%', // Example: display as percentage
                    style: TextStyle(
                      color: const Color(0xFF00FFFF).withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // MIDI Learn button and status
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(
                    _isLearningMidi ? Icons.mic_on : Icons.settings_remote_outlined, // Example: change icon
                    color: _isLearningMidi ? Colors.redAccent : Color(0xFF00FFFF).withOpacity(0.7),
                  ),
                  tooltip: _isLearningMidi ? 'MIDI Learn Active... (Tap to Cancel)' : (_currentMapping != null ? 'Change MIDI Map ($_currentMapping)' : 'Start MIDI Learn'),
                  onPressed: _toggleMidiLearn,
                ),
                if (_currentMapping != null && !_isLearningMidi)
                  Text(
                    'MIDI: ${_currentMapping.toString()}',
                    style: TextStyle(color: Color(0xFF00FFFF).withOpacity(0.6), fontSize: 9),
                  ),
                if (_isLearningMidi)
                  Text(
                    'Learning...',
                    style: TextStyle(color: Colors.redAccent, fontSize: 10),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMidiLearn() async {
    if (_isLearningMidi) {
      setState(() {
        _isLearningMidi = false;
      });
      return;
    }

    // Start learning
    setState(() {
      _isLearningMidi = true;
      _currentMapping = null; // Clear current mapping while learning new one
    });

    // Simulate MIDI capture with a dialog
    final int? capturedCc = await _showMidiCcInputDialog(context);

    if (capturedCc != null) {
      // User entered a CC number
      final newIdentifier = MidiCcIdentifier(ccNumber: capturedCc, channel: -1); // Default to any channel for now
      await MidiMappingService.instance.assignMapping(_selectedParameter, newIdentifier);
      debugPrint("Assigned CC $capturedCc to $_selectedParameter");
      setState(() {
        _currentMapping = newIdentifier;
        _isLearningMidi = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$_selectedParameter mapped to CC $capturedCc!'), backgroundColor: Colors.green)
      );
    } else {
      // User cancelled dialog or entered invalid input
      debugPrint("MIDI Learn cancelled or invalid input.");
      _loadCurrentMapping(); // Restore previous mapping if any
      setState(() {
        _isLearningMidi = false;
      });
    }
  }

  Future<int?> _showMidiCcInputDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return showDialog<int>(
      context: context,
      barrierDismissible: false, // User must enter a value or cancel
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Simulate MIDI CC Input', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter MIDI CC Number (0-127)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[600]!)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.amberAccent)),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.cyanAccent)),
              onPressed: () {
                final int? ccValue = int.tryParse(controller.text);
                if (ccValue != null && ccValue >= 0 && ccValue <= 127) {
                  Navigator.of(context).pop(ccValue);
                } else {
                  // Optionally show an error to the user in the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid CC. Must be 0-127.'), backgroundColor: Colors.red)
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void didUpdateWidget(HolographicAssignableKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialParameter != oldWidget.initialParameter) {
      setState(() {
        _selectedParameter = widget.initialParameter;
        _currentValue = _getParameterValueFromAudioEngine(_selectedParameter);
        _loadCurrentMapping();
        _triggerValueFeedback();
        _notifyEnergyColorChange(); // Update color if initial parameter changed
      });
    }
  }

}
