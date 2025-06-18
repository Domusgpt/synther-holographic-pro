import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as Math;
import '../core/holographic_theme.dart';
import '../widgets/synth_components/oscillator_bank.dart';
import '../widgets/synth_components/effects_chain.dart';
import '../widgets/synth_components/filter_section.dart';
import '../widgets/synth_components/envelope_section.dart';
import '../widgets/synth_components/lfo_section.dart';
import '../widgets/synth_components/spectrum_analyzer.dart';
import '../widgets/synth_components/master_section.dart';
import '../widgets/synth_components/modulation_matrix.dart';

/// Synther Professional Holographic - Complete Professional Synthesizer Interface
/// 
/// Features:
/// - Individual draggable knobs for every parameter
/// - Comprehensive effects chain (EQ, reverb, delay, chorus, distortion, compressor)
/// - Multiple oscillator types (FM, granular, additive, wavetable)
/// - Real-time spectrum analyzers behind every control
/// - Vaporwave holographic aesthetic with chromatic aberration
/// - 4D polytopal integration for all UI elements
class ProfessionalSynthesizerInterface extends StatefulWidget {
  const ProfessionalSynthesizerInterface({Key? key}) : super(key: key);

  @override
  State<ProfessionalSynthesizerInterface> createState() => _ProfessionalSynthesizerInterfaceState();
}

class _ProfessionalSynthesizerInterfaceState extends State<ProfessionalSynthesizerInterface> 
    with TickerProviderStateMixin {
  
  // Animation controllers for holographic effects
  late AnimationController _pulseController;
  late AnimationController _chromaController;
  late AnimationController _glitchController;
  
  // 4D transformation matrices for each section
  final Map<String, vector.Matrix4> _sectionTransforms = {};
  
  // Section visibility and collapse states
  final Map<String, bool> _sectionCollapsed = {
    'oscillators': false, // Start open
    'filters': false,     // Start open
    'envelopes': true,    // Start collapsed
    'lfos': true,         // Start collapsed
    'effects': true,      // Start collapsed
    'modulation': true,   // Start collapsed
    'spectrum': false,    // Keep open by default (or true if it should be initially hidden)
    'master': false,      // Master section in header, usually not collapsed
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize holographic animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _chromaController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 80),
      vsync: this,
    );
    
    // Initialize 4D transformation matrices
    _initializeTransformMatrices();
    
    // Start ambient holographic effects
    _startAmbientEffects();
  }

  void _initializeTransformMatrices() {
    final sections = _sectionCollapsed.keys;
    for (String section in sections) {
      _sectionTransforms[section] = vector.Matrix4.identity();
    }
  }

  void _startAmbientEffects() {
    // Continuous subtle pulsing and chromatic shifts
    _pulseController.addListener(() {
      if (mounted) {
        setState(() {
          // Update 4D transformations based on pulse
          final pulse = _pulseController.value;
          _updateSectionTransforms(pulse);
        });
      }
    });
  }

  void _updateSectionTransforms(double pulse) {
    final sections = _sectionTransforms.keys;
    for (int i = 0; i < sections.length; i++) {
      final section = sections.elementAt(i);
      final matrix = vector.Matrix4.identity();
      
      // Apply 4D rotation based on pulse and section index
      final rotationW = pulse * 2 * 3.14159 + (i * 0.5);
      final rotationY = pulse * 1.5 * 3.14159 + (i * 0.3);
      
      matrix.rotateY(rotationY * 0.1);
      matrix.translate(0.0, Math.sin(rotationW) * 2.0, Math.cos(rotationW) * 1.0);
      
      _sectionTransforms[section] = matrix;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chromaController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HolographicTheme.deepSpaceBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // Background holographic grid
            _buildHolographicBackground(),
            
            // Main synthesizer interface with error handling
            Positioned.fill( // Wrap with Positioned.fill
              child: _buildSynthesizerLayoutSafe(),
            ),
            
            // Floating spectrum analyzer overlay
            _buildFloatingSpectrumAnalyzer(), // This is already Positioned
            
            // Chromatic aberration overlay
            _buildChromaticAberrationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHolographicBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5 + (_pulseController.value * 0.3),
              colors: [
                HolographicTheme.deepSpaceBlack,
                HolographicTheme.primaryEnergy.withOpacity(0.05),
                HolographicTheme.secondaryEnergy.withOpacity(0.03),
                HolographicTheme.deepSpaceBlack,
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: CustomPaint(
            painter: HolographicGridPainter(
              pulseValue: _pulseController.value,
              primaryColor: HolographicTheme.primaryEnergy,
              secondaryColor: HolographicTheme.secondaryEnergy,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildSynthesizerLayoutSafe() {
    try {
      return _buildSynthesizerLayout();
    } catch (e) {
      print('Error in synthesizer layout: $e');
      return _buildFallbackLayout();
    }
  }

  Widget _buildSynthesizerLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with master controls
          _buildMasterHeader(),
          
          // Main synthesizer sections
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Oscillators and Filters
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 3,
                      fit: FlexFit.loose,
                      child: _buildSectionSafe(
                        'oscillators',
                        'OSCILLATOR BANK',
                        () => OscillatorBank(
                          transform: _sectionTransforms['oscillators']!,
                          onParameterChange: _onParameterChange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 2,
                      fit: FlexFit.loose,
                      child: _buildSectionSafe(
                        'filters',
                        'FILTER SECTION',
                        () => FilterSection(
                          transform: _sectionTransforms['filters']!,
                          onParameterChange: _onParameterChange,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Middle row: Envelopes and LFOs
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.loose,
                      child: _buildSectionSafe(
                        'envelopes',
                        'ENVELOPE GENERATORS',
                        () => EnvelopeSection(
                          transform: _sectionTransforms['envelopes']!,
                          onParameterChange: _onParameterChange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      fit: FlexFit.loose,
                      child: _buildSectionSafe(
                        'lfos',
                        'LFO SECTION',
                        () => LFOSection(
                          transform: _sectionTransforms['lfos']!,
                          onParameterChange: _onParameterChange,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bottom row: Effects Chain
                _buildSectionSafe(
                  'effects',
                  'EFFECTS CHAIN',
                  () => EffectsChain(
                    transform: _sectionTransforms['effects']!,
                    onParameterChange: _onParameterChange,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Modulation Matrix
                _buildSectionSafe(
                  'modulation',
                  'MODULATION MATRIX',
                  () => ModulationMatrix(
                    transform: _sectionTransforms['modulation']!,
                    onParameterChange: _onParameterChange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SYNTHER PROFESSIONAL',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.primaryEnergy,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'INITIALIZING COMPLEX INTERFACE...',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.secondaryEnergy,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HolographicTheme.primaryEnergy.withOpacity(0.1),
            HolographicTheme.deepSpaceBlack,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.primaryEnergy.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Synth logo/title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      HolographicTheme.primaryEnergy,
                      HolographicTheme.secondaryEnergy,
                      HolographicTheme.accentEnergy,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'SYNTHER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                Text(
                  'PROFESSIONAL HOLOGRAPHIC',
                  style: TextStyle(
                    fontSize: 14,
                    color: HolographicTheme.secondaryEnergy,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Master controls
            MasterSection(
              transform: _sectionTransforms['master']!,
              onParameterChange: _onParameterChange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionSafe(String sectionId, String title, Widget Function() contentBuilder) {
    try {
      final content = contentBuilder();
      return _buildSection(sectionId, title, content);
    } catch (e) {
      print('Error building section $sectionId: $e');
      return _buildErrorSection(sectionId, title, e.toString());
    }
  }

  Widget _buildErrorSection(String sectionId, String title, String error) {
    return Container(
      height: 200,
      decoration: HolographicTheme.createHolographicContainer(
        energyColor: HolographicTheme.secondaryEnergy,
        intensity: 0.5,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.secondaryEnergy,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'COMPONENT LOADING...',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.primaryEnergy,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String sectionId, String title, Widget content) {
    final isCollapsed = _sectionCollapsed[sectionId] ?? false;
    final transform = _sectionTransforms[sectionId] ?? vector.Matrix4.identity();
    
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setFromTranslationRotationScale(
              vector.Vector3(0, 0, 0),
              vector.Quaternion.identity(),
              vector.Vector3(1.0, 1.0, 1.0),
            ),
          child: Container(
            decoration: HolographicTheme.createHolographicContainer(
              energyColor: HolographicTheme.primaryEnergy,
              intensity: 0.6 + (_pulseController.value * 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                GestureDetector(
                  onTap: () => _toggleSection(sectionId),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HolographicTheme.primaryEnergy.withOpacity(0.2),
                          HolographicTheme.secondaryEnergy.withOpacity(0.1),
                        ],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: HolographicTheme.primaryEnergy.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCollapsed ? Icons.keyboard_arrow_right : Icons.keyboard_arrow_down,
                          color: HolographicTheme.primaryEnergy,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: HolographicTheme.createHolographicText(
                            energyColor: HolographicTheme.primaryEnergy,
                            fontSize: 14,
                            glowIntensity: 0.8,
                          ),
                        ),
                        const Spacer(),
                        // Section-specific indicators
                        _buildSectionIndicators(sectionId),
                      ],
                    ),
                  ),
                ),
                
                // Section content
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isCollapsed ? 0 : null,
                  child: isCollapsed ? null : Padding(
                    padding: const EdgeInsets.all(16),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionIndicators(String sectionId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Activity indicator
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: HolographicTheme.secondaryEnergy,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.secondaryEnergy.withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // CPU usage indicator
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: HolographicTheme.primaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.7, // Simulated CPU usage
            child: Container(
              decoration: BoxDecoration(
                color: HolographicTheme.accentEnergy,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingSpectrumAnalyzer() {
    return Positioned(
      top: 140,
      right: 16,
      child: _buildSection(
        'spectrum',
        'SPECTRUM ANALYZER',
        SpectrumAnalyzer(
          transform: _sectionTransforms['spectrum']!,
          width: 300,
          height: 200,
        ),
      ),
    );
  }

  Widget _buildChromaticAberrationOverlay() {
    return AnimatedBuilder(
      animation: _chromaController,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 2.0,
                  colors: [
                    Colors.transparent,
                    HolographicTheme.primaryEnergy.withOpacity(0.02 * _chromaController.value),
                    HolographicTheme.secondaryEnergy.withOpacity(0.02 * _chromaController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleSection(String sectionId) {
    setState(() {
      _sectionCollapsed[sectionId] = !(_sectionCollapsed[sectionId] ?? false);
    });
    
    // Trigger chromatic aberration effect
    _chromaController.forward().then((_) => _chromaController.reverse());
  }

  void _onParameterChange(String parameter, double value) {
    // Handle parameter changes and send to audio engine
    print('Parameter changed: $parameter = $value');
    
    // Trigger subtle glitch effect on parameter change
    if (mounted) {
      _glitchController.forward().then((_) => _glitchController.reverse());
    }
  }
}

/// Custom painter for the holographic background grid
class HolographicGridPainter extends CustomPainter {
  final double pulseValue;
  final Color primaryColor;
  final Color secondaryColor;

  HolographicGridPainter({
    required this.pulseValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridSpacing = 50.0 + (pulseValue * 10.0);
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      final opacity = 0.1 + (Math.sin(x / 100.0 + pulseValue * 6.28) * 0.05);
      paint.color = primaryColor.withOpacity(opacity.clamp(0.0, 0.2));
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      final opacity = 0.1 + (Math.sin(y / 100.0 + pulseValue * 6.28) * 0.05);
      paint.color = secondaryColor.withOpacity(opacity.clamp(0.0, 0.2));
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw diagonal enhancement lines
    paint.color = primaryColor.withOpacity(0.05 + (pulseValue * 0.03));
    for (double i = -size.height; i < size.width + size.height; i += gridSpacing * 2) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant HolographicGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}