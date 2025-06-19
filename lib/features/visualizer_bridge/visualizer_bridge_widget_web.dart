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
  bool _bridgeReadyNotified = false; // To ensure bridgeReady is called only once if JS side signals multiple times
  
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
      // Ensure assets path is correct, especially for web.
      // If assets are in 'web/assets/visualizer', then 'assets/visualizer/index-hyperav.html'
      // If assets are in 'assets/visualizer' (Flutter standard), then path might be different after build.
      // For flutter build web, assets in 'assets/' are typically served from 'assets/' path.
      ..src = 'assets/visualizer/index-enhanced.html'
      ..onLoad.listen((_) {
        debugPrint('Visualizer IFrame loaded.');
        setState(() {
          _isLoaded = true;
        });
        // _setupMessageListener() is now more robust for bridge readiness.
        // _requestMicrophoneAccess(); // This might be too early if JS bridge isn't ready
      });
    
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _iFrameElement,
    );

    // Setup message listener from JS to Flutter
    html.window.addEventListener('message', (event) {
      final messageEvent = event as html.MessageEvent;
      // Potentially check messageEvent.origin for security

      if (messageEvent.data is Map && messageEvent.data['type'] == 'bridgeReady') {
        if (!_bridgeReadyNotified) {
          debugPrint('HyperAV visualizer bridge reported ready from JS.');
          setState(() {
            // Assuming _isBridgeReady is a state variable if needed elsewhere,
            // but for now, directly enabling controls and syncing params.
          });
          _bridgeReadyNotified = true;
          _enableControlsIfNeeded(); // Enable controls once bridge is confirmed ready
          _requestMicrophoneAccess(); // Request mic access after bridge is ready
          // Perform initial sync or send any queued messages
           final SynthParametersModel params = Provider.of<SynthParametersModel>(context, listen: false);
          _syncParametersToVisualizer(params);
        }
      } else if (messageEvent.data is Map && messageEvent.data['type'] == 'visualizerError') {
        debugPrint('Error from visualizer: ${messageEvent.data['message']}');
      }
      // Handle other messages if needed
    });
  }
  
  // This was _injectParameterBridge, renamed for clarity as it primarily sets up listener
  // The actual bridge readiness is now signaled by JS.
  // void _setupMessageListener() { ... } // Combined into _setupIFrame

  void _requestMicrophoneAccess() {
    if (!_isLoaded || !_bridgeReadyNotified) {
      debugPrint("Visualizer not loaded or bridge not ready, cannot send requestMicrophone message.");
      return;
    }
    if (_iFrameElement.contentWindow == null) {
      debugPrint("Visualizer iframe contentWindow is null, cannot send requestMicrophone message.");
      return;
    }
    _iFrameElement.contentWindow?.postMessage({
      'type': 'requestMicrophone',
      'autoRequest': true, // This tells JS to try and get mic
    }, '*');
  }
  
  void _enableControlsIfNeeded() {
    if (!_isLoaded || !_bridgeReadyNotified) {
       debugPrint("Visualizer not loaded or bridge not ready, cannot send show/hideControls message.");
      return;
    }
     if (_iFrameElement.contentWindow == null) {
      debugPrint("Visualizer iframe contentWindow is null, cannot send show/hideControls message.");
      return;
    }
    
    _iFrameElement.contentWindow?.postMessage({
      'type': widget.showControls ? 'showControls' : 'hideControls',
    }, '*');
  }
  
  void _updateVisualizerParameter(String parameter, double value) {
    if (!_isLoaded || !_bridgeReadyNotified) {
      // Queue this update or log if bridge isn't ready yet
      // For now, we just don't send. A robust solution might queue.
      // debugPrint("Visualizer not loaded or bridge not ready, cannot send parameterUpdate for $parameter.");
      return;
    }
    if (_iFrameElement.contentWindow == null) {
      debugPrint("Visualizer iframe contentWindow is null, cannot send parameterUpdate message for $parameter.");
      return;
    }
    
    _iFrameElement.contentWindow?.postMessage({
      'type': 'parameterUpdate',
      'parameter': parameter,
      'value': value,
    }, '*');
  }
  
  @override
  Widget build(BuildContext context) {
    // Listen to SynthParametersModel changes to sync with visualizer
    final model = Provider.of<SynthParametersModel>(context);
    _syncParametersToVisualizer(model); // Sync on every build where model might have changed
        
    return Stack(
      children: [
        Opacity(
          opacity: widget.opacity,
          child: HtmlElementView(
            viewType: _viewType,
          ),
        ),
        if (!_isLoaded || !_bridgeReadyNotified) // Show loading until bridge is fully ready
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(HolographicTheme.accentEnergy),
            ),
          ),
      ],
    );
  }
  
  void _syncParametersToVisualizer(SynthParametersModel model) {
    if (!_isLoaded || !_bridgeReadyNotified) return; // Don't sync if not ready
    
    // Enhanced synth parameter mapping for the new visualizer
    _updateVisualizerParameter('filterCutoff', (model.filterCutoff / 20000).clamp(0.0, 1.0));
    _updateVisualizerParameter('filterResonance', model.filterResonance);
    _updateVisualizerParameter('reverbMix', model.reverbMix);
    _updateVisualizerParameter('masterVolume', model.masterVolume);
    
    // XY Pad mapped to mouse interaction for real-time control
    _updateVisualizerParameter('mouseX', model.xyPadX);
    _updateVisualizerParameter('mouseY', model.xyPadY);
    
    // Envelope parameters for temporal effects
    _updateVisualizerParameter('attackTime', model.attackTime);
    _updateVisualizerParameter('releaseTime', model.releaseTime);
    
    // Enhanced oscillator parameters
    if (model.oscillators.isNotEmpty) {
      final osc = model.oscillators[0];
      _updateVisualizerParameter('waveformType', osc.type.index.toDouble());
      _updateVisualizerParameter('oscillatorVolume', osc.volume);
      
      if (osc.frequency > 0) {
        final normalizedFreq = (osc.frequency / 2000).clamp(0.0, 1.0);
        _updateVisualizerParameter('oscillatorFrequency', normalizedFreq);
      }
    }
    
    // Enhanced synthesis-specific parameters
    if (model.synthType != null) {
      _sendSynthModeChange(model.synthType!);
    }
    
    // Send wavetable parameters
    if (model.wavetablePosition > 0) {
      _updateVisualizerParameter('wavetablePosition', model.wavetablePosition);
    }
    
    // Send FM synthesis parameters
    if (model.fmRatio > 0) {
      _updateVisualizerParameter('fmRatio', model.fmRatio);
    }
    
    // Send granular synthesis parameters
    if (model.grainDensity > 0) {
      _updateVisualizerParameter('grainDensity', model.grainDensity);
    }
    
    // Send additive synthesis parameters
    if (model.harmonicContent > 0) {
      _updateVisualizerParameter('harmonicContent', model.harmonicContent);
    }
  }
  
  void _sendSynthModeChange(String synthType) {
    if (!_isLoaded || !_bridgeReadyNotified) return;
    if (_iFrameElement.contentWindow == null) return;
    
    // Map Flutter synth types to visualizer modes
    String visualizerMode = synthType.toLowerCase();
    if (visualizerMode.contains('wavetable')) visualizerMode = 'wavetable';
    else if (visualizerMode.contains('fm')) visualizerMode = 'fm';
    else if (visualizerMode.contains('granular')) visualizerMode = 'granular';
    else if (visualizerMode.contains('additive')) visualizerMode = 'additive';
    
    _iFrameElement.contentWindow?.postMessage({
      'type': 'synthModeChange',
      'mode': visualizerMode,
    }, '*');
  }
  
  void _sendFFTData(List<double> fftData) {
    if (!_isLoaded || !_bridgeReadyNotified) return;
    if (_iFrameElement.contentWindow == null) return;
    
    _iFrameElement.contentWindow?.postMessage({
      'type': 'fftDataUpdate',
      'fftData': fftData,
    }, '*');
  }
  
  void _sendAudioStateUpdate(Map<String, dynamic> audioState) {
    if (!_isLoaded || !_bridgeReadyNotified) return;
    if (_iFrameElement.contentWindow == null) return;
    
    _iFrameElement.contentWindow?.postMessage({
      'type': 'audioStateUpdate',
      'state': audioState,
    }, '*');
  }
  
  void _togglePerformanceMode(bool enabled) {
    if (!_isLoaded || !_bridgeReadyNotified) return;
    if (_iFrameElement.contentWindow == null) return;
    
    _iFrameElement.contentWindow?.postMessage({
      'type': 'performanceMode',
      'enabled': enabled,
    }, '*');
  }
    
    // Granular parameters - check if they exist to avoid errors if model changes
    // This assumes granularParameters is a getter that might throw if not applicable.
    // A safer way is to have hasGranularSynth property or check type.
    try {
      final granular = model.granularParameters; // This might need to be made nullable or checked
      _updateVisualizerParameter('grainSize', granular?.grainSize ?? 0.5);
      _updateVisualizerParameter('grainDensity', granular?.grainDensity ?? 0.5);
    } catch (e) {
      // Granular parameters not available or error accessing them.
      // _updateVisualizerParameter('grainSize', 0.5); // Send default if not available
      // _updateVisualizerParameter('grainDensity', 0.5);
    }
    
    final delayTime = model.delayTime ?? 0.0;
    final delayFeedback = model.delayFeedback ?? 0.0;
    _updateVisualizerParameter('delayTime', delayTime);
    _updateVisualizerParameter('delayFeedback', delayFeedback);
    
    final energyLevel = (model.masterVolume * 0.4 + model.filterResonance * 0.3 + (model.oscillators.isNotEmpty ? model.oscillators[0].volume : 0.0) * 0.3);
    _updateVisualizerParameter('overallEnergy', energyLevel.clamp(0.0, 1.0));
    
    final complexity = model.oscillators.length > 1 ? 
        model.oscillators.map((osc) => osc.volume).reduce((a, b) => a + b) / model.oscillators.length : 
        (model.oscillators.isNotEmpty ? model.oscillators[0].volume : 0.0);
    _updateVisualizerParameter('harmonicComplexity', complexity.clamp(0.0, 1.0));

    // Send FFT data if available
    // Assuming model.fftMagnitudes is List<double> and is updated by an FFI callback from C++
    if (model.fftMagnitudes.isNotEmpty) {
      if (_iFrameElement.contentWindow == null) {
        debugPrint("Visualizer iframe contentWindow is null, cannot send fftDataUpdate message.");
      } else {
        // Make sure to convert to List<num> or List<double> if JS side expects plain array.
        // Sending List<double> directly should be fine for postMessage.
        _iFrameElement.contentWindow?.postMessage({
          'type': 'fftDataUpdate',
          'magnitudes': model.fftMagnitudes,
        }, '*');
        // debugPrint("Sent FFT data to visualizer: ${model.fftMagnitudes.length} bins");
      }
    }
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
        Positioned.fill(
          child: VisualizerBridgeWidget(
            opacity: opacity,
            showControls: false, // Typically no controls for an overlay
          ),
        ),
        child, // UI content on top
      ],
    );
  }
}