import 'package:flutter/material.dart';
import '../core/holographic_theme.dart';

/// Working Synthesizer Interface - Simplified but functional
/// This version prioritizes working UI over complex features
class WorkingSynthesizerInterface extends StatefulWidget {
  const WorkingSynthesizerInterface({Key? key}) : super(key: key);

  @override
  State<WorkingSynthesizerInterface> createState() => _WorkingSynthesizerInterfaceState();
}

class _WorkingSynthesizerInterfaceState extends State<WorkingSynthesizerInterface> 
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HolographicTheme.deepSpaceBlack,
      body: Stack(
        children: [
          // Background
          _buildBackground(),
          
          // Main UI
          _buildMainInterface(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
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
        );
      },
    );
  }

  Widget _buildMainInterface() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Main controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Oscillator section
                  _buildSection('OSCILLATORS', _buildOscillatorControls()),
                  
                  const SizedBox(height: 16),
                  
                  // Filter section
                  _buildSection('FILTER', _buildFilterControls()),
                  
                  const SizedBox(height: 16),
                  
                  // Effects section
                  _buildSection('EFFECTS', _buildEffectsControls()),
                  
                  const Spacer(),
                  
                  // Master controls
                  _buildMasterControls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
      child: Center(
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              HolographicTheme.primaryEnergy,
              HolographicTheme.secondaryEnergy,
            ],
          ).createShader(bounds),
          child: const Text(
            'SYNTHER PROFESSIONAL',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      decoration: HolographicTheme.glassDecoration(
        borderColor: HolographicTheme.primaryEnergy,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  HolographicTheme.primaryEnergy.withOpacity(0.2),
                  HolographicTheme.secondaryEnergy.withOpacity(0.1),
                ],
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(
                  color: HolographicTheme.primaryEnergy,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildOscillatorControls() {
    return Row(
      children: [
        _buildKnob('FREQ', 440.0, 20.0, 2000.0),
        const SizedBox(width: 16),
        _buildKnob('WAVE', 0.5, 0.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('DETUNE', 0.0, -50.0, 50.0),
        const SizedBox(width: 16),
        _buildKnob('LEVEL', 0.8, 0.0, 1.0),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Row(
      children: [
        _buildKnob('CUTOFF', 1000.0, 20.0, 20000.0),
        const SizedBox(width: 16),
        _buildKnob('RESO', 0.3, 0.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('ENV', 0.5, -1.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('LFO', 0.0, 0.0, 1.0),
      ],
    );
  }

  Widget _buildEffectsControls() {
    return Row(
      children: [
        _buildKnob('REVERB', 0.2, 0.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('DELAY', 0.1, 0.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('CHORUS', 0.0, 0.0, 1.0),
        const SizedBox(width: 16),
        _buildKnob('DRIVE', 0.1, 0.0, 1.0),
      ],
    );
  }

  Widget _buildMasterControls() {
    return Container(
      height: 100,
      decoration: HolographicTheme.glassDecoration(
        borderColor: HolographicTheme.secondaryEnergy,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'MASTER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 32),
            _buildKnob('VOLUME', 0.7, 0.0, 1.0),
            const Spacer(),
            _buildPlayButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildKnob(String label, double value, double min, double max) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                HolographicTheme.primaryEnergy.withOpacity(0.1),
                HolographicTheme.primaryEnergy.withOpacity(0.3),
              ],
            ),
            border: Border.all(
              color: HolographicTheme.primaryEnergy,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.primaryEnergy.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: HolographicTheme.primaryEnergy,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: HolographicTheme.primaryEnergy,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: HolographicTheme.primaryEnergy,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            HolographicTheme.secondaryEnergy.withOpacity(0.2),
            HolographicTheme.secondaryEnergy.withOpacity(0.4),
          ],
        ),
        border: Border.all(
          color: HolographicTheme.secondaryEnergy,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Icon(
        Icons.play_arrow,
        color: HolographicTheme.secondaryEnergy,
        size: 40,
      ),
    );
  }
}