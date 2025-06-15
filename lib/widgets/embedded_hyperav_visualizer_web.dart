// Embedded HyperAV Visualizer - Web Implementation
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../core/holographic_theme.dart';
import 'embedded_hyperav_visualizer_interface.dart';

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

  @override
  void initializePlatformSpecific() {
    try {
      // Create iframe pointing to our working HyperAV visualizer - web only
      _iframe = html.IFrameElement()
        ..src = 'assets/visualizer/index-hyperav.html'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.borderRadius = '12px'
        ..style.overflow = 'hidden'
        ..allow = 'microphone; autoplay; encrypted-media';

      // Listen for load event
      _iframe!.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isVisualizerLoaded = true;
          });
          debugPrint('✅ HyperAV Visualizer loaded successfully');
          
          // Enable audio activity detection
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _isAudioActive = true; // Assume active for now
              });
            }
          });
        }
      });

      // Listen for audio activity (if the visualizer posts messages)
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
    // For simplicity, create a direct iframe container
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Iframe placeholder - will be managed by web platform
          Container(
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.view_in_ar,
                    color: HolographicTheme.primaryEnergy,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'HyperAV 4D Visualizer',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Audio-Reactive 4D Geometry',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Open visualizer/index-hyperav.html\\nin browser for full experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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