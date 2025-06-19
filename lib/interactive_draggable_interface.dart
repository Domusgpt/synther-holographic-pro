import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for HapticFeedback
import 'package:provider/provider.dart';

// Import actual feature widgets
import 'features/xy_pad/xy_pad_widget.dart';
// Import MusicalScale and XYPadAssignment if they are moved to a shared location
// For now, PanelStateService uses indices, but SynthParametersModel might need direct enum access.
// For _PanelConfig.toSerializableConfig, we need SynthParametersModel and its enums.
import 'core/synth_parameters.dart';

import 'features/keyboard/keyboard_widget.dart';
import 'features/controls/control_panel_widget.dart';
import 'features/llm_presets/llm_preset_widget.dart';
import 'features/automation/automation_controls_widget.dart';
import 'features/presets/preset_manager_widget.dart';
import 'features/midi_settings/midi_settings_widget.dart';

import 'core/synth_parameters.dart'; // For SynthParametersModel if needed by placeholder widgets
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'ui/holographic/holographic_theme.dart';
// import 'services/firebase_service.dart'; // If used directly by this widget
// import 'core/audio_engine.dart'; // If used directly

import 'dart:ffi'; // For Pointer.fromFunction
import 'package:ffi/ffi.dart'; // For calloc if needed for string passing (not directly here)
import 'core/ffi/native_audio_ffi_factory.dart'; // For NativeAudioLib factory and callback typedef
import 'core/services/panel_state_service.dart'; // Import the new service

// Define a class to hold panel configuration and state
class _PanelConfig {
  final String id;
  final String title;
  final String childWidgetTypeKey; // Key to recreate the widget
  double normX;
  double normY;
  double normWidth;
  double normHeight;

  bool isCollapsed;
  bool isVisibleInWorkspace;
  final GlobalKey key;

  _PanelConfig({
    required this.id,
    required this.title,
    required this.childWidgetTypeKey,
    // Normalized initial values
    required this.normX,
    required this.normY,
    required this.normWidth,
    required this.normHeight,
    this.isCollapsed = false,
    this.isVisibleInWorkspace = true,
  }) : key = GlobalKey(debugLabel: id);

  // Convert to a serializable format
  SerializablePanelConfig toSerializableConfig(BuildContext context) {
    int? rootNoteX, scaleXIndex, yAxisAssignIndex;

    if (childWidgetTypeKey == 'xyPad_1') { // Match the key used in _initializePanels
      // Access SynthParametersModel safely via Provider
      try {
        final model = Provider.of<SynthParametersModel>(context, listen: false);
        rootNoteX = model.xyPadSelectedRootNoteX; // Using new getter
        scaleXIndex = model.xyPadSelectedScaleX.index; // Using new getter
        yAxisAssignIndex = model.yAxisAssignment.index;
      } catch (e) {
        print("Error accessing SynthParametersModel in toSerializableConfig for $id: $e");
        // Fallback or default values if model is not available, though it should be.
      }
    }

    return SerializablePanelConfig(
      id: id,
      title: title,
      childWidgetTypeKey: childWidgetTypeKey,
      normX: normX,
      normY: normY,
      normWidth: normWidth,
      normHeight: normHeight,
      isCollapsed: isCollapsed,
      isVisibleInWorkspace: isVisibleInWorkspace,
      xyPadRootNoteX: rootNoteX,
      xyPadScaleXIndex: scaleXIndex,
      yAxisAssignmentIndex: yAxisAssignIndex,
    );
  }

  // Create from a serializable format
  factory _PanelConfig.fromSerializableConfig(
    SerializablePanelConfig sPanel,
    // No longer need widgetBuilder here, as childWidget is not stored directly
  ) {
    return _PanelConfig(
      id: sPanel.id,
      title: sPanel.title,
      childWidgetTypeKey: sPanel.childWidgetTypeKey,
      normX: sPanel.normX,
      normY: sPanel.normY,
      normWidth: sPanel.normWidth,
      normHeight: sPanel.normHeight,
      isCollapsed: sPanel.isCollapsed,
      isVisibleInWorkspace: sPanel.isVisibleInWorkspace,
    );
  }
}

// Static members for FFI callback interaction
import 'dart:async'; // For StreamSubscription
import 'core/services/ui_midi_event_service.dart'; // Import the new service

// Top-level or static function for FFI callback
void _staticHandleUiControlMidiMessage(int targetPanelId, int ccNumber, int ccValue) {
  // This function now only publishes events to the UiMidiEventService.
  // It no longer directly manipulates UI state.
  print("Static FFI CB received: PanelID=$targetPanelId, CC=$ccNumber, Val=$ccValue. Publishing to service.");
  UiMidiEventService().publishEvent(targetPanelId, ccNumber, ccValue);
}

class InteractiveDraggableSynth extends StatefulWidget {
  const InteractiveDraggableSynth({Key? key}) : super(key: key);
  
  @override
  State<InteractiveDraggableSynth> createState() => _InteractiveDraggableSynthState();
}

class _InteractiveDraggableSynthState extends State<InteractiveDraggableSynth> {
  
  final List<_PanelConfig> _panels = []; // Instance list
  late NativeAudioLib _nativeAudioLib; // FFI instance
  StreamSubscription<UiMidiEvent>? _uiMidiEventSubscription;
  bool _isVaultAreaVisible = true; // Instance variable

  final PanelStateService _panelStateService = PanelStateService();

  @override
  void initState() {
    super.initState();
    _nativeAudioLib = createNativeAudioLib(); // Initialize FFI via factory

    // Try to load panel layout first
    _loadPanelLayoutAndInitialize();

    // Subscribe to UI MIDI events from the service
    _uiMidiEventSubscription = UiMidiEventService().events.listen(_handleUiControlEventFromStream);

    // Register the UI MIDI control callback (still uses the static trampoline)
    try {
        final callbackPointer = Pointer.fromFunction<UiControlMidiCallbackNative>(_staticHandleUiControlMidiMessage, 0);
        _nativeAudioLib.registerUiControlMidiCallback(callbackPointer);
        print("UI MIDI Control Callback Registered (via static trampoline to event service).");
    } catch (e) {
        print("Error registering UI MIDI control callback: $e");
    }
  }
  
  @override
  void dispose() {
    _uiMidiEventSubscription?.cancel(); // Cancel the stream subscription
    // TODO: Add an FFI function to unregister the callback if SynthEngine supports it.
    // Consider calling UiMidiEventService().dispose() if this is the main/root widget of the app.
    super.dispose();
  }

  // Combined load and initialize logic
  Future<void> _loadPanelLayoutAndInitialize() async {
    bool loadedSuccessfully = await _loadPanelLayout();
    if (!loadedSuccessfully || _panels.isEmpty) {
      print("No saved layout or panels empty after load attempt, initializing defaults.");
      _initializePanels(); // This will also call _savePanelLayout for the defaults
    }
    // Ensure UI reflects loaded or initialized panels.
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _savePanelLayout() async {
    // TODO: This method is not yet called in all desired UI interaction points
    // (e.g., panel resize, full set of drag-related saves, collapse) due to previous
    // tooling issues with diff application. Currently, it's called from MIDI changes (if they alter panel state),
    // vault interactions, and when initializing default panels.
    // It needs to be added to:
    // - onPanEnd of header drag in _buildDraggablePanel
    // - onPanEnd of resize drag in _buildDraggablePanel
    // - onPressed of collapse button in _buildDraggablePanel
    // - Potentially after XYPadWidget musical settings are changed if those changes
    //   don't go through SynthParametersModel immediately causing a rebuild/save here.

    if (!mounted || _panels.isEmpty) {
      print("SavePanelLayout: Not mounted or panels empty, skipping save.");
      return;
    }
    // Debounce or delay slightly to ensure state is settled.
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      List<SerializablePanelConfig> sPanels =
          _panels.map((p) => p.toSerializableConfig(context)).toList();
      await _panelStateService.savePanelStates(sPanels);
      print("Panel layout saved with ${_panels.length} panels.");
    } catch (e) {
      print("Error during _savePanelLayout: $e");
      // Optionally, show a user-facing error or log to a more persistent store.
    }
  }

  Future<bool> _loadPanelLayout() async {
    List<SerializablePanelConfig>? sPanels =
        await _panelStateService.loadPanelStates();
    if (sPanels != null && sPanels.isNotEmpty) {
      // Important: Check if context is available before using Provider.of
      if (!mounted) {
        print("LoadPanelLayout: Not mounted, skipping panel reconstruction and model update.");
        return false; // Cannot proceed without context
      }
      final model = Provider.of<SynthParametersModel>(context, listen: false);

      _panels.clear();
      for (var sPanel in sPanels) {
        _panels.add(_PanelConfig.fromSerializableConfig(sPanel));

        if (sPanel.childWidgetTypeKey == 'xyPad_1') {
          if (sPanel.xyPadRootNoteX != null) {
            model.setXYPadRootNoteX(sPanel.xyPadRootNoteX!);
          }
          if (sPanel.xyPadScaleXIndex != null &&
              sPanel.xyPadScaleXIndex! >= 0 &&
              sPanel.xyPadScaleXIndex! < MusicalScale.values.length) {
            model.setXYPadScaleX(MusicalScale.values[sPanel.xyPadScaleXIndex!]);
          } else if (sPanel.xyPadScaleXIndex != null) {
             print("Warning: Invalid xyPadScaleXIndex ${sPanel.xyPadScaleXIndex} from saved state for panel ${sPanel.id}.");
          }

          if (sPanel.yAxisAssignmentIndex != null &&
              sPanel.yAxisAssignmentIndex! >= 0 &&
              sPanel.yAxisAssignmentIndex! < XYPadAssignment.values.length) {
            model.setYAxisAssignment(XYPadAssignment.values[sPanel.yAxisAssignmentIndex!]);
          } else if (sPanel.yAxisAssignmentIndex != null) {
            print("Warning: Invalid yAxisAssignmentIndex ${sPanel.yAxisAssignmentIndex} from saved state for panel ${sPanel.id}.");
          }
        }
      }
      // No need to call setState here as _loadPanelLayoutAndInitialize will do it.
      print("Panel layout loaded from preferences with ${_panels.length} panels.");
      return true;
    }
    print("No saved panel layout found or list was empty.");
    return false;
  }

  Widget _getWidgetForTypeKey(String typeKey) {
    switch (typeKey) {
      case 'xyPad_1':
        return const XYPadWidget();
      case 'controlPanel_1':
        return const ControlPanelWidget();
      case 'keyboard_1':
        return const VirtualKeyboardWidget();
      case 'llmPresetGen_1':
        return const LlmPresetWidget();
      case 'automation_1':
        return const AutomationControlsWidget();
      case 'presets_1':
        return const PresetManagerWidget();
      case 'midiSettings_1':
        return const MidiSettingsWidget();
      case 'placeholder_1':
        return const Center(child: Text("Effects Rack Content", style: TextStyle(color: Colors.white70)));
      default:
        print("Warning: Unknown widget type key '$typeKey' encountered.");
        return const Center(child: Text("Unknown Widget Type"));
    }
  }

  void _handleUiControlEventFromStream(UiMidiEvent event) {
    print("Instance handling event from stream: ${event.toString()}");

    if (event.ccNumber == 110) { // UI_TOGGLE_VAULT (Global action)
      setState(() {
        _isVaultAreaVisible = !_isVaultAreaVisible;
      });
      return;
    }

    if (event.targetPanelId < 0 || event.targetPanelId >= _panels.length) {
      print("_handleUiControlEventFromStream: TargetPanelId ${event.targetPanelId} out of bounds for _panels length ${_panels.length}.");
      return;
    }
    final panel = _panels[event.targetPanelId];
    bool changed = false;

    switch (event.ccNumber) {
      case 102: // UI_VISIBILITY
        bool newVisibility = event.ccValue >= 64;
        if (panel.isVisibleInWorkspace != newVisibility) {
          panel.isVisibleInWorkspace = newVisibility;
          changed = true;
        }
        break;
      case 103: // UI_COLLAPSED_STATE
        bool newCollapsedState = event.ccValue >= 64;
        if (panel.isCollapsed != newCollapsedState) {
          panel.isCollapsed = newCollapsedState;
          changed = true;
        }
        break;
      case 104: // UI_POSITION_X (Normalized)
        panel.normX = (event.ccValue / 127.0).clamp(-0.1, 0.9);
        changed = true;
        break;
      case 105: // UI_POSITION_Y (Normalized)
        panel.normY = (event.ccValue / 127.0).clamp(0.0, 0.9);
        changed = true;
        break;
      case 106: // UI_SIZE_WIDTH (Normalized)
        panel.normWidth = (event.ccValue / 127.0).clamp(0.15, 1.0);
        changed = true;
        break;
      case 107: // UI_SIZE_HEIGHT (Normalized)
        panel.normHeight = (event.ccValue / 127.0).clamp(0.1, 1.0);
        changed = true;
        break;
      default:
        print("_handleUiControlEventFromStream: Unhandled UI CC ${event.ccNumber} for panel ${event.targetPanelId}");
        break;
    }

    if (changed) {
      setState(() {});
    }
  }

  void _initializePanels() {
    // Default panel layout if nothing is loaded from shared_preferences
    print("Initializing default panel layout.");
    _panels.clear();
    _panels.add(_PanelConfig(id: 'xyPad_1', title: 'XY CONTROL PAD', childWidgetTypeKey: 'xyPad_1', normX: 0.05, normY: 0.15, normWidth: 0.22, normHeight: 0.30));
    _panels.add(_PanelConfig(id: 'controlPanel_1', title: 'SYNTH CONTROLS', childWidgetTypeKey: 'controlPanel_1', normX: 0.30, normY: 0.15, normWidth: 0.22, normHeight: 0.45));
    _panels.add(_PanelConfig(id: 'keyboard_1', title: 'VIRTUAL KEYBOARD', childWidgetTypeKey: 'keyboard_1', normX: 0.05, normY: 0.65, normWidth: 0.50, normHeight: 0.20));
    _panels.add(_PanelConfig(id: 'llmPresetGen_1', title: 'AI PRESET GENERATOR', childWidgetTypeKey: 'llmPresetGen_1', normX: 0.05, normY: 0.05, normWidth: 0.30, normHeight: 0.30));
    _panels.add(_PanelConfig(id: 'automation_1', title: 'AUTOMATION', childWidgetTypeKey: 'automation_1', normX: 0.58, normY: 0.65, normWidth: 0.22, normHeight: 0.20));
    _panels.add(_PanelConfig(id: 'presets_1', title: 'PRESET MANAGER', childWidgetTypeKey: 'presets_1', normX: 0.38, normY: 0.05, normWidth: 0.22, normHeight: 0.35));
    _panels.add(_PanelConfig(id: 'midiSettings_1', title: 'MIDI SETTINGS', childWidgetTypeKey: 'midiSettings_1', normX: 0.63, normY: 0.05, normWidth: 0.22, normHeight: 0.30, isVisibleInWorkspace: false));
    _panels.add(_PanelConfig(id: 'placeholder_1', title: 'EFFECTS RACK (Vaulted)', childWidgetTypeKey: 'placeholder_1', normX: 0.63, normY: 0.40, normWidth: 0.22, normHeight: 0.25, isVisibleInWorkspace: false));

    // Don't save here by default, let loading mechanism handle initial save if needed
    if(mounted) setState(() {});
  }


  void _closePanelToVault(_PanelConfig panelConfig) {
    setState(() {
      panelConfig.isVisibleInWorkspace = false;
    });
  }

  void _showPanelFromVault(_PanelConfig panelConfig) {
    HapticFeedback.mediumImpact(); // Haptic feedback for showing from vault
    setState(() {
      panelConfig.isVisibleInWorkspace = true;
      // TODO: Future: Consider smart placement if last position is off-screen or heavily overlapping.
      // For example, reset to a default visible normX/normY if it's too far out.
      // panelConfig.normX = panelConfig.normX.clamp(0.0, 0.8);
      // panelConfig.normY = panelConfig.normY.clamp(0.0, 0.8);
    });
  }

  Widget _buildVaultArea() {
    // Use the instance visibility flag for the vault area itself
    if (!_isVaultAreaVisible) return const SizedBox.shrink();

    final hiddenPanels = _panels.where((p) => !p.isVisibleInWorkspace).toList();
    if (hiddenPanels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 10,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        margin: const EdgeInsets.symmetric(horizontal: 50), // Center it a bit
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 2.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: HolographicTheme.secondaryEnergy.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: hiddenPanels.map((panel) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ActionChip(
                  label: Text(panel.title, style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 10, glowIntensity: 0.2)),
                  tooltip: 'Show ${panel.title}',
                  backgroundColor: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: HolographicTheme.secondaryEnergy.withOpacity(0.4))
                  ),
                  onPressed: () => _showPanelFromVault(panel),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Synther Holographic Professional',
      theme: ThemeData.dark().copyWith( // Base dark theme
        // Apply HolographicTheme values if they affect MaterialApp globally
        // For now, specific widgets handle their own holographic styling.
        scaffoldBackgroundColor: Colors.black, // Ensure background for visualizer
      ),
      home: Scaffold(
        backgroundColor: Colors.black, // Main background for the visualizer to show
        body: Stack(
          children: [
            // Visualizer as the base layer
            const Positioned.fill(
              child: VisualizerBridgeWidget(
                opacity: 1.0, // Full opacity for background
                showControls: false, // Visualizer's own controls are off
              ),
            ),
            
            // Dynamically build draggable panels from the list
            ..._panels.where((panel) => panel.isVisibleInWorkspace).map((panelConfig) {
              return _buildDraggablePanel(
                panelConfig: panelConfig,
                onClosed: () => _closePanelToVault(panelConfig),
              );
            }).toList(),

            // Vault Area
            _buildVaultArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggablePanel({
    required _PanelConfig panelConfig,
    required VoidCallback onClosed,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate pixel position and size from normalized values
    final pixelX = panelConfig.normX * screenWidth;
    final pixelY = panelConfig.normY * screenHeight;
    final pixelWidth = panelConfig.normWidth * screenWidth;
    final pixelHeight = panelConfig.normHeight * screenHeight;

    // This is the frame for each draggable, resizable, collapsible panel
    return Positioned(
      left: pixelX,
      top: pixelY,
      key: panelConfig.key,
      child: Container(
        width: panelConfig.isCollapsed ? 250 : pixelWidth.clamp(150.0, 800.0), // Min/max pixel width
        height: panelConfig.isCollapsed ? 40 : pixelHeight.clamp(100.0, 700.0), // Min/max pixel height
        decoration: HolographicTheme.createHolographicBorder(
          energyColor: HolographicTheme.primaryEnergy,
          intensity: 0.8,
          cornerRadius: 10,
        ).copyWith(
          color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.25),
        ),
        child: Column(
          children: [
            // Draggable Header
            GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  // Update normalized positions
                  panelConfig.normX = (pixelX + details.delta.dx) / screenWidth;
                  panelConfig.normY = (pixelY + details.delta.dy) / screenHeight;
                  // Clamp normalized positions to keep panel somewhat on screen
                  panelConfig.normX = panelConfig.normX.clamp(-0.75, 0.9); // Allow some offscreen
                  panelConfig.normY = panelConfig.normY.clamp(0.0, 0.9);
                });
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.activeTransparency * 0.8), // Use theme color
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                   border: Border(bottom: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.hoverTransparency), width: 1)), // Use theme color
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator, color: HolographicTheme.secondaryEnergy, size: 18), // Use theme color
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        panelConfig.title,
                        style: HolographicTheme.createHolographicText( // Already uses theme
                          energyColor: HolographicTheme.primaryEnergy,
                          fontSize: 13,
                          glowIntensity: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Collapse Button
                    IconButton(
                      icon: Icon(
                        panelConfig.isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: HolographicTheme.secondaryEnergy, // Use theme color
                        size: 18,
                      ),
                      tooltip: panelConfig.isCollapsed ? "Expand" : "Collapse",
                      onPressed: () {
                        setState(() {
                          bool isNowCollapsed = !panelConfig.isCollapsed;
                          panelConfig.isCollapsed = isNowCollapsed;
                          if (isNowCollapsed) {
                            HapticFeedback.lightImpact();
                          } else {
                            HapticFeedback.mediumImpact();
                          }
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      splashRadius: 18,
                    ),
                    const SizedBox(width: 4),
                    // Close to Vault Button
                    IconButton(
                      icon: Icon(
                        Icons.visibility_off_outlined,
                        color: HolographicTheme.secondaryEnergy.withOpacity(0.8), // Use theme color
                        size: 16,
                      ),
                      tooltip: "Hide (Send to Vault)",
                      onPressed: () {
                        HapticFeedback.mediumImpact(); // Haptic feedback for closing to vault
                        onClosed();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24), // Ensure tap area
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            // Content Area
            if (!panelConfig.isCollapsed)
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    // Panel-level collapse/expand is handled by this _buildDraggablePanel widget's
                    // conditional rendering of this Expanded section and its height adjustment.
                    // The childWidget itself is rendered with the full allocated space when the panel is expanded.
                    // Any internal collapse/resize logic within the childWidget (e.g. its own header's
                    // collapse button or internal scrollability) is not currently explicitly invoked
                    // or managed by this draggable panel framework. The child is responsible for its own
                    // content layout within the space provided by this panel.
                    child: _getWidgetForTypeKey(panelConfig.childWidgetTypeKey),
                  ),
                ),
              ),

            // Resize Handle
            if (!panelConfig.isCollapsed)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      final newPixelWidth = (pixelWidth + details.delta.dx).clamp(150.0, 800.0);
                      final newPixelHeight = (pixelHeight + details.delta.dy).clamp(100.0, 700.0);
                      panelConfig.normWidth = newPixelWidth / screenWidth;
                      panelConfig.normHeight = newPixelHeight / screenHeight;
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                       color: HolographicTheme.secondaryText.withOpacity(HolographicTheme.widgetTransparency * 1.2), // Use theme color
                       borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8)),
                    ),
                    child: Icon(Icons.open_in_full_rounded, color: HolographicTheme.secondaryEnergy.withOpacity(0.9), size: 12), // Use theme color
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Placeholder build methods for actual synth components ---
  // These are now replaced by directly using the imported feature widgets
  // in _PanelConfig.childWidget.
  // Widget _buildInteractiveXYPad() => const XYPadWidget(); // Example
  // Widget _buildInteractiveControls() => const ControlPanelWidget(); // Example
  // Widget _buildInteractiveKeyboard() => const VirtualKeyboardWidget(); // Example
  // Widget _buildInteractivePresetBar() => const LlmPresetWidget(); // Example
}

// --- Dummy Painters (if they were defined in this file) ---
// These should be in their respective widget files or a shared painter file.
// For brevity, assuming they are defined elsewhere or not needed here directly.
// class InteractiveXYPainter extends CustomPainter { ... }
// class InteractiveKnobPainter extends CustomPainter { ... }