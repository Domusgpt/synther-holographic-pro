import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../core/audio_reactive_controller.dart';
import 'holographic/holographic_theme.dart';

/// Audio-Reactive Visual Effects for UI Elements
///
/// Creates subtle, elegant visual feedback that weaves audio information
/// into the control elements without explicit readouts.
class AudioReactiveUIEffects extends StatelessWidget {
  final AudioReactiveController audioController;
  final Widget child;
  final String effectType; // 'panel', 'knob', 'section'
  final List<int>? responsiveBands; // Which frequency bands affect this element

  const AudioReactiveUIEffects({
    Key? key,
    required this.audioController,
    required this.child,
    this.effectType = 'panel',
    this.responsiveBands,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioController,
      builder: (context, _) {
        return CustomPaint(
          painter: AudioReactivePainter(
            audioController: audioController,
            effectType: effectType,
            responsiveBands: responsiveBands,
          ),
          child: child,
        );
      },
    );
  }
}

/// Custom painter for audio-reactive visual effects
class AudioReactivePainter extends CustomPainter {
  final AudioReactiveController audioController;
  final String effectType;
  final List<int>? responsiveBands;

  AudioReactivePainter({
    required this.audioController,
    required this.effectType,
    this.responsiveBands,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (effectType) {
      case 'panel':
        _paintPanelEffects(canvas, size);
        break;
      case 'energy_halo':
        _paintEnergyHalo(canvas, size);
        break;
      case 'frequency_glow':
        _paintFrequencyGlow(canvas, size);
        break;
      case 'shimmer':
        _paintShimmer(canvas, size);
        break;
    }
  }

  void _paintPanelEffects(Canvas canvas, Size size) {
    final energy = audioController.totalEnergy;
    final centroid = audioController.spectralCentroid;
    final flux = audioController.spectralFlux;

    // Subtle border glow based on energy
    if (energy > 0.1) {
      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          size.width / 2,
          [
            HolographicTheme.primaryEnergy.withOpacity(energy * 0.3),
            HolographicTheme.primaryEnergy.withOpacity(0.0),
          ],
          [0.8, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        glowPaint,
      );
    }

    // Color temperature based on spectral centroid
    final warmColor = Color.lerp(
      HolographicTheme.secondaryEnergy,
      HolographicTheme.primaryEnergy,
      centroid,
    )!;

    if (centroid > 0.2) {
      final tempPaint = Paint()
        ..color = warmColor.withOpacity((centroid - 0.2) * 0.15)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        tempPaint,
      );
    }

    // Flux creates edge shimmer
    if (flux > 0.3) {
      _paintEdgeShimmer(canvas, size, flux);
    }
  }

  void _paintEdgeShimmer(Canvas canvas, Size size, double flux) {
    final shimmerPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, size.height),
        [
          HolographicTheme.accentEnergy.withOpacity(flux * 0.5),
          Colors.transparent,
          HolographicTheme.accentEnergy.withOpacity(flux * 0.5),
        ],
        [0.0, 0.5, 1.0],
      );

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(8),
        ),
      );

    canvas.drawPath(path, shimmerPaint);
  }

  void _paintEnergyHalo(Canvas canvas, Size size) {
    final energy = audioController.totalEnergy;

    if (energy > 0.05) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = (size.width / 2) * (1.0 + energy * 0.3);

      final haloPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          [
            HolographicTheme.primaryEnergy.withOpacity(energy * 0.4),
            HolographicTheme.secondaryEnergy.withOpacity(energy * 0.2),
            Colors.transparent,
          ],
          [0.0, 0.6, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, haloPaint);
    }
  }

  void _paintFrequencyGlow(Canvas canvas, Size size) {
    if (responsiveBands == null || responsiveBands!.isEmpty) return;

    final bands = audioController.bandLevels;
    double totalBandEnergy = 0.0;
    Color glowColor = HolographicTheme.primaryEnergy;

    for (int bandIndex in responsiveBands!) {
      if (bandIndex >= 0 && bandIndex < bands.length) {
        totalBandEnergy += bands[bandIndex];
      }
    }

    totalBandEnergy /= responsiveBands!.length;

    // Color based on frequency range
    if (responsiveBands!.contains(0) || responsiveBands!.contains(1)) {
      // Bass bands - red/magenta
      glowColor = HolographicTheme.secondaryEnergy;
    } else if (responsiveBands!.contains(2) || responsiveBands!.contains(3)) {
      // Mid bands - cyan/blue
      glowColor = HolographicTheme.primaryEnergy;
    } else {
      // High bands - green/white
      glowColor = HolographicTheme.accentEnergy;
    }

    if (totalBandEnergy > 0.1) {
      final center = Offset(size.width / 2, size.height / 2);

      final glowPaint = Paint()
        ..shader = ui.Gradient.radial(
          center,
          size.width / 2,
          [
            glowColor.withOpacity(totalBandEnergy * 0.4),
            glowColor.withOpacity(totalBandEnergy * 0.2),
            Colors.transparent,
          ],
          [0.0, 0.7, 1.0],
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, size.width / 2, glowPaint);
    }
  }

  void _paintShimmer(Canvas canvas, Size size) {
    final flux = audioController.spectralFlux;
    final energy = audioController.totalEnergy;

    if (flux > 0.2 || energy > 0.3) {
      final shimmerPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size.width, 0),
          [
            Colors.white.withOpacity(0.0),
            Colors.white.withOpacity(flux * 0.3),
            Colors.white.withOpacity(0.0),
          ],
        )
        ..style = PaintingStyle.fill;

      final shimmerRect = Rect.fromLTWH(
        size.width * 0.3,
        0,
        size.width * 0.4,
        size.height,
      );

      canvas.drawRect(shimmerRect, shimmerPaint);
    }
  }

  @override
  bool shouldRepaint(AudioReactivePainter oldDelegate) => true;
}

/// Audio-Reactive Knob Wrapper
///
/// Wraps knobs with frequency-specific glows and pulses
class AudioReactiveKnob extends StatelessWidget {
  final Widget knob;
  final AudioReactiveController audioController;
  final List<int> responsiveBands;
  final double size;

  const AudioReactiveKnob({
    Key? key,
    required this.knob,
    required this.audioController,
    required this.responsiveBands,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: audioController,
      builder: (context, _) {
        final bands = audioController.bandLevels;
        double bandEnergy = 0.0;

        for (int i in responsiveBands) {
          if (i >= 0 && i < bands.length) {
            bandEnergy += bands[i];
          }
        }
        bandEnergy /= responsiveBands.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow pulse
            if (bandEnergy > 0.15)
              Container(
                width: size * (1.0 + bandEnergy * 0.4),
                height: size * (1.0 + bandEnergy * 0.4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getFrequencyColor().withOpacity(bandEnergy * 0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

            // Inner glow
            if (bandEnergy > 0.2)
              Container(
                width: size * 1.1,
                height: size * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getFrequencyColor().withOpacity(bandEnergy * 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

            // The actual knob
            knob,
          ],
        );
      },
    );
  }

  Color _getFrequencyColor() {
    final avgBand = responsiveBands.isEmpty ? 3 : responsiveBands.reduce((a, b) => a + b) ~/ responsiveBands.length;

    if (avgBand <= 1) {
      return HolographicTheme.secondaryEnergy; // Bass - magenta
    } else if (avgBand <= 3) {
      return HolographicTheme.primaryEnergy; // Mids - cyan
    } else {
      return HolographicTheme.accentEnergy; // Highs - green
    }
  }
}

/// Particle effect overlay for high energy moments
class EnergyParticles extends StatefulWidget {
  final AudioReactiveController audioController;

  const EnergyParticles({
    Key? key,
    required this.audioController,
  }) : super(key: key);

  @override
  State<EnergyParticles> createState() => _EnergyParticlesState();
}

class _EnergyParticlesState extends State<EnergyParticles> with SingleTickerProviderStateMixin {
  late AnimationController _particleController;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 16),
      vsync: this,
    )..addListener(_updateParticles);

    _particleController.repeat();
  }

  void _updateParticles() {
    final energy = widget.audioController.totalEnergy;
    final flux = widget.audioController.spectralFlux;

    // Spawn particles on high flux
    if (flux > 0.5 && _particles.length < 30) {
      _particles.add(Particle());
    }

    // Update existing particles
    for (var particle in _particles) {
      particle.update();
    }

    // Remove dead particles
    _particles.removeWhere((p) => p.isDead);

    setState(() {});
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ParticlePainter(_particles),
      child: const SizedBox.expand(),
    );
  }
}

class Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double vx = (math.Random().nextDouble() - 0.5) * 0.01;
  double vy = (math.Random().nextDouble() - 0.5) * 0.01;
  double life = 1.0;
  double size = math.Random().nextDouble() * 3 + 1;

  void update() {
    x += vx;
    y += vy;
    life -= 0.02;
  }

  bool get isDead => life <= 0;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = HolographicTheme.primaryEnergy.withOpacity(particle.life * 0.5);

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
