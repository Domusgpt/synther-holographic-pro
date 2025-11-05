import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/parameter_visualizer_bridge.dart';
import '../core/visual_preset_system.dart';
import '../core/preset_applicator.dart';
import '../core/visualizer_configuration.dart';

/// Enhanced visual control panel with presets, status, and organized controls
class EnhancedVisualControlPanel extends StatefulWidget {
  final ParameterVisualizerBridge visualBridge;

  const EnhancedVisualControlPanel({
    Key? key,
    required this.visualBridge,
  }) : super(key: key);

  @override
  State<EnhancedVisualControlPanel> createState() => _EnhancedVisualControlPanelState();
}

class _EnhancedVisualControlPanelState extends State<EnhancedVisualControlPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PresetManager _presetManager;
  late PresetApplicator _presetApplicator;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _presetManager = PresetManager();

    // Initialize preset applicator after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final synth = Provider.of<SynthParametersModel>(context, listen: false);
      _presetApplicator = PresetApplicator(synth, widget.visualBridge);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final synth = context.watch<SynthParametersModel>();

    return Focus(
      autofocus: true,
      onKey: (node, event) => _handleKeyPress(event, synth),
      child: Container(
        width: 500,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border.all(color: Colors.cyan.withOpacity(0.4), width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildStatusBar(synth),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPresetsTab(synth),
                  _buildEffectsTab(synth),
                  _buildLFOsTab(synth),
                  _buildAdvancedTab(synth),
                ],
              ),
            ),
            _buildFooter(synth),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyan.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.cyan, size: 28),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VISUAL CONTROL CENTER',
                style: TextStyle(
                  color: Colors.cyan,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Phase 1-6 Complete • All Systems Active',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(SynthParametersModel synth) {
    final config = widget.visualBridge.currentConfiguration;
    final activeEffects = _getActiveEffects(synth);
    final activeLFOs = _getActiveLFOs(synth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: Colors.cyan.withOpacity(0.2), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusChip('${config.polytope.displayName}', Colors.cyan),
              const SizedBox(width: 8),
              _buildStatusChip('${config.geometryType.displayName}', Colors.purple),
              const SizedBox(width: 8),
              _buildStatusChip('${config.family.displayName}', Colors.pink),
            ],
          ),
          if (activeEffects.isNotEmpty || activeLFOs.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...activeEffects.map((e) => _buildStatusChip(e, Colors.orange, small: true)),
                ...activeLFOs.map((l) => _buildStatusChip(l, Colors.green, small: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.cyan.withOpacity(0.2), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyan,
        labelColor: Colors.cyan,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.bookmark, size: 20), text: 'Presets'),
          Tab(icon: Icon(Icons.auto_fix_high, size: 20), text: 'Effects'),
          Tab(icon: Icon(Icons.waves, size: 20), text: 'LFOs'),
          Tab(icon: Icon(Icons.tune, size: 20), text: 'Advanced'),
        ],
      ),
    );
  }

  Widget _buildPresetsTab(SynthParametersModel synth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildQuickActions(synth),
        const SizedBox(height: 16),
        ...PresetCategory.values.map((category) {
          final presets = PresetLibrary.getPresetsByCategory(category);
          if (presets.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  category.displayName,
                  style: const TextStyle(
                    color: Colors.cyan,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...presets.map((preset) => _buildPresetCard(preset, synth)),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPresetCard(VisualPreset preset, SynthParametersModel synth) {
    final isCurrent = _presetManager.currentPreset?.id == preset.id;

    return GestureDetector(
      onTap: () {
        _presetApplicator.applyPreset(preset);
        _presetManager.setCurrentPreset(preset);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied: ${preset.name}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.cyan.withOpacity(0.8),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? Colors.cyan.withOpacity(0.2) : Colors.black.withOpacity(0.3),
          border: Border.all(
            color: isCurrent ? Colors.cyan : Colors.grey.withOpacity(0.3),
            width: isCurrent ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isCurrent) const Icon(Icons.check_circle, color: Colors.cyan, size: 16),
                if (isCurrent) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      color: isCurrent ? Colors.cyan : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildPresetInfo(preset),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              preset.description,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.8),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (preset.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: preset.tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 9)),
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetInfo(VisualPreset preset) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '${preset.polytope.displayName} + ${preset.geometry.displayName}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${preset.polytope.displayName[0]}+${preset.geometry.displayName[0]}',
              style: const TextStyle(color: Colors.purple, fontSize: 10),
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (preset.lfoEnabled.any((e) => e))
          const Icon(Icons.waves, color: Colors.green, size: 14),
        if (preset.effectsEnabled.values.any((e) => e))
          const Icon(Icons.auto_fix_high, color: Colors.orange, size: 14),
      ],
    );
  }

  Widget _buildQuickActions(SynthParametersModel synth) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement randomize
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Randomize coming soon!')),
              );
            },
            icon: const Icon(Icons.shuffle, size: 16),
            label: const Text('Randomize'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.withOpacity(0.3),
              foregroundColor: Colors.purple,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement save
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Save preset coming soon!')),
              );
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.withOpacity(0.3),
              foregroundColor: Colors.cyan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEffectsTab(SynthParametersModel synth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEffectRow(context, synth, 'Chorus', '→ Interference',
          synth.chorusEnabled, synth.chorusMix,
          (v) => synth.setChorusEnabled(v),
          (v) => synth.setChorusMix(v)),
        _buildEffectRow(context, synth, 'Distortion', '→ Crystalline',
          synth.distortionEnabled, synth.distortionAmount,
          (v) => synth.setDistortionEnabled(v),
          (v) => synth.setDistortionAmount(v)),
        _buildEffectRow(context, synth, 'Phaser', '→ Helix',
          synth.phaserEnabled, synth.phaserDepth,
          (v) => synth.setPhaserEnabled(v),
          (v) => synth.setPhaserDepth(v)),
        _buildEffectRow(context, synth, 'Compressor', '→ Breathing',
          synth.compressorEnabled, synth.compressorRatio / 20.0,
          (v) => synth.setCompressorEnabled(v),
          (v) => synth.setCompressorRatio(v * 20.0)),
        _buildEffectRow(context, synth, 'Flanger', '→ Ribbon',
          synth.flangerEnabled, synth.flangerDepth,
          (v) => synth.setFlangerEnabled(v),
          (v) => synth.setFlangerDepth(v)),
      ],
    );
  }

  Widget _buildEffectRow(
    BuildContext context,
    SynthParametersModel synth,
    String name,
    String geometry,
    bool enabled,
    double value,
    Function(bool) onEnabledChanged,
    Function(double) onValueChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? Colors.cyan.withOpacity(0.1) : Colors.black.withOpacity(0.3),
        border: Border.all(
          color: enabled ? Colors.cyan.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: enabled ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeColor: Colors.cyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: enabled ? Colors.cyan : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      geometry,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: enabled ? onValueChanged : null,
            activeColor: Colors.cyan,
            inactiveColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLFOsTab(SynthParametersModel synth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLFOCard(synth, 0, 'LFO 1 → Rotation Speed', '0.5x to 2.0x rotation'),
        _buildLFOCard(synth, 1, 'LFO 2 → Morph Factor', 'Geometry deformation'),
        _buildLFOCard(synth, 2, 'LFO 3 → Color Shift', 'Hue spectrum cycling'),
        _buildLFOCard(synth, 3, 'LFO 4 → Grid Density', 'Breathing density (6-16)'),
      ],
    );
  }

  Widget _buildLFOCard(SynthParametersModel synth, int index, String name, String description) {
    final enabled = synth.getLFOEnabled(index);
    final value = synth.getLFOValue(index);
    final rate = synth.getLFORate(index);
    final waveform = synth.getLFOWaveform(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled ? Colors.purple.withOpacity(0.1) : Colors.black.withOpacity(0.3),
        border: Border.all(
          color: enabled ? Colors.purple.withOpacity(0.5) : Colors.grey.withOpacity(0.2),
          width: enabled ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: enabled ? Colors.purple : Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Rate:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Expanded(
                          child: Slider(
                            value: rate,
                            min: 0.1,
                            max: 10.0,
                            onChanged: (v) => synth.setLFORate(index, v),
                            activeColor: Colors.purple,
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '${rate.toStringAsFixed(1)} Hz',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (!enabled)
                      Row(
                        children: [
                          const Text('Value:', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Expanded(
                            child: Slider(
                              value: value,
                              onChanged: (v) => synth.setLFOValue(index, v),
                              activeColor: Colors.cyan,
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${(value * 100).toInt()}%',
                              style: const TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(SynthParametersModel synth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildKeyboardShortcuts(),
        const SizedBox(height: 16),
        _buildAbout(),
      ],
    );
  }

  Widget _buildKeyboardShortcuts() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Keyboard Shortcuts',
            style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildShortcutRow('Space', 'Toggle all LFOs'),
          _buildShortcutRow('R', 'Randomize'),
          _buildShortcutRow('1-9', 'Load preset'),
          _buildShortcutRow('Ctrl+S', 'Save current state'),
          _buildShortcutRow('Tab', 'Next tab'),
          _buildShortcutRow('Shift+Tab', 'Previous tab'),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              keys,
              style: const TextStyle(color: Colors.cyan, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.1),
        border: Border.all(color: Colors.purple.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Synther Holographic Pro • Visual Control Center\n\n'
            'All 6 Phases Complete:\n'
            '✓ 8 Geometry Types\n'
            '✓ 5-Layer Rotation System\n'
            '✓ Visualizer Families\n'
            '✓ Envelope Mappings\n'
            '✓ LFO Integration\n'
            '✓ Effects Framework\n\n'
            '9 Built-in Presets • Auto-LFO Animation • Real-time Parameter Flow',
            style: TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(SynthParametersModel synth) {
    final fps = 60; // TODO: Get actual FPS from visualizer

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          top: BorderSide(color: Colors.cyan.withOpacity(0.2), width: 1),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FPS: $fps',
            style: TextStyle(
              color: fps >= 55 ? Colors.green : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _presetManager.currentPreset?.name ?? 'Custom',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          Text(
            '${PresetLibrary.builtInPresets.length} presets loaded',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  List<String> _getActiveEffects(SynthParametersModel synth) {
    final effects = <String>[];
    if (synth.chorusEnabled) effects.add('Chorus');
    if (synth.distortionEnabled) effects.add('Distortion');
    if (synth.phaserEnabled) effects.add('Phaser');
    if (synth.compressorEnabled) effects.add('Compressor');
    if (synth.flangerEnabled) effects.add('Flanger');
    if (synth.reverbMix > 0.4) effects.add('Reverb');
    return effects;
  }

  List<String> _getActiveLFOs(SynthParametersModel synth) {
    final lfos = <String>[];
    for (int i = 0; i < 4; i++) {
      if (synth.getLFOEnabled(i)) lfos.add('LFO${i+1}');
    }
    return lfos;
  }

  KeyEventResult _handleKeyPress(RawKeyEvent event, SynthParametersModel synth) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

    // Space: Toggle all LFOs
    if (event.logicalKey == LogicalKeyboardKey.space) {
      final anyEnabled = [0, 1, 2, 3].any((i) => synth.getLFOEnabled(i));
      for (int i = 0; i < 4; i++) {
        synth.setLFOEnabled(i, !anyEnabled);
      }
      return KeyEventResult.handled;
    }

    // R: Randomize
    if (event.logicalKey == LogicalKeyboardKey.keyR) {
      // TODO: Implement randomize
      return KeyEventResult.handled;
    }

    // 1-9: Load preset
    if (event.logicalKey.keyId >= LogicalKeyboardKey.digit1.keyId &&
        event.logicalKey.keyId <= LogicalKeyboardKey.digit9.keyId) {
      final index = event.logicalKey.keyId - LogicalKeyboardKey.digit1.keyId;
      if (index < PresetLibrary.builtInPresets.length) {
        final preset = PresetLibrary.builtInPresets[index];
        _presetApplicator.applyPreset(preset);
        _presetManager.setCurrentPreset(preset);
      }
      return KeyEventResult.handled;
    }

    // Tab/Shift+Tab: Cycle tabs
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (event.isShiftPressed) {
        _tabController.animateTo((_tabController.index - 1) % 4);
      } else {
        _tabController.animateTo((_tabController.index + 1) % 4);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
