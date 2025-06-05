// Enhanced LLM Preset Generator with Professional UI
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/holographic_theme.dart';
import '../services/firebase_service.dart';

class EnhancedLLMGenerator extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Function(Map<String, dynamic>)? onPresetGenerated;

  const EnhancedLLMGenerator({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onPresetGenerated,
  }) : super(key: key);

  @override
  State<EnhancedLLMGenerator> createState() => _EnhancedLLMGeneratorState();
}

class _EnhancedLLMGeneratorState extends State<EnhancedLLMGenerator>
    with TickerProviderStateMixin {
  
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  String _lastGeneratedDescription = '';
  
  // Animation controllers
  late AnimationController _glowController;
  late AnimationController _typewriterController;
  late Animation<double> _glowAnimation;
  
  // Predefined prompt suggestions
  final List<String> _promptSuggestions = [
    'warm analog bass with deep sub frequencies',
    'ethereal pad with shimmer and long decay',
    'aggressive lead synth with distortion',
    'crystal-clear bell sounds with reverb',
    'dark atmospheric drone with modulation',
    'punchy drum kit with compressed transients',
    'vintage analog warmth with tape saturation',
    'futuristic digital textures with glitch',
  ];

  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );
    
    _typewriterController = AnimationController(
      duration: Duration(milliseconds: 800),
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
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome,
            color: HolographicTheme.tertiaryEnergy,
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
        width: 450,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _buildGeneratorContent(),
              ),
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
        color: HolographicTheme.tertiaryEnergy.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 15),
          Icon(
            Icons.auto_awesome,
            color: HolographicTheme.tertiaryEnergy,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            'AI PRESET GENERATOR',
            style: TextStyle(
              color: HolographicTheme.tertiaryEnergy,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              shadows: [
                Shadow(
                  color: HolographicTheme.tertiaryEnergy.withOpacity(0.8),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
          Spacer(),
          // Collapse button
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.tertiaryEnergy,
                size: 14,
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildGeneratorContent() {
    return Row(
      children: [
        // Text input field
        Expanded(
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return TextField(
                  controller: _textController,
                  style: TextStyle(
                    color: HolographicTheme.tertiaryEnergy,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Describe your sound...',
                    hintStyle: TextStyle(
                      color: HolographicTheme.tertiaryEnergy.withOpacity(0.5),
                      fontSize: 13,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    border: InputBorder.none,
                    suffixIcon: _textController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
                            size: 18,
                          ),
                          onPressed: () {
                            _textController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  ),
                  onChanged: (value) => setState(() {}),
                  onSubmitted: (value) => _generatePreset(),
                );
              },
            ),
          ),
        ),
        
        SizedBox(width: 10),
        
        // Generate button
        GestureDetector(
          onTap: _isGenerating ? null : _generatePreset,
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 45,
                decoration: BoxDecoration(
                  color: _isGenerating 
                    ? HolographicTheme.secondaryEnergy.withOpacity(0.3)
                    : HolographicTheme.tertiaryEnergy.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isGenerating 
                      ? HolographicTheme.secondaryEnergy.withOpacity(0.6)
                      : HolographicTheme.tertiaryEnergy.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isGenerating 
                        ? HolographicTheme.secondaryEnergy 
                        : HolographicTheme.tertiaryEnergy).withOpacity(0.3 * _glowAnimation.value),
                      blurRadius: 10 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: _isGenerating 
                  ? _buildGeneratingIndicator()
                  : Center(
                      child: Text(
                        'GENERATE',
                        style: TextStyle(
                          color: HolographicTheme.tertiaryEnergy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
              );
            },
          ),
        ),
        
        SizedBox(width: 10),
        
        // Quick suggestions button
        GestureDetector(
          onTap: _showSuggestions,
          child: Container(
            width: 40,
            height: 45,
            decoration: BoxDecoration(
              color: HolographicTheme.primaryEnergy.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: HolographicTheme.primaryEnergy.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.lightbulb_outline,
              color: HolographicTheme.primaryEnergy,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(HolographicTheme.secondaryEnergy),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'AI',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _generatePreset() async {
    if (_textController.text.trim().isEmpty || _isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _lastGeneratedDescription = _textController.text.trim();
    });
    
    try {
      // Get Firebase service
      final firebaseService = context.read<FirebaseService?>();
      
      if (firebaseService == null) {
        throw Exception('Firebase not available');
      }
      
      // Generate preset using LLM
      final generatedParams = await firebaseService.generateAIPreset(_lastGeneratedDescription);
      
      if (generatedParams != null) {
        // Convert to map for callback
        final presetMap = generatedParams.toJson();
        
        // Trigger callback
        widget.onPresetGenerated?.call(presetMap);
        
        // Show success feedback
        _showSuccessFeedback();
        
        // Clear input
        _textController.clear();
        
      } else {
        throw Exception('Failed to generate preset');
      }
      
    } catch (e) {
      debugPrint('Preset generation error: $e');
      _showErrorFeedback(e.toString());
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
  }

  void _showSuggestions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 350,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: HolographicTheme.primaryEnergy,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'PROMPT SUGGESTIONS',
                      style: TextStyle(
                        color: HolographicTheme.primaryEnergy,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close,
                        color: HolographicTheme.primaryEnergy,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Suggestions list
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: _promptSuggestions.map((suggestion) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          _textController.text = suggestion;
                          Navigator.of(context).pop();
                          setState(() {});
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HolographicTheme.primaryEnergy.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              color: HolographicTheme.primaryEnergy.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: HolographicTheme.secondaryEnergy),
            SizedBox(width: 10),
            Text(
              '🎵 AI preset generated successfully!',
              style: TextStyle(color: HolographicTheme.secondaryEnergy),
            ),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorFeedback(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Generation failed: $error',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        duration: Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _glowController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }
}