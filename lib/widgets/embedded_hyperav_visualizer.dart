// Embedded HyperAV Visualizer - Simple Platform Detection
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../core/holographic_theme.dart';

/// A simple embedded HyperAV visualizer widget that works on all platforms
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
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  bool _isVisualizerLoaded = false;
  bool _isAudioActive = false;

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _glowController.repeat(reverse: true);
    
    _initializePlatformSpecific();
  }

  void _initializePlatformSpecific() {
    // Simple initialization - just mark as loaded after a brief delay
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isVisualizerLoaded = true;
          _isAudioActive = kIsWeb; // On web, assume active; on mobile, false
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return _buildCollapsedState();
    }
    
    return _buildFullInterface();
  }

  Widget _buildCollapsedState() {
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
            _buildHeader(),
            
            // Visualizer content
            Expanded(
              child: _buildVisualizerContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          
          // Status indicator
          _buildStatusIndicator(),
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

  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: _glowAnimation,
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
                color: HolographicTheme.secondaryEnergy.withOpacity(0.6 * _glowAnimation.value),
                blurRadius: 8 * _glowAnimation.value,
                spreadRadius: 2 * _glowAnimation.value,
              ),
            ] : null,
          ),
        );
      },
    );
  }

  Widget _buildVisualizerContent() {
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
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // Main content
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
                    kIsWeb ? 'HyperAV 4D Visualizer' : 'HyperAV Visualizer',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    kIsWeb 
                      ? 'Audio-Reactive 4D Geometry'
                      : 'Available on Web Platform',
                    style: TextStyle(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  if (!kIsWeb) ...[
                    SizedBox(height: 16),
                    Icon(
                      Icons.smartphone,
                      color: HolographicTheme.primaryEnergy.withOpacity(0.4),
                      size: 24,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Audio controls available\non mobile platforms',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                  if (kIsWeb) ...[
                    SizedBox(height: 16),
                    Text(
                      'Open visualizer/index-hyperav.html\nin browser for full experience',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HolographicTheme.primaryEnergy.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                  ],
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
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: HolographicTheme.primaryEnergy.withOpacity(0.2 * _glowAnimation.value),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: HolographicTheme.primaryEnergy.withOpacity(0.4 * _glowAnimation.value),
                        blurRadius: 15 * _glowAnimation.value,
                        spreadRadius: 3 * _glowAnimation.value,
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
    _glowController.dispose();
    super.dispose();
  }
}