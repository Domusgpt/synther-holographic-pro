// HyperAV Bridge - Simple Platform Detection
import 'package:flutter/foundation.dart';

/// Abstract interface for HyperAV visualizer bridge
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

/// Simple implementation that uses kIsWeb for platform detection
class HyperAVBridgeImpl extends HyperAVBridgeInterface {
  bool _isInitialized = false;
  
  @override
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      if (kIsWeb) {
        debugPrint('✅ HyperAV visualizer initialized (web)');
      } else {
        debugPrint('HyperAV Bridge: Mobile implementation initialized (visualizer not available)');
      }
    } catch (e) {
      debugPrint('❌ HyperAV initialization error: $e');
    }
  }
  
  @override
  void mountVisualizerBackground(dynamic container) {
    if (!kIsWeb) {
      debugPrint('HyperAV Bridge: Visualizer mounting not available on mobile');
      return;
    }
    
    // Web implementation would go here
    debugPrint('HyperAV Bridge: Mounting visualizer background (web)');
  }
  
  @override
  void updateVisualizerParameter(String paramName, double value) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      // Web implementation - would communicate with iframe
      debugPrint('HyperAV Bridge: Parameter $paramName = $value (web)');
    } else {
      // Mobile implementation - log only
      if (kDebugMode) {
        debugPrint('HyperAV Bridge: Parameter $paramName = $value (mobile - no visualizer)');
      }
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
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      // Web implementation - would send to iframe
      debugPrint('HyperAV Bridge: Audio data - Bass: $bass, Mid: $mid, High: $high (web)');
    } else {
      // Mobile implementation - log only
      if (kDebugMode) {
        debugPrint('HyperAV Bridge: Audio data - Bass: $bass, Mid: $mid, High: $high (mobile - no visualizer)');
      }
    }
  }
  
  @override
  void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params}) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      debugPrint('HyperAV Bridge: Effect $effectName triggered (web)');
    } else {
      debugPrint('HyperAV Bridge: Effect $effectName triggered (mobile - no visualizer)');
    }
  }
  
  @override
  void setGeometryType(String geometryType) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      debugPrint('HyperAV Bridge: Geometry type $geometryType set (web)');
    } else {
      debugPrint('HyperAV Bridge: Geometry type $geometryType set (mobile - no visualizer)');
    }
  }
  
  @override
  void setProjectionMethod(String projectionMethod) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      debugPrint('HyperAV Bridge: Projection method $projectionMethod set (web)');
    } else {
      debugPrint('HyperAV Bridge: Projection method $projectionMethod set (mobile - no visualizer)');
    }
  }
  
  @override
  void dispose() {
    if (kIsWeb) {
      debugPrint('HyperAV Bridge: Web implementation disposed');
    } else {
      debugPrint('HyperAV Bridge: Mobile implementation disposed');
    }
    _isInitialized = false;
  }
}

/// Main HyperAV Bridge accessor
class HyperAVBridge {
  static HyperAVBridgeInterface? _instance;
  static HyperAVBridgeInterface get instance => _instance ??= HyperAVBridgeImpl();
  
  // Convenience static methods
  static Future<void> initialize() => instance.initialize();
  static void mountVisualizerBackground(dynamic container) => instance.mountVisualizerBackground(container);
  static void updateVisualizerParameter(String paramName, double value) => instance.updateVisualizerParameter(paramName, value);
  static void updateAudioData({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  }) => instance.updateAudioData(bass: bass, mid: mid, high: high, pitch: pitch, note: note);
  static void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params}) => instance.triggerVisualizerEffect(effectName, params: params);
  static void setGeometryType(String geometryType) => instance.setGeometryType(geometryType);
  static void setProjectionMethod(String projectionMethod) => instance.setProjectionMethod(projectionMethod);
  static void dispose() => instance.dispose();
}