// Embedded HyperAV Visualizer - Abstract Interface
import 'package:flutter/material.dart';
import '../core/holographic_theme.dart';

/// Abstract interface for the embedded HyperAV visualizer widget
/// Provides a platform-agnostic way to display the 4D visualizer
abstract class EmbeddedHyperAVVisualizerWidget extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final double width;
  final double height;

  const EmbeddedHyperAVVisualizerWidget({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.width = 400.0,
    this.height = 300.0,
  }) : super(key: key);
}

/// Base state class with common functionality
abstract class EmbeddedHyperAVVisualizerState<T extends EmbeddedHyperAVVisualizerWidget> extends State<T>
    with TickerProviderStateMixin {
  
  @protected
  late AnimationController glowController;
  @protected
  late Animation<double> glowAnimation;

  @override
  void initState() {
    super.initState();
    
    glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: glowController,
      curve: Curves.easeInOut,
    ));
    
    glowController.repeat(reverse: true);
    
    initializePlatformSpecific();
  }

  /// Platform-specific initialization - override in subclasses
  void initializePlatformSpecific() {}

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return buildCollapsedState();
    }
    
    return buildFullInterface();
  }

  Widget buildCollapsedState() {
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

  Widget buildFullInterface() {
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
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.primaryEnergy.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            buildHeader(),
            
            // Visualizer content
            Expanded(
              child: buildVisualizerContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: HolographicTheme.primaryEnergy.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Icon(
            Icons.view_in_ar,
            color: HolographicTheme.primaryEnergy,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'HYPERAV 4D VISUALIZER',
            style: TextStyle(
              color: HolographicTheme.primaryEnergy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.8),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
          Spacer(),
          
          // Platform-specific status indicator
          buildStatusIndicator(),
          SizedBox(width: 8),
          
          // Collapse button
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: HolographicTheme.primaryEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.primaryEnergy,
                size: 12,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  /// Platform-specific status indicator - override in subclasses
  Widget buildStatusIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: HolographicTheme.primaryEnergy.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
    );
  }

  /// Platform-specific visualizer content - override in subclasses
  Widget buildVisualizerContent();

  @override
  void dispose() {
    glowController.dispose();
    super.dispose();
  }
}