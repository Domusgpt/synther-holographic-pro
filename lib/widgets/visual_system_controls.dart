import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/parameter_visualizer_bridge.dart';
import '../ui/holographic/holographic_theme.dart';

/// System Type and Geometry Toggle Controls
///
/// These toggles directly affect oscillator and voice parameters:
/// - System Type: Controls oscillator waveform types
/// - Geometry: Controls filter characteristics and voice spread
class VisualSystemControls extends StatefulWidget {
  const VisualSystemControls({Key? key}) : super(key: key);

  @override
  State<VisualSystemControls> createState() => _VisualSystemControlsState();
}

class _VisualSystemControlsState extends State<VisualSystemControls> {
  SystemType _currentSystemType = SystemType.tesseract;
  GeometryMode _currentGeometry = GeometryMode.hypercube;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: HolographicTheme.primaryEnergy.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'VISUAL SYSTEM',
            style: HolographicTheme.createHolographicText(
              energyColor: HolographicTheme.primaryEnergy,
              fontSize: 12,
              glowIntensity: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          // System Type Toggles
          _buildSystemTypeToggles(),

          const SizedBox(height: 16),

          // Geometry Mode Toggles
          _buildGeometryToggles(),
        ],
      ),
    );
  }

  Widget _buildSystemTypeToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SYSTEM TYPE',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: SystemType.values.map((type) {
            final isActive = _currentSystemType == type;
            return _buildToggleButton(
              label: type.name.toUpperCase(),
              isActive: isActive,
              onTap: () => _setSystemType(type),
              color: HolographicTheme.primaryEnergy,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGeometryToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GEOMETRY MODE',
          style: TextStyle(
            color: HolographicTheme.secondaryEnergy.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: GeometryMode.values.map((mode) {
            final isActive = _currentGeometry == mode;
            return _buildToggleButton(
              label: mode.name.toUpperCase(),
              isActive: isActive,
              onTap: () => _setGeometry(mode),
              color: HolographicTheme.secondaryEnergy,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? color.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color : color.withOpacity(0.3),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? color : color.withOpacity(0.6),
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            shadows: isActive
                ? [
                    Shadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
        ),
      ),
    );
  }

  void _setSystemType(SystemType type) {
    setState(() {
      _currentSystemType = type;
    });

    // Map system type to oscillator parameters
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    final bridge = ParameterVisualizerBridge();

    switch (type) {
      case SystemType.tesseract:
        // Tesseract: Pure geometric waveforms (sine/triangle)
        if (synthParams.oscillators.isNotEmpty) {
          synthParams.updateOscillator(
            0,
            synthParams.oscillators[0].copyWith(type: OscillatorType.sine),
          );
        }
        bridge.updateParameter('dimension', 4.0);
        bridge.updateParameter('morphFactor', 0.5);
        break;

      case SystemType.polytope:
        // Polytope: Complex harmonics (sawtooth)
        if (synthParams.oscillators.isNotEmpty) {
          synthParams.updateOscillator(
            0,
            synthParams.oscillators[0].copyWith(type: OscillatorType.sawtooth),
          );
        }
        bridge.updateParameter('dimension', 4.5);
        bridge.updateParameter('morphFactor', 1.2);
        break;

      case SystemType.hypersphere:
        // Hypersphere: Smooth modulation (triangle/wavetable)
        if (synthParams.oscillators.isNotEmpty) {
          synthParams.updateOscillator(
            0,
            synthParams.oscillators[0].copyWith(type: OscillatorType.triangle),
          );
        }
        bridge.updateParameter('dimension', 3.5);
        bridge.updateParameter('morphFactor', 0.8);
        break;

      case SystemType.fractal:
        // Fractal: Chaotic noise patterns
        if (synthParams.oscillators.isNotEmpty) {
          synthParams.updateOscillator(
            0,
            synthParams.oscillators[0].copyWith(type: OscillatorType.noise),
          );
        }
        bridge.updateParameter('dimension', 5.0);
        bridge.updateParameter('morphFactor', 1.8);
        break;
    }
  }

  void _setGeometry(GeometryMode mode) {
    setState(() {
      _currentGeometry = mode;
    });

    // Map geometry mode to filter and voice parameters
    final synthParams = Provider.of<SynthParametersModel>(context, listen: false);
    final bridge = ParameterVisualizerBridge();

    switch (mode) {
      case GeometryMode.hypercube:
        // Hypercube: Sharp, defined filtering
        synthParams.setFilterType(FilterType.lowPass);
        synthParams.setFilterResonance(0.7);
        bridge.updateParameter('gridDensity', 8.0);
        bridge.updateParameter('patternIntensity', 1.3);
        break;

      case GeometryMode.simplex:
        // Simplex: Smooth, rounded filtering
        synthParams.setFilterType(FilterType.bandPass);
        synthParams.setFilterResonance(0.4);
        bridge.updateParameter('gridDensity', 5.0);
        bridge.updateParameter('patternIntensity', 0.9);
        break;

      case GeometryMode.torus:
        // Torus: Circular, resonant filtering
        synthParams.setFilterType(FilterType.highPass);
        synthParams.setFilterResonance(0.9);
        bridge.updateParameter('gridDensity', 12.0);
        bridge.updateParameter('patternIntensity', 1.8);
        break;

      case GeometryMode.klein:
        // Klein Bottle: Non-orientable, phase-shifting
        synthParams.setFilterType(FilterType.notch);
        synthParams.setFilterResonance(0.6);
        bridge.updateParameter('gridDensity', 15.0);
        bridge.updateParameter('patternIntensity', 2.2);
        break;
    }
  }
}

/// System Type Enum - Maps to oscillator waveform characteristics
enum SystemType {
  tesseract,   // Pure geometric waveforms
  polytope,    // Complex harmonic structures
  hypersphere, // Smooth modulation
  fractal,     // Chaotic/noise patterns
}

/// Geometry Mode Enum - Maps to filter characteristics and voice spread
enum GeometryMode {
  hypercube, // Sharp, defined edges
  simplex,   // Smooth, rounded
  torus,     // Circular, resonant
  klein,     // Non-orientable, phase-shifting
}
