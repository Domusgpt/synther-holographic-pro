import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Assuming Provider is used for SynthParametersModel

import '../../core/ffi/native_audio_ffi_factory.dart';
import '../../core/synth_parameters.dart'; // Assuming this provides SynthParametersModel
import '../../ui/holographic/holographic_theme.dart';

// Static callback function to be passed to native code
// This function needs a way to access the SynthParametersModel to update it.
// A common way is to have a global key for the Navigator/MaterialApp context,
// or to pass a SendPort to an Isolate, or use a globally accessible StreamController/ChangeNotifier.
// For simplicity in this example, if SynthParametersModel is a ChangeNotifier,
// we might need a static reference or a more complex setup.
// Let's assume SynthParametersModel has a static instance or a global way to be updated.
// If not, this callback would typically emit events on a Stream that a widget then listens to.

void _automationParameterChangeCallback(int parameterId, double value) {
  print('Automation Parameter Change (Dart): ID=$parameterId, Value=$value');
  // This is tricky. Accessing context/provider here is not direct.
  // One common pattern: use a global event bus or a static method on a ChangeNotifier.
  // For now, let's assume SynthParametersModel has a static way to update, or this is handled by a global stream.
  // Example: GlobalSynthParams.instance.updateParameterFromNative(parameterId, value);
  // Or, if SynthParametersModel is a ChangeNotifier that this widget also listens to,
  // it would update its own copy and other widgets would react.
  // For this subtask, the crucial part is that the callback IS CALLED.
  // The actual state update mechanism in Flutter would depend on the app's architecture.
  // We will simulate this by having the widget itself register this and update its own state
  // or a model it holds, assuming it can get the model.

  // If we assume AutomationControlsWidget is always present and can register an instance method (needs complex FFI):
  // _AutomationControlsWidgetState.staticInstance?.updateParameterDisplay(parameterId, value);
  // This is generally not good practice.
  // A better way: _callbackEventController.add({'id': parameterId, 'value': value}); (using a global StreamController)

  // **IMPORTANT**: For this callback to effectively update the UI (e.g., knobs in ControlPanelWidget),
  // it needs to update a shared state that those widgets are listening to.
  // For example, if using Provider with a SynthParametersModel:
  //
  // 1. SynthParametersModel would need a method like:
  //    `void updateParameterFromAutomation(int parameterId, double value) { ... notifyListeners(); }`
  // 2. This callback would need access to that model instance. This can be achieved via:
  //    a) A global static instance of the model (simplest for this FFI context, but not always best practice).
  //       Example: `GlobalSynthModel.instance.updateParameterFromAutomation(parameterId, value.toDouble());`
  //    b) Passing a SendPort to an Isolate that holds the model (more complex).
  //    c) Using a global StreamController that the model listens to.
  //
  // For this example, we'll log and conceptually acknowledge this is where shared state update happens.
  // If `SynthParametersModel` is accessible globally (e.g. via a singleton `GlobalSynthModel.instance`):
  // try {
  //   GlobalSynthModel.instance?.updateParameterFromAutomation(parameterId, value);
  // } catch (e) {
  //   print("Error updating model from automation callback: $e");
  // }
}


class AutomationControlsWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  const AutomationControlsWidget({
    Key? key,
    this.initialSize = const Size(280, 150),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  _AutomationControlsWidgetState createState() => _AutomationControlsWidgetState();
}

class _AutomationControlsWidgetState extends State<AutomationControlsWidget> {
  late bool _isCollapsed;
  late Size _currentSize;

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasAutomation = false;

  final NativeAudioLib _nativeAudioLib = createNativeAudioLib();

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _updateStatesFromNative();

    // Register the callback
    // IMPORTANT: For a real app, how this static callback updates app state (e.g. SynthParametersModel)
    // needs careful design (e.g. global stream, static access to a model, etc.)
    final callbackPointer = Pointer.fromFunction<ParameterChangeCallbackNative>(_automationParameterChangeCallback, 0);
    _nativeAudioLib.registerParameterChangeCallback(callbackPointer);
    print("Automation Parameter Change Callback Registered.");
    // TODO: Listen to a stream/event that _automationParameterChangeCallback would populate.
  }

  void _updateStatesFromNative() {
    setState(() {
      _isRecording = _nativeAudioLib.isAutomationRecording();
      _isPlaying = _nativeAudioLib.isAutomationPlaying();
      _hasAutomation = _nativeAudioLib.hasAutomationData();
    });
  }

  void _toggleRecord() {
    if (_isRecording) {
      _nativeAudioLib.stopAutomationRecording();
    } else {
      _nativeAudioLib.startAutomationRecording();
    }
    _updateStatesFromNative(); // Update UI immediately
  }

  void _togglePlay() {
    if (_isPlaying) {
      _nativeAudioLib.stopAutomationPlayback();
    } else {
      if (_hasAutomation) {
        _nativeAudioLib.startAutomationPlayback();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No automation data to play.", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.warningEnergy)),
          backgroundColor: HolographicTheme.warningEnergy.withOpacity(HolographicTheme.activeTransparency),
        ));
      }
    }
     _updateStatesFromNative(); // Update UI immediately
  }

  void _clearAutomation() {
    _nativeAudioLib.clearAutomationData();
    _updateStatesFromNative(); // Update UI immediately
  }

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
          Text('AUTOMATION', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
          const Spacer(),
          IconButton(
            icon: Icon(_isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: HolographicTheme.primaryEnergy),
            onPressed: () {
              setState(() { _isCollapsed = !_isCollapsed; });
              widget.onCollapsedChanged?.call(_isCollapsed);
            },
            iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: _isRecording ? Icons.stop_circle_outlined : Icons.fiber_manual_record_rounded,
                label: _isRecording ? "STOP REC" : "RECORD",
                onPressed: _toggleRecord,
                isActive: _isRecording,
                activeColor: HolographicTheme.warningEnergy,
              ),
              _buildControlButton(
                icon: _isPlaying ? Icons.stop_circle_outlined : Icons.play_arrow_rounded,
                label: _isPlaying ? "STOP PLAY" : "PLAY",
                onPressed: _togglePlay,
                isActive: _isPlaying,
                activeColor: HolographicTheme.successEnergy,
                disabled: !_hasAutomation && !_isPlaying,
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildControlButton(
            icon: Icons.delete_sweep_outlined,
            label: "CLEAR DATA",
            onPressed: _clearAutomation,
            disabled: !_hasAutomation && !_isRecording && !_isPlaying, // Disable if no data and not active
            activeColor: HolographicTheme.secondaryEnergy, // Non-state specific color
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? activeColor,
    bool disabled = false,
  }) {
    final color = isActive ? activeColor ?? HolographicTheme.accentEnergy : HolographicTheme.secondaryEnergy;
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18, color: disabled ? color.withOpacity(0.5) : color),
      label: Text(
        label,
        style: HolographicTheme.createHolographicText(
          energyColor: disabled ? color.withOpacity(0.5) : color,
          fontSize: 11,
          glowIntensity: isActive ? 0.7 : 0.3,
        ),
      ),
      onPressed: disabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(HolographicTheme.widgetTransparency * (isActive ? 2.5 : 1.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: color.withOpacity(disabled ? 0.3 : 0.7), width: 1),
        ),
      ).copyWith(
        overlayColor: MaterialStateProperty.all(color.withOpacity(0.2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Periodically update state from native if playing, as events might be missed otherwise
    // This is a simple polling mechanism. A stream/event bus would be better.
    // TODO: Replace with a proper event-driven update from the FFI callback.
    // For now, the callback only logs. This widget will poll when it's active.
    if (_isPlaying && mounted) {
       Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _updateStatesFromNative(); // Check if still playing and update other states too
       });
    }


    return Container(
      width: _isCollapsed ? 200 : _currentSize.width,
      height: _isCollapsed ? 40 : _currentSize.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: HolographicTheme.primaryEnergy,
        intensity: 0.7,
        cornerRadius: 10,
      ).copyWith(
         color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.3),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed) Expanded(child: _buildContent()),
        ],
      ),
    );
  }
}
