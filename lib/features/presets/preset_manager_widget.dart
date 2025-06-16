import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart'; // For Utf8, calloc
import 'dart:convert'; // For jsonEncode, jsonDecode (if Dart handles more JSON work)

// Assuming these are correctly set up and accessible
import '../../core/ffi/native_audio_ffi.dart';
import '../../ui/holographic/holographic_theme.dart';
// import '../../core/synth_parameters.dart'; // If needed for model updates directly here

// For conceptual file operations (replace with actual file_picker/path_provider in a real app)
// import 'package:path_provider/path_provider.dart';
// import 'dart:io';

class PresetEntry {
  String name;
  String filePath; // Conceptual path or just use name as filename
  PresetEntry({required this.name, required this.filePath});
}

class PresetManagerWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  const PresetManagerWidget({
    Key? key,
    this.initialSize = const Size(280, 350),
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  _PresetManagerWidgetState createState() => _PresetManagerWidgetState();
}

class _PresetManagerWidgetState extends State<PresetManagerWidget> {
  late bool _isCollapsed;
  late Size _currentSize;

  List<PresetEntry> _presets = [];
  bool _isLoading = false;
  String _statusMessage = "";

  final NativeAudioLib _nativeAudioLib = NativeAudioLib();
  final TextEditingController _presetNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    _loadPresetsFromStorage(); // Load preset list
  }

  @override
  void dispose() {
    _presetNameController.dispose();
    super.dispose();
  }

  // --- Conceptual File Operations ---
  Future<String> _getPresetsDirectoryPath() async {
    // In a real app:
    // final directory = await getApplicationDocumentsDirectory();
    // return '${directory.path}/presets';
    return "dummy_presets_path"; // Placeholder
  }

  Future<void> _loadPresetsFromStorage() async {
    setState(() { _isLoading = true; _statusMessage = "Loading presets..."; });
    // In a real app:
    // final presetsDir = Directory(await _getPresetsDirectoryPath());
    // if (!await presetsDir.exists()) await presetsDir.create(recursive: true);
    // final files = presetsDir.listSync().where((item) => item.path.endsWith('.json')).toList();
    // List<PresetEntry> loadedPresets = [];
    // for (var fileEntity in files) {
    //   String fileName = fileEntity.path.split('/').last.replaceAll('.json', '');
    //   loadedPresets.add(PresetEntry(name: fileName, filePath: fileEntity.path));
    // }
    // For now, using mock data
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate async
    setState(() {
      _presets = [
        PresetEntry(name: "Bright Lead", filePath: "dummy/Bright Lead.json"),
        PresetEntry(name: "Dark Pad", filePath: "dummy/Dark Pad.json"),
        PresetEntry(name: "Deep Bass", filePath: "dummy/Deep Bass.json"),
      ];
      _isLoading = false;
      _statusMessage = _presets.isEmpty ? "No presets found." : "Presets loaded.";
    });
  }

  Future<void> _savePreset(String presetName) async {
    if (presetName.isEmpty) {
      setState(() { _statusMessage = "Preset name cannot be empty."; });
      return;
    }
    setState(() { _isLoading = true; _statusMessage = "Saving preset '$presetName'..."; });

    Pointer<Utf8> namePtr = presetName.toNativeUtf8(); // Changed to non-nullable, will be freed in finally
    Pointer<Utf8> jsonResultPtr = nullptr; // Initialize to nullptr

    try {
      jsonResultPtr = _nativeAudioLib.getCurrentPresetJson(namePtr);

      if (jsonResultPtr.address == 0) {
        // Handle null pointer from native call
        print("Error saving preset: Native function returned null JSON pointer.");
        setState(() { _statusMessage = "Error saving preset: Failed to retrieve preset data from engine."; });
        // No need to free jsonResultPtr here as it's null
        // namePtr will be freed in finally
        return;
      }

      final String presetJson = jsonResultPtr.toDartString();

      // --- CORRECT MEMORY MANAGEMENT ---
      _nativeAudioLib.freePresetJson(jsonResultPtr);
      // --- END CORRECT MEMORY MANAGEMENT ---

      // Conceptual file saving
      // final dirPath = await _getPresetsDirectoryPath();
      // final filePath = '$dirPath/$presetName.json';
      // final file = File(filePath);
      // await file.writeAsString(presetJson);
      print("Conceptually saved preset '$presetName' with JSON: $presetJson");

      // Update UI list
      final existing = _presets.indexWhere((p) => p.name == presetName);
      if (existing != -1) {
        _presets[existing].filePath = "dummy/$presetName.json"; // Update path if needed
      } else {
        _presets.add(PresetEntry(name: presetName, filePath: "dummy/$presetName.json"));
      }
      _presets.sort((a,b) => a.name.compareTo(b.name));
      setState(() { _statusMessage = "Preset '$presetName' saved!"; });

    } catch (e) {
      print("Error saving preset: $e");
      setState(() { _statusMessage = "Error saving preset: $e"; });
      // If jsonResultPtr was allocated but an error occurred (e.g., during toDartString or file ops), free it.
      if (jsonResultPtr != nullptr && jsonResultPtr.address != 0) {
        _nativeAudioLib.freePresetJson(jsonResultPtr);
      }
    } finally {
      calloc.free(namePtr); // Free namePtr, which is allocated by toNativeUtf8()
      // jsonResultPtr is already freed or was null, so no need to free it here again.
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadPreset(PresetEntry preset) async {
    setState(() { _isLoading = true; _statusMessage = "Loading preset '${preset.name}'..."; });

    // Conceptual file loading
    // final file = File(preset.filePath);
    // if (!await file.exists()) {
    //   setState(() { _isLoading = false; _statusMessage = "Preset file not found!"; });
    //   return;
    // }
    // final String presetJson = await file.readAsString();

    // For demo, using a placeholder JSON based on the preset name (as if loaded)
    // This would be the content read from the file.
    // The JSON structure here must match what applyPresetDataJson expects.
    // The C++ side currently has a very basic parser.
    String placeholderJson = '{"name":"${preset.name}","parameters":{"10":0.6,"11":0.4},"midiMappings":{"64":20}}'; // Example
    if (preset.name == "Dark Pad") {
        placeholderJson = '{"name":"${preset.name}","parameters":{"10":0.2,"11":0.7, "20":0.8, "30":0.5},"midiMappings":{}}';
    }


    Pointer<Utf8>? jsonPtr = placeholderJson.toNativeUtf8();
    try {
      final result = _nativeAudioLib.applyPresetJson(jsonPtr);
      if (result == 0) {
        setState(() { _statusMessage = "Preset '${preset.name}' loaded!"; });
        // UI controls should update via the parameter change callback & SynthParametersModel
      } else {
        setState(() { _statusMessage = "Failed to apply preset '${preset.name}'. Error code: $result"; });
      }
    } catch (e) {
      print("Error loading preset: $e");
      setState(() { _statusMessage = "Error loading preset: $e"; });
    } finally {
      if (jsonPtr != nullptr) calloc.free(jsonPtr);
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _deletePreset(PresetEntry preset) async {
    // Conceptual file deletion
    // final file = File(preset.filePath);
    // if (await file.exists()) {
    //   await file.delete();
    // }
    print("Conceptually deleted preset file: ${preset.filePath}");

    setState(() {
      _presets.removeWhere((p) => p.name == preset.name);
      _statusMessage = "Preset '${preset.name}' deleted.";
    });
  }

  void _showSavePresetDialog() {
    _presetNameController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.2), // Adjusted for more translucency
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.7), width: 1.5),
          ),
          title: Text("Save Preset", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 16)),
          content: TextField(
            controller: _presetNameController,
            autofocus: true,
            style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Enter preset name",
              hintStyle: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy.withOpacity(0.5), fontSize: 14),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: HolographicTheme.secondaryEnergy.withOpacity(0.7))),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: HolographicTheme.accentEnergy)),
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Save", style: TextStyle(color: Colors.black87)),
              style: ElevatedButton.styleFrom(backgroundColor: HolographicTheme.accentEnergy.withOpacity(0.8)),
              onPressed: () {
                _savePreset(_presetNameController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          Text('PRESET MANAGER', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.save_alt_rounded, size: 18, color: Colors.black87),
            label: Text("Save Current Preset", style: TextStyle(color: Colors.black87, fontSize: 12)),
            onPressed: _showSavePresetDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.activeTransparency * 1.8),
              padding: EdgeInsets.symmetric(horizontal:12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading && _presets.isEmpty)
            Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(HolographicTheme.accentEnergy)))
          else if (_presets.isEmpty && !_isLoading)
            Center(child: Text("No presets.", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy)))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _presets.length,
                itemBuilder: (context, index) {
                  final preset = _presets[index];
                  return Container(
                     margin: const EdgeInsets.symmetric(vertical: 2.0),
                     decoration: BoxDecoration(
                       color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.5),
                       borderRadius: BorderRadius.circular(4),
                       border: Border.all(color: HolographicTheme.primaryEnergy.withOpacity(0.3), width:0.5)
                     ),
                    child: ListTile(
                      title: Text(preset.name, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 13)),
                      dense: true,
                      onTap: () => _loadPreset(preset),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline, color: HolographicTheme.warningEnergy.withOpacity(0.7), size: 20),
                        onPressed: () async {
                           final confirm = await showDialog<bool>(context: context, builder: (ctx) =>
                             AlertDialog(
                               title: Text("Delete Preset?", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.warningEnergy)),
                               content: Text("Delete '${preset.name}'? This cannot be undone.", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy)),
                                backgroundColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.2), // Adjusted for more translucency
                               actions: [
                                 TextButton(child: Text("Cancel", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy)), onPressed: () => Navigator.of(ctx).pop(false)),
                                 ElevatedButton(child: Text("Delete", style: TextStyle(color: Colors.black87)), style: ElevatedButton.styleFrom(backgroundColor: HolographicTheme.warningEnergy), onPressed: () => Navigator.of(ctx).pop(true)),
                               ]
                             ));
                            if (confirm == true) _deletePreset(preset);
                        },
                        splashRadius: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_statusMessage, style: HolographicTheme.createHolographicText(fontSize: 10, energyColor: _statusMessage.startsWith("Error") ? HolographicTheme.warningEnergy : HolographicTheme.successEnergy)),
          ]
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
