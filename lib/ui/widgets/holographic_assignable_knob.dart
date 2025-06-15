import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart'; // For HolographicDropdown styling
import 'package:synther_app/ui/holographic/holographic_widget.dart';
import 'package:synther_app/features/shared_controls/control_knob_widget.dart';
import 'package:synther_app/core/audio_engine.dart'; // Corrected import
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


class HolographicAssignableKnob extends StatefulWidget {
  final SynthParameterType initialParameter;
  final AudioEngine audioEngine;
  // final MorphUIVisualizerBridge? visualizerBridge; // Optional, if visual feedback is tied
  final Function(SynthParameterType type, double value)? onAssignmentChanged; // Callback for parameter type and its initial value
  final Function(SynthParameterType type, double value)? onValueUpdated; // Callback for value changes

  const HolographicAssignableKnob({
    super.key,
    this.initialParameter = SynthParameterType.filterCutoff,
    required this.audioEngine,
    // this.visualizerBridge,
    this.onAssignmentChanged,
    this.onValueUpdated,
  });

  @override
  State<HolographicAssignableKnob> createState() => _HolographicAssignableKnobState();
}

class _HolographicAssignableKnobState extends State<HolographicAssignableKnob> {
  late SynthParameterType _selectedParameter;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _selectedParameter = widget.initialParameter;
    _currentValue = _getParameterValueFromAudioEngine(_selectedParameter);

    // Call onAssignmentChanged for initial setup if needed by parent
    WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onAssignmentChanged?.call(_selectedParameter, _currentValue);
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
                    _updateAudioEngineParameter(_selectedParameter, _currentValue); // Update engine with new param's current value
                  });
                  widget.onAssignmentChanged?.call(newValue, _currentValue);
                }
              },
            ),
          ),

          Expanded(
            child: Center( // Center the knob
              child: ControlKnob(
                value: _currentValue,
                size: 120, // Adjusted size for better fit
                thumbColor: const Color(0xFF00FFFF), // Cyan accent
                trackColor: Colors.white.withOpacity(0.2),
                onChanged: (double newValue) {
                  setState(() {
                    _currentValue = newValue;
                  });
                  _updateAudioEngineParameter(_selectedParameter, newValue);
                  widget.onValueUpdated?.call(_selectedParameter, newValue);
                },
              ),
            ),
          ),

          // Placeholder for MIDI Learn button
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: IconButton(
              icon: Icon(Icons.settings_remote_outlined, color: Color(0xFF00FFFF).withOpacity(0.7)),
              tooltip: 'MIDI Learn (Not Implemented)',
              onPressed: () {
                // TODO: Implement MIDI Learn functionality
                // 1. Enter "learning" state for this knob.
                // 2. Listen for the next MIDI CC input globally.
                // 3. Associate the captured MIDI CC with _selectedParameter.
                // 4. Store this mapping.
                // 5. Provide visual feedback.
                print('MIDI Learn button pressed for $_selectedParameter (Not Implemented)');
              },
            ),
          ),
        ],
      ),
    );
  }
}
