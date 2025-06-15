// Embedded HyperAV Visualizer - Mobile Implementation (iOS/Android)
import 'package:flutter/material.dart';
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
  State<EmbeddedHyperAVVisualizer> createState() => _EmbeddedHyperAVVisualizerMobileState();
}

class _EmbeddedHyperAVVisualizerMobileState extends EmbeddedHyperAVVisualizerState<EmbeddedHyperAVVisualizer> {

  @override
  void initializePlatformSpecific() {
    // No specific initialization needed for mobile
    // The visualizer is not available on mobile platforms
  }

  @override
  Widget buildStatusIndicator() {
    // Static indicator for mobile (no audio activity detection)
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: HolographicTheme.primaryEnergy.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
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
        child: _buildMobileMessage(),
      ),
    );
  }

  Widget _buildMobileMessage() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.web,
              color: HolographicTheme.primaryEnergy.withOpacity(0.6),
              size: 32,
            ),
            SizedBox(height: 12),
            Text(
              'HyperAV Visualizer',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Available on Web',
              style: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
            SizedBox(height: 16),
            Icon(
              Icons.smartphone,
              color: HolographicTheme.primaryEnergy.withOpacity(0.4),
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'Mobile Version:\nAudio controls available',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}