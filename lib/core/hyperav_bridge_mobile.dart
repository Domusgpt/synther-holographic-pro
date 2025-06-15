// HyperAV Bridge - Mobile Implementation (iOS/Android)
import 'package:flutter/foundation.dart';
import 'hyperav_bridge_interface.dart';

/// Mobile-specific implementation of HyperAV Bridge
/// This is a stub implementation since 4D visualizer is web-only
class HyperAVBridgeImpl extends HyperAVBridgeInterface {
  bool _isInitialized = false;
  
  @override
  Future<void> initialize() async {
    _isInitialized = true;
    debugPrint('HyperAV Bridge: Mobile implementation initialized (visualizer not available)');
  }
  
  @override
  void mountVisualizerBackground(dynamic container) {
    // No-op - visualizer not available on mobile
    debugPrint('HyperAV Bridge: Visualizer mounting not available on mobile');
  }
  
  @override
  void updateVisualizerParameter(String paramName, double value) {
    // No-op - visualizer not available on mobile
    // Could potentially log parameter changes for debugging
    if (kDebugMode) {
      debugPrint('HyperAV Bridge: Parameter $paramName = $value (mobile - no visualizer)');
    }
  }
  
  @override
  void updateAudioData({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  }) {
    // No-op - visualizer not available on mobile
    // Could potentially store audio data for other uses
    if (kDebugMode) {
      debugPrint('HyperAV Bridge: Audio data - Bass: $bass, Mid: $mid, High: $high (mobile - no visualizer)');
    }
  }
  
  @override
  void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params}) {
    // No-op - visualizer not available on mobile
    debugPrint('HyperAV Bridge: Effect $effectName triggered (mobile - no visualizer)');
  }
  
  @override
  void setGeometryType(String geometryType) {
    // No-op - visualizer not available on mobile
    debugPrint('HyperAV Bridge: Geometry type $geometryType set (mobile - no visualizer)');
  }
  
  @override
  void setProjectionMethod(String projectionMethod) {
    // No-op - visualizer not available on mobile
    debugPrint('HyperAV Bridge: Projection method $projectionMethod set (mobile - no visualizer)');
  }
  
  @override
  void dispose() {
    _isInitialized = false;
    debugPrint('HyperAV Bridge: Mobile implementation disposed');
  }
}