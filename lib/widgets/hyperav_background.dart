// HyperAV Background Widget - Integrates your 4D visualizer as the background
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../core/hyperav_bridge.dart';

class HyperAVBackground extends StatefulWidget {
  final Widget child;
  final bool enableAudioReactivity;
  final String geometryType;
  final String projectionMethod;
  
  const HyperAVBackground({
    Key? key,
    required this.child,
    this.enableAudioReactivity = true,
    this.geometryType = 'hypercube',
    this.projectionMethod = 'perspective',
  }) : super(key: key);

  @override
  State<HyperAVBackground> createState() => _HyperAVBackgroundState();
}

class _HyperAVBackgroundState extends State<HyperAVBackground> {
  bool _isVisualizerReady = false;
  html.DivElement? _visualizerContainer;

  @override
  void initState() {
    super.initState();
    _initializeVisualizer();
  }

  Future<void> _initializeVisualizer() async {
    if (!kIsWeb) return;
    
    try {
      // Initialize the HyperAV bridge
      await HyperAVBridge.instance.initialize();
      
      // Create container for the visualizer
      _visualizerContainer = html.DivElement()
        ..style.position = 'fixed'
        ..style.top = '0'
        ..style.left = '0'
        ..style.width = '100vw'
        ..style.height = '100vh'
        ..style.zIndex = '-1'
        ..style.pointerEvents = 'none'
        ..id = 'hyperav-background-container';
      
      // Mount the visualizer
      HyperAVBridge.instance.mountVisualizerBackground(_visualizerContainer!);
      
      // Add to page
      html.document.body?.append(_visualizerContainer!);
      
      // Configure initial settings
      HyperAVBridge.instance.setGeometryType(widget.geometryType);
      HyperAVBridge.instance.setProjectionMethod(widget.projectionMethod);
      
      setState(() {
        _isVisualizerReady = true;
      });
      
      debugPrint('✅ HyperAV background visualizer ready');
    } catch (e) {
      debugPrint('❌ HyperAV background setup error: $e');
    }
  }

  @override
  void didUpdateWidget(HyperAVBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.geometryType != widget.geometryType) {
      HyperAVBridge.instance.setGeometryType(widget.geometryType);
    }
    
    if (oldWidget.projectionMethod != widget.projectionMethod) {
      HyperAVBridge.instance.setProjectionMethod(widget.projectionMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visualizer status indicator
        if (!_isVisualizerReady)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.cyan),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Loading HyperAV...',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Visualizer ready indicator
        if (_isVisualizerReady)
          Positioned(
            bottom: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility,
                    color: Colors.green,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'HyperAV Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Main interface content (on top of visualizer)
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _visualizerContainer?.remove();
    super.dispose();
  }
}

// Widget to control HyperAV parameters
class HyperAVController extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isActive;
  
  const HyperAVController({
    Key? key,
    required this.label,
    this.onTap,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? Colors.cyan.withOpacity(0.2)
            : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
              ? Colors.cyan.withOpacity(0.8)
              : Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.cyan : Colors.cyan.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

// HyperAV control panel
class HyperAVControlPanel extends StatefulWidget {
  const HyperAVControlPanel({Key? key}) : super(key: key);

  @override
  State<HyperAVControlPanel> createState() => _HyperAVControlPanelState();
}

class _HyperAVControlPanelState extends State<HyperAVControlPanel> {
  String _currentGeometry = 'hypercube';
  String _currentProjection = 'perspective';
  
  final List<String> _geometryTypes = [
    'hypercube',
    'hypersphere', 
    'hypertetrahedron',
  ];
  
  final List<String> _projectionMethods = [
    'perspective',
    'orthographic',
    'stereographic',
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.cyan.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HYPERAV CONTROL',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12),
            
            // Geometry selection
            Text(
              'GEOMETRY',
              style: TextStyle(
                color: Colors.cyan.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _geometryTypes.map((geometry) {
                return HyperAVController(
                  label: geometry.toUpperCase(),
                  isActive: _currentGeometry == geometry,
                  onTap: () {
                    setState(() {
                      _currentGeometry = geometry;
                    });
                    HyperAVBridge.instance.setGeometryType(geometry);
                  },
                );
              }).toList(),
            ),
            
            SizedBox(height: 12),
            
            // Projection selection
            Text(
              'PROJECTION',
              style: TextStyle(
                color: Colors.cyan.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: _projectionMethods.map((projection) {
                return HyperAVController(
                  label: projection.toUpperCase(),
                  isActive: _currentProjection == projection,
                  onTap: () {
                    setState(() {
                      _currentProjection = projection;
                    });
                    HyperAVBridge.instance.setProjectionMethod(projection);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}