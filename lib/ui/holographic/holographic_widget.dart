import 'package:flutter/material.dart';
import 'holographic_theme.dart';

/// A versatile holographic UI widget shell that provides common windowing behaviors.
///
/// Features:
/// - **Draggable:** Can be moved around on the screen.
/// - **Resizable:** User can resize the widget from its bottom-right corner.
/// - **Collapsible:** Can be minimized to a small icon and expanded back.
/// - **Dynamic Sizing:** Supports programmatic expansion to a default expanded size
///   and contraction to a specified compact size via `expandToDefault()` and `contractTo()` methods.
///   This is managed using an [AnimatedContainer] for smooth size transitions for width/height changes.
///   The full collapse to an icon uses a separate scale animation (`_collapseAnimation`) on top of this.
/// - **Customizable Appearance:** Takes an `energyColor` for theming and a `title`.
/// - **State Callbacks:** Provides callbacks for collapse, expand, position, and size changes.
///
/// Parameters:
/// - [initialSize]: The initial size of the widget when it first appears or when not compact/collapsed.
///   This can represent a "compact" size if `defaultExpandedSize` is also provided.
/// - [defaultExpandedSize]: The target size when `expandToDefault()` is called. If null, defaults to `initialSize`.
///   This allows a widget to have a different compact `initialSize` and a larger "default expanded" size.
class HolographicWidget extends StatefulWidget {
  final Widget child;
  final String title;
  final Color energyColor;
  final bool isDraggable;
  final bool isResizable;
  final bool isCollapsible;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final VoidCallback? onCollapse;
  final VoidCallback? onExpand;
  final ValueChanged<Offset>? onPositionChanged;
  final ValueChanged<Size>? onSizeChanged;
  final bool startCollapsed;
  final Size initialSize;
  final Size? defaultExpandedSize; // New optional parameter
  
  const HolographicWidget({
    Key? key,
    required this.child,
    required this.title,
    this.energyColor = HolographicTheme.primaryEnergy,
    this.isDraggable = true,
    this.isResizable = true,
    this.isCollapsible = true,
    this.minWidth = 100.0,
    this.minHeight = 100.0,
    this.maxWidth = 800.0,
    this.maxHeight = 600.0,
    this.onCollapse,
    this.onExpand,
    this.onPositionChanged,
    this.onSizeChanged,
    this.startCollapsed = false,
    this.initialSize = const Size(300, 200),
    this.defaultExpandedSize,
  }) : super(key: key);
  
  @override
  State<HolographicWidget> createState() => _HolographicWidgetState();
}

class _HolographicWidgetState extends State<HolographicWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late AnimationController _collapseController;
  late Animation<double> _glowAnimation;
  late Animation<double> _collapseAnimation;
  
  Offset _position = const Offset(100, 100);
  // Size _size = const Size(300, 200); // Will be initialized from _defaultExpandedSize or widget.initialSize
  late Size _size; // Current animated size
  late Size _defaultExpandedSize; // Default expanded size, from initialSize
  bool _isCollapsed = false;
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    _defaultExpandedSize = widget.defaultExpandedSize ?? widget.initialSize; // Use provided or default to initialSize
    _size = widget.startCollapsed ? const Size(24,24) : (widget.initialSize == _defaultExpandedSize ? _defaultExpandedSize : widget.initialSize) ; // Start with initialSize, which might be compact
    _isCollapsed = widget.startCollapsed;
    
    // Glow animation for energy effects
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
    
    // Collapse/expand animation
    _collapseController = AnimationController(
      duration: HolographicTheme.collapseDuration,
      vsync: this,
    );
    _collapseAnimation = CurvedAnimation(
      parent: _collapseController,
      curve: Curves.elasticOut,
    );
    
    if (!_isCollapsed) {
      _collapseController.value = 1.0;
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    _collapseController.dispose();
    super.dispose();
  }
  
  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
    
    if (_isCollapsed) {
      _collapseController.reverse();
      widget.onCollapse?.call();
    } else {
      _collapseController.forward();
      widget.onExpand?.call();
    }
    setState(() { // Ensure UI rebuilds with correct size if toggling from icon state
        _size = _isCollapsed ? const Size(24,24) : _defaultExpandedSize;
    });
  }
  
  // Public methods for dynamic sizing
  /// Expands the widget to its `_defaultExpandedSize`.
  /// If the widget is fully collapsed (iconified), it first performs the expand animation
  /// (which includes setting `_isCollapsed = false` and setting `_size` to `_defaultExpandedSize`).
  /// The size change itself is animated by the [AnimatedContainer] in the build method.
  /// The `_collapseController` (scale animation) is also driven to full to ensure opacity.
  void expandToDefault() {
    bool needsToUncollapse = _isCollapsed;

    if (needsToUncollapse) {
      _toggleCollapse(); // This will set _isCollapsed = false and _size = _defaultExpandedSize
    } else {
      // If already expanded or in a compact state, just ensure size is defaultExpandedSize
      if (_size != _defaultExpandedSize) {
        setState(() {
          _size = _defaultExpandedSize;
        });
      }
    }

    // Ensure opacity/scale animation (controlled by _collapseController) is in the fully expanded state.
    if (_collapseController.status != AnimationStatus.completed && !_isCollapsed) {
      _collapseController.forward();
    }
  }

  /// Contracts the widget to a specified [newSize].
  /// This is for a "compact" view, not a full collapse to an icon.
  /// The size change is animated by the [AnimatedContainer].
  /// Does nothing if the widget is already fully collapsed to an icon.
  void contractTo(Size newSize) {
    if (_isCollapsed) return; // Don't contract if already fully collapsed to icon state

    Size clampedNewSize = Size(
      newSize.width.clamp(widget.minWidth, widget.maxWidth),
      newSize.height.clamp(widget.minHeight, widget.maxHeight)
    );

    if (_size != clampedNewSize) {
      setState(() {
        _size = clampedNewSize;
      });
    }

    // Ensure opacity/scale animation is in expanded state if it wasn't (e.g. if it was mid-collapse).
    // This ensures the widget is visually opaque and fully scaled, even if its dimensions are now "compact".
     if (_collapseController.status != AnimationStatus.completed && !_isCollapsed) {
      _collapseController.forward();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isDraggable) return;
    
    setState(() {
      _position += details.delta;
      _isDragging = true;
    });
    
    widget.onPositionChanged?.call(_position);
  }
  
  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
  }
  
  void _onResizePanUpdate(DragUpdateDetails details) {
    if (!widget.isResizable) return;
    
    setState(() {
      final newWidth = (_size.width + details.delta.dx)
          .clamp(widget.minWidth, widget.maxWidth);
      final newHeight = (_size.height + details.delta.dy)
          .clamp(widget.minHeight, widget.maxHeight);
      
      _size = Size(newWidth, newHeight);
      _isResizing = true;
    });
    
    widget.onSizeChanged?.call(_size);
  }
  
  void _onResizePanEnd(DragEndDetails details) {
    setState(() {
      _isResizing = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnimation, _collapseAnimation]),
          builder: (context, child) {
            final glowIntensity = _glowAnimation.value * 
                (_isHovered ? 1.3 : 1.0) * 
                (_isDragging || _isResizing ? 1.5 : 1.0);
            
            if (_isCollapsed && _collapseAnimation.value < 0.1) {
              // Collapsed state - show as glowing dot
              return _buildCollapsedWidget(glowIntensity);
            }
            
            return Transform.scale(
              scale: _collapseAnimation.value,
              child: Opacity(
                opacity: _collapseAnimation.value,
                child: _buildExpandedWidget(glowIntensity),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildCollapsedWidget(double glowIntensity) {
    return GestureDetector(
      onTap: _toggleCollapse,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: widget.energyColor.withOpacity(0.6),
          shape: BoxShape.circle,
          boxShadow: [
            HolographicTheme.createEnergyGlow(
              color: widget.energyColor,
              intensity: glowIntensity,
              radius: 12.0,
            ),
          ],
        ),
        child: Icon(
          Icons.add,
          color: widget.energyColor,
          size: 16,
        ),
      ),
    );
  }
  
  Widget _buildExpandedWidget(double glowIntensity) {
    return AnimatedContainer(
      duration: HolographicTheme.generalAnimationDuration, // Use a theme duration
      curve: Curves.fastOutSlowIn,
      width: _size.width,
      height: _size.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: widget.energyColor,
        intensity: glowIntensity,
        cornerRadius: 12.0,
      ),
      child: Stack(
        children: [
          // Title bar with drag handle and collapse button
          _buildTitleBar(),
          
          // Main content area
          Positioned(
            left: 8,
            top: 40,
            right: 8,
            bottom: widget.isResizable ? 24 : 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: widget.child,
              ),
            ),
          ),
          
          // Resize handle
          if (widget.isResizable)
            Positioned(
              right: 4,
              bottom: 4,
              child: GestureDetector(
                onPanUpdate: _onResizePanUpdate,
                onPanEnd: _onResizePanEnd,
                child: HolographicTheme.createResizeHandle(
                  energyColor: widget.energyColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildTitleBar() {
    return Positioned(
      left: 0,
      top: 0,
      right: 0,
      height: 32,
      child: Container(
        decoration: BoxDecoration(
          color: widget.energyColor.withOpacity(0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12.0),
            topRight: Radius.circular(12.0),
          ),
          border: Border(
            bottom: BorderSide(
              color: widget.energyColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
        ),
        child: Row(
          children: [
            // Drag handle
            if (widget.isDraggable)
              GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: HolographicTheme.createDragHandle(
                    energyColor: widget.energyColor,
                    size: 20.0,
                  ),
                ),
              ),
            
            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  widget.title,
                  style: HolographicTheme.createHolographicText(
                    energyColor: widget.energyColor,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Collapse button
            if (widget.isCollapsible)
              GestureDetector(
                onTap: _toggleCollapse,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: widget.energyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.energyColor.withOpacity(0.6),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      color: widget.energyColor,
                      size: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Holographic dropdown with energy effects
class HolographicDropdown<T> extends StatefulWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;
  final Color energyColor;
  
  const HolographicDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
    this.energyColor = HolographicTheme.primaryEnergy,
  }) : super(key: key);
  
  @override
  State<HolographicDropdown<T>> createState() => _HolographicDropdownState<T>();
}

class _HolographicDropdownState<T> extends State<HolographicDropdown<T>> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: HolographicTheme.createHolographicBorder(
          energyColor: widget.energyColor,
          intensity: _isHovered ? 1.3 : 1.0,
          cornerRadius: 6.0,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: widget.value,
            items: widget.items,
            onChanged: widget.onChanged,
            hint: Text(
              widget.hint,
              style: HolographicTheme.createHolographicText(
                energyColor: widget.energyColor.withOpacity(0.7),
                fontSize: 12.0,
              ),
            ),
            style: HolographicTheme.createHolographicText(
              energyColor: widget.energyColor,
              fontSize: 12.0,
            ),
            dropdownColor: Colors.black.withOpacity(0.9),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: widget.energyColor,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}