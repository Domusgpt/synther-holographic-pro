import 'dart:ui';
import 'package:flutter/material.dart';
import '../design_system.dart';

/// Bezel-mounted tab system for Morph-UI
/// Tabs are positioned on screen edges and never cover the visualizer
class BezelTabSystem extends StatefulWidget {
  final List<BezelTab> leftTabs;
  final List<BezelTab> rightTabs;
  final List<BezelTab> topTabs;
  final List<BezelTab> bottomTabs;
  final String activeTabId;
  final ValueChanged<String>? onTabChanged;
  final bool enableReordering;
  final EdgeInsets safeAreaPadding;
  
  const BezelTabSystem({
    Key? key,
    this.leftTabs = const [],
    this.rightTabs = const [],
    this.topTabs = const [],
    this.bottomTabs = const [],
    this.activeTabId = '',
    this.onTabChanged,
    this.enableReordering = true,
    this.safeAreaPadding = EdgeInsets.zero,
  }) : super(key: key);
  
  @override
  State<BezelTabSystem> createState() => _BezelTabSystemState();
}

class _BezelTabSystemState extends State<BezelTabSystem>
    with TickerProviderStateMixin {
  String? _draggedTabId;
  BezelPosition? _dragTargetPosition;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Left tabs
        if (widget.leftTabs.isNotEmpty)
          _buildTabColumn(
            widget.leftTabs,
            BezelPosition.left,
            Alignment.centerLeft,
          ),
        
        // Right tabs
        if (widget.rightTabs.isNotEmpty)
          _buildTabColumn(
            widget.rightTabs,
            BezelPosition.right,
            Alignment.centerRight,
          ),
        
        // Top tabs
        if (widget.topTabs.isNotEmpty)
          _buildTabRow(
            widget.topTabs,
            BezelPosition.top,
            Alignment.topCenter,
          ),
        
        // Bottom tabs
        if (widget.bottomTabs.isNotEmpty)
          _buildTabRow(
            widget.bottomTabs,
            BezelPosition.bottom,
            Alignment.bottomCenter,
          ),
      ],
    );
  }
  
  Widget _buildTabColumn(
    List<BezelTab> tabs,
    BezelPosition position,
    Alignment alignment,
  ) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: EdgeInsets.only(
            left: position == BezelPosition.left ? widget.safeAreaPadding.left : 0,
            right: position == BezelPosition.right ? widget.safeAreaPadding.right : 0,
            top: widget.safeAreaPadding.top + 60,
            bottom: widget.safeAreaPadding.bottom + 60,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tabs.map((tab) => _buildBezelTabWidget(
              tab,
              position,
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabRow(
    List<BezelTab> tabs,
    BezelPosition position,
    Alignment alignment,
  ) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: Container(
          margin: EdgeInsets.only(
            left: widget.safeAreaPadding.left + 60,
            right: widget.safeAreaPadding.right + 60,
            top: position == BezelPosition.top ? widget.safeAreaPadding.top : 0,
            bottom: position == BezelPosition.bottom ? widget.safeAreaPadding.bottom : 0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: tabs.map((tab) => _buildBezelTabWidget(
              tab,
              position,
            )).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBezelTabWidget(
    BezelTab tab,
    BezelPosition position,
  ) {
    final isActive = tab.id == widget.activeTabId;
    final isDragTarget = _dragTargetPosition == position;
    
    return Padding(
      padding: const EdgeInsets.all(4),
      child: widget.enableReordering
        ? _buildDraggableTab(tab, position, isActive, isDragTarget)
        : _buildStaticTab(tab, position, isActive),
    );
  }
  
  Widget _buildDraggableTab(
    BezelTab tab,
    BezelPosition position,
    bool isActive,
    bool isDragTarget,
  ) {
    return GestureDetector(
      onTap: () => widget.onTabChanged?.call(tab.id),
      child: _buildTabContent(tab, position, isActive, isDragTarget),
    );
  }
  
  Widget _buildStaticTab(
    BezelTab tab,
    BezelPosition position,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => widget.onTabChanged?.call(tab.id),
      child: _buildTabContent(tab, position, isActive, false),
    );
  }
  
  Widget _buildTabContent(
    BezelTab tab,
    BezelPosition position,
    bool isActive,
    bool isDragTarget,
  ) {
    final isVertical = position == BezelPosition.left || position == BezelPosition.right;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isVertical ? 40 : (tab.label.length * 8 + 24),
      height: isVertical ? (tab.label.length * 8 + 24) : 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tab.color.withOpacity(isActive ? 0.3 : 0.1),
            tab.color.withOpacity(isActive ? 0.2 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tab.color.withOpacity(isActive ? 0.6 : 0.3),
          width: isDragTarget ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: tab.color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: isVertical
              ? RotatedBox(
                  quarterTurns: position == BezelPosition.left ? 3 : 1,
                  child: _buildTabText(tab, isActive),
                )
              : _buildTabText(tab, isActive),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTabText(BezelTab tab, bool isActive) {
    return Text(
      tab.label,
      style: SyntherTypography.labelSmall.copyWith(
        color: isActive ? tab.color : tab.color.withOpacity(0.8),
        fontSize: 10,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Individual bezel tab data
class BezelTab {
  final String id;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final Widget? icon;
  final String? tooltip;
  
  const BezelTab({
    required this.id,
    required this.label,
    this.color = Colors.cyan,
    this.onTap,
    this.icon,
    this.tooltip,
  });
}

/// Bezel position enumeration
enum BezelPosition {
  left,
  right,
  top,
  bottom,
}