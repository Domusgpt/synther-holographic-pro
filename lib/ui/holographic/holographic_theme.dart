import 'package:flutter/material.dart';

/// Vaporwave/Holographic color palette and theme system
class HolographicTheme {
  // Vaporwave Colors
  static const Color primaryEnergy = Color(0xFFFF00FF); // Magenta
  static const Color secondaryEnergy = Color(0xFF00FFFF); // Cyan
  static const Color accentEnergy = Color(0xFFFFFF00); // Electric Yellow
  static const Color glowColor = Color(0xFFFF0080); // Hot Pink
  static const Color warningEnergy = Color(0xFFFF4000); // Electric Orange
  static const Color successEnergy = Color(0xFF00FF80); // Electric Green
  
  // Transparency levels
  static const double widgetTransparency = 0.15;
  static const double hoverTransparency = 0.25;
  static const double activeTransparency = 0.35;
  
  // Glow effects
  static const double baseGlowRadius = 8.0;
  static const double hoverGlowRadius = 12.0;
  static const double activeGlowRadius = 16.0;
  
  // Animation durations
  static const Duration hoverDuration = Duration(milliseconds: 200);
  static const Duration activeDuration = Duration(milliseconds: 100);
  static const Duration collapseDuration = Duration(milliseconds: 300);
  
  /// Creates energy glow effect with specified color and intensity
  static List<BoxShadow> createEnergyGlow({
    required Color color,
    double intensity = 1.0,
    double radius = baseGlowRadius,
  }) {
    return [
      BoxShadow(
        color: color.withOpacity(0.6 * intensity),
        blurRadius: radius * intensity,
        spreadRadius: (radius * 0.3) * intensity,
      ),
    ];
  }
  
  /// Creates text glow effects
  static List<Shadow> textGlow(Color color, {double intensity = 1.0}) {
    return [
      Shadow(
        color: color.withOpacity(0.8 * intensity),
        blurRadius: 4.0 * intensity,
      ),
      Shadow(
        color: color.withOpacity(0.4 * intensity),
        blurRadius: 8.0 * intensity,
      ),
    ];
  }
  
  /// Creates holographic border with energy effect
  static BoxDecoration createHolographicBorder({
    required Color energyColor,
    double intensity = 1.0,
    double borderWidth = 1.5,
    double cornerRadius = 8.0,
  }) {
    return BoxDecoration(
      color: energyColor.withOpacity(widgetTransparency * intensity),
      borderRadius: BorderRadius.circular(cornerRadius),
      border: Border.all(
        color: energyColor.withOpacity(0.8 * intensity),
        width: borderWidth,
      ),
      boxShadow: [
        ...createEnergyGlow(color: energyColor, intensity: intensity),
        // Inner glow
        BoxShadow(
          color: energyColor.withOpacity(0.3 * intensity),
          blurRadius: 4.0,
          spreadRadius: -2.0,
        ),
      ],
    );
  }
  
  /// Creates holographic text style with glow
  static TextStyle createHolographicText({
    required Color energyColor,
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.w500,
    double glowIntensity = 1.0,
  }) {
    return TextStyle(
      color: energyColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFamily: 'monospace',
      shadows: [
        Shadow(
          color: energyColor.withOpacity(0.8 * glowIntensity),
          blurRadius: 4.0 * glowIntensity,
        ),
        Shadow(
          color: energyColor.withOpacity(0.4 * glowIntensity),
          blurRadius: 8.0 * glowIntensity,
        ),
      ],
    );
  }
  
  /// Creates energy ripple effect for touch interactions
  static Widget createEnergyRipple({
    required Widget child,
    required Color energyColor,
    required VoidCallback onTap,
    double intensity = 1.0,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: energyColor.withOpacity(0.3 * intensity),
        highlightColor: energyColor.withOpacity(0.1 * intensity),
        borderRadius: BorderRadius.circular(8.0),
        child: child,
      ),
    );
  }
  
  /// Creates pulsing energy animation
  static Widget createPulsingEnergy({
    required Widget child,
    required Color energyColor,
    bool isActive = false,
    double baseIntensity = 0.5,
    double pulseIntensity = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: baseIntensity, end: isActive ? pulseIntensity : baseIntensity),
      builder: (context, intensity, _) {
        return AnimatedContainer(
          duration: hoverDuration,
          decoration: createHolographicBorder(
            energyColor: energyColor,
            intensity: intensity,
          ),
          child: child,
        );
      },
    );
  }
  
  /// Creates floating energy particle effect
  static Widget createFloatingParticles({
    required Widget child,
    required Color energyColor,
    int particleCount = 3,
  }) {
    return Stack(
      children: [
        child,
        // Add floating particles overlay when needed
        ...List.generate(particleCount, (index) {
          return Positioned(
            top: 10.0 + (index * 15.0),
            right: 10.0 + (index * 8.0),
            child: Container(
              width: 2.0,
              height: 2.0,
              decoration: BoxDecoration(
                color: energyColor,
                shape: BoxShape.circle,
                boxShadow: createEnergyGlow(color: energyColor, radius: 3.0),
              ),
            ),
          );
        }),
      ],
    );
  }
  
  /// Creates drag handle with energy effects
  static Widget createDragHandle({
    required Color energyColor,
    double size = 20.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: energyColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: energyColor.withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: createEnergyGlow(color: energyColor, radius: 4.0),
      ),
      child: Icon(
        Icons.drag_indicator,
        color: energyColor,
        size: size * 0.7,
      ),
    );
  }
  
  /// Creates resize handle with corner energy glow
  static Widget createResizeHandle({
    required Color energyColor,
    double size = 16.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: energyColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2.0),
        boxShadow: createEnergyGlow(color: energyColor, radius: 3.0),
      ),
      child: CustomPaint(
        painter: _ResizeHandlePainter(energyColor),
      ),
    );
  }
}

/// Custom painter for resize handle energy lines
class _ResizeHandlePainter extends CustomPainter {
  final Color energyColor;
  
  _ResizeHandlePainter(this.energyColor);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = energyColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    // Draw energy lines in corner pattern
    final center = Offset(size.width / 2, size.height / 2);
    
    // Diagonal lines
    canvas.drawLine(
      Offset(2, size.height - 2),
      Offset(size.width - 2, 2),
      paint,
    );
    
    canvas.drawLine(
      Offset(2, size.height - 6),
      Offset(size.width - 6, 2),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}