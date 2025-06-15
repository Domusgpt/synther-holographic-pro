// Embedded HyperAV Visualizer - Works with live microphone input
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web; // Import for platformViewRegistry
import '../core/holographic_theme.dart';

class EmbeddedHyperAVVisualizer extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final double width;
  final double height;

  const EmbeddedHyperAVVisualizer({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.width = 400.0,
    this.height = 300.0,
  }) : super(key: key);

  @override
  State<EmbeddedHyperAVVisualizer> createState() => _EmbeddedHyperAVVisualizerState();
}

class _EmbeddedHyperAVVisualizerState extends State<EmbeddedHyperAVVisualizer>
    with TickerProviderStateMixin {
  
  html.IFrameElement? _iframe;
  bool _isVisualizerLoaded = false; // True when iframe emits 'load'
  bool _isBridgeReady = false; // True when JS inside iframe signals it's ready
  bool _isAudioActive = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  String _viewType = ''; // Unique view type for platform view registry

  @override
  void initState() {
    super.initState();
    
    _viewType = 'hyperav-visualizer-${hashCode}'; // Ensure unique viewType per instance

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // _glowController.repeat(reverse: true); // Start animation when/if needed

    if (kIsWeb) {
      _initializeVisualizer();
    }
  }

  void _initializeVisualizer() {
    try {
      _iframe = html.IFrameElement()
        ..src = 'assets/visualizer/index-hyperav.html' // Correct path
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '12px' // Applied to iframe directly
        ..style.overflow = 'hidden'
        ..allow = 'microphone; autoplay; encrypted-media'; // Permissions for mic

      _iframe!.onLoad.listen((_) {
        if (!mounted) return;
        setState(() {
          _isVisualizerLoaded = true;
        });
        debugPrint('✅ HyperAV Visualizer: IFrame loaded successfully ($_viewType)');
        // JS inside index-hyperav.html should post 'bridgeReady' or similar
        // We'll listen for that to set _isBridgeReady
      });

      // Listen for messages from the iframe (e.g., ready signal, audio activity)
      html.window.addEventListener('message', _handleIframeMessage);

      // Register platform view for Flutter web
      // ignore: undefined_function
      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _iframe!,
      );

    } catch (e) {
      debugPrint('❌ Error initializing HyperAV for $_viewType: $e');
      if (mounted) {
        setState(() {
          _isVisualizerLoaded = false; // Mark as not loaded on error
        });
      }
    }
  }

  void _handleIframeMessage(html.Event event) {
    if (!mounted) return;
    if (event is html.MessageEvent) {
      final data = event.data;
      // Check origin if necessary for security: if (event.origin != expected_origin) return;

      if (data is String && data == 'bridgeReady') { // From visualizer-main-hyperav.js
         debugPrint('✅ HyperAV Visualizer: Bridge Ready signal received from iframe ($_viewType).');
         setState(() {
           _isBridgeReady = true;
         });
         if(!_glowController.isAnimating) _glowController.repeat(reverse: true);
      } else if (data is Map) {
        if (data['type'] == 'audioActivity') {
          setState(() {
            _isAudioActive = data['active'] ?? false;
          });
          if (_isAudioActive && !_glowController.isAnimating) {
            _glowController.repeat(reverse: true);
          } else if (!_isAudioActive && _glowController.isAnimating) {
            // _glowController.stop(); // Or let it fade out
          }
        } else if (data['type'] == 'statusUpdate') { // Example
            debugPrint('HyperAV Status from iframe ($_viewType): ${data['message']}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return _buildCollapsedState();
    }
    return _buildFullInterface();
  }

  Widget _buildCollapsedState() {
    // ... (collapsed state UI remains the same)
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: GestureDetector(
        onTap: widget.onToggleCollapse,
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(
            (widget.position ?? Offset.zero) + details.delta,
          );
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: HolographicTheme.primaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.view_in_ar,
            color: HolographicTheme.primaryEnergy,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFullInterface() {
    // ... (full interface structure remains similar)
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [ /* ... shadows ... */ ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildVisualizerContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // ... (header remains similar, maybe use _isBridgeReady for indicator)
    return Container(
      height: 40,
      decoration: BoxDecoration( /* ... */ ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Icon(Icons.view_in_ar, color: HolographicTheme.primaryEnergy, size: 16),
          SizedBox(width: 8),
          Text('HYPERAV 4D VISUALIZER', style: TextStyle(color: HolographicTheme.primaryEnergy, /* ... */)),
          Spacer(),
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              bool audioOrBridgeActive = _isAudioActive || (_isBridgeReady && !_isAudioActive); // Glow if bridge ready but no audio yet
              return Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: audioOrBridgeActive
                    ? (_isAudioActive ? HolographicTheme.secondaryEnergy : HolographicTheme.primaryEnergy.withOpacity(0.5))
                    : HolographicTheme.primaryEnergy.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: audioOrBridgeActive ? [
                    BoxShadow(
                      color: (_isAudioActive ? HolographicTheme.secondaryEnergy : HolographicTheme.primaryEnergy).withOpacity(0.6 * _glowAnimation.value),
                      blurRadius: 8 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ] : null,
                ),
              );
            },
          ),
          SizedBox(width: 8),
          GestureDetector(onTap: widget.onToggleCollapse, child: Container( /* ... */ )),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildVisualizerContent() {
    if (!kIsWeb) return _buildWebOnlyMessage();

    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HolographicTheme.primaryEnergy.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        // Show loading until iframe content signals it's truly ready, not just iframe loaded
        child: (_isVisualizerLoaded && _isBridgeReady)
          ? _buildLoadedVisualizer()
          : _buildLoadingState(),
      ),
    );
  }

  Widget _buildLoadedVisualizer() {
    // This is the corrected part: Use HtmlElementView
    if (!kIsWeb || _iframe == null) return Container(child: Center(child: Text("Error: Iframe not available.")));
    
    return HtmlElementView(
      viewType: _viewType,
    );
  }

  Widget _buildLoadingState() {
    // ... (loading state UI remains the same)
    return Container(child: Center(child: Text("Loading Visualizer...", style: TextStyle(color: HolographicTheme.primaryEnergy))));
  }

  Widget _buildWebOnlyMessage() {
    // ... (web only message UI remains the same)
    return Container(child: Center(child: Text("Visualizer available on Web only.", style: TextStyle(color: HolographicTheme.primaryEnergy))));
  }

  @override
  void dispose() {
    _glowController.dispose();
    // Important: Remove the message listener to avoid memory leaks
    if (kIsWeb) {
      html.window.removeEventListener('message', _handleIframeMessage);
    }
    // The platform view itself should be disposed automatically by Flutter.
    // If _iframe needed manual removal from DOM, it would be here, but
    // with PlatformView, Flutter manages its lifecycle.
    super.dispose();
  }
}