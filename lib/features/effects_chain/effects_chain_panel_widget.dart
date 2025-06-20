import 'package:flutter/material.dart';
import 'effects_chain_types.dart';
import '../../ui/holographic/holographic_theme.dart'; // Assuming this path is correct

class EffectsChainPanelWidget extends StatefulWidget {
  const EffectsChainPanelWidget({Key? key}) : super(key: key);

  @override
  _EffectsChainPanelWidgetState createState() => _EffectsChainPanelWidgetState();
}

class _EffectsChainPanelWidgetState extends State<EffectsChainPanelWidget> {
  List<EffectUnitConfig> _effectsChain = [
    EffectUnitConfig(id: 'eff1', name: 'Space Verb', type: EffectType.reverb, initialParams: {'mix': 0.5, 'decay': 0.7}),
    EffectUnitConfig(id: 'eff2', name: 'Echoes', type: EffectType.delay, bypass: true, initialParams: {'time': 300, 'feedback': 0.4}),
    EffectUnitConfig(id: 'eff3', name: 'Low Pass', type: EffectType.filter, initialParams: {'cutoff': 8000, 'resonance': 0.2}),
    EffectUnitConfig(id: 'eff4', name: 'Fuzz Box', type: EffectType.distortion, initialParams: {'drive': 0.8, 'tone': 0.6}),
  ];
  String? _selectedEffectId; // To track which effect's params to show

  // Method to build each effect slot in the chain
  Widget _buildEffectSlot(EffectUnitConfig effect) {
    bool isSelected = _selectedEffectId == effect.id;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: isSelected
               ? HolographicTheme.accentEnergy.withOpacity(0.25)
               : HolographicTheme.primaryEnergy.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: isSelected
                 ? HolographicTheme.accentEnergy.withOpacity(0.8)
                 : HolographicTheme.secondaryEnergy.withOpacity(0.5),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: HolographicTheme.accentEnergy.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1,
          )
        ] : null,
      ),
      child: Row(
        children: [
          // Drag Handle (conceptual)
          Icon(Icons.drag_indicator, color: HolographicTheme.secondaryText.withOpacity(0.7), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(effect.name, style: HolographicTheme.createHolographicText(fontSize: 13, glowIntensity: 0.2, energyColor: HolographicTheme.primaryText)),
                Text(effect.type.displayName, style: HolographicTheme.createHolographicText(fontSize: 10, glowIntensity: 0.1, energyColor: HolographicTheme.secondaryText)),
              ],
            ),
          ),
          Text('Bypass', style: HolographicTheme.createHolographicText(fontSize: 10, energyColor: HolographicTheme.secondaryText)),
          Switch(
            value: effect.bypass,
            onChanged: (value) {
              setState(() {
                effect.bypass = value;
                // Here you would also call the audio engine to bypass/enable the effect
              });
            },
            activeColor: HolographicTheme.accentEnergy,
            inactiveThumbColor: HolographicTheme.secondaryText.withOpacity(0.5),
            inactiveTrackColor: Colors.grey.withOpacity(0.2),
          ),
          IconButton(
            icon: Icon(Icons.settings_ethernet, color: HolographicTheme.primaryText.withOpacity(isSelected ? 1.0 : 0.6), size: 18),
            tooltip: "Show Parameters",
            onPressed: () {
              setState(() {
                if (_selectedEffectId == effect.id) {
                  _selectedEffectId = null; // Toggle off if already selected
                } else {
                  _selectedEffectId = effect.id;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, color: HolographicTheme.warningEnergy.withOpacity(0.7), size: 18),
            tooltip: "Remove Effect",
            onPressed: () {
              setState(() {
                _effectsChain.removeWhere((e) => e.id == effect.id);
                if (_selectedEffectId == effect.id) {
                  _selectedEffectId = null;
                }
                // Call audio engine to remove effect
              });
            },
          ),
          // Conceptual Move Up/Down Icons
          // Icon(Icons.arrow_upward, color: HolographicTheme.secondaryText.withOpacity(0.5), size: 16),
          // Icon(Icons.arrow_downward, color: HolographicTheme.secondaryText.withOpacity(0.5), size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    EffectUnitConfig? currentEffect = _selectedEffectId == null
        ? null
        : _effectsChain.firstWhere((e) => e.id == _selectedEffectId, orElse: () => _effectsChain.first); // Fallback, should not happen if ID is valid

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(HolographicTheme.widgetTransparency * 0.5), // Panel background
        borderRadius: BorderRadius.circular(HolographicTheme.cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Effects List
          Expanded(
            flex: 2, // Give more space to the list
            child: ListView.builder(
              itemCount: _effectsChain.length,
              itemBuilder: (context, index) {
                return _buildEffectSlot(_effectsChain[index]);
              },
            ),
          ),
          // "Add Effect" Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: HolographicTheme.primaryText),
              label: Text('Add Effect', style: HolographicTheme.createHolographicText(energyColor: HolographicTheme.primaryText)),
              style: ElevatedButton.styleFrom(
                backgroundColor: HolographicTheme.accentEnergy.withOpacity(0.3),
                foregroundColor: HolographicTheme.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(HolographicTheme.cornerRadiusS),
                  side: BorderSide(color: HolographicTheme.accentEnergy.withOpacity(0.7)),
                ),
              ),
              onPressed: () {
                // Placeholder: Show a dialog or navigate to an effect picker
                // For now, just add a new dummy effect
                setState(() {
                  String newId = 'eff${_effectsChain.length + 1}_${DateTime.now().millisecondsSinceEpoch}';
                  _effectsChain.add(EffectUnitConfig(id: newId, name: 'New Effect', type: EffectType.values[(_effectsChain.length) % EffectType.values.length]));
                });
              },
            ),
          ),
          // Placeholder for Selected Effect's Parameters
          if (_selectedEffectId != null && currentEffect != null)
            Expanded(
              flex: 1, // Give less space to params for now
              child: Container(
                margin: const EdgeInsets.only(top: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: HolographicTheme.primaryEnergy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(HolographicTheme.cornerRadiusS),
                  border: Border.all(color: HolographicTheme.accentEnergy.withOpacity(0.5)),
                ),
                child: SingleChildScrollView( // In case params get long
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        'Parameters for: ${currentEffect.name} (${currentEffect.type.displayName})',
                        style: HolographicTheme.createHolographicText(fontSize: 14, energyColor: HolographicTheme.accentEnergy),
                      ),
                      const SizedBox(height: 10),
                      // Display actual parameters (conceptual for now)
                      ...currentEffect.params.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${entry.key}:', style: HolographicTheme.createHolographicText(fontSize: 12)),
                              Text('${entry.value}', style: HolographicTheme.createHolographicText(fontSize: 12, energyColor: HolographicTheme.secondaryText)),
                              // In a real UI, this would be a slider, knob, or dropdown
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      Text(
                        "Actual parameter controls (knobs, sliders) would go here.",
                        style: HolographicTheme.createHolographicText(fontSize: 10, energyColor: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
