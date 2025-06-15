import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui' as ui; // Corrected from dart:ui_web to dart:ui for platformViewRegistry
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';
import '../../core/parameter_visualizer_bridge.dart';
import '../../design_system/design_system.dart'; // Assuming this exists

class MorphUIVisualizerBridge extends StatefulWidget {
  final Widget? child;
  final bool enableBackground;
  final double backgroundOpacity;
  final bool enableTinting;
  final Function(String, Color, double)? onParameterTint;
  
  const MorphUIVisualizerBridge({
    Key? key,
    this.child,
    this.enableBackground = true,
    this.backgroundOpacity = 0.6,
    this.enableTinting = true,
    this.onParameterTint,
  }) : super(key: key);
  
  @override
  State<MorphUIVisualizerBridge> createState() => _MorphUIVisualizerBridgeState();
}

class _MorphUIVisualizerBridgeState extends State<MorphUIVisualizerBridge> 
    with TickerProviderStateMixin {
  late html.IFrameElement _iFrameElement;
  // final String _viewType = 'morph-ui-visualizer'; // Consider making this unique per instance if needed
  bool _isVisualizerReady = false; // JS visualizer ready
  bool _isIframeLoaded = false; // Iframe DOM loaded
  
  late AnimationController _connectionController;
  late AnimationController _tintController;
  late Animation<double> _connectionAnimation;
  // late Animation<double> _tintAnimation; // Already declared in original
  
  final ParameterVisualizerBridge _parameterBridge = ParameterVisualizerBridge();
  final Map<String, Color> _activeTints = {};
  String _viewType = ''; // Made non-final and initialized in initState
  
  @override
  void initState() {
    super.initState();
    _viewType = 'morph-ui-visualizer-${hashCode}'; // Make viewType unique

    _connectionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _tintController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _connectionAnimation = CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeInOut,
    );
    
    // _tintAnimation = CurvedAnimation(parent: _tintController, curve: Curves.easeInOut); // Already in original
    
    _setupVisualizer();
    _initializeParameterBridge();
  }
  
  void _setupVisualizer() {
    _iFrameElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.pointerEvents = widget.child != null ? 'none' : 'auto'
      ..src = 'assets/visualizer/index-flutter.html' // Ensure this is the correct, updated HTML
      ..onLoad.listen((_) {
        if (!mounted) return;
        setState(() {
          _isIframeLoaded = true;
        });
        debugPrint('MorphUI Visualizer: IFrame DOM loaded for $_viewType.');
        // JS will postMessage {'type': 'visualizer_ready'} when its internal init is done
      });
    
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory( // Using dart:ui's platformViewRegistry
      _viewType,
      (int viewId) => _iFrameElement,
    );

    // Listen for messages from JS (e.g. visualizer_ready)
    html.window.addEventListener('message', _handleJsMessages);
  }
  
  void _handleJsMessages(html.Event event) {
    if (!mounted) return;
    if (event is html.MessageEvent) {
      final data = event.data;
      // Optional: Check event.origin for security
      // if (event.origin != Uri.base.origin) {
      //   debugPrint("Ignoring message from different origin: ${event.origin}");
      //   return;
      // }

      if (data is Map && data.containsKey('type')) {
        switch (data['type']) {
          case 'visualizer_ready':
            if (data['status'] == 'success') {
              debugPrint('MorphUI Visualizer: JS reported ready for $_viewType!');
              setState(() {
                _isVisualizerReady = true;
              });
              _connectionController.forward();
              _initializeVisualizerDefaults(); // Send initial params now
            } else {
               debugPrint('MorphUI Visualizer: JS reported error on ready: ${data['message']}');
               // Handle error state
            }
            break;
          case 'parameter_feedback':
            // Handle parameter feedback if JS sends any
            break;
          case 'performance_stats':
            // Handle performance stats if JS sends any
            break;
        }
      }
    }
  }

  void _initializeParameterBridge() {
    _parameterBridge.initialize(
      visualizerUpdateCallback: _updateVisualizerParameterViaBridge, // Changed name for clarity
      uiTintCallback: widget.enableTinting ? _handleUITinting : null,
    );
  }
  
  // Called by ParameterVisualizerBridge
  void _updateVisualizerParameterViaBridge(String parameter, double value) {
    if (!_isVisualizerReady) return;
    try {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'updateParameter',
        'parameter': parameter,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
    } catch (e) {
      debugPrint('Error updating visualizer parameter via bridge: $e');
    }
  }

  void _handleUITinting(String parameter, Color color, double intensity) { /* ... (same as original) ... */ }
  
  void _initializeVisualizerDefaults() {
    if (!_isVisualizerReady) return;
    _iFrameElement.contentWindow?.postMessage({
      'type': 'configure', // Or 'initialize' if JS expects that for initial full config
      'config': { /* ... default params from original ... */
        'dimension': 4.0, 'morphFactor': 0.7, 'rotationSpeed': 0.5,
        'gridDensity': 8.0, 'lineThickness': 0.03, 'patternIntensity': 1.3,
        'universeModifier': 1.0, 'colorShift': 0.0, 'glitchIntensity': 0.02,
        'enablePerformanceMonitoring': true, 'targetFPS': 60,
        'adaptiveQuality': true, 'enableFeedback': true,
      }
    }, '*');
  }
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _parameterBridge, // Provide the bridge
      child: Consumer<SynthParametersModel>(
        builder: (context, synthModel, child) {
          if (_isVisualizerReady) { // Only sync if JS side is ready
            _syncParametersFromSynth(synthModel);
            _sendAudioAnalysisUpdate(synthModel); // New call for audio data
          }
          
          return Stack(
            children: [
              if (widget.enableBackground) _buildVisualizerBackground(),
              if (widget.child != null) Positioned.fill(child: widget.child!),
              if (!_isVisualizerReady && _isIframeLoaded) _buildConnectionIndicator(), // Show loading if iframe loaded but JS not ready
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildVisualizerBackground() { /* ... (same as original, ensure it uses _isVisualizerReady for opacity animation) ... */
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _connectionAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: widget.backgroundOpacity * (_isVisualizerReady ? _connectionAnimation.value : 0.2), // Dim if not fully ready
            child: HtmlElementView(viewType: _viewType),
          );
        },
      ),
    );
  }
  Widget _buildConnectionIndicator() { /* ... (same as original, uses _isVisualizerReady) ... */
    return Positioned(top:16, right:16, child: Text(_isVisualizerReady ? 'Connected' : (_isIframeLoaded ? 'Initializing JS...' : 'Loading Iframe...')) );
  }
  // _buildTintingOverlay remains same

  void _syncParametersFromSynth(SynthParametersModel synthModel) {
    if (!_isVisualizerReady) return; // Redundant check, but safe
    
    // Using ParameterVisualizerBridge to send individual parameters
    _parameterBridge.updateParameter('xyPadX', synthModel.xyPadX);
    _parameterBridge.updateParameter('xyPadY', synthModel.xyPadY);
    _parameterBridge.updateParameter('filterCutoff', synthModel.filterCutoff / 20000); // Normalize
    _parameterBridge.updateParameter('filterResonance', synthModel.filterResonance);
    _parameterBridge.updateParameter('attackTime', synthModel.attackTime / 2.0); // Normalize
    _parameterBridge.updateParameter('releaseTime', synthModel.releaseTime / 2.0); // Normalize
    _parameterBridge.updateParameter('masterVolume', synthModel.masterVolume);
    _parameterBridge.updateParameter('reverbMix', synthModel.reverbMix);
    _parameterBridge.updateParameter('delayMix', synthModel.delayMix);
    
    if (synthModel.oscillators.isNotEmpty) {
      final osc = synthModel.oscillators[0];
      _parameterBridge.updateParameter('oscillatorDetune', osc.detune / 100.0); // Normalize
      // Could also send osc.type.index, osc.volume etc. if mapped in JS
    }
  }

  // NEW METHOD to send structured audio analysis data
  void _sendAudioAnalysisUpdate(SynthParametersModel synthModel) {
    if (!_isVisualizerReady) return;

    // Placeholder: Real audio analysis data (bass, mid, high, amplitude)
    // would need to be sourced from the AudioEngine/AudioService,
    // not typically available directly in SynthParametersModel.
    // For this example, we'll derive some pseudo-values from synthModel
    // to demonstrate the message structure.
    double pseudoAmplitude = synthModel.masterVolume;
    double pseudoBass = (1.0 - (synthModel.filterCutoff / 20000.0)) * pseudoAmplitude; // More bass if cutoff is low
    double pseudoMid = (synthModel.filterResonance + 0.1) * pseudoAmplitude;
    double pseudoHigh = (synthModel.filterCutoff / 20000.0) * pseudoAmplitude; // More high if cutoff is high

    final audioDataPayload = {
      'amplitude': pseudoAmplitude.clamp(0.0, 1.0),
      'bass': pseudoBass.clamp(0.0, 1.0),
      'mid': pseudoMid.clamp(0.0, 1.0),
      'high': pseudoHigh.clamp(0.0, 1.0),
      // 'frequencyData': [], // Optional actual FFT data
      // 'timeDomainData': [], // Optional actual Time Domain data
    };

    try {
      _iFrameElement.contentWindow?.postMessage({
        'type': 'audioAnalysisUpdate',
        'payload': audioDataPayload,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, '*');
    } catch (e) {
      debugPrint('Error sending audioAnalysisUpdate: $e');
    }
  }
  
  // Public methods like updateParameter, refreshVisualizer, etc. remain same
  // but should also check _isVisualizerReady. E.g.:
  void updateParameter(String parameter, double value) { // Public API for external control
     if (!_isVisualizerReady) return;
    _parameterBridge.updateParameter(parameter, value); // Uses the bridge
  }
  
  void refreshVisualizer() {
    if (!_isVisualizerReady) return;
    _iFrameElement.contentWindow?.postMessage({'type': 'refresh'}, '*');
  }
  void toggleEffect(String effectName) { /* ... check _isVisualizerReady ... */ }
  void resetVisualizer() { /* ... check _isVisualizerReady ... */ }
  
  @override
  void dispose() {
    _connectionController.dispose();
    _tintController.dispose();
    _parameterBridge.dispose();
    // Remove JS message listener
    html.window.removeEventListener('message', _handleJsMessages);
    super.dispose();
  }
}
// VisualizerBackground and VisualizerOverlayWrapper remain the same
// VisualizerPerformanceMonitor remains the same