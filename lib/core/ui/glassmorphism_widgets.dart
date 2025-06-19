import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'holographic_theme.dart';

/// Professional Glassmorphism Widget Library
/// 
/// Provides comprehensive glassmorphism UI components:
/// - GlassmorphismContainer with blur and transparency
/// - HolographicButton with chromatic aberration
/// - GlassPanel for control surfaces
/// - HolographicSlider with audio-reactive feedback
/// - ChromaticText with RGB channel separation
/// - DepthCard with 3D layering effects

/// Base glassmorphism container with blur effects
class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final GlassmorphismConfig? config;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;
  final bool enableRipple;
  
  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.config,
    this.borderRadius,
    this.onTap,
    this.enableHover = false,
    this.enableRipple = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    final glassConfig = config ?? theme.glassmorphism;
    final radius = borderRadius ?? BorderRadius.circular(theme.borderRadius);
    
    Widget container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: glassConfig.borderColor.withOpacity(glassConfig.borderOpacity),
          width: glassConfig.borderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: glassConfig.blur,
            sigmaY: glassConfig.blur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: glassConfig.tintColor.withOpacity(glassConfig.opacity),
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  glassConfig.tintColor.withOpacity(glassConfig.opacity * 1.2),
                  glassConfig.tintColor.withOpacity(glassConfig.opacity * 0.8),
                ],
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
    
    if (onTap != null) {
      container = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: enableRipple 
            ? theme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
          highlightColor: enableHover
            ? theme.primaryColor.withOpacity(0.05)
            : Colors.transparent,
          child: container,
        ),
      );
    }
    
    return container;
  }
}

/// Holographic button with chromatic aberration effects
class HolographicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enabled;
  final ButtonStyle? style;
  final bool enableChromaticAberration;
  final bool enableGlow;
  final bool enablePulse;
  
  const HolographicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.enabled = true,
    this.style,
    this.enableChromaticAberration = true,
    this.enableGlow = true,
    this.enablePulse = false,
  });
  
  @override
  State<HolographicButton> createState() => _HolographicButtonState();
}

class _HolographicButtonState extends State<HolographicButton>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _pressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pressAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ));
    
    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _pressController.dispose();
    super.dispose();
  }
  
  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
  }
  
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }
  
  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _pressAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pressAnimation.value * _pulseAnimation.value,
            child: GestureDetector(
              onTapDown: widget.enabled ? _handleTapDown : null,
              onTapUp: widget.enabled ? _handleTapUp : null,
              onTapCancel: _handleTapCancel,
              onTap: widget.enabled ? widget.onPressed : null,
              child: AnimatedContainer(
                duration: theme.shortAnimation,
                width: widget.width,
                height: widget.height,
                padding: widget.padding ?? theme.defaultPadding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  border: Border.all(
                    color: widget.enabled
                      ? theme.primaryColor.withOpacity(_isHovered ? 0.6 : 0.3)
                      : theme.onSurfaceColor.withOpacity(0.1),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.enabled
                      ? [
                          theme.primaryColor.withOpacity(_isPressed ? 0.3 : 0.1),
                          theme.secondaryColor.withOpacity(_isPressed ? 0.2 : 0.05),
                        ]
                      : [
                          theme.surfaceColor.withOpacity(0.3),
                          theme.surfaceColor.withOpacity(0.1),
                        ],
                  ),
                  boxShadow: widget.enableGlow && widget.enabled ? [
                    BoxShadow(
                      color: theme.glowColor.withOpacity(_isHovered ? 0.3 : 0.1),
                      blurRadius: _isHovered ? 15.0 : 8.0,
                      spreadRadius: _isHovered ? 2.0 : 0.0,
                    ),
                  ] : null,
                ),
                child: widget.enableChromaticAberration && widget.enabled
                  ? ChromaticText(
                      child: widget.child,
                      intensity: _isHovered ? 0.7 : 0.3,
                    )
                  : widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Glass panel for control surfaces
class GlassPanel extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final double? width;
  final double? height;
  final bool showBorder;
  final bool enableDepthEffect;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const GlassPanel({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.width,
    this.height,
    this.showBorder = true,
    this.enableDepthEffect = true,
    this.padding,
    this.margin,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || titleWidget != null)
            Padding(
              padding: EdgeInsets.only(bottom: theme.baseUnit),
              child: titleWidget ?? ChromaticText(
                child: Text(
                  title!,
                  style: theme.headlineStyle.copyWith(fontSize: 18),
                ),
              ),
            ),
          
          Flexible(
            child: GlassmorphismContainer(
              width: width,
              height: height,
              padding: padding ?? theme.defaultPadding,
              config: theme.glassmorphism.copyWith(
                blur: enableDepthEffect ? theme.glassmorphism.blur * 1.2 : theme.glassmorphism.blur,
                opacity: enableDepthEffect ? theme.glassmorphism.opacity * 1.1 : theme.glassmorphism.opacity,
              ),
              borderRadius: BorderRadius.circular(theme.borderRadius * 1.5),
              child: enableDepthEffect
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.surfaceColor.withOpacity(0.1),
                          theme.surfaceColor.withOpacity(0.05),
                          theme.surfaceColor.withOpacity(0.02),
                        ],
                      ),
                    ),
                    child: child,
                  )
                : child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Holographic slider with audio-reactive feedback
class HolographicSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String? label;
  final String? unit;
  final bool showValue;
  final bool enableAudioReactivity;
  final double? width;
  final double? height;
  
  const HolographicSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.label,
    this.unit,
    this.showValue = true,
    this.enableAudioReactivity = false,
    this.width,
    this.height = 40.0,
  });
  
  @override
  State<HolographicSlider> createState() => _HolographicSliderState();
}

class _HolographicSliderState extends State<HolographicSlider>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.enableAudioReactivity) {
      _glowController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    
    return Container(
      width: widget.width,
      height: widget.height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.label != null || widget.showValue)
            Padding(
              padding: EdgeInsets.only(bottom: theme.baseUnit / 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.label != null)
                    Text(
                      widget.label!,
                      style: theme.captionStyle,
                    ),
                  if (widget.showValue)
                    ChromaticText(
                      child: Text(
                        '${widget.value.toStringAsFixed(2)}${widget.unit ?? ''}',
                        style: theme.captionStyle.copyWith(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      intensity: 0.4,
                    ),
                ],
              ),
            ),
          
          Expanded(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return GestureDetector(
                  onPanStart: (details) {
                    setState(() => _isDragging = true);
                    widget.onChangeStart?.call(widget.value);
                  },
                  onPanUpdate: (details) {
                    if (widget.onChanged == null) return;
                    
                    final RenderBox box = context.findRenderObject() as RenderBox;
                    final localPosition = box.globalToLocal(details.globalPosition);
                    final percentage = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
                    final newValue = widget.min + (widget.max - widget.min) * percentage;
                    
                    widget.onChanged!(newValue);
                  },
                  onPanEnd: (details) {
                    setState(() => _isDragging = false);
                    widget.onChangeEnd?.call(widget.value);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                      gradient: LinearGradient(
                        colors: [
                          theme.surfaceColor.withOpacity(0.3),
                          theme.surfaceColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.2),
                        width: 1.0,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Track
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                            color: theme.backgroundColor.withOpacity(0.5),
                          ),
                        ),
                        
                        // Fill
                        FractionallySizedBox(
                          widthFactor: (widget.value - widget.min) / (widget.max - widget.min),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(theme.borderRadius / 2),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor.withOpacity(0.8),
                                  theme.secondaryColor.withOpacity(0.6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.glowColor.withOpacity(
                                    (_isDragging ? 0.5 : 0.2) * _glowAnimation.value
                                  ),
                                  blurRadius: 8.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // Thumb
                        Positioned(
                          left: ((widget.value - widget.min) / (widget.max - widget.min)) * 
                               (widget.width ?? 200) - 6,
                          top: 2,
                          child: Container(
                            width: 12,
                            height: (widget.height ?? 40) - 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: theme.onSurfaceColor,
                              border: Border.all(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.glowColor.withOpacity(
                                    (_isDragging ? 0.8 : 0.4) * _glowAnimation.value
                                  ),
                                  blurRadius: 6.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Chromatic text with RGB channel separation
class ChromaticText extends StatelessWidget {
  final Widget child;
  final double intensity;
  final ChromaticAberrationConfig? config;
  final bool enableAnimation;
  
  const ChromaticText({
    super.key,
    required this.child,
    this.intensity = 0.5,
    this.config,
    this.enableAnimation = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    final chromaticConfig = config ?? theme.chromaticAberration;
    
    if (intensity <= 0.0) return child;
    
    return Stack(
      children: [
        // Red channel
        Transform.translate(
          offset: Offset(
            chromaticConfig.redOffset * intensity,
            0,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Colors.red, Colors.red],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Opacity(
              opacity: intensity,
              child: child,
            ),
          ),
        ),
        
        // Green channel (center)
        Transform.translate(
          offset: Offset(
            chromaticConfig.greenOffset * intensity,
            0,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Colors.green, Colors.green],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Opacity(
              opacity: intensity,
              child: child,
            ),
          ),
        ),
        
        // Blue channel
        Transform.translate(
          offset: Offset(
            chromaticConfig.blueOffset * intensity,
            0,
          ),
          child: ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Colors.blue, Colors.blue],
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn,
            child: Opacity(
              opacity: intensity,
              child: child,
            ),
          ),
        ),
        
        // Original (reduced opacity)
        Opacity(
          opacity: 1.0 - intensity * 0.5,
          child: child,
        ),
      ],
    );
  }
}

/// Depth card with 3D layering effects
class DepthCard extends StatefulWidget {
  final Widget child;
  final double depth;
  final bool enableHover;
  final bool enableTilt;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  const DepthCard({
    super.key,
    required this.child,
    this.depth = 8.0,
    this.enableHover = true,
    this.enableTilt = true,
    this.onTap,
    this.padding,
    this.margin,
  });
  
  @override
  State<DepthCard> createState() => _DepthCardState();
}

class _DepthCardState extends State<DepthCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  
  Offset _tiltOffset = Offset.zero;
  bool _isHovered = false;
  
  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _hoverAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }
  
  void _handlePointerMove(PointerEvent details) {
    if (!widget.enableTilt || !_isHovered) return;
    
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.position);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final offset = localPosition - center;
    
    setState(() {
      _tiltOffset = Offset(
        (offset.dx / box.size.width) * 0.1,
        (offset.dy / box.size.height) * 0.1,
      );
    });
  }
  
  void _handlePointerExit(PointerEvent details) {
    setState(() {
      _isHovered = false;
      _tiltOffset = Offset.zero;
    });
    _hoverController.reverse();
  }
  
  void _handlePointerEnter(PointerEvent details) {
    setState(() => _isHovered = true);
    if (widget.enableHover) {
      _hoverController.forward();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    
    return MouseRegion(
      onEnter: (_) => _handlePointerEnter(_),
      onExit: (_) => _handlePointerExit(_),
      child: Listener(
        onPointerMove: _handlePointerMove,
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_tiltOffset.dy)
                ..rotateY(-_tiltOffset.dx)
                ..scale(_hoverAnimation.value),
              child: Container(
                margin: widget.margin,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.borderRadius),
                  boxShadow: [
                    // Main shadow
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.3),
                      blurRadius: widget.depth * _hoverAnimation.value,
                      spreadRadius: widget.depth * 0.1,
                      offset: Offset(0, widget.depth * 0.5 * _hoverAnimation.value),
                    ),
                    // Glow effect
                    if (_isHovered)
                      BoxShadow(
                        color: theme.glowColor.withOpacity(0.2),
                        blurRadius: widget.depth * 2,
                        spreadRadius: widget.depth * 0.2,
                      ),
                  ],
                ),
                child: GlassmorphismContainer(
                  padding: widget.padding,
                  onTap: widget.onTap,
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Holographic loading indicator
class HolographicLoader extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final bool showText;
  final String? text;
  
  const HolographicLoader({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
    this.showText = false,
    this.text,
  });
  
  @override
  State<HolographicLoader> createState() => _HolographicLoaderState();
}

class _HolographicLoaderState extends State<HolographicLoader>
    with TickerProviderStateMixin {
  
  late AnimationController _spinController;
  late AnimationController _glowController;
  late Animation<double> _spinAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _spinAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.linear,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _spinController.repeat();
    _glowController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _spinController.dispose();
    _glowController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = HolographicTheme.of(context);
    final loaderColor = widget.color ?? theme.primaryColor;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_spinAnimation, _glowAnimation]),
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: loaderColor.withOpacity(0.5 * _glowAnimation.value),
                    blurRadius: 10.0 * _glowAnimation.value,
                    spreadRadius: 2.0 * _glowAnimation.value,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: _spinAnimation.value,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _HolographicLoaderPainter(
                    color: loaderColor,
                    strokeWidth: widget.strokeWidth,
                    glowIntensity: _glowAnimation.value,
                  ),
                ),
              ),
            );
          },
        ),
        
        if (widget.showText && widget.text != null)
          Padding(
            padding: EdgeInsets.only(top: theme.baseUnit),
            child: ChromaticText(
              intensity: 0.3,
              child: Text(
                widget.text!,
                style: theme.captionStyle,
              ),
            ),
          ),
      ],
    );
  }
}

class _HolographicLoaderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double glowIntensity;
  
  _HolographicLoaderPainter({
    required this.color,
    required this.strokeWidth,
    required this.glowIntensity,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Draw glow
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3 * glowIntensity)
      ..strokeWidth = strokeWidth * 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      glowPaint,
    );
    
    // Draw main arc
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 1.5,
      false,
      paint,
    );
    
    // Draw highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = strokeWidth * 0.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      math.pi * 0.5,
      false,
      highlightPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}