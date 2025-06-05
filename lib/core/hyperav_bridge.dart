// HyperAV Bridge - Connects Flutter to your 4D visualizer system
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class HyperAVBridge {
  static HyperAVBridge? _instance;
  static HyperAVBridge get instance => _instance ??= HyperAVBridge._();
  
  HyperAVBridge._();
  
  html.IFrameElement? _visualizerFrame;
  bool _isInitialized = false;
  
  // Connect to your existing HyperAV visualizer
  Future<void> initialize() async {
    if (!kIsWeb) return;
    
    try {
      // Create iframe to load your HyperAV visualizer
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
      _isInitialized = true;
      
      debugPrint('✅ HyperAV visualizer connected successfully');
    } catch (e) {
      debugPrint('❌ HyperAV initialization error: $e');
    }
  }
  
  Future<void> _waitForVisualizerLoad() async {
    // Wait for your visualizer to be ready
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
  
  // Mount the visualizer in the background
  void mountVisualizerBackground(html.Element container) {
    if (!kIsWeb || _visualizerFrame == null) return;
    
    container.children.clear();
    container.append(_visualizerFrame!);
  }
  
  // Update visualizer parameters from synthesizer controls
  void updateVisualizerParameter(String paramName, double value) {
    if (!kIsWeb || !_isInitialized) return;
    
    try {
      // Map synthesizer parameters to visualizer parameters
      final visualizerParam = _mapSynthToVisualizerParam(paramName, value);
      
      // Send to your HyperAV system
      _visualizerFrame?.contentWindow?.postMessage({
        'type': 'updateParameter',
        'parameter': visualizerParam['name'],
        'value': visualizerParam['value'],
      }, '*');
      
    } catch (e) {
      debugPrint('Error updating visualizer: $e');
    }
  }
  
  // Send audio data to visualizer for real-time reactivity
  void updateAudioData({
    required double bass,
    required double mid,
    required double high,
    double? pitch,
    String? note,
  }) {
    if (!kIsWeb || !_isInitialized) return;
    
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
  
  // Map synthesizer parameters to your HyperAV visualizer parameters
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
  
  // Trigger special visualizer effects
  void triggerVisualizerEffect(String effectName, {Map<String, dynamic>? params}) {
    if (!kIsWeb || !_isInitialized) return;
    
    _visualizerFrame?.contentWindow?.postMessage({
      'type': 'triggerEffect',
      'effect': effectName,
      'params': params ?? {},
    }, '*');
  }
  
  // Change visualizer geometry type
  void setGeometryType(String geometryType) {
    if (!kIsWeb || !_isInitialized) return;
    
    _visualizerFrame?.contentWindow?.postMessage({
      'type': 'setGeometry',
      'geometry': geometryType, // 'hypercube', 'hypersphere', 'hypertetrahedron'
    }, '*');
  }
  
  // Set projection method
  void setProjectionMethod(String projectionMethod) {
    if (!kIsWeb || !_isInitialized) return;
    
    _visualizerFrame?.contentWindow?.postMessage({
      'type': 'setProjection',
      'projection': projectionMethod, // 'perspective', 'orthographic', 'stereographic'
    }, '*');
  }
  
  void dispose() {
    _visualizerFrame?.remove();
    _visualizerFrame = null;
    _isInitialized = false;
  }
}