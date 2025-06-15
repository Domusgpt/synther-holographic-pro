import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Note: MusicalScale and XYPadAssignment enums would ideally be imported from a shared location.
// For this service, we'll assume their indices are used for serialization.

class SerializablePanelConfig {
  final String id;
  final String title;
  final String childWidgetTypeKey; // Key to recreate the actual widget
  double normX, normY, normWidth, normHeight;
  bool isCollapsed;
  bool isVisibleInWorkspace;

  // XY Pad specific musical settings (example)
  int? xyPadRootNoteX;      // MIDI note offset (0-11)
  int? xyPadScaleXIndex;    // Index of MusicalScale enum
  int? yAxisAssignmentIndex;// Index of XYPadAssignment enum for Y-axis
  // Note: xAxisAssignment is implicitly 'Pitch' if XYPad is quantized, or could be stored if configurable

  SerializablePanelConfig({
    required this.id,
    required this.title,
    required this.childWidgetTypeKey,
    required this.normX,
    required this.normY,
    required this.normWidth,
    required this.normHeight,
    required this.isCollapsed,
    required this.isVisibleInWorkspace,
    this.xyPadRootNoteX,
    this.xyPadScaleXIndex,
    this.yAxisAssignmentIndex,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'childWidgetTypeKey': childWidgetTypeKey,
    'normX': normX,
    'normY': normY,
    'normWidth': normWidth,
    'normHeight': normHeight,
    'isCollapsed': isCollapsed,
    'isVisibleInWorkspace': isVisibleInWorkspace,
    // XY Pad specific
    'xyPadRootNoteX': xyPadRootNoteX,
    'xyPadScaleXIndex': xyPadScaleXIndex,
    'yAxisAssignmentIndex': yAxisAssignmentIndex,
  };

  factory SerializablePanelConfig.fromJson(Map<String, dynamic> json) =>
      SerializablePanelConfig(
        id: json['id'] as String,
        title: json['title'] as String,
        childWidgetTypeKey: json['childWidgetTypeKey'] as String,
        normX: (json['normX'] as num).toDouble(),
        normY: (json['normY'] as num).toDouble(),
        normWidth: (json['normWidth'] as num).toDouble(),
        normHeight: (json['normHeight'] as num).toDouble(),
        isCollapsed: json['isCollapsed'] as bool,
        isVisibleInWorkspace: json['isVisibleInWorkspace'] as bool,
        // XY Pad specific
        xyPadRootNoteX: json['xyPadRootNoteX'] as int?,
        xyPadScaleXIndex: json['xyPadScaleXIndex'] as int?,
        yAxisAssignmentIndex: json['yAxisAssignmentIndex'] as int?,
      );
}

class PanelStateService {
  static const String _panelStatesKey = 'panel_states_v1'; // Added a version suffix

  Future<void> savePanelStates(List<SerializablePanelConfig> panelConfigs) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> panelConfigsJson =
        panelConfigs.map((pc) => jsonEncode(pc.toJson())).toList();
    await prefs.setStringList(_panelStatesKey, panelConfigsJson);
    print("PanelStateService: Saved ${panelConfigs.length} panel states.");
  }

  Future<List<SerializablePanelConfig>?> loadPanelStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? panelConfigsJson = prefs.getStringList(_panelStatesKey);
      if (panelConfigsJson == null) {
        print("PanelStateService: No panel states found in shared_preferences.");
        return null;
      }
      List<SerializablePanelConfig> configs = panelConfigsJson
          .map((jsonString) =>
              SerializablePanelConfig.fromJson(jsonDecode(jsonString)))
          .toList();
      print("PanelStateService: Loaded ${configs.length} panel states.");
      return configs;
    } catch (e) {
      print("PanelStateService: Error loading panel states: $e");
      // Optionally clear corrupted data
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove(_panelStatesKey);
      return null;
    }
  }
}
