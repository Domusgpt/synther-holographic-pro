import 'package:flutter/material.dart';
import '../../core/holographic_theme.dart';
import '../../core/microtonal_system.dart';

/// Professional Scale Selector Widget
/// 
/// Provides comprehensive interface for selecting and configuring microtonal scales
/// with real-time analysis and visual feedback
class ScaleSelectorWidget extends StatefulWidget {
  final AdvancedMicrotonalScale currentScale;
  final Function(AdvancedMicrotonalScale) onScaleChanged;
  final bool showAnalysis;
  final bool enableCustomScales;
  
  const ScaleSelectorWidget({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
    this.showAnalysis = true,
    this.enableCustomScales = false,
  });
  
  @override
  State<ScaleSelectorWidget> createState() => _ScaleSelectorWidgetState();
}

class _ScaleSelectorWidgetState extends State<ScaleSelectorWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  ScaleCategory _selectedCategory = ScaleCategory.equalTemperament;
  List<AdvancedMicrotonalScale> _availableScales = [];
  ScaleAnalysis? _currentAnalysis;
  
  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
    
    _loadScalesForCategory(_selectedCategory);
    if (widget.showAnalysis) {
      _analyzeCurrentScale();
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  void _loadScalesForCategory(ScaleCategory category) {
    setState(() {
      _selectedCategory = category;
      _availableScales = MicrotonalScaleLibrary.getScalesByCategory(category);
    });
  }
  
  void _analyzeCurrentScale() {
    setState(() {
      _currentAnalysis = widget.currentScale.analyzeIntervals();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HolographicTheme.primaryEnergy.withValues(alpha: 0.1),
                HolographicTheme.deepSpaceBlack.withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HolographicTheme.primaryEnergy.withValues(alpha: 0.3 + (_glowAnimation.value * 0.2)),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              const SizedBox(height: 12),
              _buildScaleSelector(),
              if (widget.showAnalysis && _currentAnalysis != null) ...[
                const SizedBox(height: 12),
                _buildScaleAnalysis(),
              ],
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.music_note,
          color: HolographicTheme.primaryEnergy,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'MICROTONAL SCALE SELECTOR',
          style: TextStyle(
            color: HolographicTheme.primaryEnergy,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: HolographicTheme.accentEnergy.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.accentEnergy.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            widget.currentScale.name.toUpperCase(),
            style: TextStyle(
              color: HolographicTheme.accentEnergy,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCALE CATEGORY',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: ScaleCategory.values.map((category) {
            final isSelected = category == _selectedCategory;
            return GestureDetector(
              onTap: () => _loadScalesForCategory(category),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? HolographicTheme.primaryEnergy.withValues(alpha: 0.2)
                    : HolographicTheme.deepSpaceBlack.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected 
                      ? HolographicTheme.primaryEnergy
                      : HolographicTheme.primaryEnergy.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  _categoryDisplayName(category),
                  style: TextStyle(
                    color: isSelected 
                      ? HolographicTheme.primaryEnergy
                      : HolographicTheme.primaryEnergy.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildScaleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AVAILABLE SCALES',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: HolographicTheme.deepSpaceBlack.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.secondaryEnergy.withValues(alpha: 0.3),
            ),
          ),
          child: ListView.builder(
            itemCount: _availableScales.length,
            itemBuilder: (context, index) {
              final scale = _availableScales[index];
              final isSelected = scale.name == widget.currentScale.name;
              
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                title: Text(
                  scale.name,
                  style: TextStyle(
                    color: isSelected 
                      ? HolographicTheme.accentEnergy
                      : HolographicTheme.primaryEnergy.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  scale.description,
                  style: TextStyle(
                    color: HolographicTheme.secondaryEnergy.withValues(alpha: 0.6),
                    fontSize: 9,
                  ),
                ),
                trailing: isSelected 
                  ? Icon(
                      Icons.check_circle,
                      color: HolographicTheme.accentEnergy,
                      size: 16,
                    )
                  : null,
                onTap: () {
                  widget.onScaleChanged(scale);
                  if (widget.showAnalysis) {
                    _analyzeCurrentScale();
                  }
                },
                selected: isSelected,
                selectedTileColor: HolographicTheme.accentEnergy.withValues(alpha: 0.1),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildScaleAnalysis() {
    if (_currentAnalysis == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCALE ANALYSIS',
          style: TextStyle(
            color: HolographicTheme.accentEnergy,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HolographicTheme.deepSpaceBlack.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: HolographicTheme.accentEnergy.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnalysisRow('Degrees', '${widget.currentScale.ratios.length}'),
              _buildAnalysisRow('Avg Step', '${_currentAnalysis!.averageStepSize.toStringAsFixed(1)}¢'),
              _buildAnalysisRow('Symmetry', _currentAnalysis!.symmetryDegree > 0 ? 'Yes' : 'None'),
              _buildAnalysisRow('Category', _categoryDisplayName(widget.currentScale.category)),
              if (widget.currentScale.metadata.isNotEmpty)
                _buildAnalysisRow('Origin', widget.currentScale.metadata['origin']?.toString() ?? 'Unknown'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: HolographicTheme.secondaryEnergy.withValues(alpha: 0.8),
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: HolographicTheme.accentEnergy,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _categoryDisplayName(ScaleCategory category) {
    switch (category) {
      case ScaleCategory.equalTemperament:
        return 'EQUAL TEMP';
      case ScaleCategory.justIntonation:
        return 'JUST INTON';
      case ScaleCategory.historicalTemperament:
        return 'HISTORICAL';
      case ScaleCategory.worldMusic:
        return 'WORLD MUSIC';
      case ScaleCategory.experimental:
        return 'EXPERIMENTAL';
      case ScaleCategory.custom:
        return 'CUSTOM';
    }
  }
}