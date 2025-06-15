// HyperAV Bridge - Abstract Interface
import 'package:flutter/foundation.dart';

/// Abstract interface for HyperAV visualizer bridge
/// Provides a platform-agnostic way to interact with the 4D visualizer
abstract class HyperAVBridgeInterface {
  
  /// Initialize the visualizer bridge
  Future<void> initialize();
  
  /// Mount the visualizer in the background
  void mountVisualizerBackground(dynamic container);
  
  /// Update visualizer parameters from synthesizer controls
  void updateVisualizerParameter(String paramName, double value);
  
  /// Send audio data to visualizer for real-time reactivity
  void updateAudioData({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  });
  
  /// Trigger special visualizer effects
  void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params});
  
  /// Change visualizer geometry type
  void setGeometryType(String geometryType);
  
  /// Set projection method
  void setProjectionMethod(String projectionMethod);
  
  /// Dispose of resources
  void dispose();
}

/// Factory function to create platform-specific implementation
HyperAVBridgeInterface createHyperAVBridge() {
  throw UnsupportedError('Platform not supported');
}