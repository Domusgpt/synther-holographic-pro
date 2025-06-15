# MIDI UI Mapping Design Proposal

This document outlines an initial design for how MIDI messages can be used to control visual properties and states of UI elements within the Synther application.

## 1. Goals

- Allow external MIDI controllers to manipulate the UI layout (panel visibility, position, size, collapsed state).
- Allow MIDI messages to change visual attributes of specific UI elements (e.g., color, intensity).
- Provide a flexible system that can be expanded in the future.

## 2. Proposed MIDI Mapping Scheme

We will use MIDI Control Change (CC) messages on a dedicated MIDI channel for UI control.

**Dedicated MIDI Channel:**
- **Channel 16** (by convention, often used for less common messages) will be reserved for UI control messages. Messages on other channels will be processed for sound parameters as usual.

**Targeting UI Elements (Panels):**
- Each draggable panel (`_PanelConfig.id`) will need to be assignable a **UI MIDI Target ID** (e.g., an integer from 0-127). This mapping could be done in a new settings section in the Flutter app. For now, we can assume a default mapping based on panel order or a predefined scheme.
- **CC 0 (Bank Select MSB - traditionally): Used as `UI_TARGET_PANEL_ID_MSB`**. (Value 0-127)
- **CC 32 (Bank Select LSB - traditionally): Used as `UI_TARGET_PANEL_ID_LSB`**. (Value 0-127)
    - This allows for `128*128 = 16384` targetable UI elements if needed, though initially we'll use only LSB for up to 128 panels. For simplicity in the first implementation, we might only use `CC 32` to select one of the first 128 panels based on its value.

**Controlling Properties of the Selected Panel:**
Once a panel is targeted using `UI_TARGET_PANEL_ID_LSB` (and MSB if implemented), subsequent CC messages on Channel 16 will affect its properties:

-   **CC 102: `UI_VISIBILITY`**
    -   Value 0-63: Hide panel (set `isVisibleInWorkspace = false`)
    -   Value 64-127: Show panel (set `isVisibleInWorkspace = true`)
-   **CC 103: `UI_COLLAPSED_STATE`**
    -   Value 0-63: Expand panel (set `isCollapsed = false`)
    -   Value 64-127: Collapse panel (set `isCollapsed = true`)
-   **CC 104: `UI_POSITION_X`** (Coarse)
    -   Value 0-127: Maps to the panel's horizontal screen position (e.g., 0 = left edge, 127 = right edge). Needs scaling.
-   **CC 105: `UI_POSITION_Y`** (Coarse)
    -   Value 0-127: Maps to the panel's vertical screen position (e.g., 0 = top edge, 127 = bottom edge). Needs scaling.
-   **CC 106: `UI_SIZE_WIDTH`** (Coarse)
    -   Value 0-127: Maps to the panel's width. Needs scaling.
-   **CC 107: `UI_SIZE_HEIGHT`** (Coarse)
    -   Value 0-127: Maps to the panel's height. Needs scaling.
-   **CC 108: `UI_VISUAL_THEME_VARIATION`** (Conceptual)
    -   Value 0-127: Could map to different pre-defined visual styles or intensity levels for the panel's theme (e.g., different glow colors, border styles). This is more advanced and for future consideration.

**Special Actions (using unused CCs):**
- **CC 109: `UI_CYCLE_NEXT_PANEL_TARGET`**: Increments the internally selected `UI_TARGET_PANEL_ID`. (Value irrelevant).
- **CC 110: `UI_TOGGLE_VAULT`**: Shows/Hides the vault area itself. (Value irrelevant).


## 3. Implementation Considerations

-   **Native Engine (`SynthEngine`)**:
    -   Needs to be able to receive all MIDI messages on Channel 16.
    -   It will maintain an internal `currentUiTargetPanelId`.
    -   When a `UI_TARGET_PANEL_ID_LSB` (CC 32 on Ch 16) message is received, it updates `currentUiTargetPanelId`.
    -   When other UI-mapped CCs are received on Channel 16, the engine will package the `currentUiTargetPanelId` and the specific CC number + value into a new type of message to be sent to Flutter via a dedicated FFI callback.
-   **FFI Bridge**:
    -   A new FFI callback function (e.g., `uiControlMidiCallback(int targetPanelId, int ccNumber, int ccValue)`) needs to be defined and exposed.
-   **Flutter Application**:
    -   The Flutter side will register a Dart function for this new FFI callback.
    -   This Dart function will receive the `targetPanelId`, `ccNumber`, and `ccValue`.
    -   It will then update the state of the corresponding `_PanelConfig` object in `_InteractiveDraggableSynthState` (e.g., changing its `position`, `size`, `isCollapsed`, `isVisibleInWorkspace` properties).
    -   This state change in Flutter will cause the UI to rebuild and reflect the MIDI-driven changes.
    -   A mapping from `targetPanelId` (integer) to the actual `_PanelConfig.id` (string) will be needed in Flutter.

## 4. Future Expansions

-   Finer control over X/Y/Width/Height using MSB/LSB for 14-bit values if needed.
-   NRPN messages for more detailed control of specific visual attributes of individual controls *within* a panel.
-   SysEx messages for saving/loading entire UI layouts or MIDI mapping presets.
-   Using MIDI notes to trigger show/hide of specific panels.

This initial design provides a basic framework. The exact CC numbers are suggestions and can be adjusted. The key is the concept of a dedicated UI channel, a way to target panels, and then CCs to modify their common properties.
