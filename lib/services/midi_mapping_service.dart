import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // For @immutable
import '../ui/widgets/holographic_assignable_knob.dart';

/// Identifies a MIDI Continuous Controller (CC) message.
///
/// Uniquely defined by a [ccNumber] and an optional MIDI [channel].
/// If [channel] is -1 (default), it signifies "any channel".
@immutable
class MidiCcIdentifier {
  final int ccNumber;
  final int channel; // 0-15, or a special value like -1 for any channel

  const MidiCcIdentifier({required this.ccNumber, this.channel = -1}); // Default to any channel

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiCcIdentifier &&
          runtimeType == other.runtimeType &&
          ccNumber == other.ccNumber &&
          channel == other.channel;

  @override
  int get hashCode => ccNumber.hashCode ^ channel.hashCode;

  Map<String, dynamic> toJson() => {
        'ccNumber': ccNumber,
        'channel': channel,
      };

  factory MidiCcIdentifier.fromJson(Map<String, dynamic> json) => MidiCcIdentifier(
        ccNumber: json['ccNumber'] as int,
        channel: json['channel'] as int? ?? -1,
      );

  @override
  String toString() => 'CC $ccNumber${channel != -1 ? " (Ch ${channel + 1})" : ""}';
}

/// Manages MIDI CC mappings to synthesizer parameters ([SynthParameterType]).
///
/// This service allows assigning a MIDI CC identifier (controller number and optionally channel)
/// to a specific synthesizer parameter. These mappings are persisted locally using
/// `shared_preferences`.
///
/// It provides methods to:
/// - Assign a mapping.
/// - Retrieve the parameter associated with a MIDI CC.
/// - Retrieve the MIDI CC associated with a parameter.
/// - Load and save mappings.
///
/// The service is implemented as a singleton.
class MidiMappingService {
  // Singleton pattern
  static final MidiMappingService _instance = MidiMappingService._internal();
  factory MidiMappingService() => _instance;
  MidiMappingService._internal() {
    // Load mappings when the service is first initialized.
    // Note: This is synchronous in the constructor which is generally okay for
    // a singleton that's initialized early, but for heavier async operations,
    // an explicit init method is better. SharedPreferences is typically fast.
    _loadMappingsSync();
  }

  static MidiMappingService get instance => _instance;

  final Map<MidiCcIdentifier, SynthParameterType> _mappings = {};
  final Map<SynthParameterType, MidiCcIdentifier> _reverseMappings = {}; // For quick lookup

  static const String _mappingsKey = 'midi_cc_mappings';

  // Synchronous load for constructor, not ideal but works for SharedPreferences
  ///
  /// This method is called by the constructor. For more controlled asynchronous
  /// loading, use [loadMappings].
  void _loadMappingsSync() {
    // This is a workaround because async cannot be in constructor directly.
    // A proper solution would be an async init method called after construction.
    SharedPreferences.getInstance().then((prefs) {
        final String? jsonString = prefs.getString(_mappingsKey);
        if (jsonString != null) {
          try {
            final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
            jsonMap.forEach((key, value) {
              // Key is "ccNumber_channel", value is SynthParameterType enum index
              final parts = key.split('_');
              if (parts.length == 2) {
                final cc = int.tryParse(parts[0]);
                final ch = int.tryParse(parts[1]);
                final paramIndex = value is int ? value : int.tryParse(value.toString());

                if (cc != null && ch != null && paramIndex != null && paramIndex < SynthParameterType.values.length) {
                  final identifier = MidiCcIdentifier(ccNumber: cc, channel: ch);
                  final paramType = SynthParameterType.values[paramIndex];
                  _mappings[identifier] = paramType;
                  _reverseMappings[paramType] = identifier;
                }
              }
            });
            debugPrint("MidiMappingService: Loaded ${_mappings.length} mappings.");
          } catch (e) {
            debugPrint("MidiMappingService: Error decoding mappings: $e");
            // Optionally clear corrupted mappings
            // prefs.remove(_mappingsKey);
          }
        }
    }).catchError((e) {
        debugPrint("MidiMappingService: Error loading SharedPreferences: $e");
    });
  }

  /// Loads MIDI CC mappings from `shared_preferences`.
  ///
  /// This method clears any existing in-memory mappings before loading.
  /// It should be called at app startup to restore persisted mappings.
  Future<void> loadMappings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_mappingsKey);
    _mappings.clear();
    _reverseMappings.clear();
    if (jsonString != null) {
      try {
        final Map<String, dynamic> jsonMap = json.decode(jsonString) as Map<String, dynamic>;
         jsonMap.forEach((key, value) {
            final parts = key.split('_');
            if (parts.length == 2) {
              final cc = int.tryParse(parts[0]);
              final ch = int.tryParse(parts[1]);
              final paramIndex = value is int ? value : int.tryParse(value.toString());

              if (cc != null && ch != null && paramIndex != null && paramIndex < SynthParameterType.values.length) {
                final identifier = MidiCcIdentifier(ccNumber: cc, channel: ch);
                final paramType = SynthParameterType.values[paramIndex];
                _mappings[identifier] = paramType;
                _reverseMappings[paramType] = identifier;
              }
            }
        });
        debugPrint("MidiMappingService: Loaded ${_mappings.length} mappings.");
      } catch (e) {
         debugPrint("MidiMappingService: Error decoding mappings on load: $e");
      }
    }
  }

  /// Assigns a [SynthParameterType] to a [MidiCcIdentifier].
  ///
  /// This will overwrite any existing mapping for the given parameter or CC identifier.
  /// The mappings are then persisted.
  Future<void> assignMapping(SynthParameterType param, MidiCcIdentifier cc) async {
    // Remove any existing mapping for this parameter or this CC identifier to avoid conflicts
    _mappings.removeWhere((key, value) => value == param || key == cc);
    _reverseMappings.removeWhere((key, value) => key == param || value == cc);

    _mappings[cc] = param;
    _reverseMappings[param] = cc;
    await saveMappings();
    debugPrint("MidiMappingService: Assigned $param to $cc. Total mappings: ${_mappings.length}");
  }

  /// Retrieves the [SynthParameterType] mapped to the given [MidiCcIdentifier].
  ///
  /// It first attempts an exact match (CC number and channel). If no exact match is found
  /// and the input `cc.channel` is specific (not -1), it then attempts to find a mapping
  /// for the same CC number but with "any channel" (channel = -1).
  SynthParameterType? getParameterForCc(MidiCcIdentifier cc) {
    // First, try exact match (ccNumber and channel)
    if (_mappings.containsKey(cc)) {
      return _mappings[cc];
    }
    // If no exact match, try with "any channel" (-1) if the incoming CC had a specific channel
    if (cc.channel != -1) {
      final anyChannelIdentifier = MidiCcIdentifier(ccNumber: cc.ccNumber, channel: -1);
      if (_mappings.containsKey(anyChannelIdentifier)) {
        return _mappings[anyChannelIdentifier];
      }
    }
    return null;
  }

  /// Retrieves the [MidiCcIdentifier] mapped to the given [SynthParameterType].
  MidiCcIdentifier? getCcForParameter(SynthParameterType param) {
    return _reverseMappings[param];
  }

  /// Removes the mapping for a given [SynthParameterType].
  Future<void> removeMappingForParameter(SynthParameterType param) async {
    final cc = _reverseMappings.remove(param);
    if (cc != null) {
      _mappings.remove(cc);
    }
    await saveMappings();
  }

  /// Saves the current in-memory mappings to `shared_preferences`.
  ///
  /// Mappings are stored as a JSON string. `SynthParameterType` is stored by its enum index.
  /// `MidiCcIdentifier` is stored as a string key "ccNumber_channel".
  Future<void> saveMappings() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Store SynthParameterType as its enum index for stable serialization
    final Map<String, int> storableMap = _mappings.map(
      (identifier, paramType) => MapEntry("${identifier.ccNumber}_${identifier.channel}", paramType.index),
    );
    final String jsonString = json.encode(storableMap);
    await prefs.setString(_mappingsKey, jsonString);
    debugPrint("MidiMappingService: Saved ${_mappings.length} mappings.");
  }

  /// Returns an unmodifiable view of all current MIDI CC mappings.
  Map<MidiCcIdentifier, SynthParameterType> getAllMappings() {
    return Map.unmodifiable(_mappings);
  }
}

// Example of a simple MidiCcMessage class
class MidiCcMessage {
  final int channel; // 0-15
  final int ccNumber;
  final int value; // 0-127

  MidiCcMessage({required this.channel, required this.ccNumber, required this.value});
}
