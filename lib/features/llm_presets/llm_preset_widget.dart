import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart'; // Firebase Cloud Functions
import 'dart:convert'; // For jsonDecode

import '../../core/audio_engine.dart'; // For AudioEngine
import '../../ui/holographic/holographic_theme.dart';


class LlmPresetWidget extends StatefulWidget {
  final Size initialSize;
  final bool isInitiallyCollapsed;
  final Function(Size)? onSizeChanged;
  final Function(bool)? onCollapsedChanged;

  const LlmPresetWidget({
    Key? key,
    this.initialSize = const Size(320, 280), // Adjusted default size
    this.isInitiallyCollapsed = false,
    this.onSizeChanged,
    this.onCollapsedChanged,
  }) : super(key: key);

  @override
  State<LlmPresetWidget> createState() => _LlmPresetWidgetState();
}

class _LlmPresetWidgetState extends State<LlmPresetWidget> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isGenerating = false;
  String _statusMessage = '';
  late bool _isCollapsed;
  late Size _currentSize;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isInitiallyCollapsed;
    _currentSize = widget.initialSize;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _generatePresetViaFirebase() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a sound description.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Generating preset...';
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('generatePreset');
      final HttpsCallableResult result = await callable.call(
        <String, dynamic>{'description': description},
      );

      final Map<String, dynamic>? parameters = result.data as Map<String, dynamic>?;
      
      if (parameters != null && parameters.isNotEmpty) {
        final audioEngine = Provider.of<AudioEngine>(context, listen: false);

        // Define mapping from LLM keys to AudioEngine.loadPreset keys
        const Map<String, String> llmToEngineKeyMap = {
          'filterCutoff': 'cutoff',       // Example: LLM returns 'filterCutoff', AudioEngine expects 'cutoff'
          'filterResonance': 'resonance',
          'attackTime': 'attack',
          'decayTime': 'decay',
          'sustainLevel': 'sustain',     // Assuming AudioEngine supports 'sustain'
          'releaseTime': 'release',     // Assuming AudioEngine supports 'release'
          'reverbMix': 'reverb',
          'delayTime': 'delay',         // Assuming AudioEngine supports 'delay'
          'masterVolume': 'volume',       // Example for master volume
          // Add all other necessary mappings here
          // 'oscillatorType': 'oscType',
          // 'lfoRate': 'lfoRate',
        };

        Map<String, dynamic> enginePreset = {};
        parameters.forEach((llmKey, value) {
          if (llmToEngineKeyMap.containsKey(llmKey)) {
            final engineKey = llmToEngineKeyMap[llmKey]!;
            if (value is num) {
              enginePreset[engineKey] = value.toDouble();
              print("[LlmPresetWidget] Mapping LLM param: $llmKey to Engine param: $engineKey with value: ${value.toDouble()}");
            } else {
              print("[LlmPresetWidget] Warning: Invalid value type for param: $llmKey, value: $value. Expected number.");
            }
          } else {
            print("[LlmPresetWidget] Warning: Unmapped LLM param: $llmKey, value: $value. Not included in preset.");
          }
        });
        
        if (enginePreset.isNotEmpty) {
          await audioEngine.loadPreset(enginePreset);
          setState(() {
            _statusMessage = 'Preset applied successfully!';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_statusMessage),
              backgroundColor: HolographicTheme.successEnergy.withOpacity(0.8),
            ),
          );
        } else {
          setState(() {
            _statusMessage = 'No valid parameters found to apply after mapping.';
          });
        }

      } else {
        setState(() {
          _statusMessage = 'Failed to get parameters from LLM. Response was empty or invalid.';
        });
      }
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Functions Exception: ${e.code} - ${e.message}');
      setState(() {
        _statusMessage = 'Error: ${e.message ?? "Cloud function error."}';
      });
    } catch (e) {
      print('Generic Exception: $e');
      setState(() {
        _statusMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
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
          Text('LLM PRESET GENERATOR', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryEnergy, fontSize: 12, glowIntensity: 0.4)),
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

  Widget _buildContentUI() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min, // Important for SingleChildScrollView
        children: [
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            minLines: 1,
            style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Describe sound (e.g., "bright synth lead")...',
              hintStyle: HolographicTheme.createHolographicText(energyColor: HolographicTheme.secondaryEnergy.withOpacity(0.6), fontSize: 14, glowIntensity: 0.2),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: HolographicTheme.secondaryEnergy.withOpacity(0.7), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: HolographicTheme.secondaryEnergy, width: 1.5),
              ),
              filled: true,
              fillColor: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.7),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          _isGenerating
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(HolographicTheme.accentEnergy),
                      strokeWidth: 2.5,
                    ),
                  ))
              : ElevatedButton(
                  onPressed: _generatePresetViaFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HolographicTheme.accentEnergy.withOpacity(HolographicTheme.activeTransparency * 1.8),
                    foregroundColor: Colors.black, // Text color for contrast
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: HolographicTheme.accentEnergy.withOpacity(0.8), width: 1),
                    ),
                  ).copyWith(
                     overlayColor: MaterialStateProperty.all(HolographicTheme.accentEnergy.withOpacity(0.4)),
                  ),
                  child: Text(
                    'GENERATE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, shadows: [Shadow(blurRadius: 2, color: Colors.black.withOpacity(0.15))]),
                  ),
                ),
          if (_statusMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _statusMessage,
              style: HolographicTheme.createHolographicText(
                energyColor: _statusMessage.startsWith('Error:') || _statusMessage.startsWith('Failed')
                    ? HolographicTheme.warningEnergy
                    : HolographicTheme.successEnergy,
                fontSize: 11,
                glowIntensity: 0.4
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
           Wrap(
              spacing: 6,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _ExampleChip(label: '8-bit Blip', onTap: () => _descriptionController.text = '8-bit blip sound'),
                _ExampleChip(label: 'Deep Sub Bass', onTap: () => _descriptionController.text = 'Deep sub bass, smooth'),
                _ExampleChip(label: 'Sci-fi Drone', onTap: () => _descriptionController.text = 'Sci-fi drone, evolving slowly'),
              ],
            ),
        ],
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
         color: HolographicTheme.primaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 0.4), // Slightly more opaque than other widgets
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!_isCollapsed) Expanded(child: SingleChildScrollView(child: _buildContentUI())),
        ],
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ExampleChip({ required this.label, required this.onTap });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: TextStyle(fontSize: 10, color: HolographicTheme.secondaryEnergy.withOpacity(0.9))),
      onPressed: onTap,
      backgroundColor: HolographicTheme.secondaryEnergy.withOpacity(HolographicTheme.widgetTransparency * 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: HolographicTheme.secondaryEnergy.withOpacity(0.5), width: 0.5)
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}