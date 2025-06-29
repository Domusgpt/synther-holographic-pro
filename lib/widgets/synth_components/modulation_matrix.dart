import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;
import '../../core/holographic_theme.dart';
import 'holographic_knob.dart';

/// Professional Modulation Matrix for complex routing
/// 
/// Features:
/// - Visual connection matrix with drag-and-drop routing
/// - Multiple modulation sources (LFOs, envelopes, velocity, aftertouch, etc.)
/// - Multiple modulation destinations (oscillator parameters, filter cutoff, etc.)
/// - Modulation amount and polarity control for each connection
/// - Visual feedback showing modulation flow with animated connections
/// - Preset modulation templates for common routing scenarios
/// - Real-time modulation visualization with flowing energy particles
class ModulationMatrix extends StatefulWidget {
  final vector.Matrix4 transform;
  final Function(String, double) onParameterChange;

  const ModulationMatrix({
    Key? key,
    required this.transform,
    required this.onParameterChange,
  }) : super(key: key);

  @override
  State<ModulationMatrix> createState() => _ModulationMatrixState();
}

class _ModulationMatrixState extends State<ModulationMatrix> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _flowController;
  late AnimationController _particleController;
  
  // Modulation sources
  final List<String> _modulationSources = [
    'LFO 1', 'LFO 2', 'LFO 3',
    'ENV 1', 'ENV 2', 'ENV 3',
    'VELOCITY', 'AFTERTOUCH', 'MOD WHEEL',
    'PITCH BEND', 'KEY TRACK', 'RANDOM'
  ];

  // Modulation destinations  
  final List<String> _modulationDestinations = [
    'OSC1 FREQ', 'OSC1 AMP', 'OSC1 PHASE',
    'OSC2 FREQ', 'OSC2 AMP', 'OSC2 PHASE',
    'FILTER CUTOFF', 'FILTER RES', 'FILTER DRIVE',
    'AMP LEVEL', 'PAN', 'REVERB MIX',
    'DELAY TIME', 'CHORUS RATE', 'DISTORTION'
  ];

  // Modulation matrix state
  // Each entry: [sourceIndex, destIndex, amount, enabled]
  final List<List<double>> _modulationMatrix = [];
  
  // Visual interaction state
  int _selectedConnection = -1;
  bool _isDragging = false;
  Offset? _dragStart;
  Offset? _dragEnd;
  
  // Templates for common modulation setups
  final Map<String, List<List<double>>> _modulationTemplates = {
    'Classic Synth': [
      [0, 0, 0.5, 1], // LFO 1 -> OSC1 FREQ
      [0, 3, 0.3, 1], // LFO 1 -> OSC2 FREQ
      [3, 6, 0.8, 1], // ENV 1 -> FILTER CUTOFF
      [4, 9, 1.0, 1], // ENV 2 -> AMP LEVEL
    ],
    'Wobble Bass': [
      [1, 6, 0.9, 1], // LFO 2 -> FILTER CUTOFF
      [1, 7, 0.4, 1], // LFO 2 -> FILTER RES
      [2, 12, 0.6, 1], // LFO 3 -> DELAY TIME
    ],
    'Evolving Pad': [
      [0, 0, 0.2, 1], // LFO 1 -> OSC1 FREQ
      [1, 1, 0.4, 1], // LFO 2 -> OSC1 AMP
      [2, 6, 0.7, 1], // LFO 3 -> FILTER CUTOFF
      [3, 11, 0.6, 1], // ENV 1 -> REVERB MIX
    ],
  };

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _flowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
    
    // Initialize with some default connections
    _loadTemplate('Classic Synth');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HolographicTheme.primaryEnergy.withOpacity(0.05 + (_pulseController.value * 0.02)),
                HolographicTheme.secondaryEnergy.withOpacity(0.03),
                HolographicTheme.deepSpaceBlack.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withOpacity(0.3 + (_pulseController.value * 0.1)),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with template selector
                _buildHeader(),
                
                const SizedBox(height: 16),
                
                // Modulation matrix visualization
                Flexible(
                  fit: FlexFit.loose,
                  child: _buildModulationMatrix(),
                ),
                
                const SizedBox(height: 16),
                
                // Selected connection controls
                if (_selectedConnection >= 0) _buildConnectionControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'MODULATION MATRIX',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.primaryEnergy,
            fontSize: 14,
            glowIntensity: 0.6,
          ),
        ),
        
        const Spacer(),
        
        // Template selector
        Text(
          'TEMPLATE:',
          style: HolographicTheme.createHolographicText(
            energyColor: HolographicTheme.secondaryEnergy,
            fontSize: 10,
            glowIntensity: 0.4,
          ),
        ),
        
        const SizedBox(width: 8),
        
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                HolographicTheme.accentEnergy.withOpacity(0.1),
                HolographicTheme.accentEnergy.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: HolographicTheme.accentEnergy.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButton<String>(
            value: null,
            hint: Text(
              'Select...',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.accentEnergy,
                fontSize: 10,
                glowIntensity: 0.4,
              ),
            ),
            onChanged: (template) {
              if (template != null) {
                _loadTemplate(template);
              }
            },
            dropdownColor: HolographicTheme.deepSpaceBlack,
            underline: Container(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: HolographicTheme.accentEnergy,
              size: 16,
            ),
            items: _modulationTemplates.keys.map((template) {
              return DropdownMenuItem<String>(
                value: template,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    template,
                    style: HolographicTheme.createHolographicText(
                      energyColor: HolographicTheme.accentEnergy,
                      fontSize: 10,
                      glowIntensity: 0.4,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Clear all connections button
        GestureDetector(
          onTap: _clearAllConnections,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HolographicTheme.secondaryEnergy.withOpacity(0.1),
                  HolographicTheme.secondaryEnergy.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'CLEAR',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.secondaryEnergy,
                fontSize: 8,
                glowIntensity: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModulationMatrix() {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HolographicTheme.deepSpaceBlack.withOpacity(0.9),
              HolographicTheme.primaryEnergy.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: Listenable.merge([_flowController, _particleController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: ModulationMatrixPainter(
                    sources: _modulationSources,
                    destinations: _modulationDestinations,
                    connections: _modulationMatrix,
                    selectedConnection: _selectedConnection,
                    flowAnimation: _flowController.value,
                    particleAnimation: _particleController.value,
                    isDragging: _isDragging,
                    dragStart: _dragStart,
                    dragEnd: _dragEnd,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight.isFinite ? constraints.maxHeight : 300),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectionControls() {
    if (_selectedConnection < 0 || _selectedConnection >= _modulationMatrix.length) {
      return Container();
    }
    
    final connection = _modulationMatrix[_selectedConnection];
    final sourceIndex = connection[0].round();
    final destIndex = connection[1].round();
    final amount = connection[2];
    final enabled = connection[3] > 0.5;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HolographicTheme.accentEnergy.withOpacity(0.1),
            HolographicTheme.accentEnergy.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.accentEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Connection info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONNECTION ${_selectedConnection + 1}',
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.accentEnergy,
                    fontSize: 10,
                    glowIntensity: 0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_modulationSources[sourceIndex]} → ${_modulationDestinations[destIndex]}',
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.primaryEnergy,
                    fontSize: 9,
                    glowIntensity: 0.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Amount control
          Expanded(
            child: HolographicKnob(
              label: 'AMOUNT',
              value: (amount + 1.0) / 2.0, // Convert -1..1 to 0..1
              onChanged: (value) => _updateConnectionAmount(_selectedConnection, (value * 2.0) - 1.0),
              color: HolographicTheme.accentEnergy,
              showSpectrum: false,
              size: 60,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Enable/disable toggle
          GestureDetector(
            onTap: () => _toggleConnection(_selectedConnection),
            child: Container(
              width: 50,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    HolographicTheme.secondaryEnergy.withOpacity(enabled ? 0.3 : 0.1),
                    HolographicTheme.secondaryEnergy.withOpacity(enabled ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: HolographicTheme.secondaryEnergy.withOpacity(enabled ? 0.8 : 0.3),
                  width: enabled ? 2 : 1,
                ),
              ),
              child: Center(
                child: Text(
                  enabled ? 'ON' : 'OFF',
                  style: HolographicTheme.createHolographicText(
                    energyColor: HolographicTheme.secondaryEnergy,
                    fontSize: 9,
                    glowIntensity: enabled ? 0.8 : 0.4,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Delete connection button
          GestureDetector(
            onTap: () => _deleteConnection(_selectedConnection),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.2),
                    Colors.red.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.red.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final size = context.size;
    if (size == null) return;
    
    final localPosition = details.localPosition;
    
    // Check if clicking on an existing connection
    for (int i = 0; i < _modulationMatrix.length; i++) {
      final connection = _modulationMatrix[i];
      if (_isClickOnConnection(localPosition, size, connection)) {
        setState(() {
          _selectedConnection = i;
        });
        return;
      }
    }
    
    // Start creating a new connection
    setState(() {
      _isDragging = true;
      _dragStart = localPosition;
      _dragEnd = localPosition;
      _selectedConnection = -1;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      setState(() {
        _dragEnd = details.localPosition;
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDragging && _dragStart != null && _dragEnd != null) {
      final size = context.size;
      if (size != null) {
        _createConnectionFromDrag(size);
      }
    }
    
    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragEnd = null;
    });
  }

  bool _isClickOnConnection(Offset position, Size size, List<double> connection) {
    // Calculate connection line and check if click is near it
    final sourcePos = _getSourcePosition(connection[0].round(), size);
    final destPos = _getDestinationPosition(connection[1].round(), size);
    
    // Simple distance check to connection line
    final distance = _distanceToLine(position, sourcePos, destPos);
    return distance < 10.0; // 10 pixel tolerance
  }

  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final A = point.dx - lineStart.dx;
    final B = point.dy - lineStart.dy;
    final C = lineEnd.dx - lineStart.dx;
    final D = lineEnd.dy - lineStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    if (lenSq == 0) return math.sqrt(A * A + B * B);
    
    final param = dot / lenSq;
    
    double xx, yy;
    if (param < 0) {
      xx = lineStart.dx;
      yy = lineStart.dy;
    } else if (param > 1) {
      xx = lineEnd.dx;
      yy = lineEnd.dy;
    } else {
      xx = lineStart.dx + param * C;
      yy = lineStart.dy + param * D;
    }

    final dx = point.dx - xx;
    final dy = point.dy - yy;
    return math.sqrt(dx * dx + dy * dy);
  }

  Offset _getSourcePosition(int sourceIndex, Size size) {
    final sourceY = 40 + (sourceIndex * (size.height - 80) / _modulationSources.length);
    return Offset(40, sourceY);
  }

  Offset _getDestinationPosition(int destIndex, Size size) {
    final destY = 40 + (destIndex * (size.height - 80) / _modulationDestinations.length);
    return Offset(size.width - 40, destY);
  }

  void _createConnectionFromDrag(Size size) {
    if (_dragStart == null || _dragEnd == null) return;
    
    // Determine source and destination from drag positions
    final sourceIndex = _getSourceIndexFromPosition(_dragStart!, size);
    final destIndex = _getDestinationIndexFromPosition(_dragEnd!, size);
    
    if (sourceIndex >= 0 && destIndex >= 0) {
      // Check if connection already exists
      final existingConnection = _modulationMatrix.indexWhere((conn) =>
          conn[0].round() == sourceIndex && conn[1].round() == destIndex);
      
      if (existingConnection == -1) {
        // Create new connection
        setState(() {
          _modulationMatrix.add([sourceIndex.toDouble(), destIndex.toDouble(), 0.5, 1.0]);
          _selectedConnection = _modulationMatrix.length - 1;
        });
        
        _notifyConnectionChange();
      }
    }
  }

  int _getSourceIndexFromPosition(Offset position, Size size) {
    if (position.dx > size.width / 2) return -1; // Must be on left side
    
    final normalizedY = (position.dy - 40) / (size.height - 80);
    final index = (normalizedY * _modulationSources.length).round();
    return index.clamp(0, _modulationSources.length - 1);
  }

  int _getDestinationIndexFromPosition(Offset position, Size size) {
    if (position.dx < size.width / 2) return -1; // Must be on right side
    
    final normalizedY = (position.dy - 40) / (size.height - 80);
    final index = (normalizedY * _modulationDestinations.length).round();
    return index.clamp(0, _modulationDestinations.length - 1);
  }

  void _loadTemplate(String templateName) {
    final template = _modulationTemplates[templateName];
    if (template != null) {
      setState(() {
        _modulationMatrix.clear();
        _modulationMatrix.addAll(template.map((conn) => List<double>.from(conn)));
        _selectedConnection = -1;
      });
      
      _notifyConnectionChange();
    }
  }

  void _clearAllConnections() {
    setState(() {
      _modulationMatrix.clear();
      _selectedConnection = -1;
    });
    
    _notifyConnectionChange();
  }

  void _updateConnectionAmount(int connectionIndex, double amount) {
    if (connectionIndex >= 0 && connectionIndex < _modulationMatrix.length) {
      setState(() {
        _modulationMatrix[connectionIndex][2] = amount.clamp(-1.0, 1.0);
      });
      
      _notifyConnectionChange();
    }
  }

  void _toggleConnection(int connectionIndex) {
    if (connectionIndex >= 0 && connectionIndex < _modulationMatrix.length) {
      setState(() {
        _modulationMatrix[connectionIndex][3] = _modulationMatrix[connectionIndex][3] > 0.5 ? 0.0 : 1.0;
      });
      
      _notifyConnectionChange();
    }
  }

  void _deleteConnection(int connectionIndex) {
    if (connectionIndex >= 0 && connectionIndex < _modulationMatrix.length) {
      setState(() {
        _modulationMatrix.removeAt(connectionIndex);
        _selectedConnection = -1;
      });
      
      _notifyConnectionChange();
    }
  }

  void _notifyConnectionChange() {
    // Notify parent of modulation matrix changes
    for (int i = 0; i < _modulationMatrix.length; i++) {
      final connection = _modulationMatrix[i];
      widget.onParameterChange('mod_matrix_${i}_source', connection[0]);
      widget.onParameterChange('mod_matrix_${i}_dest', connection[1]);
      widget.onParameterChange('mod_matrix_${i}_amount', connection[2]);
      widget.onParameterChange('mod_matrix_${i}_enabled', connection[3]);
    }
  }
}

/// Custom painter for the modulation matrix visualization
class ModulationMatrixPainter extends CustomPainter {
  final List<String> sources;
  final List<String> destinations;
  final List<List<double>> connections;
  final int selectedConnection;
  final double flowAnimation;
  final double particleAnimation;
  final bool isDragging;
  final Offset? dragStart;
  final Offset? dragEnd;

  ModulationMatrixPainter({
    required this.sources,
    required this.destinations,
    required this.connections,
    required this.selectedConnection,
    required this.flowAnimation,
    required this.particleAnimation,
    required this.isDragging,
    this.dragStart,
    this.dragEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSourceLabels(canvas, size);
    _drawDestinationLabels(canvas, size);
    _drawConnections(canvas, size);
    
    if (isDragging && dragStart != null && dragEnd != null) {
      _drawDragLine(canvas, size);
    }
  }

  void _drawSourceLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    for (int i = 0; i < sources.length; i++) {
      final y = 40 + (i * (size.height - 80) / sources.length);
      
      // Source node
      final nodePaint = Paint()
        ..color = HolographicTheme.primaryEnergy.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(40, y), 6, nodePaint);
      
      // Source label
      textPainter.text = TextSpan(
        text: sources[i],
        style: HolographicTheme.createHolographicText(
          energyColor: HolographicTheme.primaryEnergy,
          fontSize: 9,
          glowIntensity: 0.5,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(50, y - textPainter.height / 2));
    }
  }

  void _drawDestinationLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    for (int i = 0; i < destinations.length; i++) {
      final y = 40 + (i * (size.height - 80) / destinations.length);
      
      // Destination node
      final nodePaint = Paint()
        ..color = HolographicTheme.secondaryEnergy.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(Offset(size.width - 40, y), 6, nodePaint);
      
      // Destination label
      textPainter.text = TextSpan(
        text: destinations[i],
        style: HolographicTheme.createHolographicText(
          energyColor: HolographicTheme.secondaryEnergy,
          fontSize: 9,
          glowIntensity: 0.5,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - 50 - textPainter.width, y - textPainter.height / 2));
    }
  }

  void _drawConnections(Canvas canvas, Size size) {
    for (int i = 0; i < connections.length; i++) {
      final connection = connections[i];
      final sourceIndex = connection[0].round();
      final destIndex = connection[1].round();
      final amount = connection[2];
      final enabled = connection[3] > 0.5;
      
      if (!enabled) continue;
      
      final sourceY = 40 + (sourceIndex * (size.height - 80) / sources.length);
      final destY = 40 + (destIndex * (size.height - 80) / destinations.length);
      
      final sourcePos = Offset(46, sourceY);
      final destPos = Offset(size.width - 46, destY);
      
      final isSelected = i == selectedConnection;
      final connectionColor = isSelected 
        ? HolographicTheme.accentEnergy 
        : HolographicTheme.primaryEnergy;
      
      // Draw connection curve
      _drawConnectionCurve(canvas, sourcePos, destPos, amount, connectionColor, isSelected);
      
      // Draw flow particles
      if (enabled) {
        _drawFlowParticles(canvas, sourcePos, destPos, amount, connectionColor);
      }
    }
  }

  void _drawConnectionCurve(Canvas canvas, Offset start, Offset end, double amount, Color color, bool isSelected) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Create smooth curve
    final controlPoint1 = Offset(start.dx + (end.dx - start.dx) * 0.5, start.dy);
    final controlPoint2 = Offset(start.dx + (end.dx - start.dx) * 0.5, end.dy);
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );
    
    // Connection line style based on amount
    final paint = Paint()
      ..color = color.withOpacity(0.6 + (amount.abs() * 0.4))
      ..strokeWidth = isSelected ? 4.0 : (2.0 + amount.abs() * 2.0)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Glow effect
    if (isSelected || amount.abs() > 0.5) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = paint.strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawPath(path, glowPaint);
    }
    
    canvas.drawPath(path, paint);
    
    // Amount indicator (arrow direction for polarity)
    if (amount != 0) {
      _drawAmountIndicator(canvas, start, end, amount, color);
    }
  }

  void _drawAmountIndicator(Canvas canvas, Offset start, Offset end, double amount, Color color) {
    final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final direction = end - start;
    final normalizedDirection = direction / direction.distance;
    
    // Arrow size based on amount
    final arrowSize = 8.0 + (amount.abs() * 6.0);
    
    final arrowPaint = Paint()
      ..color = amount > 0 ? color : Colors.red
      ..style = PaintingStyle.fill;
    
    // Arrow pointing in direction of modulation
    final arrowPath = Path();
    if (amount > 0) {
      // Positive modulation - arrow forward
      arrowPath.moveTo(center.dx + normalizedDirection.dx * arrowSize, center.dy + normalizedDirection.dy * arrowSize);
      arrowPath.lineTo(center.dx - normalizedDirection.dy * arrowSize * 0.5, center.dy + normalizedDirection.dx * arrowSize * 0.5);
      arrowPath.lineTo(center.dx + normalizedDirection.dy * arrowSize * 0.5, center.dy - normalizedDirection.dx * arrowSize * 0.5);
    } else {
      // Negative modulation - arrow backward
      arrowPath.moveTo(center.dx - normalizedDirection.dx * arrowSize, center.dy - normalizedDirection.dy * arrowSize);
      arrowPath.lineTo(center.dx + normalizedDirection.dy * arrowSize * 0.5, center.dy - normalizedDirection.dx * arrowSize * 0.5);
      arrowPath.lineTo(center.dx - normalizedDirection.dy * arrowSize * 0.5, center.dy + normalizedDirection.dx * arrowSize * 0.5);
    }
    arrowPath.close();
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawFlowParticles(Canvas canvas, Offset start, Offset end, double amount, Color color) {
    if (amount == 0) return;
    
    final numParticles = (amount.abs() * 5).round() + 1;
    final particlePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < numParticles; i++) {
      // Stagger particles along the flow animation
      final particleProgress = (flowAnimation + (i / numParticles)) % 1.0;
      
      // Calculate position along curve
      final t = particleProgress;
      final controlPoint1 = Offset(start.dx + (end.dx - start.dx) * 0.5, start.dy);
      final controlPoint2 = Offset(start.dx + (end.dx - start.dx) * 0.5, end.dy);
      
      final particlePos = _cubicBezierPoint(start, controlPoint1, controlPoint2, end, t);
      
      // Particle size varies with amount and animation
      final particleSize = (2.0 + amount.abs() * 3.0) * (0.5 + 0.5 * math.sin(particleAnimation * 2 * math.pi + i));
      
      canvas.drawCircle(particlePos, particleSize, particlePaint);
      
      // Particle glow
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particleSize);
      
      canvas.drawCircle(particlePos, particleSize * 1.5, glowPaint);
    }
  }

  Offset _cubicBezierPoint(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
    final u = 1 - t;
    final tt = t * t;
    final uu = u * u;
    final uuu = uu * u;
    final ttt = tt * t;
    
    final x = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
    final y = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
    
    return Offset(x, y);
  }

  void _drawDragLine(Canvas canvas, Size size) {
    if (dragStart == null || dragEnd == null) return;
    
    final paint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    // Dashed line effect
    final dashPaint = Paint()
      ..color = HolographicTheme.accentEnergy.withOpacity(0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(dragStart!, dragEnd!, paint);
    
    // Draw potential connection indicators
    final sourceIndex = _getSourceIndexFromDragPosition(dragStart!, size);
    final destIndex = _getDestinationIndexFromDragPosition(dragEnd!, size);
    
    if (sourceIndex >= 0) {
      final sourceY = 40 + (sourceIndex * (size.height - 80) / sources.length);
      canvas.drawCircle(
        Offset(40, sourceY),
        10,
        Paint()
          ..color = HolographicTheme.accentEnergy.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    
    if (destIndex >= 0) {
      final destY = 40 + (destIndex * (size.height - 80) / destinations.length);
      canvas.drawCircle(
        Offset(size.width - 40, destY),
        10,
        Paint()
          ..color = HolographicTheme.accentEnergy.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  int _getSourceIndexFromDragPosition(Offset position, Size size) {
    if (position.dx > size.width / 2) return -1;
    final normalizedY = (position.dy - 40) / (size.height - 80);
    final index = (normalizedY * sources.length).round();
    return index.clamp(0, sources.length - 1);
  }

  int _getDestinationIndexFromDragPosition(Offset position, Size size) {
    if (position.dx < size.width / 2) return -1;
    final normalizedY = (position.dy - 40) / (size.height - 80);
    final index = (normalizedY * destinations.length).round();
    return index.clamp(0, destinations.length - 1);
  }

  @override
  bool shouldRepaint(ModulationMatrixPainter oldDelegate) {
    return oldDelegate.connections != connections ||
           oldDelegate.selectedConnection != selectedConnection ||
           oldDelegate.flowAnimation != flowAnimation ||
           oldDelegate.particleAnimation != particleAnimation ||
           oldDelegate.isDragging != isDragging ||
           oldDelegate.dragStart != dragStart ||
           oldDelegate.dragEnd != dragEnd;
  }
}