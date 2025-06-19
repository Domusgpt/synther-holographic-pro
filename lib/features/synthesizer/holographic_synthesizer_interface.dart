import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
// Platform-specific imports (web only)
// import 'dart:html' as html;
import 'dart:math' as math;
import '../../core/ui/holographic_theme.dart';
import '../../core/ui/glassmorphism_widgets.dart';
import '../../core/synthesis/synthesis_manager.dart';
import '../../core/synthesis/synthesis_engine.dart';
// import '../../core/visualization/polytope_visualization_engine.dart';
// import '../../widgets/synth_components/modulation_matrix.dart';
import '../../features/keyboard/mpe_keyboard_widget.dart';
import '../../core/microtonal_system.dart';

/// Professional Holographic Synthesizer Interface
/// 
/// Main UI that provides:
/// - 4D polytope visualization background
/// - Glassmorphism control panels overlaid on top
/// - Real-time synthesis engine controls
/// - MPE keyboard with holographic effects
/// - Modulation matrix with visual connections
/// - Professional preset management
/// - Audio-reactive UI that responds to synthesis

class HolographicSynthesizerInterface extends StatefulWidget {
  const HolographicSynthesizerInterface({super.key});
  
  @override
  State<HolographicSynthesizerInterface> createState() => 
    _HolographicSynthesizerInterfaceState();
}

class _HolographicSynthesizerInterfaceState 
    extends State<HolographicSynthesizerInterface>
    with TickerProviderStateMixin {
  
  // Core systems
  late SynthesisManager _synthesisManager;
  // late PolytopeVisualizationEngine _visualizationEngine;
  late AudioReactiveThemeController _themeController;
  
  // Animation controllers
  late AnimationController _interfaceController;
  late AnimationController _pulseController;
  late Animation<double> _interfaceAnimation;
  late Animation<double> _pulseAnimation;
  
  // UI state
  bool _isInitialized = false;
  bool _showAdvancedControls = false;
  bool _isKeyboardVisible = true;
  bool _isModulationMatrixVisible = false;
  int _selectedSynthEngine = 0;
  int _selectedVisualizationPreset = 0;
  
  // Layout state
  double _leftPanelWidth = 300.0;
  double _rightPanelWidth = 300.0;
  double _audioLevel = 0.0;
  double _keyboardHeight = 200.0;
  
  // Audio reactive state
  double _currentAmplitude = 0.0;
  double _currentFrequency = 440.0;
  double _currentSpectralCentroid = 0.5;
  double _currentHarmonicContent = 0.5;
  
  @override
  void initState() {
    super.initState();
    
    _interfaceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _interfaceAnimation = CurvedAnimation(
      parent: _interfaceController,
      curve: Curves.easeOutCubic,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
    
    _initializeSynthesizer();
  }
  
  @override
  void dispose() {
    _interfaceController.dispose();
    _pulseController.dispose();
    // _visualizationEngine.dispose();
    _synthesisManager.dispose();
    super.dispose();
  }
  
  Future<void> _initializeSynthesizer() async {
    try {
      // Initialize synthesis manager
      _synthesisManager = SynthesisManager();
      
      // Initialize theme controller
      final initialTheme = HolographicThemeData.fromColorScheme(
        HolographicColorScheme.deepSpace
      );
      _themeController = AudioReactiveThemeController(initialTheme);
      
      // Initialize visualization engine
      // _visualizationEngine = PolytopeVisualizationEngine();
      
      // Create visualization canvas (web only - disabled for platform compatibility)
      // if (kIsWeb) {
      //   final canvas = html.CanvasElement()
      //     ..width = 1920
      //     ..height = 1080
      //     ..style.width = '100%'
      //     ..style.height = '100%'
      //     ..style.position = 'absolute'
      //     ..style.top = '0'
      //     ..style.left = '0'
      //     ..style.zIndex = '-1';
      // }
      
      // Initialize visualization with synthesis manager
      // final visualizationInitialized = await _visualizationEngine.initialize(
      //   canvas,
      //   synthesisManager: _synthesisManager,
      // );
      
      // if (!visualizationInitialized) {
      //   print('Warning: Polytope visualization failed to initialize');
      // }
      
      // Start audio-reactive updates
      _startAudioReactiveUpdates();
      
      setState(() {
        _isInitialized = true;
      });
      
      _interfaceController.forward();
      
    } catch (e) {
      print('Failed to initialize synthesizer: $e');
      setState(() {
        _isInitialized = true; // Show UI even if visualization fails
      });
    }
  }
  
  void _startAudioReactiveUpdates() {
    // Update audio parameters from synthesis manager every frame
    Stream.periodic(const Duration(milliseconds: 16)).listen((_) {
      if (!mounted) return;
      
      final visualizationData = _synthesisManager.getVisualizationData();
      final metrics = visualizationData['metrics'] as Map<String, dynamic>?;
      
      if (metrics != null) {
        final amplitude = (metrics['totalCpuUsage'] as double? ?? 0.0) * 0.1;
        final voiceCount = metrics['totalVoiceCount'] as int? ?? 0;
        
        // Calculate synthetic audio parameters from synthesis activity
        _currentAmplitude = amplitude.clamp(0.0, 1.0);
        _currentFrequency = 440.0 * (1.0 + voiceCount * 0.1);
        _currentSpectralCentroid = math.min(1.0, voiceCount / 10.0);
        _currentHarmonicContent = amplitude;
        
        // Update theme controller
        _themeController.updateFromAudio(
          amplitude: _currentAmplitude,
          frequency: _currentFrequency,
          spectralCentroid: _currentSpectralCentroid,
          harmonicContent: _currentHarmonicContent,
        );
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: HolographicLoader(
            size: 60.0,
            showText: true,
            text: 'Initializing Holographic Synthesizer...',
          ),
        ),
      );
    }
    
    return ChangeNotifierProvider.value(
      value: _themeController,
      child: Consumer<AudioReactiveThemeController>(
        builder: (context, themeController, child) {
          return HolographicTheme(
            data: themeController.currentTheme,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: AnimatedBuilder(
                animation: _interfaceAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _interfaceAnimation.value,
                    child: Opacity(
                      opacity: _interfaceAnimation.value,
                      child: _buildMainInterface(),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainInterface() {
    return Stack(
      children: [
        // 4D Polytope Visualization Background
        _buildVisualizationBackground(),
        
        // Main interface layout
        Column(
          children: [
            // Top control bar
            _buildTopControlBar(),
            
            // Main synthesis area
            Expanded(
              child: Row(
                children: [
                  // Left control panel
                  _buildLeftControlPanel(),
                  
                  // Center visualization area
                  Expanded(
                    child: _buildCenterVisualizationArea(),
                  ),
                  
                  // Right control panel
                  _buildRightControlPanel(),
                ],
              ),
            ),
            
            // Bottom keyboard area
            if (_isKeyboardVisible)
              _buildKeyboardArea(),
          ],
        ),
        
        // Modulation matrix overlay
        if (_isModulationMatrixVisible)
          _buildModulationMatrixOverlay(),
      ],
    );
  }
  
  Widget _buildVisualizationBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.95),
              Colors.black,
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.purple.withOpacity(0.05),
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Text(
              '4D POLYTOPE VISUALIZATION\nCOMING ONLINE...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.cyan.withOpacity(0.7),
                fontSize: 16,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopControlBar() {
    final theme = HolographicTheme.of(context);
    
    return GlassmorphismContainer(
      height: 60.0,
      padding: EdgeInsets.symmetric(horizontal: theme.baseUnit * 2),
      margin: EdgeInsets.all(theme.baseUnit),
      child: Row(
        children: [
          // Logo/Title - Made flexible to prevent overflow
          Expanded(
            flex: 3,
            child: ChromaticText(
              intensity: 0.6,
              child: Text(
                'SYNTHER HOLOGRAPHIC PRO',
                style: theme.headlineStyle.copyWith(
                  fontSize: MediaQuery.of(context).size.width < 800 ? 16 : 20,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          
          SizedBox(width: theme.baseUnit),
          
          // Right controls - Made flexible
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Performance indicator
                _buildPerformanceIndicator(),
                
                SizedBox(width: theme.baseUnit),
                
                // Theme selector
                _buildThemeSelector(),
                
                SizedBox(width: theme.baseUnit),
                
                // Settings button
                HolographicButton(
                  onPressed: () => _showSettingsDialog(),
                  padding: EdgeInsets.all(theme.baseUnit),
                  child: Icon(
                    Icons.settings,
                    color: theme.onSurfaceColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLeftControlPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _leftPanelWidth,
      child: Column(
        children: [
          // Synthesis engine selector
          _buildSynthEngineSelector(),
          
          SizedBox(height: HolographicTheme.of(context).baseUnit),
          
          // Engine-specific controls
          Expanded(
            child: _buildEngineControls(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRightControlPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _rightPanelWidth,
      child: Column(
        children: [
          // Visualization controls
          _buildVisualizationControls(),
          
          SizedBox(height: HolographicTheme.of(context).baseUnit),
          
          // Effects and modulation
          Expanded(
            child: _buildEffectsControls(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCenterVisualizationArea() {
    final theme = HolographicTheme.of(context);
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: EdgeInsets.all(theme.baseUnit),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.borderRadius * 2),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.glowColor.withOpacity(0.2),
                  blurRadius: 20.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius * 2),
              child: Stack(
                children: [
                  // Visualization info overlay
                  Positioned(
                    top: theme.baseUnit,
                    left: theme.baseUnit,
                    child: GlassmorphismContainer(
                      padding: EdgeInsets.all(theme.baseUnit),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChromaticText(
                            intensity: 0.4,
                            child: Text(
                              'POLYTOPE VISUALIZATION',
                              style: theme.captionStyle,
                            ),
                          ),
                          SizedBox(height: theme.baseUnit / 2),
                          Text(
                            'Amplitude: ${(_currentAmplitude * 100).toStringAsFixed(1)}%',
                            style: theme.captionStyle,
                          ),
                          Text(
                            'Frequency: ${_currentFrequency.toStringAsFixed(1)} Hz',
                            style: theme.captionStyle,
                          ),
                          Text(
                            'Voices: ${(_currentHarmonicContent * 10).round()}',
                            style: theme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildKeyboardArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _keyboardHeight,
      child: GlassPanel(
        title: 'MPE KEYBOARD',
        padding: EdgeInsets.all(HolographicTheme.of(context).baseUnit),
        child: MPEKeyboardWidget(
          layout: KeyboardLayout.piano,
          scale: MicrotonalScaleLibrary.standard12TET,
          mpeEnabled: true,
          octaves: 2,
          startOctave: 3,
          onSizeChanged: (size) {
            // Handle keyboard resize
          },
        ),
      ),
    );
  }
  
  Widget _buildSynthEngineSelector() {
    final theme = HolographicTheme.of(context);
    final engines = ['Wavetable', 'FM', 'Granular', 'Additive'];
    
    return GlassPanel(
      title: 'SYNTHESIS ENGINE',
      child: Column(
        children: engines.asMap().entries.map((entry) {
          final index = entry.key;
          final name = entry.value;
          final isSelected = index == _selectedSynthEngine;
          
          return Padding(
            padding: EdgeInsets.only(bottom: theme.baseUnit / 2),
            child: HolographicButton(
              onPressed: () => _selectSynthEngine(index),
              enableGlow: isSelected,
              enablePulse: isSelected,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: theme.baseUnit),
                child: Center(
                  child: ChromaticText(
                    intensity: isSelected ? 0.8 : 0.2,
                    child: Text(
                      name,
                      style: theme.buttonStyle,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildEngineControls() {
    final theme = HolographicTheme.of(context);
    
    switch (_selectedSynthEngine) {
      case 0: // Wavetable
        return _buildWavetableControls();
      case 1: // FM
        return _buildFMControls();
      case 2: // Granular
        return _buildGranularControls();
      case 3: // Additive
        return _buildAdditiveControls();
      default:
        return Container();
    }
  }
  
  Widget _buildWavetableControls() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'WAVETABLE CONTROLS',
      child: Column(
        children: [
          HolographicSlider(
            label: 'Wavetable Position',
            value: 0.5,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.wavetable,
                SynthParameter.wavetablePosition,
                value,
              );
            },
            enableAudioReactivity: true,
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Morph Amount',
            value: 0.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.wavetable,
                SynthParameter.wavetableMorph,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicButton(
            onPressed: () {
              // Cycle through wavetables
            },
            child: Text(
              'NEXT WAVETABLE',
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFMControls() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'FM SYNTHESIS',
      child: Column(
        children: [
          HolographicSlider(
            label: 'FM Ratio',
            value: 1.0,
            min: 0.1,
            max: 10.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.fm,
                SynthParameter.fmRatio,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'FM Amount',
            value: 0.5,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.fm,
                SynthParameter.fmAmount,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Feedback',
            value: 0.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.fm,
                SynthParameter.fmFeedback,
                value,
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildGranularControls() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'GRANULAR SYNTHESIS',
      child: Column(
        children: [
          HolographicSlider(
            label: 'Grain Size',
            value: 0.1,
            min: 0.001,
            max: 2.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.granular,
                SynthParameter.grainSize,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Grain Density',
            value: 10.0,
            min: 0.1,
            max: 1000.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.granular,
                SynthParameter.grainDensity,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Grain Position',
            value: 0.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.granular,
                SynthParameter.grainPosition,
                value,
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdditiveControls() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'ADDITIVE SYNTHESIS',
      child: Column(
        children: [
          HolographicSlider(
            label: 'Harmonic Content',
            value: 0.7,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.additive,
                SynthParameter.harmonicContent,
                value,
              );
            },
            enableAudioReactivity: true,
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Spectral Tilt',
            value: 0.0,
            min: -1.0,
            max: 1.0,
            onChanged: (value) {
              _synthesisManager.setEngineParameter(
                SynthesisType.additive,
                SynthParameter.spectralTilt,
                value,
              );
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicButton(
            onPressed: () {
              // Show harmonic editor
            },
            child: Text(
              'HARMONIC EDITOR',
              style: theme.buttonStyle,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVisualizationControls() {
    final theme = HolographicTheme.of(context);
    final presets = ['Classic Tesseract', 'Frequency Crystal', 'Harmonic Sphere', 'Multi-Dimensional', 'Minimal'];
    
    return GlassPanel(
      title: 'VISUALIZATION',
      child: Column(
        children: presets.asMap().entries.map((entry) {
          final index = entry.key;
          final name = entry.value;
          final isSelected = index == _selectedVisualizationPreset;
          
          return Padding(
            padding: EdgeInsets.only(bottom: theme.baseUnit / 2),
            child: HolographicButton(
              onPressed: () => _selectVisualizationPreset(index),
              enableGlow: isSelected,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: theme.baseUnit / 2),
                child: Center(
                  child: Text(
                    name,
                    style: theme.captionStyle.copyWith(
                      fontSize: 12,
                      color: isSelected ? theme.primaryColor : theme.onSurfaceColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildEffectsControls() {
    final theme = HolographicTheme.of(context);
    
    return GlassPanel(
      title: 'EFFECTS & MODULATION',
      child: Column(
        children: [
          HolographicButton(
            onPressed: () => _toggleModulationMatrix(),
            enableGlow: _isModulationMatrixVisible,
            child: Text(
              'MODULATION MATRIX',
              style: theme.buttonStyle,
            ),
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Reverb',
            value: 0.3,
            onChanged: (value) {
              // Set reverb amount
            },
          ),
          
          SizedBox(height: theme.baseUnit),
          
          HolographicSlider(
            label: 'Delay',
            value: 0.2,
            onChanged: (value) {
              // Set delay amount
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceIndicator() {
    final theme = HolographicTheme.of(context);
    
    return GlassmorphismContainer(
      padding: EdgeInsets.symmetric(
        horizontal: theme.baseUnit,
        vertical: theme.baseUnit / 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.memory,
            color: theme.primaryColor,
            size: 16,
          ),
          SizedBox(width: theme.baseUnit / 2),
          Text(
            'CPU: ${(_currentAmplitude * 100).toStringAsFixed(0)}%',
            style: theme.captionStyle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeSelector() {
    final theme = HolographicTheme.of(context);
    
    return HolographicButton(
      onPressed: _showThemeSelector,
      padding: EdgeInsets.all(theme.baseUnit),
      child: Icon(
        Icons.palette,
        color: theme.onSurfaceColor,
        size: 20,
      ),
    );
  }
  
  Widget _buildModulationMatrixOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
              maxHeight: 700,
            ),
            child: GlassmorphismContainer(
              padding: EdgeInsets.all(40),
              child: Text(
                'MODULATION MATRIX\nCOMING ONLINE...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 24,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _selectSynthEngine(int index) {
    setState(() {
      _selectedSynthEngine = index;
    });
    
    // Switch synthesis manager to selected engine
    final engineType = [
      SynthesisType.wavetable,
      SynthesisType.fm,
      SynthesisType.granular,
      SynthesisType.additive,
    ][index];
    
    _synthesisManager.setPrimaryEngine(engineType);
  }
  
  void _selectVisualizationPreset(int index) {
    setState(() {
      _selectedVisualizationPreset = index;
    });
    
    // _visualizationEngine.setPreset(index);
  }
  
  void _toggleModulationMatrix() {
    setState(() {
      _isModulationMatrixVisible = !_isModulationMatrixVisible;
    });
  }
  
  void _showThemeSelector() {
    // Show theme selection dialog
    showDialog(
      context: context,
      builder: (context) => _buildThemeSelectionDialog(),
    );
  }
  
  void _showSettingsDialog() {
    // Show settings dialog
  }
  
  Widget _buildThemeSelectionDialog() {
    final themes = [
      'Deep Space',
      'Crystalline',
      'Neon Cyber',
      'Warm Analog',
      'Spectral',
      'Minimal',
    ];
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DepthCard(
        child: GlassPanel(
          title: 'SELECT THEME',
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: themes.asMap().entries.map((entry) {
              final index = entry.key;
              final name = entry.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: HolographicButton(
                  onPressed: () {
                    final colorScheme = HolographicColorScheme.values[index];
                    final newTheme = HolographicThemeData.fromColorScheme(colorScheme);
                    _themeController.setBaseTheme(newTheme);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        name,
                        style: HolographicTheme.of(context).buttonStyle,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}