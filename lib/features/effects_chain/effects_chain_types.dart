// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:core'; // Required for 'name' in String extension, though not directly used if manually switching

enum EffectType {
  reverb,
  delay,
  filter,
  distortion,
  chorus
}

extension EffectTypeExtension on EffectType {
  String get displayName {
    switch (this) {
      case EffectType.reverb: return 'Reverb';
      case EffectType.delay: return 'Delay';
      case EffectType.filter: return 'Filter';
      case EffectType.distortion: return 'Distortion';
      case EffectType.chorus: return 'Chorus';
      default: return 'Unknown Effect';
    }
  }
}

class EffectUnitConfig {
  final String id;
  String name;
  EffectType type;
  bool bypass;
  // Placeholder for parameters - actual parameters would be more complex
  // In a real scenario, this might be a specific class instance per EffectType,
  // or a more structured map.
  Map<String, dynamic> params;

  EffectUnitConfig({
    required this.id,
    required this.name,
    required this.type,
    this.bypass = false,
    Map<String, dynamic>? initialParams,
  }) : params = initialParams ?? {};

  // Basic toString for debugging
  @override
  String toString() {
    return 'EffectUnitConfig(id: $id, name: $name, type: ${type.displayName}, bypass: $bypass, params: $params)';
  }
}
