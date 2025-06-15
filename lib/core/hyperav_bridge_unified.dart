// HyperAV Bridge - Unified Implementation
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

/// Unified implementation that works on all platforms
class HyperAVBridgeImpl extends HyperAVBridgeInterface {
  bool _isInitialized = false;
  dynamic _visualizerFrame; // Will be html.IFrameElement on web, null on mobile
  
  @override
  Future<void> initialize() async {
    if (kIsWeb) {
      await _initializeWeb();
    } else {
      await _initializeMobile();
    }
    _isInitialized = true;
  }
  
  Future<void> _initializeWeb() async {
    try {
      // Web-specific initialization using dynamic import
      if (kIsWeb) {
        // Import dart:html dynamically only on web
        final html = await import('dart:html');
        
        // Create iframe to load HyperAV visualizer - web only
        _visualizerFrame = html.IFrameElement()
          ..src = '/assets/visualizer/index-flutter.html'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.border = 'none'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0'
          ..style.zIndex = '-1' // Behind the controls
          ..style.pointerEvents = 'none'; // Let touches pass through to controls
        
        // Wait for visualizer to load
        await _waitForVisualizerLoad();
        
        debugPrint('✅ HyperAV visualizer connected successfully (web)');
      }
    } catch (e) {
      debugPrint('❌ HyperAV web initialization error: $e');
    }
  }
  
  Future<void> _initializeMobile() async {
    debugPrint('HyperAV Bridge: Mobile implementation initialized (visualizer not available)');
  }
  
  Future<void> _waitForVisualizerLoad() async {
    if (!kIsWeb) return;
    
    // Wait for visualizer to be ready
    int attempts = 0;
    while (attempts < 50) {
      try {
        if (_visualizerFrame?.contentWindow != null) {
          break;
        }
      } catch (e) {
        // Still loading
      }
      
      await Future.delayed(Duration(milliseconds: 100));
      attempts++;
    }
  }
  
  @override
  void mountVisualizerBackground(dynamic container) {
    if (!kIsWeb || _visualizerFrame == null) return;
    
    try {
      // On web, container should be an html.Element
      container?.children?.clear();
      container?.append(_visualizerFrame);
    } catch (e) {
      debugPrint('Error mounting visualizer: $e');
    }
  }
  
  @override
  void updateVisualizerParameter(String paramName, double value) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      _updateVisualizerParameterWeb(paramName, value);
    } else {
      _updateVisualizerParameterMobile(paramName, value);
    }
  }
  
  void _updateVisualizerParameterWeb(String paramName, double value) {
    try {
      // Map synthesizer parameters to visualizer parameters
      final visualizerParam = _mapSynthToVisualizerParam(paramName, value);
      
      // Send to HyperAV system
      _visualizerFrame?.contentWindow?.postMessage({
        'type': 'updateParameter',
        'parameter': visualizerParam['name'],
        'value': visualizerParam['value'],
      }, '*');
      
    } catch (e) {
      debugPrint('Error updating visualizer: $e');
    }
  }
  
  void _updateVisualizerParameterMobile(String paramName, double value) {
    // Log parameter changes for debugging on mobile
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
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      _updateAudioDataWeb(bass: bass, mid: mid, high: high, pitch: pitch, note: note);
    } else {
      _updateAudioDataMobile(bass: bass, mid: mid, high: high, pitch: pitch, note: note);
    }
  }
  
  void _updateAudioDataWeb({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  }) {
    try {
      _visualizerFrame?.contentWindow?.postMessage({
        'type': 'audioData',
        'bass': bass,
        'mid': mid,
        'high': high,
        'pitch': pitch ?? 0.0,
        'note': note ?? 'A',
      }, '*');
    } catch (e) {
      debugPrint('Error sending audio data: $e');
    }
  }
  
  void _updateAudioDataMobile({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  }) {
    if (kDebugMode) {
      debugPrint('HyperAV Bridge: Audio data - Bass: $bass, Mid: $mid, High: $high (mobile - no visualizer)');
    }
  }
  
  @override
  void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params}) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      try {
        _visualizerFrame?.contentWindow?.postMessage({
          'type': 'triggerEffect',
          'effect': effectName,
          'params': params ?? {},
        }, '*');
      } catch (e) {
        debugPrint('Error triggering effect: $e');
      }
    } else {
      debugPrint('HyperAV Bridge: Effect $effectName triggered (mobile - no visualizer)');
    }
  }
  
  @override
  void setGeometryType(String geometryType) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      try {
        _visualizerFrame?.contentWindow?.postMessage({
          'type': 'setGeometry',
          'geometry': geometryType, // 'hypercube', 'hypersphere', 'hypertetrahedron'
        }, '*');
      } catch (e) {
        debugPrint('Error setting geometry: $e');
      }
    } else {
      debugPrint('HyperAV Bridge: Geometry type $geometryType set (mobile - no visualizer)');
    }
  }
  
  @override
  void setProjectionMethod(String projectionMethod) {
    if (!_isInitialized) return;
    
    if (kIsWeb) {
      try {
        _visualizerFrame?.contentWindow?.postMessage({
          'type': 'setProjection',
          'projection': projectionMethod, // 'perspective', 'orthographic', 'stereographic'
        }, '*');
      } catch (e) {
        debugPrint('Error setting projection: $e');
      }
    } else {
      debugPrint('HyperAV Bridge: Projection method $projectionMethod set (mobile - no visualizer)');
    }
  }
  
  @override
  void dispose() {
    if (kIsWeb) {
      try {
        _visualizerFrame?.remove();
      } catch (e) {
        debugPrint('Error disposing visualizer: $e');
      }
    }
    _visualizerFrame = null;
    _isInitialized = false;
  }
  
  // Map synthesizer parameters to HyperAV visualizer parameters
  Map<String, dynamic> _mapSynthToVisualizerParam(String synthParam, double value) {
    switch (synthParam) {
      case 'cutoff':
        return {'name': 'gridDensity', 'value': value * 16.0}; // 0-1 -> 0-16
      case 'resonance':
        return {'name': 'lineThickness', 'value': value * 0.1}; // 0-1 -> 0-0.1
      case 'reverb':
        return {'name': 'morphFactor', 'value': value}; // 0-1 -> 0-1
      case 'distortion':
        return {'name': 'glitchIntensity', 'value': value * 0.5}; // 0-1 -> 0-0.5
      case 'volume':
        return {'name': 'patternIntensity', 'value': 0.5 + value}; // 0-1 -> 0.5-1.5
      case 'attack':
        return {'name': 'rotationSpeed', 'value': value * 2.0}; // 0-1 -> 0-2
      case 'decay':
        return {'name': 'universeModifier', 'value': 0.5 + value * 1.5}; // 0-1 -> 0.5-2
      default:
        return {'name': 'colorShift', 'value': value}; // Default mapping
    }
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