import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:provider/provider.dart';
import '../../core/synth_parameters.dart';

/// Web-specific implementation of the visualizer bridge
class VisualizerBridgeWidget extends StatefulWidget {
  final bool showControls;
  final double opacity;
  
  const VisualizerBridgeWidget({
    Key? key,
    this.showControls = false,
    this.opacity = 1.0,
  }) : super(key: key);
  
  @override
  State<VisualizerBridgeWidget> createState() => _VisualizerBridgeWidgetState();
}

class _VisualizerBridgeWidgetState extends State<VisualizerBridgeWidget> {
  late html.IFrameElement _iFrameElement;
  final String _viewType = 'visualizer-iframe';
  bool _isLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _setupIFrame();
  }
  
  void _setupIFrame() {
    _iFrameElement = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.background = 'transparent'
      ..src = 'assets/assets/visualizer/index-hyperav.html'
      ..onLoad.listen((_) {
        setState(() {
          _isLoaded = true;
        });
        _injectParameterBridge();
        _requestMicrophoneAccess();
      });
    
    // Register the iframe with Flutter's platform view
    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iFrameElement,
      );
    } catch (e) {
      // Fallback for platforms without platform view registry
      print('Platform view registry not available: $e');
    }
  }
  
  void _injectParameterBridge() {
    // Set up message passing with the iframe
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      if (messageEvent.data == 'bridgeReady') {
        debugPrint('HyperAV visualizer bridge ready');
        _enableControlsIfNeeded();
      }
    });
  }
  
  void _requestMicrophoneAccess() {
    if (!_isLoaded) return;
    
    // Request microphone access automatically for better user experience
    _iFrameElement.contentWindow?.postMessage({
      'type': 'requestMicrophone',
      'autoRequest': true,
    }, '*');
  }
  
  void _enableControlsIfNeeded() {
    if (!_isLoaded || !widget.showControls) return;
    
    // Show controls if requested
    _iFrameElement.contentWindow?.postMessage({
      'type': 'toggleControls',
      'show': widget.showControls,
    }, '*');
  }
  
  void _updateVisualizerParameter(String parameter, double value) {
    if (!_isLoaded) return;
    
    // Send parameter updates to the iframe
    _iFrameElement.contentWindow?.postMessage({
      'type': 'parameterUpdate',
      'parameter': parameter,
      'value': value,
    }, '*');
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<SynthParametersModel>(
      builder: (context, model, child) {
        // Update visualizer when parameters change
        _syncParametersToVisualizer(model);
        
        return Stack(
          children: [
            // HtmlElementView for the iframe
            Opacity(
              opacity: widget.opacity,
              child: HtmlElementView(
                viewType: _viewType,
              ),
            ),
            
            // Loading indicator
            if (!_isLoaded)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        );
      },
    );
  }
  
  void _syncParametersToVisualizer(SynthParametersModel model) {
    if (!_isLoaded) return;
    
    // Enhanced HyperAV parameter mapping for better audio-visual coupling
    
    // Filter parameters -> Visual geometry and effects
    final normalizedCutoff = (model.filterCutoff / 20000).clamp(0.0, 1.0);
    _updateVisualizerParameter('filterCutoff', normalizedCutoff);
    _updateVisualizerParameter('filterResonance', model.filterResonance);
    
    // Reverb and effects -> Glitch and color shift
    _updateVisualizerParameter('reverbMix', model.reverbMix);
    
    // Master volume -> Overall intensity
    _updateVisualizerParameter('masterVolume', model.masterVolume);
    
    // XY pad -> Primary dimensional control (most expressive mapping)
    _updateVisualizerParameter('rotationX', model.xyPadX);
    _updateVisualizerParameter('rotationY', model.xyPadY);
    
    // Envelope -> Pattern dynamics and morphing
    _updateVisualizerParameter('attackTime', model.attackTime);
    _updateVisualizerParameter('releaseTime', model.releaseTime);
    
    // Oscillator params -> Core visual characteristics
    if (model.oscillators.isNotEmpty) {
      final osc = model.oscillators[0];
      _updateVisualizerParameter('waveformType', osc.type.index.toDouble());
      _updateVisualizerParameter('oscillatorVolume', osc.volume);
      
      // Map oscillator frequency to color if available
      if (osc.frequency > 0) {
        final normalizedFreq = (osc.frequency / 2000).clamp(0.0, 1.0);
        _updateVisualizerParameter('oscillatorFrequency', normalizedFreq);
      }
    }
    
    // Granular parameters if available
    try {
      final granular = model.granularParameters;
      _updateVisualizerParameter('grainSize', 0.5); // Default values for now
      _updateVisualizerParameter('grainDensity', 0.5);
    } catch (e) {
      // Granular parameters not available
    }
    
    // Additional enhanced mappings for HyperAV
    final delayTime = model.delayTime ?? 0.0;
    final delayFeedback = model.delayFeedback ?? 0.0;
    
    // Delay parameters -> Recursive visual effects
    _updateVisualizerParameter('delayTime', delayTime);
    _updateVisualizerParameter('delayFeedback', delayFeedback);
    
    // Create composite parameters for enhanced visualization
    final energyLevel = (model.masterVolume * 0.4 + model.filterResonance * 0.3 + (model.oscillators.isNotEmpty ? model.oscillators[0].volume : 0.0) * 0.3);
    _updateVisualizerParameter('overallEnergy', energyLevel.clamp(0.0, 1.0));
    
    // Harmonic complexity indicator
    final complexity = model.oscillators.length > 1 ? 
        model.oscillators.map((osc) => osc.volume).reduce((a, b) => a + b) / model.oscillators.length : 
        (model.oscillators.isNotEmpty ? model.oscillators[0].volume : 0.0);
    _updateVisualizerParameter('harmonicComplexity', complexity.clamp(0.0, 1.0));
  }
}

/// Transparent overlay version for use over UI
class VisualizerOverlay extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final double opacity;
  
  const VisualizerOverlay({
    Key? key,
    required this.child,
    this.enabled = true,
    this.opacity = 0.3,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    
    return Stack(
      children: [
        // Visualizer background
        Positioned.fill(
          child: VisualizerBridgeWidget(
            opacity: opacity,
            showControls: false,
          ),
        ),
        
        // UI content on top
        child,
      ],
    );
  }
}