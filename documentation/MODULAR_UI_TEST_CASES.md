# Modular UI and MIDI Control - Conceptual Test Cases

## I. Draggable, Resizable, Collapsible Panels

1.  **Drag Panel**:
    -   Verify a panel can be dragged freely around the workspace by its header.
    -   Verify panel's normalized position (`normX`, `normY`) is clamped such that a small portion (e.g., header) always remains on screen (e.g., `normX` between approx -0.75 to 0.9, `normY` between approx 0.0 to 0.9). Test dragging to all edges.
    -   Verify dragging one panel does not affect other panels' positions or states.
2.  **Resize Panel**:
    -   Verify a panel can be resized using its bottom-right resize handle.
    -   Verify resizing has reasonable minimum pixel limits (e.g., width not less than 150px, height not less than 100px) and maximum limits (e.g., not exceeding screen dimensions or a large sensible cap like 800x600).
    -   Verify content within the panel (`childWidget`) adapts or clips correctly to the new size.
    -   Verify normalized width/height (`normWidth`, `normHeight`) are updated and reflect the resize.
3.  **Collapse/Expand Panel**:
    -   Target a panel. Tap the collapse/expand icon in its header.
    -   Verify the panel shrinks to show only its header (approx. 40px height) when collapsed.
    -   Verify the panel restores to its previous size when expanded.
    -   Verify the collapse/expand icon changes appropriately.
    -   Verify haptic feedback occurs: `HapticFeedback.lightImpact()` on collapse, `HapticFeedback.mediumImpact()` on expand.
4.  **Close to Vault / Show from Vault**:
    -   Target a visible panel. Tap the "close" (hide/visibility_off) icon in its header.
    -   Verify `panel.isVisibleInWorkspace` becomes `false`.
    -   Verify the panel disappears from the main workspace.
    -   Verify the panel's title appears as an `ActionChip` or button in the "Vault" area.
    -   Verify haptic feedback (`HapticFeedback.mediumImpact()`) occurs when closing.
    -   Tap the panel's representation in the vault.
    -   Verify `panel.isVisibleInWorkspace` becomes `true`.
    -   Verify the panel reappears in the workspace at its last known position and size.
    -   Verify haptic feedback (`HapticFeedback.mediumImpact()`) occurs when showing from vault.
5.  **Vault Visibility (MIDI Controlled)**:
    -   (Requires MIDI setup) Send CC 110 on Channel 16.
    -   Verify the vault area (`_buildVaultArea` rendering based on `_staticIsVaultAreaVisible`) toggles its visibility.
    -   Test interactions with multiple panels and the vault (e.g., closing all panels, verifying all appear in vault; restoring some).
6.  **Overlapping Panels**:
    -   Verify that panels can overlap when dragged.
    -   (Bringing a panel to the front on interaction is an advanced feature, not currently implemented, but basic overlap should be functional).

## II. MIDI Control over UI Elements

(Requires a MIDI controller or MIDI sending software configured to send messages on Channel 16 as per `documentation/MIDI_UI_MAPPING_DESIGN.md`)

1.  **Target Panel Selection**:
    -   Send CC 32 (UI_TARGET_PANEL_ID_LSB) on Ch 16 with value X (e.g., 0, 1, 2).
    -   Verify subsequent UI CCs affect the panel at index X in the `_InteractiveDraggableSynthState._panels` list. (Confirm with logging or by observing UI changes).
    -   Send CC 109 (UI_CYCLE_NEXT_PANEL_TARGET) on Ch 16. Verify internal `currentUiTargetPanelId_` in the C++ engine increments (confirm with logging). Test wrapping around (e.g., from max index back to 0).
2.  **Panel Visibility (CC 102)**:
    -   Target a panel (e.g., panel at index 0). Send CC 102 with value 30 (0-63 range). Verify the targeted panel hides (moves to vault).
    -   Target the same panel (or re-target if needed). Send CC 102 with value 90 (64-127 range). Verify panel shows.
3.  **Panel Collapse State (CC 103)**:
    -   Target a visible, expanded panel. Send CC 103 with value 90 (64-127 range). Verify panel collapses.
    -   Target the same panel. Send CC 103 with value 30 (0-63 range). Verify panel expands.
4.  **Panel Position (CC 104, 105)**:
    -   Target a panel.
    -   Send CC 104 (X pos) with value 0. Verify panel moves to the left edge (or near, considering normX clamp of -0.1).
    -   Send CC 104 with value 127. Verify panel moves to the right edge (or near, considering normX clamp of 0.9).
    -   Send CC 105 (Y pos) with value 0. Verify panel moves to the top edge (normY clamp 0.0).
    -   Send CC 105 with value 127. Verify panel moves to the bottom edge (or near, considering normY clamp of 0.9).
    -   Verify panel movement is scaled to screen dimensions.
5.  **Panel Size (CC 106, 107)**:
    -   Target a panel.
    -   Send CC 106 (Width) with value 0. Verify panel width shrinks to its minimum normalized size (e.g., 0.15 of screen).
    -   Send CC 106 with value 127. Verify panel width expands to its maximum normalized size (e.g., 1.0 of screen).
    -   Send CC 107 (Height) with value 0. Verify panel height shrinks to its minimum (e.g., 0.1 of screen).
    -   Send CC 107 with value 127. Verify panel height expands to its maximum (e.g., 1.0 of screen).
6.  **Vault Toggle (CC 110)**:
    -   Send CC 110 (value irrelevant). Verify the vault area visibility toggles. Send again to confirm toggle back.

## III. General
1.  **Visual Consistency**: All panel elements (headers, buttons, vault, icons) use `HolographicTheme` colors and styles.
2.  **Performance**: UI remains responsive during dragging, resizing, and MIDI control. No excessive lag, jank, or dropped frames. (Subjective test, best with Flutter DevTools).
3.  **Stability**: No crashes or freezes during extended interaction, rapid MIDI messages, or boundary condition testing for panel manipulation.
4.  **State Preservation (Conceptual)**: If app were to save/load workspace, panel positions, sizes, visibility, and collapse states should be part of that. (Not implemented, but good to keep in mind).
5.  **FFI Callback Workaround Documentation**: Verify the prominent comment regarding the static FFI callback mechanism is present in `_InteractiveDraggableSynthState`.
