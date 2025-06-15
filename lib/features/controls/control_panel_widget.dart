import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'dart:math' as math;

import '../../core/ffi/native_audio_ffi.dart'; // FFI
import '../../ui/holographic/holographic_theme.dart';

// --- Placeholder Definitions ---
// These would typically come from a central place, e.g. synth_parameters.dart or similar
class SynthParameterId {
  static const int filterCutoff = 10;
  static const int filterResonance = 11;
  static const int attackTime = 20;
  static const int releaseTime = 23;
  static const int reverbMix = 30;
  static const int delayTime = 31;
  // For MIDI Learn display (conceptual)
  static const int genericCCBase = 200; // If we map CCs directly
}

enum SynthParameter {
  filterCutoff('FiltCut', SynthParameterId.filterCutoff),
  filterResonance('FiltRes', SynthParameterId.filterResonance),
  attackTime('Attack', SynthParameterId.attackTime),
  releaseTime('Release', SynthParameterId.releaseTime),
  reverbMix('RevMix', SynthParameterId.reverbMix),
  delayTime('DelayTime', SynthParameterId.delayTime);

  const SynthParameter(this.shortName, this.id);
  final String shortName;
  final int id;
}

// Placeholder for actual audio engine interface
class AudioEngineInterface {
  static void setParameter(int parameterId, double value) {
    print('AudioEngineInterface: SetParam ID $parameterId to $value');
    // NativeAudioLib().setParameter(parameterId, value); // Actual call
  }
}
// --- End Placeholder Definitions ---

class ControlConfig {
  final String id;
  SynthParameter assignedParameter;
  double currentValue;
  final bool isKnob;
  bool isLearningMidi;
  int? learnedCcNumber; // MIDI CC number learned for this control

  ControlConfig({
    required this.id,
    required this.assignedParameter,
    this.currentValue = 0.5,
    required this.isKnob,
    this.isLearningMidi = false,
    this.learnedCcNumber,
  });
}

class ControlPanelWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  const ControlPanelWidget({
    Key? key,
    this.initialSize = const Size(280, 400), // Adjusted for more controls
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  _ControlPanelWidgetState createState() => _ControlPanelWidgetState();
}

class _ControlPanelWidgetState extends State<ControlPanelWidget> {
  late bool _isCollapsed;
  late Size _currentSize;
  String? _currentlyLearningControlId;
  final NativeAudioLib _nativeAudioLib = NativeAudioLib();

  final List<ControlConfig> _controls = [
    ControlConfig(id: 'knob1', assignedParameter: SynthParameter.filterCutoff, currentValue: 0.75, isKnob: true),
    ControlConfig(id: 'knob2', assignedParameter: SynthParameter.filterResonance, currentValue: 0.3, isKnob: true),
    ControlConfig(id: 'slider1', assignedParameter: SynthParameter.attackTime, currentValue: 0.1, isKnob: false),
    ControlConfig(id: 'slider2', assignedParameter: SynthParameter.reverbMix, currentValue: 0.25, isKnob: false),
  ];

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
    for (var control in _controls) {
      AudioEngineInterface.setParameter(control.assignedParameter.id, control.currentValue);
      // TODO: In a full app, load existing MIDI mappings for each control here.
      // For example: control.learnedCcNumber = _nativeAudioLib.getCcMappingForParamFfi(control.assignedParameter.id);
      // (Requires get_cc_mapping_for_param_ffi to be implemented)
    }
    // TODO: Implement a listener for MIDI learn completion events if native side can emit them.
    // Or use a periodic timer to check _nativeAudioLib.isMidiLearnActiveFfi() and update UI.
  }

  void _updateControlValue(ControlConfig control, double newValue) {
    newValue = newValue.clamp(0.0, 1.0);
    if (control.currentValue != newValue) {
      setState(() {
        control.currentValue = newValue;
      });
      AudioEngineInterface.setParameter(control.assignedParameter.id, control.currentValue);
    }
  }

  void _toggleMidiLearn(ControlConfig control) {
    setState(() {
      if (control.isLearningMidi) { // Was learning, so stop/cancel
        _nativeAudioLib.stopMidiLearnFfi();
        control.isLearningMidi = false;
        if (_currentlyLearningControlId == control.id) {
          _currentlyLearningControlId = null;
        }
      } else { // Was not learning, so start
        // Stop any other control that might be learning
        if (_currentlyLearningControlId != null) {
          final currentlyLearningCtrl = _controls.firstWhere((c) => c.id == _currentlyLearningControlId);
          currentlyLearningCtrl.isLearningMidi = false;
        }

        _nativeAudioLib.startMidiLearnFfi(control.assignedParameter.id);
        control.isLearningMidi = true;
        _currentlyLearningControlId = control.id;
        // TODO: After learning, we need a mechanism to get the learned CC
        // For now, we assume the native side handles mapping and stops learn mode.
        // The UI will stop showing "learning" when _nativeAudioLib.isMidiLearnActiveFfi() is false
        // (requires periodic check or callback for isMidiLearnActiveFfi).
        // For simplicity, the user can toggle the learn button again to manually exit UI learn state.
      }
    });
  }


  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 1.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: HolographicTheme.primaryEnergy.withOpacity(0.6), width: 1)),
      ),
      child: Row(
        children: [
          Text('CONTROL PANEL', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
          const Spacer(),
          IconButton(
            icon: Icon(_isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: HolographicTheme.primaryEnergy),
            onPressed: () {
              setState(() { _isCollapsed = !_isCollapsed; });
              widget.onCollapsedChanged?.call(_isCollapsed);
            },
            iconSize: 18, padding: EdgeInsets.zero, constraints: const BoxConstraints(), splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildControlsArea() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9, // Adjusted for taller items due to learn button/text
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: _controls.length,
          itemBuilder: (context, index) {
            final control = _controls[index];
            return _buildControlItem(control);
          },
        ),
      ),
    );
  }

  Widget _buildControlItem(ControlConfig control) {
    // TODO: Periodically check if _currentlyLearningControlId == control.id AND !_nativeAudioLib.isMidiLearnActiveFfi()
    // If so, it means learning finished for this control. Then call:
    // control.learnedCcNumber = _nativeAudioLib.getCcMappingForParamFfi(control.assignedParameter.id);
    // control.isLearningMidi = false; _currentlyLearningControlId = null; setState((){});

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: control.isLearningMidi ? HolographicTheme.accentEnergy : HolographicTheme.secondaryEnergy.withOpacity(0.6),
        intensity: control.isLearningMidi ? 1.2 : 0.6,
        cornerRadius: 7,
        borderWidth: control.isLearningMidi ? 1.8 : 1.2,
      ).copyWith(color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * (control.isLearningMidi ? 1.0 : 0.6))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: _buildParameterDropdown(control)),
              IconButton(
                icon: Icon(
                  control.isLearningMidi ? Icons.stop_circle_outlined : Icons.sensors,
                  color: control.isLearningMidi ? HolographicTheme.warningEnergy : HolographicTheme.accentEnergy.withOpacity(0.8),
                  size: 18,
                ),
                onPressed: () => _toggleMidiLearn(control),
                padding: const EdgeInsets.all(4), // Small padding
                constraints: const BoxConstraints(),
                splashRadius: 14,
                tooltip: "MIDI Learn",
              ),
            ],
          ),
          if (control.learnedCcNumber != null) // Placeholder for learned CC display
             Text("CC ${control.learnedCcNumber}", style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.accentEnergy, fontSize: 8)),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              '${(control.currentValue * 100).toStringAsFixed(0)}%',
              style: HolographicTheme.createHolographicText(
                energyColor: HolographicTheme.accentEnergy.withOpacity(0.9),
                fontSize: 10,
                glowIntensity: 0.3,
              ),
            ),
          ),
          Expanded(
            child: control.isKnob
                ? _HolographicKnob(
                    value: control.currentValue,
                    onChanged: (newValue) => _updateControlValue(control, newValue),
                    isLearning: control.isLearningMidi,
                  )
                : _HolographicSlider(
                    value: control.currentValue,
                    onChanged: (newValue) => _updateControlValue(control, newValue),
                    isLearning: control.isLearningMidi,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterDropdown(ControlConfig control) {
    return Container(
      height: 28,
      padding: const EdgeInsets.only(left: 6.0, right: 2.0),
      decoration: BoxDecoration(
        color: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * (control.isLearningMidi ? 2.5 : 1.5)),
        borderRadius: BorderRadius.circular(4),
         border: Border.all(color: HolographicTheme.secondaryEnergy.withOpacity(0.3), width:0.5)
      ),
      child: DropdownButton<SynthParameter>(
        value: control.assignedParameter,
        isDense: true,
        dropdownColor: Colors.black.withOpacity(HolographicTheme.hoverTransparency * 1.5), // Adjusted for more translucency
        underline: Container(),
        icon: Icon(Icons.arrow_drop_down, color: HolographicTheme.secondaryEnergy.withOpacity(0.8), size: 18),
        style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 10, glowIntensity: 0.2),
        items: SynthParameter.values.map((SynthParameter param) {
          return DropdownMenuItem<SynthParameter>(
            value: param,
            child: Text(
              param.shortName,
              style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: control.isLearningMidi ? null : (SynthParameter? newValue) { // Disable dropdown if learning
          if (newValue != null) {
            setState(() {
              control.assignedParameter = newValue;
              control.learnedCcNumber = null; // Clear learned CC when param changes
            });
            AudioEngineInterface.setParameter(newValue.id, control.currentValue);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _isCollapsed ? 200 : _currentSize.width,
      height: _isCollapsed ? 40 : _currentSize.height,
      decoration: HolographicTheme.createHolographicBorder(
        energyColor: HolographicTheme.primaryEnergy,
        intensity: 0.7,
        cornerRadius: 10,
      ).copyWith(
         color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.3),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed) _buildControlsArea(),
        ],
      ),
    );
  }
}

// --- Knob Widget ---
class _HolographicKnob extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double size;
  final bool isLearning;

  const _HolographicKnob({
    required this.value,
    required this.onChanged,
    this.size = 60.0,
    this.isLearning = false,
  });

  @override
  __HolographicKnobState createState() => __HolographicKnobState();
}

class __HolographicKnobState extends State<_HolographicKnob> with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isDragging = false;
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _glowAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    )..addListener(() {
        setState(() {}); // Redraw on animation change
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.isLearning) return;
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (widget.isLearning || !_isDragging) return;
    double newValue = widget.value - (details.delta.dy / (widget.size * 1.5));
    widget.onChanged(newValue.clamp(0.0, 1.0));
  }

  void _handleDragEnd(DragEndDetails details) {
    if (widget.isLearning) return;
    setState(() {
      _isDragging = false;
    });
    _animationController.reverse();
    HapticFeedback.lightImpact();
  }

  void _handleDragCancel() {
    if (widget.isLearning) return;
    setState(() {
      _isDragging = false;
    });
     _animationController.reverse();
    HapticFeedback.lightImpact();
  }


  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onPanEnd: _handleDragEnd,
        onPanCancel: _handleDragCancel,
        child: Container(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _HolographicKnobPainter(
              value: widget.value,
              baseColor: widget.isLearning ? HolographicTheme.accentEnergy.withOpacity(0.7) : HolographicTheme.secondaryEnergy,
              glowColor: widget.isLearning ? HolographicTheme.warningEnergy : HolographicTheme.glowColor,
              isHovering: _isHovering,
              isDragging: _isDragging,
              glowAnimationValue: _glowAnimation.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _HolographicKnobPainter extends CustomPainter {
  final double value;
  final Color baseColor;
  final Color glowColor;
  final bool isHovering;
  final bool isDragging;
  final double glowAnimationValue;

  _HolographicKnobPainter({
    required this.value,
    required this.baseColor,
    required this.glowColor,
    required this.isHovering,
    required this.isDragging,
    required this.glowAnimationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.80;
    final paint = Paint();
    final double baseStrokeWidth = 5;

    double currentGlowIntensity = isDragging ? glowAnimationValue : (isHovering ? 1.2 : 1.0);
    double currentStrokeWidth = baseStrokeWidth * (isDragging ? 1.1 : 1.0);

    // Modulate base color for hover/drag
    Color effectiveBaseColor = baseColor;
    if (isDragging) {
      effectiveBaseColor = HSLColor.fromColor(baseColor).withLightness((HSLColor.fromColor(baseColor).lightness * 1.2).clamp(0.0, 1.0)).toColor();
    } else if (isHovering) {
      effectiveBaseColor = HSLColor.fromColor(baseColor).withLightness((HSLColor.fromColor(baseColor).lightness * 1.1).clamp(0.0, 1.0)).toColor();
    }

    // Value-based color modulation for the arc
    HSLColor hslValueColor = HSLColor.fromColor(effectiveBaseColor);
    Color valueArcColor = hslValueColor
        .withSaturation((hslValueColor.saturation * (0.7 + 0.3 * value)).clamp(0.0, 1.0))
        .withLightness((hslValueColor.lightness * (0.8 + 0.2 * value)).clamp(0.0, 1.0))
        .toColor();

    // Background track (subtle)
    paint
      ..color = effectiveBaseColor.withOpacity(HolographicTheme.widgetTransparency * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentStrokeWidth * 0.8;
    canvas.drawCircle(center, radius, paint);

    // Blurred background track (glow)
    final Path trackPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = effectiveBaseColor.withOpacity(0.1 * currentGlowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * currentGlowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth * 1.2,
    );

    // Value Arc
    final double arcAngleRange = math.pi * 1.5;
    final double startAngle = -math.pi * 0.75 - (math.pi * 0.5);
    paint
      ..color = valueArcColor // Use modulated color
      ..style = PaintingStyle.stroke
      ..strokeWidth = currentStrokeWidth
      ..strokeCap = StrokeCap.round;
    double sweepAngle = value * arcAngleRange;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);

    // Value Arc Glow
    final Path valueArcPath = Path();
    valueArcPath.addArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle);
    canvas.drawPath(
      valueArcPath,
      Paint()
        ..color = glowColor.withOpacity(0.7 * currentGlowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentStrokeWidth * 0.8 * currentGlowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth,
    );
     canvas.drawPath(
      valueArcPath,
      Paint()
        ..color = glowColor.withOpacity(0.4 * currentGlowIntensity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentStrokeWidth * 1.5 * currentGlowIntensity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStrokeWidth,
    );

    // Indicator Dot
    final double indicatorAngle = startAngle + sweepAngle;
    final indicatorPosition = Offset(
      center.dx + radius * math.cos(indicatorAngle),
      center.dy + radius * math.sin(indicatorAngle),
    );
    final double indicatorRadius = currentStrokeWidth * 0.8 * (isDragging ? 1.15 : 1.0);

    // Indicator dot glow
    canvas.drawCircle(indicatorPosition, indicatorRadius * 1.5, Paint()..color = glowColor.withOpacity(0.8 * currentGlowIntensity)..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * currentGlowIntensity));
    // Indicator dot base
    canvas.drawCircle(indicatorPosition, indicatorRadius, Paint()..color = valueArcColor);
    // Indicator dot highlight
    canvas.drawCircle(indicatorPosition, indicatorRadius * 0.5, Paint()..color = Colors.white.withOpacity(0.7 * (isDragging ? 1.0 : (isHovering ? 0.85 : 0.7))));
  }

  @override
  bool shouldRepaint(_HolographicKnobPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.isHovering != isHovering ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.glowAnimationValue != glowAnimationValue;
}


// --- Slider Widget ---
class _HolographicSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double length;
  final bool isVertical;
  final bool isLearning;

  const _HolographicSlider({
    required this.value,
    required this.onChanged,
    this.length = 80.0,
    this.isVertical = true,
    this.isLearning = false,
  });

  @override
  __HolographicSliderState createState() => __HolographicSliderState();
}

class __HolographicSliderState extends State<_HolographicSlider> {
  bool _isHovering = false;
  bool _isDragging = false;

  void _handlePanStart(DragStartDetails details) {
    if (widget.isLearning) return;
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (widget.isLearning || !_isDragging) return;
    double newValue;
    if (widget.isVertical) {
      newValue = widget.value - (details.delta.dy / widget.length);
    } else {
      newValue = widget.value + (details.delta.dx / widget.length);
    }
    widget.onChanged(newValue.clamp(0.0, 1.0));
  }

  void _handlePanEnd(DragEndDetails details) {
    if (widget.isLearning) return;
    setState(() {
      _isDragging = false;
    });
    HapticFeedback.lightImpact();
  }

  void _handlePanCancel() {
     if (widget.isLearning) return;
    setState(() {
      _isDragging = false;
    });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        onPanCancel: _handlePanCancel,
        child: Container(
          width: widget.isVertical ? 24 : widget.length,
          height: widget.isVertical ? widget.length : 24,
          child: CustomPaint(
            painter: _HolographicSliderPainter(
              value: widget.value,
              baseColor: widget.isLearning ? HolographicTheme.accentEnergy.withOpacity(0.7) : HolographicTheme.secondaryEnergy,
              glowColor: widget.isLearning ? HolographicTheme.warningEnergy : HolographicTheme.glowColor,
              isVertical: widget.isVertical,
              isHovering: _isHovering,
              isDragging: _isDragging,
            ),
          ),
        ),
      ),
    );
  }
}

class _HolographicSliderPainter extends CustomPainter {
  final double value;
  final Color baseColor;
  final Color glowColor;
  final bool isVertical;
  final bool isHovering;
  final bool isDragging;

  _HolographicSliderPainter({
    required this.value,
    required this.baseColor,
    required this.glowColor,
    this.isVertical = true,
    required this.isHovering,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double trackThickness = 5.0 * (isDragging ? 1.1 : 1.0);
    final double baseThumbRadius = 10.0;
    final double thumbRadius = baseThumbRadius * (isDragging ? 1.2 : (isHovering ? 1.1 : 1.0));

    final RRect trackRect;
    final Offset thumbCenter;
    Rect activeTrackRect;

    Color effectiveBaseColor = baseColor;
    if (isDragging) {
      effectiveBaseColor = HSLColor.fromColor(baseColor).withLightness((HSLColor.fromColor(baseColor).lightness * 1.2).clamp(0.0, 1.0)).toColor();
    } else if (isHovering) {
      effectiveBaseColor = HSLColor.fromColor(baseColor).withLightness((HSLColor.fromColor(baseColor).lightness * 1.1).clamp(0.0, 1.0)).toColor();
    }

    // Value-based color modulation for active track and thumb
    HSLColor hslValueColor = HSLColor.fromColor(effectiveBaseColor);
    Color valueBasedColor = hslValueColor
        .withSaturation((hslValueColor.saturation * (0.7 + 0.3 * value)).clamp(0.0, 1.0))
        .withLightness((hslValueColor.lightness * (0.8 + 0.2 * value)).clamp(0.0, 1.0))
        .toColor();

    if (isVertical) {
      trackRect = RRect.fromLTRBR(
        size.width / 2 - trackThickness / 2, thumbRadius,
        size.width / 2 + trackThickness / 2, size.height - thumbRadius,
        Radius.circular(trackThickness / 2),
      );
      double thumbY = (size.height - 2 * thumbRadius) * (1.0 - value) + thumbRadius;
      thumbCenter = Offset(size.width / 2, thumbY);
      activeTrackRect = Rect.fromLTRB(
        trackRect.left, thumbY,
        trackRect.right, trackRect.bottom,
      );
    } else {
      trackRect = RRect.fromLTRBR(
        thumbRadius, size.height / 2 - trackThickness / 2,
        size.width - thumbRadius, size.height / 2 + trackThickness / 2,
        Radius.circular(trackThickness / 2),
      );
      double thumbX = (size.width - 2 * thumbRadius) * value + thumbRadius;
      thumbCenter = Offset(thumbX, size.height / 2);
      activeTrackRect = Rect.fromLTRB(
        trackRect.left, trackRect.top,
        thumbX, trackRect.bottom,
      );
    }

    // Inactive Track
    paint
      ..color = effectiveBaseColor.withOpacity(HolographicTheme.widgetTransparency * (isHovering || isDragging ? 0.9 : 0.7))
      ..style = PaintingStyle.fill;
    canvas.drawRRect(trackRect, paint);

    // Active Track
    paint
      ..color = valueBasedColor; // Use value-modulated color
    canvas.drawRect(activeTrackRect, paint);

    // Active Track Glow
    double glowIntensity = isDragging ? 0.8 : (isHovering ? 0.7 : 0.6);
    final Paint activeTrackGlowPaint = Paint()
      ..color = glowColor.withOpacity(glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0 * (isDragging ? 1.5 : 1.0));
    canvas.drawRect(activeTrackRect, activeTrackGlowPaint);

    // Thumb
    double thumbGlowRadius = isDragging ? 5.0 : (isHovering ? 4.0 : 3.0);
    canvas.drawCircle(thumbCenter, thumbRadius * 1.2, Paint()..color = glowColor.withOpacity(0.5 * (isDragging ? 1.2 : 1.0))..maskFilter = MaskFilter.blur(BlurStyle.normal, thumbGlowRadius));
    paint..color = valueBasedColor; // Use value-modulated color for thumb base
    canvas.drawCircle(thumbCenter, thumbRadius, paint);
    paint..color = Colors.white.withOpacity(0.7 * (isDragging ? 0.9 : (isHovering ? 0.8 : 0.7)));
    canvas.drawCircle(thumbCenter, thumbRadius * 0.5, paint);
    paint..color = valueBasedColor.withOpacity(0.8)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    canvas.drawCircle(thumbCenter, thumbRadius, paint);
  }

  @override
  bool shouldRepaint(_HolographicSliderPainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.baseColor != baseColor ||
      oldDelegate.glowColor != glowColor ||
      oldDelegate.isHovering != isHovering ||
      oldDelegate.isDragging != isDragging ||
      oldDelegate.isVertical != isVertical;
}
