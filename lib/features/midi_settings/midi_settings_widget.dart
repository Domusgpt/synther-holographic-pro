import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'dart:convert'; // For jsonDecode

import '../../core/ffi/native_audio_ffi.dart'; // Assumed path
import '../../ui/holographic/holographic_theme.dart';

class MidiDevice {
  final String id;
  final String name;
  MidiDevice({required this.id, required this.name});
}

// The static callback function that will be passed to native code
// It must be a top-level function or a static method.
void _globalMidiMessageHandler(Pointer<Uint8> messageData, int length) {
  final  message = messageData.asTypedList(length);
  // Simple log for now. In a real app, this might update a Provider/Stream.
  print('MIDI Message Received (Dart): Status=0x${message[0].toRadixString(16)}, Data1=${message.length > 1 ? message[1] : ""}, Data2=${message.length > 2 ? message[2] : ""}');
}


class MidiSettingsWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  const MidiSettingsWidget({
    Key? key,
    this.initialSize = const Size(300, 250),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  _MidiSettingsWidgetState createState() => _MidiSettingsWidgetState();
}

class _MidiSettingsWidgetState extends State<MidiSettingsWidget> {
  late bool _isCollapsed;
  late Size _currentSize;

  List<MidiDevice> _availableDevices = [];
  Set<String> _selectedDeviceIds = {}; // Store IDs of selected devices
  String _lastMidiMessage = "No MIDI messages received yet.";

  // Native library instance
  final NativeAudioLib _nativeAudioLib = NativeAudioLib();

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _loadMidiDevices();
    _registerMidiCallback();
  }

  void _loadMidiDevices() {
    try {
      final devicesJsonPtr = _nativeAudioLib.getMidiDevicesJson();
      final devicesJsonString = devicesJsonPtr.toDartString();
      final List<dynamic> decodedList = jsonDecode(devicesJsonString);

      setState(() {
        _availableDevices = decodedList.map((item) {
          if (item is Map<String, dynamic>) {
            return MidiDevice(id: item['id'] as String, name: item['name'] as String);
          }
          return MidiDevice(id: 'unknown', name: 'Unknown Device');
        }).toList();
      });
    } catch (e) {
      print("Error loading MIDI devices: $e");
      setState(() {
        _statusMessage = "Error loading MIDI devices.";
      });
    }
  }

  // Local message handler to update UI state
  void _handleIncomingMidiMessage(Pointer<Uint8> messageData, int length) {
    final message = messageData.asTypedList(length);
    String status = '0x${message[0].toRadixString(16)}';
    String data1 = message.length > 1 ? message[1].toString() : "";
    String data2 = message.length > 2 ? message[2].toString() : "";

    setState(() {
      _lastMidiMessage = 'MIDI: S=$status D1=$data1 D2=$data2';
    });
  }

  void _registerMidiCallback() {
    // Pass the static _globalMidiMessageHandler to FFI.
    // For UI updates, _globalMidiMessageHandler would need a way to communicate
    // with this widget's state (e.g. a global Stream, or if this widget is always mounted,
    // it could register its own instance method if the FFI setup allows for context/user_data).
    // For simplicity here, we'll use a static callback that just logs.
    // To update THIS widget's state, we'd need a more complex setup or use a global event bus.
    // Let's try to register an instance method if possible, but it's tricky with FFI directly.
    // A common pattern is a static Trampoline that calls an instance method on a known instance.
    // For now, we use the global one for logging, and a separate local string for demo.

    // This is the simplified approach where the global handler updates some global state or logs.
    // If we want _handleIncomingMidiMessage of this instance to be called, it's more involved.
    // Let's assume _globalMidiMessageHandler is simple for now.
    final callbackPointer = Pointer.fromFunction<MidiMessageCallbackNative>(_globalMidiMessageHandler, 0); // 0 for exceptional return value
    _nativeAudioLib.registerMidiMessageCallback(callbackPointer);
    print("MIDI Callback Registered (pointing to _globalMidiMessageHandler).");

    // To demonstrate UI update, let's set up a manual way to feed messages to _handleIncomingMidiMessage
    // In a real app, _globalMidiMessageHandler would use a Stream or ValueNotifier.
    // For this test, I will call it manually when a device is selected.
  }

  void _selectDevice(String deviceId, bool isSelected) {
    final deviceIdPtr = deviceId.toNativeUtf8();
    try {
      if (isSelected) {
        _nativeAudioLib.selectMidiDevice(deviceIdPtr); // Conceptual: tell native to use this
        setState(() {
          _selectedDeviceIds.add(deviceId);
          // Simulate a message for demo purposes when a device is selected
          // In real app, this comes from native only via the registered callback
           final Pointer<Uint8> simulatedMessage = calloc<Uint8>(3);
           simulatedMessage[0] = 0x90; // Note On
           simulatedMessage[1] = 60;   // C4
           simulatedMessage[2] = 100;  // Velocity
          _handleIncomingMidiMessage(simulatedMessage, 3);
          calloc.free(simulatedMessage);
        });
        print("Selected MIDI device: $deviceId");
      } else {
        // nativeAudioLib.deselectMidiDevice(deviceIdPtr); // Conceptual
        setState(() {
          _selectedDeviceIds.remove(deviceId);
        });
        print("Deselected MIDI device: $deviceId");
      }
    } finally {
      calloc.free(deviceIdPtr);
    }
  }

  String _statusMessage = ""; // For displaying errors or info

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
          Text('MIDI SETTINGS', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
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
    if (_availableDevices.isEmpty && _statusMessage.isEmpty) {
      return Center(child: Text("No MIDI devices found or error loading.", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.warningEnergy)));
    }
     if (_statusMessage.startsWith("Error")) {
      return Center(child: Text(_statusMessage, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.warningEnergy)));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text("Available MIDI Input Devices:", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _availableDevices.length,
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                final bool isSelected = _selectedDeviceIds.contains(device.id);
                return Theme( // Override CheckboxListTile theme for holographic look
                  data: Theme.of(context).copyWith(
                    unselectedWidgetColor: HolographicTheme.secondaryEnergy.withOpacity(0.7),
                  ),
                  child: CheckboxListTile(
                    title: Text(device.name, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 12)),
                    value: isSelected,
                    onChanged: (bool? value) {
                      if (value != null) {
                        _selectDevice(device.id, value);
                      }
                    },
                    activeColor: HolographicTheme.accentEnergy,
                    checkColor: Colors.black87,
                    tileColor: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.2),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text("Last MIDI Message (Global Log):", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 10)),
          Text(_lastMidiMessage, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
