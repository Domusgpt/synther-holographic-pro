import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';

/// Test panel for Phase 5 (LFO) and Phase 6 (Effects) visual integration
/// This provides UI controls to test all the new audio-visual mappings
class VisualEffectsTestPanel extends StatelessWidget {
  const VisualEffectsTestPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader('🎛️ Visual Effects Test Panel'),
            const SizedBox(height: 16),
            _buildHeader('Phase 6: Effects', fontSize: 16),
            const _EffectsSection(),
            const SizedBox(height: 24),
            _buildHeader('Phase 5: LFO Modulation', fontSize: 16),
            const _LFOSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text, {double fontSize = 20}) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.cyan,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _EffectsSection extends StatelessWidget {
  const _EffectsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final synth = context.watch<SynthParametersModel>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEffectRow(
          context,
          'Chorus → Interference',
          synth.chorusEnabled,
          synth.chorusMix,
          (enabled) => synth.setChorusEnabled(enabled),
          (value) => synth.setChorusMix(value),
          'Wave patterns, moiré effects',
        ),
        _buildEffectRow(
          context,
          'Distortion → Crystalline',
          synth.distortionEnabled,
          synth.distortionAmount,
          (enabled) => synth.setDistortionEnabled(enabled),
          (value) => synth.setDistortionAmount(value),
          'Angular facets, shattering',
        ),
        _buildEffectRow(
          context,
          'Phaser → Helix',
          synth.phaserEnabled,
          synth.phaserDepth,
          (enabled) => synth.setPhaserEnabled(enabled),
          (value) => synth.setPhaserDepth(value),
          'Spiraling rotation',
        ),
        _buildEffectRow(
          context,
          'Compressor → Breathing',
          synth.compressorEnabled,
          synth.compressorRatio / 20.0, // Normalize to 0-1
          (enabled) => synth.setCompressorEnabled(enabled),
          (value) => synth.setCompressorRatio(value * 20.0),
          'Pulsing scale effect',
        ),
        _buildEffectRow(
          context,
          'Flanger → Ribbon',
          synth.flangerEnabled,
          synth.flangerDepth,
          (enabled) => synth.setFlangerEnabled(enabled),
          (value) => synth.setFlangerDepth(value),
          'Undulating surfaces',
        ),
      ],
    );
  }

  Widget _buildEffectRow(
    BuildContext context,
    String name,
    bool enabled,
    double value,
    Function(bool) onEnabledChanged,
    Function(double) onValueChanged,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 200,
                child: Row(
                  children: [
                    Switch(
                      value: enabled,
                      onChanged: onEnabledChanged,
                      activeColor: Colors.cyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: enabled ? Colors.cyan : Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: enabled ? onValueChanged : null,
                  activeColor: Colors.cyan,
                  inactiveColor: Colors.grey.withOpacity(0.3),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LFOSection extends StatelessWidget {
  const _LFOSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final synth = context.watch<SynthParametersModel>();

    return Column(
      children: [
        _buildLFORow(context, synth, 0, 'LFO 1 → Rotation Speed', '0.5x to 2.0x rotation'),
        _buildLFORow(context, synth, 1, 'LFO 2 → Morph Factor', 'Geometry deformation'),
        _buildLFORow(context, synth, 2, 'LFO 3 → Color Shift', 'Hue spectrum cycling'),
        _buildLFORow(context, synth, 3, 'LFO 4 → Grid Density', 'Breathing density (6-16)'),
      ],
    );
  }

  Widget _buildLFORow(
    BuildContext context,
    SynthParametersModel synth,
    int index,
    String name,
    String description,
  ) {
    final value = synth.getLFOValue(index);
    final rate = synth.getLFORate(index);
    final waveform = synth.getLFOWaveform(index);
    final enabled = synth.getLFOEnabled(index);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: enabled,
                onChanged: (v) => synth.setLFOEnabled(index, v),
                activeColor: Colors.purple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: enabled ? Colors.cyan : Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: DropdownButton<String>(
                  value: waveform,
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: ['sine', 'triangle', 'square', 'sawtooth', 'random']
                      .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                      .toList(),
                  onChanged: (w) => synth.setLFOWaveform(index, w!),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Value:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: enabled ? null : (v) => synth.setLFOValue(index, v), // Disable slider when auto-animating
                  activeColor: Colors.cyan,
                  inactiveColor: Colors.grey.withOpacity(0.3),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 108),
              const Text('Rate:', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: rate,
                  min: 0.1,
                  max: 10.0,
                  onChanged: (r) => synth.setLFORate(index, r),
                  activeColor: Colors.purple,
                ),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  '${rate.toStringAsFixed(1)} Hz',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              description,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
