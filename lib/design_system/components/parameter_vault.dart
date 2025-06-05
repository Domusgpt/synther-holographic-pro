import '../design_system.dart';

/// Parameter vault for drag-and-drop parameter management
/// Allows users to assign any knob/parameter to any control surface
class ParameterVault extends StatefulWidget {
  final List<DraggableParameter> availableParameters;
  final List<ParameterSlot> activeSlots;
  final bool isOpen;
  final VoidCallback? onToggle;
  final ValueChanged<ParameterBinding>? onParameterAssigned;
  final VoidCallback? onParameterRemoved;
  final double width;
  final double height;
  
  const ParameterVault({
    Key? key,
    required this.availableParameters,
    required this.activeSlots,
    this.isOpen = false,
    this.onToggle,
    this.onParameterAssigned,
    this.onParameterRemoved,
    this.width = 300,
    this.height = 400,
  }) : super(key: key);
  
  @override
  State<ParameterVault> createState() => _ParameterVaultState();
}

class _ParameterVaultState extends State<ParameterVault>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  String? _draggedParameterId;
  String? _dropTargetSlotId;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -widget.width,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isOpen) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(ParameterVault oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: _buildVaultContent(),
          ),
        );
      },
    );
  }
  
  Widget _buildVaultContent() {
    return GlassmorphicPane(
      width: widget.width,
      height: widget.height,
      tintColor: DesignTokens.neonPurple,
      opacity: 0.15,
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Available parameters section
          Expanded(
            flex: 2,
            child: _buildAvailableParameters(),
          ),
          
          // Active bindings section
          Expanded(
            flex: 1,
            child: _buildActiveBindings(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing3),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: DesignTokens.neonPurple,
            size: 20,
          ),
          SizedBox(width: DesignTokens.spacing2),
          Text(
            'PARAMETER VAULT',
            style: SyntherTypography.titleSmall.copyWith(
              color: DesignTokens.neonPurple,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onToggle,
            child: Icon(
              Icons.close,
              color: DesignTokens.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvailableParameters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing3),
          child: Text(
            'Available Parameters',
            style: SyntherTypography.labelMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacing2),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing2),
            itemCount: widget.availableParameters.length,
            itemBuilder: (context, index) {
              final parameter = widget.availableParameters[index];
              return _buildParameterItem(parameter);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildParameterItem(DraggableParameter parameter) {
    final isDragging = _draggedParameterId == parameter.id;
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing1),
      child: LongPressDraggable<DraggableParameter>(
        data: parameter,
        onDragStarted: () {
          setState(() => _draggedParameterId = parameter.id);
        },
        onDragEnd: (details) {
          setState(() {
            _draggedParameterId = null;
            _dropTargetSlotId = null;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: _buildParameterChip(parameter, true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildParameterChip(parameter, false),
        ),
        child: _buildParameterChip(parameter, false),
      ),
    );
  }
  
  Widget _buildParameterChip(DraggableParameter parameter, bool isDragging) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.spacing2,
        vertical: DesignTokens.spacing1,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            parameter.color.withOpacity(0.2),
            parameter.color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: parameter.color.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: isDragging
          ? [
              BoxShadow(
                color: parameter.color.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ]
          : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: parameter.color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: DesignTokens.spacing1),
          Text(
            parameter.name,
            style: SyntherTypography.labelSmall,
          ),
          if (parameter.unit.isNotEmpty) ...[
            SizedBox(width: DesignTokens.spacing1),
            Text(
              parameter.unit,
              style: SyntherTypography.labelSmall.copyWith(
                color: DesignTokens.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActiveBindings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing3),
          child: Text(
            'Active Bindings',
            style: SyntherTypography.labelMedium.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
        ),
        SizedBox(height: DesignTokens.spacing2),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.spacing2),
            itemCount: widget.activeSlots.length,
            itemBuilder: (context, index) {
              final slot = widget.activeSlots[index];
              return _buildSlotItem(slot);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSlotItem(ParameterSlot slot) {
    final isDropTarget = _dropTargetSlotId == slot.id;
    
    return Padding(
      padding: EdgeInsets.only(bottom: DesignTokens.spacing1),
      child: DragTarget<DraggableParameter>(
        onWillAccept: (data) => data != null,
        onAccept: (parameter) {
          final binding = ParameterBinding(
            slotId: slot.id,
            parameterId: parameter.id,
            parameterName: parameter.name,
            slotName: slot.name,
          );
          widget.onParameterAssigned?.call(binding);
        },
        onMove: (details) {
          setState(() => _dropTargetSlotId = slot.id);
        },
        onLeave: (data) {
          setState(() => _dropTargetSlotId = null);
        },
        builder: (context, candidateData, rejectedData) {
          return _buildSlotContent(slot, candidateData.isNotEmpty || isDropTarget);
        },
      ),
    );
  }
  
  Widget _buildSlotContent(ParameterSlot slot, bool isHighlighted) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.spacing2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slot.color.withOpacity(isHighlighted ? 0.3 : 0.1),
            slot.color.withOpacity(isHighlighted ? 0.2 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        border: Border.all(
          color: slot.color.withOpacity(isHighlighted ? 0.8 : 0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            slot.icon,
            color: slot.color,
            size: 16,
          ),
          SizedBox(width: DesignTokens.spacing2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.name,
                  style: SyntherTypography.labelSmall.copyWith(
                    color: slot.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (slot.assignedParameter != null) ...[
                  SizedBox(height: 2),
                  Text(
                    slot.assignedParameter!,
                    style: SyntherTypography.labelSmall.copyWith(
                      color: DesignTokens.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (slot.assignedParameter != null)
            GestureDetector(
              onTap: widget.onParameterRemoved,
              child: Icon(
                Icons.clear,
                color: DesignTokens.textSecondary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }
}

/// Represents a draggable parameter
class DraggableParameter {
  final String id;
  final String name;
  final String unit;
  final Color color;
  
  const DraggableParameter({
    required this.id,
    required this.name,
    this.unit = '',
    required this.color,
  });
}

/// Represents a slot where parameters can be assigned
class ParameterSlot {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final String? assignedParameter;
  
  const ParameterSlot({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.assignedParameter,
  });
  
  ParameterSlot copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    String? assignedParameter,
  }) {
    return ParameterSlot(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      assignedParameter: assignedParameter ?? this.assignedParameter,
    );
  }
}

/// Represents a binding between a parameter and a slot
class ParameterBinding {
  final String slotId;
  final String parameterId;
  final String parameterName;
  final String slotName;
  final DateTime createdAt;
  
  ParameterBinding({
    required this.slotId,
    required this.parameterId,
    required this.parameterName,
    required this.slotName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'parameterId': parameterId,
      'parameterName': parameterName,
      'slotName': slotName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  factory ParameterBinding.fromJson(Map<String, dynamic> json) {
    return ParameterBinding(
      slotId: json['slotId'],
      parameterId: json['parameterId'],
      parameterName: json['parameterName'],
      slotName: json['slotName'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

/// Predefined parameter slots for common controls
class ParameterSlots {
  static const List<ParameterSlot> xyPadSlots = [
    ParameterSlot(
      id: 'xy_x',
      name: 'XY Pad X-Axis',
      color: DesignTokens.neonCyan,
      icon: Icons.swap_horiz,
    ),
    ParameterSlot(
      id: 'xy_y',
      name: 'XY Pad Y-Axis',
      color: DesignTokens.neonCyan,
      icon: Icons.swap_vert,
    ),
  ];
  
  static const List<ParameterSlot> touchPadSlots = [
    ParameterSlot(
      id: 'pad_1',
      name: 'Touch Pad 1',
      color: DesignTokens.neonPink,
      icon: Icons.touch_app,
    ),
    ParameterSlot(
      id: 'pad_2',
      name: 'Touch Pad 2',
      color: DesignTokens.neonPink,
      icon: Icons.touch_app,
    ),
    ParameterSlot(
      id: 'pad_3',
      name: 'Touch Pad 3',
      color: DesignTokens.neonPink,
      icon: Icons.touch_app,
    ),
    ParameterSlot(
      id: 'pad_4',
      name: 'Touch Pad 4',
      color: DesignTokens.neonPink,
      icon: Icons.touch_app,
    ),
  ];
  
  static const List<ParameterSlot> modWheelSlots = [
    ParameterSlot(
      id: 'mod_wheel',
      name: 'Mod Wheel',
      color: DesignTokens.neonPurple,
      icon: Icons.tune,
    ),
    ParameterSlot(
      id: 'pitch_bend',
      name: 'Pitch Bend',
      color: DesignTokens.neonPurple,
      icon: Icons.graphic_eq,
    ),
  ];
}