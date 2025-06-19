import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../core/ui/holographic_theme.dart';
import '../../core/ui/glassmorphism_widgets.dart';
import '../../core/effects/effects_engine.dart';
import '../../core/effects/additional_effects.dart';

/// Professional Effects Interface
/// 
/// Provides comprehensive effects control UI:
/// - Effects chain visualization with drag-and-drop reordering
/// - Real-time parameter controls with audio reactivity
/// - Frequency response visualization for EQ
/// - Effects presets and automation
/// - Performance monitoring and optimization
/// - Professional effects routing matrix

class EffectsInterface extends StatefulWidget {
  final EffectsEngine effectsEngine;
  final Function(String effectType)? onAddEffect;
  final Function(String effectName)? onRemoveEffect;
  final Function(String effectName, int newIndex)? onReorderEffect;
  
  const EffectsInterface({
    super.key,
    required this.effectsEngine,
    this.onAddEffect,
    this.onRemoveEffect,
    this.onReorderEffect,
  });
  
  @override
  State<EffectsInterface> createState() => _EffectsInterfaceState();
}

class _EffectsInterfaceState extends State<EffectsInterface>
    with TickerProviderStateMixin {
  
  late AnimationController _visualizationController;
  late AnimationController _effectsChainController;
  late Animation<double> _visualizationAnimation;
  late Animation<double> _effectsChainAnimation;
  
  AudioEffect? _selectedEffect;
  bool _showEffectLibrary = false;
  bool _showFrequencyResponse = false;
  double _masterGain = 1.0;
  
  // Available effects
  final List<Map<String, dynamic>> _availableEffects = [
    {
      'name': 'Convolution Reverb',
      'type': 'convolutionReverb',
      'category': 'Spatial',
      'description': 'High-quality convolution reverb with impulse responses',
      'color': Colors.blue,
    },
    {
      'name': 'Multiband Compressor',
      'type': 'multibandCompressor',
      'category': 'Dynamics',
      'description': '4-band compressor with crossover filters',
      'color': Colors.orange,
    },
    {
      'name': 'Granular Delay',
      'type': 'granularDelay',
      'category': 'Delay',
      'description': 'Granular delay with particle processing',
      'color': Colors.purple,
    },
    {
      'name': 'Parametric EQ',
      'type': 'parametricEQ',
      'category': 'Filter',
      'description': '8-band parametric equalizer',
      'color': Colors.green,
    },
    {
      'name': 'Analog Distortion',
      'type': 'analogDistortion',
      'category': 'Saturation',
      'description': 'Vintage analog-modeled distortion',
      'color': Colors.red,
    },
    {
      'name': 'Vintage Chorus',
      'type': 'vintageChorus',
      'category': 'Modulation',
      'description': 'BBD-modeled vintage chorus effect',
      'color': Colors.cyan,
    },
    {
      'name': 'Professional Limiter',
      'type': 'professionalLimiter',
      'category': 'Dynamics',
      'description': 'Lookahead limiter with transparent operation',
      'color': Colors.amber,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    _visualizationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _effectsChainController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _visualizationAnimation = CurvedAnimation(
      parent: _visualizationController,
      curve: Curves.easeInOut,
    );
    
    _effectsChainAnimation = CurvedAnimation(
      parent: _effectsChainController,
      curve: Curves.easeOutCubic,
    );
    
    _visualizationController.repeat(reverse: true);
    _effectsChainController.forward();
    
    // Listen to effects engine changes
    widget.effectsEngine.addListener(_onEffectsEngineChanged);
  }
  
  @override
  void dispose() {
    _visualizationController.dispose();
    _effectsChainController.dispose();
    widget.effectsEngine.removeListener(_onEffectsEngineChanged);
    super.dispose();
  }
  
  void _onEffectsEngineChanged() {
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        // Effects header with controls
        _buildEffectsHeader(),
        
        SizedBox(height: theme.baseUnit),
        
        // Effects chain visualization
        Expanded(
          flex: 2,
          child: _buildEffectsChain(),
        ),
        
        SizedBox(height: theme.baseUnit),
        
        // Selected effect controls
        if (_selectedEffect != null)
          Expanded(
            flex: 3,
            child: _buildEffectControls(),
          ),
        
        // Effects library overlay
        if (_showEffectLibrary)
          Positioned.fill(
            child: _buildEffectsLibraryOverlay(),
          ),
      ],
    );
  }
  
  Widget _buildEffectsHeader() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'EFFECTS ENGINE',
      child: Row(
        children: [
          // Master controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HolographicSlider(
                  label: 'Master Gain',
                  value: _masterGain,
                  min: 0.0,
                  max: 2.0,
                  onChanged: (value) {
                    setState(() => _masterGain = value);
                    widget.effectsEngine.setMasterGain(value);
                  },
                  enableAudioReactivity: true,
                ),
                
                SizedBox(height: theme.baseUnit),
                
                Row(
                  children: [
                    // CPU usage indicator
                    Expanded(
                      child: _buildPerformanceIndicator(),
                    ),
                    
                    SizedBox(width: theme.baseUnit),
                    
                    // Bypass all effects
                    HolographicButton(
                      onPressed: () {
                        widget.effectsEngine.setEnabled(!widget.effectsEngine.enabled);
                      },
                      enableGlow: !widget.effectsEngine.enabled,
                      child: Text(
                        widget.effectsEngine.enabled ? 'BYPASS' : 'ACTIVE',
                        style: theme.captionStyle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(width: theme.baseUnit * 2),
          
          // Effects library button
          HolographicButton(
            onPressed: () {
              setState(() => _showEffectLibrary = !_showEffectLibrary);
            },
            enableGlow: _showEffectLibrary,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_add,
                  color: theme.primaryColor,
                  size: 24,
                ),
                SizedBox(height: theme.baseUnit / 2),
                Text(
                  'ADD EFFECT',
                  style: theme.captionStyle.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEffectsChain() {
    final theme = HolographicTheme.of(context);
    
    if (widget.effectsEngine.effects.isEmpty) {
      return GlassmorphismContainer(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.graphic_eq,
                color: theme.primaryColor.withOpacity(0.5),
                size: 48,
              ),
              SizedBox(height: theme.baseUnit),
              ChromaticText(
                intensity: 0.3,
                child: Text(
                  'NO EFFECTS LOADED',
                  style: theme.headlineStyle.copyWith(fontSize: 16),
                ),
              ),
              SizedBox(height: theme.baseUnit / 2),
              Text(
                'Add effects to start processing audio',
                style: theme.captionStyle,
              ),
            ],
          ),
        ),
      );
    }
    
    return GlassmorphismContainer(
      padding: EdgeInsets.all(theme.baseUnit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChromaticText(
            intensity: 0.4,
            child: Text(
              'EFFECTS CHAIN',
              style: theme.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          SizedBox(height: theme.baseUnit),
          
          Expanded(
            child: AnimatedBuilder(
              animation: _effectsChainAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _effectsChainAnimation.value,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.effectsEngine.effects.length,
                    itemBuilder: (context, index) {
                      final effect = widget.effectsEngine.effects[index];
                      return Padding(
                        padding: EdgeInsets.only(right: theme.baseUnit),
                        child: _buildEffectChainItem(effect, index),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEffectChainItem(AudioEffect effect, int index) {
    final theme = HolographicTheme.of(context);
    final isSelected = effect == _selectedEffect;
    final effectInfo = _getEffectInfo(effect.type);
    
    return AnimatedBuilder(
      animation: _visualizationAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _selectEffect(effect),
          child: DepthCard(
            depth: isSelected ? 12.0 : 6.0,
            enableTilt: true,
            child: Container(
              width: 120,
              height: 100,
              padding: EdgeInsets.all(theme.baseUnit),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    effectInfo['color'].withOpacity(0.2),
                    effectInfo['color'].withOpacity(0.1),
                  ],
                ),
                border: Border.all(
                  color: isSelected
                    ? theme.primaryColor
                    : effectInfo['color'].withOpacity(0.5),
                  width: isSelected ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(theme.borderRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Effect name
                  ChromaticText(
                    intensity: isSelected ? 0.6 : 0.3,
                    child: Text(
                      effect.name,
                      style: theme.captionStyle.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Effect status indicators
                  Row(
                    children: [
                      // Enabled indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: effect.enabled
                            ? theme.primaryColor
                            : theme.onSurfaceColor.withOpacity(0.3),
                          boxShadow: effect.enabled ? [
                            BoxShadow(
                              color: theme.glowColor.withOpacity(0.5),
                              blurRadius: 4.0,
                              spreadRadius: 1.0,
                            ),
                          ] : null,
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Remove button
                      GestureDetector(
                        onTap: () => _removeEffect(effect),
                        child: Icon(
                          Icons.close,
                          color: theme.onSurfaceColor.withOpacity(0.7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEffectControls() {
    final theme = HolographicTheme.of(context);
    
    if (_selectedEffect == null) return Container();
    
    return GlassPanel(
      title: _selectedEffect!.name.toUpperCase(),
      child: Column(
        children: [
          // Effect-specific controls
          Expanded(
            child: _buildEffectSpecificControls(_selectedEffect!),
          ),
          
          SizedBox(height: theme.baseUnit),
          
          // Common controls
          _buildCommonEffectControls(_selectedEffect!),
        ],
      ),
    );
  }
  
  Widget _buildEffectSpecificControls(AudioEffect effect) {
    final theme = HolographicTheme.of(context);
    
    switch (effect.type) {
      case EffectType.parametricEQ:
        return _buildEQControls(effect as ParametricEQ);
      case EffectType.convolutionReverb:
        return _buildReverbControls(effect);
      case EffectType.multibandCompressor:
        return _buildCompressorControls(effect);
      case EffectType.granularDelay:
        return _buildDelayControls(effect);
      case EffectType.distortion:
        return _buildDistortionControls(effect);
      case EffectType.chorus:
        return _buildChorusControls(effect);
      case EffectType.limiter:
        return _buildLimiterControls(effect);
      default:
        return Container(
          child: Center(
            child: Text(
              'No specific controls available',
              style: theme.captionStyle,
            ),
          ),
        );
    }
  }
  
  Widget _buildEQControls(ParametricEQ eq) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        // Frequency response visualization
        if (_showFrequencyResponse)
          Expanded(
            flex: 2,
            child: _buildFrequencyResponseChart(eq),
          ),
        
        // EQ band controls
        Expanded(
          flex: 3,
          child: GridView.count(
            crossAxisCount: 3,
            childAspectRatio: 0.8,
            children: [
              _buildEQBandControl('Low', EffectParameter.lowFreq, EffectParameter.lowGain),
              _buildEQBandControl('Mid', EffectParameter.midFreq, EffectParameter.midGain),
              _buildEQBandControl('High', EffectParameter.highFreq, EffectParameter.highGain),
            ],
          ),
        ),
        
        // Show/hide frequency response
        HolographicButton(
          onPressed: () {
            setState(() => _showFrequencyResponse = !_showFrequencyResponse);
          },
          child: Text(
            _showFrequencyResponse ? 'HIDE RESPONSE' : 'SHOW RESPONSE',
            style: theme.captionStyle,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEQBandControl(String label, EffectParameter freqParam, EffectParameter gainParam) {
    final theme = HolographicTheme.of(context);
    
    return Container(
      padding: EdgeInsets.all(theme.baseUnit / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.captionStyle.copyWith(fontSize: 10),
          ),
          
          SizedBox(height: theme.baseUnit / 2),
          
          HolographicSlider(
            label: 'Gain',
            value: _selectedEffect!.getParameter(gainParam),
            min: -15.0,
            max: 15.0,
            height: 30,
            onChanged: (value) {
              _selectedEffect!.setParameter(gainParam, value);
            },
          ),
          
          SizedBox(height: theme.baseUnit / 2),
          
          HolographicSlider(
            label: 'Freq',
            value: _selectedEffect!.getParameter(freqParam),
            min: 20.0,
            max: 20000.0,
            height: 30,
            onChanged: (value) {
              _selectedEffect!.setParameter(freqParam, value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildReverbControls(AudioEffect reverb) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        HolographicSlider(
          label: 'Reverb Time',
          value: reverb.getParameter(EffectParameter.reverbTime),
          min: 0.1,
          max: 10.0,
          unit: 's',
          onChanged: (value) {
            reverb.setParameter(EffectParameter.reverbTime, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Room Size',
          value: reverb.getParameter(EffectParameter.reverbSize),
          onChanged: (value) {
            reverb.setParameter(EffectParameter.reverbSize, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Damping',
          value: reverb.getParameter(EffectParameter.reverbDamping),
          onChanged: (value) {
            reverb.setParameter(EffectParameter.reverbDamping, value);
          },
        ),
      ],
    );
  }
  
  Widget _buildCompressorControls(AudioEffect compressor) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HolographicSlider(
                label: 'Threshold',
                value: compressor.getParameter(EffectParameter.threshold),
                min: -60.0,
                max: 0.0,
                unit: 'dB',
                onChanged: (value) {
                  compressor.setParameter(EffectParameter.threshold, value);
                },
              ),
            ),
            
            SizedBox(width: theme.baseUnit),
            
            Expanded(
              child: HolographicSlider(
                label: 'Ratio',
                value: compressor.getParameter(EffectParameter.ratio),
                min: 1.0,
                max: 20.0,
                unit: ':1',
                onChanged: (value) {
                  compressor.setParameter(EffectParameter.ratio, value);
                },
              ),
            ),
          ],
        ),
        
        SizedBox(height: theme.baseUnit),
        
        Row(
          children: [
            Expanded(
              child: HolographicSlider(
                label: 'Attack',
                value: compressor.getParameter(EffectParameter.attack),
                min: 0.1,
                max: 100.0,
                unit: 'ms',
                onChanged: (value) {
                  compressor.setParameter(EffectParameter.attack, value);
                },
              ),
            ),
            
            SizedBox(width: theme.baseUnit),
            
            Expanded(
              child: HolographicSlider(
                label: 'Release',
                value: compressor.getParameter(EffectParameter.release),
                min: 1.0,
                max: 1000.0,
                unit: 'ms',
                onChanged: (value) {
                  compressor.setParameter(EffectParameter.release, value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDelayControls(AudioEffect delay) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        HolographicSlider(
          label: 'Delay Time',
          value: delay.getParameter(EffectParameter.delayTime),
          max: 2.0,
          unit: 's',
          onChanged: (value) {
            delay.setParameter(EffectParameter.delayTime, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Feedback',
          value: delay.getParameter(EffectParameter.feedback),
          max: 0.95,
          onChanged: (value) {
            delay.setParameter(EffectParameter.feedback, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Grain Rate',
          value: delay.getParameter(EffectParameter.rate),
          min: 0.1,
          max: 50.0,
          unit: '/s',
          onChanged: (value) {
            delay.setParameter(EffectParameter.rate, value);
          },
          enableAudioReactivity: true,
        ),
      ],
    );
  }
  
  Widget _buildDistortionControls(AudioEffect distortion) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        HolographicSlider(
          label: 'Drive',
          value: distortion.getParameter(EffectParameter.drive),
          min: 1.0,
          max: 20.0,
          onChanged: (value) {
            distortion.setParameter(EffectParameter.drive, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Tone',
          value: distortion.getParameter(EffectParameter.tone),
          onChanged: (value) {
            distortion.setParameter(EffectParameter.tone, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Saturation',
          value: distortion.getParameter(EffectParameter.saturation),
          onChanged: (value) {
            distortion.setParameter(EffectParameter.saturation, value);
          },
        ),
      ],
    );
  }
  
  Widget _buildChorusControls(AudioEffect chorus) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        HolographicSlider(
          label: 'Rate',
          value: chorus.getParameter(EffectParameter.rate),
          min: 0.1,
          max: 5.0,
          unit: 'Hz',
          onChanged: (value) {
            chorus.setParameter(EffectParameter.rate, value);
          },
          enableAudioReactivity: true,
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Depth',
          value: chorus.getParameter(EffectParameter.depth),
          onChanged: (value) {
            chorus.setParameter(EffectParameter.depth, value);
          },
        ),
      ],
    );
  }
  
  Widget _buildLimiterControls(AudioEffect limiter) {
    final theme = HolographicTheme.of(context);
    
    return Column(
      children: [
        HolographicSlider(
          label: 'Threshold',
          value: limiter.getParameter(EffectParameter.threshold),
          min: -20.0,
          max: 0.0,
          unit: 'dB',
          onChanged: (value) {
            limiter.setParameter(EffectParameter.threshold, value);
          },
        ),
        
        SizedBox(height: theme.baseUnit),
        
        HolographicSlider(
          label: 'Release',
          value: limiter.getParameter(EffectParameter.release),
          min: 1.0,
          max: 1000.0,
          unit: 'ms',
          onChanged: (value) {
            limiter.setParameter(EffectParameter.release, value);
          },
        ),
      ],
    );
  }
  
  Widget _buildCommonEffectControls(AudioEffect effect) {
    final theme = HolographicTheme.of(context);
    
    return Row(
      children: [
        // Enable/disable toggle
        HolographicButton(
          onPressed: () {
            setState(() {
              effect.enabled = !effect.enabled;
            });
          },
          enableGlow: effect.enabled,
          child: Text(
            effect.enabled ? 'ENABLED' : 'BYPASSED',
            style: theme.captionStyle,
          ),
        ),
        
        SizedBox(width: theme.baseUnit),
        
        // Mix control
        Expanded(
          child: HolographicSlider(
            label: 'Mix',
            value: effect.getParameter(EffectParameter.mix),
            onChanged: (value) {
              effect.setParameter(EffectParameter.mix, value);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildPerformanceIndicator() {
    final theme = HolographicTheme.of(context);
    final cpuUsage = widget.effectsEngine.cpuUsage;
    final activeEffects = widget.effectsEngine.activeEffects;
    
    return GlassmorphismContainer(
      padding: EdgeInsets.all(theme.baseUnit),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PERFORMANCE',
            style: theme.captionStyle.copyWith(fontSize: 10),
          ),
          
          SizedBox(height: theme.baseUnit / 2),
          
          Row(
            children: [
              Icon(
                Icons.memory,
                color: theme.primaryColor,
                size: 12,
              ),
              SizedBox(width: theme.baseUnit / 2),
              Text(
                'CPU: ${(cpuUsage * 100).toStringAsFixed(1)}%',
                style: theme.captionStyle.copyWith(fontSize: 10),
              ),
            ],
          ),
          
          Row(
            children: [
              Icon(
                Icons.tune,
                color: theme.secondaryColor,
                size: 12,
              ),
              SizedBox(width: theme.baseUnit / 2),
              Text(
                'Effects: $activeEffects',
                style: theme.captionStyle.copyWith(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildFrequencyResponseChart(ParametricEQ eq) {
    final theme = HolographicTheme.of(context);
    
    return GlassmorphismContainer(
      child: Container(
        padding: EdgeInsets.all(theme.baseUnit),
        child: CustomPaint(
          size: const Size(double.infinity, 100),
          painter: FrequencyResponsePainter(
            eq: eq,
            theme: theme,
          ),
        ),
      ),
    );
  }
  
  Widget _buildEffectsLibraryOverlay() {
    final theme = HolographicTheme.of(context);
    
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 500,
          ),
          child: DepthCard(
            depth: 20.0,
            child: GlassPanel(
              title: 'EFFECTS LIBRARY',
              child: Column(
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _availableEffects.length,
                      itemBuilder: (context, index) {
                        final effectData = _availableEffects[index];
                        return _buildEffectLibraryItem(effectData);
                      },
                    ),
                  ),
                  
                  SizedBox(height: theme.baseUnit),
                  
                  HolographicButton(
                    onPressed: () {
                      setState(() => _showEffectLibrary = false);
                    },
                    child: Text(
                      'CLOSE',
                      style: theme.buttonStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEffectLibraryItem(Map<String, dynamic> effectData) {
    final theme = HolographicTheme.of(context);
    
    return HolographicButton(
      onPressed: () => _addEffect(effectData['type']),
      child: Container(
        padding: EdgeInsets.all(theme.baseUnit),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              effectData['color'].withOpacity(0.2),
              effectData['color'].withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              effectData['name'],
              style: theme.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: theme.baseUnit / 2),
            
            Text(
              effectData['category'],
              style: theme.captionStyle.copyWith(
                fontSize: 10,
                color: effectData['color'],
              ),
            ),
            
            const Spacer(),
            
            Text(
              effectData['description'],
              style: theme.captionStyle.copyWith(fontSize: 10),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  void _selectEffect(AudioEffect effect) {
    setState(() {
      _selectedEffect = effect;
    });
  }
  
  void _addEffect(String effectType) {
    // Create and add effect based on type
    AudioEffect? effect;
    
    switch (effectType) {
      case 'convolutionReverb':
        effect = ConvolutionReverb();
        break;
      case 'multibandCompressor':
        effect = MultibandCompressor();
        break;
      case 'granularDelay':
        effect = GranularDelay();
        break;
      case 'parametricEQ':
        effect = ParametricEQ();
        break;
      case 'analogDistortion':
        effect = AnalogDistortion();
        break;
      case 'vintageChorus':
        effect = VintageChorus();
        break;
      case 'professionalLimiter':
        effect = ProfessionalLimiter();
        break;
    }
    
    if (effect != null) {
      widget.effectsEngine.addEffect(effect);
      setState(() {
        _selectedEffect = effect;
        _showEffectLibrary = false;
      });
      widget.onAddEffect?.call(effectType);
    }
  }
  
  void _removeEffect(AudioEffect effect) {
    widget.effectsEngine.removeEffect(effect.name);
    if (_selectedEffect == effect) {
      setState(() => _selectedEffect = null);
    }
    widget.onRemoveEffect?.call(effect.name);
  }
  
  Map<String, dynamic> _getEffectInfo(EffectType type) {
    return _availableEffects.firstWhere(
      (effect) => effect['type'] == type.toString().split('.').last,
      orElse: () => {
        'name': 'Unknown Effect',
        'color': Colors.grey,
        'category': 'Unknown',
      },
    );
  }
}

/// Custom painter for frequency response visualization
class FrequencyResponsePainter extends CustomPainter {
  final ParametricEQ eq;
  final HolographicThemeData theme;
  
  FrequencyResponsePainter({
    required this.eq,
    required this.theme,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.primaryColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final glowPaint = Paint()
      ..color = theme.glowColor.withOpacity(0.3)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    
    // Generate frequency response curve
    final path = Path();
    final glowPath = Path();
    
    const numPoints = 200;
    final frequencies = List.generate(numPoints, (i) {
      final logMin = math.log(20.0);
      final logMax = math.log(20000.0);
      final t = i / (numPoints - 1);
      return math.exp(logMin + t * (logMax - logMin));
    });
    
    final response = eq.getFrequencyResponse(frequencies);
    
    for (int i = 0; i < numPoints; i++) {
      final x = (i / (numPoints - 1)) * size.width;
      final gainDb = response[i];
      final y = size.height * (1.0 - (gainDb + 15.0) / 30.0); // -15dB to +15dB range
      
      if (i == 0) {
        path.moveTo(x, y);
        glowPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        glowPath.lineTo(x, y);
      }
    }
    
    // Draw glow effect
    canvas.drawPath(glowPath, glowPaint);
    
    // Draw main curve
    canvas.drawPath(path, paint);
    
    // Draw grid lines
    final gridPaint = Paint()
      ..color = theme.onSurfaceColor.withOpacity(0.2)
      ..strokeWidth = 1.0;
    
    // Horizontal grid lines (gain)
    for (int db = -12; db <= 12; db += 6) {
      final y = size.height * (1.0 - (db + 15.0) / 30.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    
    // Vertical grid lines (frequency)
    final frequencies_grid = [100.0, 1000.0, 10000.0];
    for (final freq in frequencies_grid) {
      final logFreq = math.log(freq);
      final logMin = math.log(20.0);
      final logMax = math.log(20000.0);
      final x = ((logFreq - logMin) / (logMax - logMin)) * size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}