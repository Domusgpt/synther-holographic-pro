// Holographic Theme for Vaporwave Aesthetic
import 'package:flutter/material.dart';

class HolographicTheme {
  // Primary Energy Colors - Electric Cyan/Magenta/Green
  static const Color primaryEnergy = Color(0xFF00FFFF);    // Electric cyan
  static const Color secondaryEnergy = Color(0xFFFF0066);  // Hot magenta  
  static const Color tertiaryEnergy = Color(0xFF66FF00);   // Neon green
  
  // Background and Surface Colors
  static const Color voidBlack = Color(0xFF000011);        // Deep void black
  static const Color glassWhite = Color(0x1AFFFFFF);       // Translucent white
  
  // Accent Colors for Variations
  static const Color electricBlue = Color(0xFF0099FF);
  static const Color neonPurple = Color(0xFF9900FF);
  static const Color holographicPink = Color(0xFFFF3399);
  
  // Gradient Definitions
  static const LinearGradient energyGradient = LinearGradient(
    colors: [primaryEnergy, secondaryEnergy, tertiaryEnergy],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient vaporwaveGradient = LinearGradient(
    colors: [
      Color(0xFF9900FF), // Purple
      Color(0xFFFF0066), // Magenta
      Color(0xFF00FFFF), // Cyan
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Glass Material Decoration
  static BoxDecoration glassDecoration({
    Color? borderColor,
    double borderOpacity = 0.4,
    double backgroundOpacity = 0.1,
    double blurRadius = 20.0,
    double spreadRadius = 5.0,
  }) {
    final effectiveBorderColor = borderColor ?? primaryEnergy;
    
    return BoxDecoration(
      color: Colors.black.withOpacity(backgroundOpacity),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: effectiveBorderColor.withOpacity(borderOpacity),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: effectiveBorderColor.withOpacity(0.2),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
        ),
      ],
    );
  }
  
  // Energy Glow Effect
  static BoxShadow energyGlow({
    required Color color,
    double intensity = 1.0,
    double blurRadius = 15.0,
    double spreadRadius = 3.0,
  }) {
    return BoxShadow(
      color: color.withOpacity(0.4 * intensity),
      blurRadius: blurRadius * intensity,
      spreadRadius: spreadRadius * intensity,
    );
  }
  
  // Text Styles with Glow Effects
  static TextStyle glowText({
    required Color color,
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.bold,
    double letterSpacing = 1.0,
    double glowRadius = 4.0,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      shadows: [
        Shadow(
          color: color.withOpacity(0.8),
          blurRadius: glowRadius,
        ),
      ],
    );
  }
  
  // Holographic Material Colors
  static const Map<String, Color> materialColors = {
    'crystal': Color(0xFF00FFFF),
    'shimmer': Color(0xFFFF0066),
    'depth': Color(0xFF66FF00),
    'warp': Color(0xFF9900FF),
    'energy': Color(0xFFFF3399),
    'void': Color(0xFF000011),
  };
  
  // Chromatic Aberration Effect Offsets
  static const Offset chromaticRedOffset = Offset(2.0, 0.0);
  static const Offset chromaticGreenOffset = Offset(-1.0, 1.0);
  static const Offset chromaticBlueOffset = Offset(-1.0, -1.0);
  
  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 600);
  static const Duration breathingAnimation = Duration(seconds: 2);
  static const Duration pulseAnimation = Duration(seconds: 3);
  
  // Professional Synth Colors
  static const Color filterColor = primaryEnergy;
  static const Color oscillatorColor = secondaryEnergy;
  static const Color effectColor = tertiaryEnergy;
  static const Color sequencerColor = neonPurple;
  static const Color modulationColor = holographicPink;
  
  // UI Component Helpers
  static Widget energyParticle({
    required Color color,
    double size = 2.0,
    double opacity = 0.6,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 4.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
    );
  }
  
  // RGB Chromatic Separation Paint
  static Paint chromaticPaint(Color baseColor, String channel) {
    switch (channel.toLowerCase()) {
      case 'r':
      case 'red':
        return Paint()
          ..color = Color.fromARGB(
            (baseColor.alpha * 0.8).round(),
            baseColor.red,
            0,
            0,
          )
          ..blendMode = BlendMode.screen;
      case 'g':
      case 'green':
        return Paint()
          ..color = Color.fromARGB(
            (baseColor.alpha * 0.8).round(),
            0,
            baseColor.green,
            0,
          )
          ..blendMode = BlendMode.screen;
      case 'b':
      case 'blue':
        return Paint()
          ..color = Color.fromARGB(
            (baseColor.alpha * 0.8).round(),
            0,
            0,
            baseColor.blue,
          )
          ..blendMode = BlendMode.screen;
      default:
        return Paint()..color = baseColor;
    }
  }
}