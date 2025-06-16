// Embedded HyperAV Visualizer - Web Implementation
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui' as ui; // Required for platform view registration
import '../core/holographic_theme.dart';
import 'embedded_hyperav_visualizer_interface.dart';

/// Factory function for web platform
EmbeddedHyperAVVisualizerWidget createEmbeddedHyperAVVisualizer({
  Key? key,
  Offset? position,
  Function(Offset)? onPositionChanged,
  bool isCollapsed = false,
  VoidCallback? onToggleCollapse,
  double width = 400.0,
  double height = 300.0,
}) => EmbeddedHyperAVVisualizer(
  key: key,
  position: position,
  onPositionChanged: onPositionChanged,
  isCollapsed: isCollapsed,
  onToggleCollapse: onToggleCollapse,
  width: width,
  height: height,
);

class EmbeddedHyperAVVisualizer extends EmbeddedHyperAVVisualizerWidget {
  const EmbeddedHyperAVVisualizer({
    Key? key,
    Offset? position,
    Function(Offset)? onPositionChanged,
    bool isCollapsed = false,
    VoidCallback? onToggleCollapse,
    double width = 400.0,
    double height = 300.0,
  }) : super(
    key: key,
    position: position,
    onPositionChanged: onPositionChanged,
    isCollapsed: isCollapsed,
    onToggleCollapse: onToggleCollapse,
    width: width,
    height: height,
  );

  @override
  State<EmbeddedHyperAVVisualizer> createState() => _EmbeddedHyperAVVisualizerWebState();
}

class _EmbeddedHyperAVVisualizerWebState extends EmbeddedHyperAVVisualizerState<EmbeddedHyperAVVisualizer> {
  html.IFrameElement? _iframe;
  bool _isVisualizerLoaded = false;
  bool _isAudioActive = false;
  final String _viewId = 'hyperav_visualizer_iframe'; // Unique ID for the view

  @override
  void initializePlatformSpecific() {
    if (!kIsWeb) return; // Should not happen due to conditional import, but good practice

    try {
      _iframe = html.IFrameElement()
        ..id = _viewId // Not strictly necessary but good for DOM inspection
        ..src = 'assets/assets/visualizer/index-hyperav.html' // Corrected path for Flutter web
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        // borderRadius and overflow should be handled by Flutter's ClipRRect if possible,
        // but setting them here ensures iframe itself doesn't break parent's clipping.
        ..style.borderRadius = '8px' // Match the ClipRRect in buildVisualizerContent
        ..style.overflow = 'hidden'
        ..allow = 'microphone; autoplay; encrypted-media';

      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) => _iframe!,
      );

      // Listen for load event on the iframe itself
      _iframe!.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isVisualizerLoaded = true;
          });
          debugPrint('✅ HyperAV Visualizer IFrame content loaded successfully');
          
          // Example: Simulate audio activity detection after load for testing UI
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isAudioActive = true;
              });
            }
          });
        }
      });

      // Error handling for iframe
      _iframe!.onError.listen((event) {
        debugPrint('❌ HyperAV Visualizer IFrame error: $event');
        if (mounted) {
          setState(() {
            _isVisualizerLoaded = false; // Mark as not loaded on error
          });
        }
      });


      // Listen for audio activity messages from the iframe
      html.window.addEventListener('message', (event) {
        if (event is html.MessageEvent && mounted) {
          final data = event.data;
          if (data is Map && data['type'] == 'audioActivity') {
            setState(() {
              _isAudioActive = data['active'] ?? false;
            });
          }
        }
      });

    } catch (e) {
      debugPrint('❌ Error initializing HyperAV: $e');
    }
  }

  @override
  Widget buildStatusIndicator() {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _isAudioActive 
              ? HolographicTheme.secondaryEnergy
              : HolographicTheme.primaryEnergy.withOpacity(0.3),
            shape: BoxShape.circle,
            boxShadow: _isAudioActive ? [
              BoxShadow(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.6 * glowAnimation.value),
                blurRadius: 8 * glowAnimation.value,
                spreadRadius: 2 * glowAnimation.value,
              ),
            ] : null,
          ),
        );
      },
    );
  }

  @override
  Widget buildVisualizerContent() {
    return Container(
      margin: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isVisualizerLoaded 
          ? _buildLoadedVisualizer()
          : _buildLoadingState(),
      ),
    );
  }

  Widget _buildLoadedVisualizer() {
    if (_iframe == null) {
      // This case should ideally not be reached if initializePlatformSpecific was successful
      return Center(
        child: Text(
          'Visualizer IFrame not initialized.',
          style: TextStyle(color: HolographicTheme.warningEnergy),
        ),
      );
    }

    // Use HtmlElementView to display the registered IFrame.
    return HtmlElementView(viewType: _viewId);
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.2 * glowAnimation.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HolographicTheme.primaryEnergy.withOpacity(0.4 * glowAnimation.value),
                        blurRadius: 15 * glowAnimation.value,
                        spreadRadius: 3 * glowAnimation.value,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.view_in_ar,
                    color: HolographicTheme.primaryEnergy,
                    size: 20,
                  ),
                );
              },
            ),
            SizedBox(height: 12),
            Text(
              'Loading HyperAV...',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _iframe?.remove();
    super.dispose();
  }
}