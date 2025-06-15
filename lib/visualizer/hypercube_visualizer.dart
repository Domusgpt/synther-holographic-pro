import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../core/audio_engine.dart'; // Assuming AudioEngine is in core

/// Professional 4D Hypercube Visualizer
///
/// This widget displays the real-time 4D polytope projections that react
/// to audio parameters. It uses WebGL for high-performance rendering.
class HypercubeVisualizer extends StatefulWidget {
  final AudioEngine audioEngine;

  const HypercubeVisualizer({
    super.key,
    required this.audioEngine,
  });

  @override
  State<HypercubeVisualizer> createState() => _HypercubeVisualizerState();
}

class _HypercubeVisualizerState extends State<HypercubeVisualizer>
    with TickerProviderStateMixin {
  late WebViewController _controller;
  bool _isPageLoaded = false; // Tracks if the HTML page itself has loaded
  bool _isVisualizerReady = false; // Tracks if the JS visualizer signals it's ready
  late AnimationController _updateController;

  @override
  void initState() {
    super.initState();

    _updateController = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60fps
      vsync: this,
    )..addListener(_updateVisualizerLoop); // Renamed to avoid conflict

    _initializeWebView();
    // _startVisualizerUpdates(); // Start updates only after visualizer is ready
  }

  @override
  void dispose() {
    _updateController.dispose();
    super.dispose();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterCommChannel', // Name of the channel JS will use
        onMessageReceived: (JavaScriptMessage message) {
          print('Message from JS Visualizer: ${message.message}');
          if (message.message == 'visualizer_ready_success') {
            setState(() {
              _isVisualizerReady = true;
            });
            _initializeVisualizerParameters(); // Initialize params now that JS is ready
            _startVisualizerUpdates(); // Start sending data
            print('🎨 HypercubeVisualizer: JS Visualizer is ready.');
          } else if (message.message == 'visualizer_ready_error') {
             setState(() {
              _isVisualizerReady = false;
            });
            print('❌ HypercubeVisualizer: JS Visualizer reported an error on ready.');
            // Handle error, maybe show an error message on the UI
          }
          // Handle other messages if needed
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('🎨 HypercubeVisualizer: Page finished loading: $url');
            setState(() {
              _isPageLoaded = true;
            });
            // Do NOT call _initializeVisualizerParameters here anymore.
            // Wait for the 'visualizer_ready' message via JavascriptChannel.
            // JS side will call initializeHypercube itself and then signal readiness.
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  domain: ${error.domain}
  description: ${error.description}
  errorCode: ${error.errorCode}
  isForMainFrame: ${error.isForMainFrame}
          ''');
            setState(() {
              _isPageLoaded = false;
              _isVisualizerReady = false;
            });
             // Optionally, display an error to the user
          },
        ),
      )
      ..loadFlutterAsset('assets/visualizer/index-flutter.html');
  }

  void _startVisualizerUpdates() {
    if (_isVisualizerReady) {
      _updateController.repeat();
      print("Visualizer updates started.");
    } else {
      print("Visualizer not ready, updates not started.");
    }
  }

  void _updateVisualizerLoop() {
    if (!_isPageLoaded || !_isVisualizerReady) return;

    final data = widget.audioEngine.getVisualizerData();
    final jsCommand = '''
      if (typeof window.updateAudioData === 'function') {
        window.updateAudioData(${jsonEncode(data)});
      } else {
        // console.warn('window.updateAudioData is not a function');
      }
    ''';
    _controller.runJavaScript(jsCommand);
  }

  void _initializeVisualizerParameters() {
    // This is called after JS signals it's ready
    if (!_isPageLoaded || !_isVisualizerReady) {
        print("Cannot initialize parameters: Page not loaded or Visualizer not ready.");
        return;
    }
    
    // Parameters are now set by the JS side's initializeHypercube and its defaults.
    // If we need to send an initial configuration from Flutter AFTER it's ready:
    const initialConfig = {
      // 'geometryType': 'hypersphere', // Example: override JS defaults if needed
      // 'rotationSpeed': 0.1,
    };

    // The JS side's initializeHypercube is called automatically by index-flutter.html's own script.
    // If we need to send a specific config *after* it's ready, we'd use a new JS function or postMessage type.
    // For now, we assume the JS self-initialization is sufficient, and this function is more of a placeholder
    // if we wanted to send overrides.
    // The main thing is that JS calls `FlutterCommChannel.postMessage('visualizer_ready_success')`
    
    final jsCommand = '''
      if (typeof window.initializeHypercube === 'function') {
        // window.initializeHypercube(${jsonEncode(initialConfig)});
        // Commented out: JS in index-flutter.html now calls initializeHypercube itself.
        // This Flutter function could be used to *reconfigure* if needed,
        // perhaps by calling a *different* JS function like `window.reconfigureVisualizer`.
        console.log('Flutter: JS initializeHypercube function is present.');
      } else {
        console.error('Flutter: window.initializeHypercube is not defined in JS.');
      }
    ''';
    _controller.runJavaScript(jsCommand);
    print("Attempted to check/call JS initializeHypercube (likely redundant as JS self-inits).");
  }

  // Functions to send commands to JS (examples)
  void updateRotation(double x, double y) {
    if (!_isVisualizerReady) return;
    _controller.runJavaScript("if(window.setRotation4D) window.setRotation4D($x, $y);");
  }

  void setMorphIntensity(double intensity) {
    if (!_isVisualizerReady) return;
    _controller.runJavaScript("if(window.setMorphIntensity) window.setMorphIntensity($intensity);");
  }

  void setColorPalette(String palette) {
    if (!_isVisualizerReady) return;
    _controller.runJavaScript("if(window.setColorPalette) window.setColorPalette('$palette');");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF000010),
            Color(0xFF000020),
            Color(0xFF000000),
          ],
        ),
      ),
      child: Stack(
        children: [
          if (_isPageLoaded) // Only build WebView if page has started loading to avoid issues
            WebViewWidget(controller: _controller),
          
          if (!_isVisualizerReady) // Show loading until JS visualizer confirms it's ready
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF00FFFF),
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'INITIALIZING HYPERCUBE VISUALIZER...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Visualizer parameter presets for different music styles
class VisualizerPresets {
  static const Map<String, Map<String, dynamic>> presets = {
    'vaporwave': { /* ... presets ... */ },
    'cyberpunk': { /* ... presets ... */ },
    // Add other presets as before
  };
  
  static Map<String, dynamic>? getPreset(String name) {
    return presets[name];
  }
  
  static List<String> getPresetNames() {
    return presets.keys.toList();
  }
}