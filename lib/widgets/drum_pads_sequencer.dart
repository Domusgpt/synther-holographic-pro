// Professional Drum Pads and Sequencer with Holographic Effects
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/hyperav_bridge.dart';
import '../core/holographic_theme.dart';

class DrumPadsSequencer extends StatefulWidget {
  final Offset? position;
  final Function(Offset)? onPositionChanged;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final Function(String)? onDrumHit;

  const DrumPadsSequencer({
    Key? key,
    this.position,
    this.onPositionChanged,
    this.isCollapsed = false,
    this.onToggleCollapse,
    this.onDrumHit,
  }) : super(key: key);

  @override
  State<DrumPadsSequencer> createState() => _DrumPadsSequencerState();
}

class _DrumPadsSequencerState extends State<DrumPadsSequencer>
    with TickerProviderStateMixin {
  
  // Drum pad definitions
  final List<DrumPad> _drumPads = [
    DrumPad('KICK', 'Kick Drum', HolographicTheme.primaryEnergy),
    DrumPad('SNARE', 'Snare Drum', HolographicTheme.secondaryEnergy),
    DrumPad('HAT', 'Hi-Hat', HolographicTheme.tertiaryEnergy),
    DrumPad('OPEN', 'Open Hat', HolographicTheme.primaryEnergy.withOpacity(0.8)),
    DrumPad('PERC', 'Percussion', HolographicTheme.secondaryEnergy.withOpacity(0.8)),
    DrumPad('FX', 'Effects', HolographicTheme.tertiaryEnergy.withOpacity(0.8)),
  ];

  // Sequencer state
  bool _isPlaying = false;
  int _currentStep = 0;
  int _bpm = 120;
  final int _steps = 16;
  
  // Pattern data - [drum][step]
  late List<List<bool>> _pattern;
  
  // Animation controllers
  late AnimationController _glowController;
  late AnimationController _sequencerController;
  late Animation<double> _glowAnimation;
  
  // Hit animation tracking
  Map<String, AnimationController> _hitControllers = {};
  Map<String, Animation<double>> _hitAnimations = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize pattern
    _pattern = List.generate(
      _drumPads.length,
      (index) => List.generate(_steps, (step) => false),
    );
    
    _glowController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _sequencerController = AnimationController(
      duration: Duration(milliseconds: 60000 ~/ _bpm ~/ 4), // 16th note timing
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // Setup hit animations for each drum
    for (final drum in _drumPads) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 150),
        vsync: this,
      );
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
      
      _hitControllers[drum.name] = controller;
      _hitAnimations[drum.name] = animation;
    }
    
    _glowController.repeat(reverse: true);
    
    // Setup sequencer loop
    _sequencerController.addListener(_onSequencerTick);
  }

  void _onSequencerTick() {
    if (!_isPlaying) return;
    
    final progress = _sequencerController.value;
    final currentStep = (progress * _steps).floor() % _steps;
    
    if (currentStep != _currentStep) {
      setState(() {
        _currentStep = currentStep;
      });
      
      // Check for hits on current step
      for (int drumIndex = 0; drumIndex < _drumPads.length; drumIndex++) {
        if (_pattern[drumIndex][currentStep]) {
          _triggerDrumHit(_drumPads[drumIndex].name);
        }
      }
    }
  }

  void _triggerDrumHit(String drumName) {
    // Trigger hit animation
    _hitControllers[drumName]?.forward().then((_) {
      _hitControllers[drumName]?.reverse();
    });
    
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();
    
    // Update visualizer
    HyperAVBridge.instance.triggerVisualizerEffect('drumHit', params: {
      'drum': drumName,
      'intensity': 1.0,
    });
    
    // Callback
    widget.onDrumHit?.call(drumName);
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    if (_isPlaying) {
      _sequencerController.repeat();
    } else {
      _sequencerController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return _buildCollapsedState();
    }
    
    return _buildFullInterface();
  }

  Widget _buildCollapsedState() {
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: GestureDetector(
        onTap: widget.onToggleCollapse,
        onPanUpdate: (details) {
          widget.onPositionChanged?.call(
            (widget.position ?? Offset.zero) + details.delta,
          );
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Icon(
            Icons.music_note,
            color: HolographicTheme.tertiaryEnergy,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildFullInterface() {
    return Positioned(
      left: widget.position?.dx ?? 0,
      top: widget.position?.dy ?? 0,
      child: Container(
        width: 600,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with controls
            _buildHeader(),
            
            // Main content
            Expanded(
              child: Row(
                children: [
                  // Drum pads
                  _buildDrumPads(),
                  
                  // Sequencer grid
                  Expanded(
                    child: _buildSequencerGrid(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: HolographicTheme.tertiaryEnergy.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        border: Border(
          bottom: BorderSide(
            color: HolographicTheme.tertiaryEnergy.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 20),
          Text(
            'DRUM MACHINE',
            style: TextStyle(
              color: HolographicTheme.tertiaryEnergy,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              shadows: [
                Shadow(
                  color: HolographicTheme.tertiaryEnergy.withOpacity(0.8),
                  blurRadius: 6.0,
                ),
              ],
            ),
          ),
          
          SizedBox(width: 30),
          
          // Play/Stop button
          GestureDetector(
            onTap: _togglePlayback,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: _isPlaying 
                  ? HolographicTheme.secondaryEnergy.withOpacity(0.3)
                  : HolographicTheme.primaryEnergy.withOpacity(0.3),
                borderRadius: BorderRadius.circular(17.5),
                border: Border.all(
                  color: _isPlaying 
                    ? HolographicTheme.secondaryEnergy
                    : HolographicTheme.primaryEnergy,
                  width: 2,
                ),
              ),
              child: Icon(
                _isPlaying ? Icons.stop : Icons.play_arrow,
                color: _isPlaying 
                  ? HolographicTheme.secondaryEnergy
                  : HolographicTheme.primaryEnergy,
                size: 20,
              ),
            ),
          ),
          
          SizedBox(width: 20),
          
          // BPM display
          Text(
            'BPM: $_bpm',
            style: TextStyle(
              color: HolographicTheme.tertiaryEnergy.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          Spacer(),
          
          // Collapse button
          GestureDetector(
            onTap: widget.onToggleCollapse,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: HolographicTheme.tertiaryEnergy.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: HolographicTheme.tertiaryEnergy.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.minimize,
                color: HolographicTheme.tertiaryEnergy,
                size: 16,
              ),
            ),
          ),
          SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildDrumPads() {
    return Container(
      width: 200,
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          // Top row
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildDrumPadButton(0)), // KICK
                SizedBox(width: 10),
                Expanded(child: _buildDrumPadButton(1)), // SNARE
                SizedBox(width: 10),
                Expanded(child: _buildDrumPadButton(2)), // HAT
              ],
            ),
          ),
          
          SizedBox(height: 10),
          
          // Bottom row
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildDrumPadButton(3)), // OPEN
                SizedBox(width: 10),
                Expanded(child: _buildDrumPadButton(4)), // PERC
                SizedBox(width: 10),
                Expanded(child: _buildDrumPadButton(5)), // FX
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrumPadButton(int drumIndex) {
    final drum = _drumPads[drumIndex];
    final hitAnimation = _hitAnimations[drum.name]!;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_glowAnimation, hitAnimation]),
      builder: (context, child) {
        final hitIntensity = hitAnimation.value;
        final glowIntensity = _glowAnimation.value + hitIntensity;
        
        return GestureDetector(
          onTapDown: (_) => _triggerDrumHit(drum.name),
          child: Transform.scale(
            scale: 1.0 + hitIntensity * 0.1,
            child: Container(
              decoration: BoxDecoration(
                color: drum.color.withOpacity(0.1 + hitIntensity * 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: drum.color.withOpacity(0.6 + hitIntensity * 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: drum.color.withOpacity(0.4 * glowIntensity),
                    blurRadius: 15 * glowIntensity,
                    spreadRadius: 3 * glowIntensity,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    drum.name,
                    style: TextStyle(
                      color: drum.color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: drum.color.withOpacity(0.8),
                          blurRadius: 4.0,
                        ),
                      ],
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

  Widget _buildSequencerGrid() {
    return Padding(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          // Step indicator
          Container(
            height: 30,
            child: Row(
              children: List.generate(_steps, (stepIndex) {
                final isCurrentStep = _isPlaying && stepIndex == _currentStep;
                
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isCurrentStep 
                        ? HolographicTheme.primaryEnergy.withOpacity(0.6)
                        : HolographicTheme.primaryEnergy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: HolographicTheme.primaryEnergy.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: HolographicTheme.primaryEnergy,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          SizedBox(height: 10),
          
          // Pattern grid
          Expanded(
            child: Column(
              children: List.generate(_drumPads.length, (drumIndex) {
                return Expanded(
                  child: Row(
                    children: [
                      // Drum label
                      Container(
                        width: 50,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _drumPads[drumIndex].name,
                          style: TextStyle(
                            color: _drumPads[drumIndex].color.withOpacity(0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 10),
                      
                      // Step buttons
                      Expanded(
                        child: Row(
                          children: List.generate(_steps, (stepIndex) {
                            final isActive = _pattern[drumIndex][stepIndex];
                            
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pattern[drumIndex][stepIndex] = !isActive;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: Container(
                                  margin: EdgeInsets.all(1),
                                  decoration: BoxDecoration(
                                    color: isActive 
                                      ? _drumPads[drumIndex].color.withOpacity(0.6)
                                      : _drumPads[drumIndex].color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      color: _drumPads[drumIndex].color.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sequencerController.dispose();
    
    for (final controller in _hitControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}

// Data class for drum pad definition
class DrumPad {
  final String name;
  final String description;
  final Color color;

  const DrumPad(this.name, this.description, this.color);
}