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
    -   Verify the vault area (`_buildVaultArea` rendering based on `_isVaultAreaVisible`) toggles its visibility.
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

## IV. Keyboard - Musicality & Gestures

1.  **Root Note Selection**:
    -   Open the Virtual Keyboard.
    -   Change the "Root" note using the dropdown (e.g., to "G").
    -   Verify `HapticFeedback.selectionClick()` occurs.
    -   Verify the visual representation of keys (if any specific root note highlighting is implemented beyond scale highlighting) updates.
    -   Play notes; verify their MIDI values are correctly offset by the new root.
2.  **Scale Selection**:
    -   Open the Virtual Keyboard.
    -   Change the "Scale" using the dropdown (e.g., to "Minor Pentatonic").
    -   Verify `HapticFeedback.selectionClick()` occurs.
    -   Verify keys not in the selected scale are visually dimmed or otherwise distinguished.
    -   Verify keys in the selected scale are visually highlighted (if not pressed).
    -   Attempt to play notes:
        -   Verify only notes belonging to the selected scale are audible.
        -   Verify tapping a dimmed (out-of-scale) key produces no sound.
    -   Switch back to "Chromatic" scale. Verify all keys are normally styled and playable.
3.  **Key Size (Pinch-to-Zoom)**:
    -   Using two fingers, pinch inward on the keyboard area.
    -   Verify `_keyWidthFactor` decreases and keys become narrower.
    -   Verify `HapticFeedback.lightImpact()` occurs on change.
    -   Pinch outward. Verify `_keyWidthFactor` increases and keys become wider.
    -   Verify clamping of key size (min/max width).
    -   Verify keyboard remains scrollable horizontally if total width exceeds view.
4.  **Octave Scroll (3-Finger Drag or Alternative)**:
    -   If implemented: Using three fingers (or specified alternative), drag horizontally across the keyboard.
    -   Verify `_currentOctave` changes.
    -   Verify `HapticFeedback.selectionClick()` occurs on octave change.
    -   Verify octave value is clamped within min/max limits.
    -   Verify displayed notes and played MIDI notes reflect the new octave.
5.  **Gesture Conflict**:
    -   While pinch-zooming, verify the horizontal scroll of the `SingleChildScrollView` is disabled.

## V. XY Pad - Musicality

1.  **X-Axis Root Note Selection**:
    -   Open the XY Pad.
    -   Change the "X-Key" using its dropdown.
    -   Verify `HapticFeedback.selectionClick()` occurs.
    -   Verify the internal `_selectedRootNoteMidiOffsetX` updates.
    -   Verify `SynthParametersModel.setXYPadRootNoteX()` is called.
2.  **X-Axis Scale Selection**:
    -   Open the XY Pad.
    -   Change the "X-Scale" using its dropdown.
    -   Verify `HapticFeedback.selectionClick()` occurs.
    -   Verify internal `_selectedScaleX` updates and `_quantizedPitchMapX` is recalculated.
    -   Verify `SynthParametersModel.setXYPadScaleX()` is called.
3.  **X-Axis Pitch Quantization**:
    -   Select a scale (e.g., C Major).
    -   Drag the cursor horizontally across the XY Pad.
    -   Verify the output pitch (conceptually, via logging `outputPitchMidiNote` or observing a connected sound source) snaps to notes within the C Major scale over the defined 3-octave range.
    -   Verify `HapticFeedback.selectionClick()` occurs each time the quantized note changes (`_lastXAxisMidiNote` logic).
    -   Change scale to Pentatonic and verify snapping to pentatonic notes.
    -   Change to Chromatic and verify all notes in the range are hit.
4.  **Y-Axis Parameter Control**:
    -   Assign a parameter to the Y-axis (e.g., Filter Resonance).
    -   Drag the cursor vertically.
    -   Verify the Y-axis still controls the assigned parameter as expected (e.g., `AudioEngineInterface.setParameter` is called with correct ID and value for Y-axis).
    -   Verify this is independent of X-axis quantization.
5.  **Drag Haptics**:
    -   Verify `HapticFeedback.lightImpact()` on `onPanStart`, `onPanEnd`, `onPanCancel` for the pad area.

## VI. Dynamic Visual Reactivity of Controls

1.  **Knobs (`_HolographicKnobPainter`)**:
    -   **Hover**: Mouse over a knob. Verify its outline/indicator subtly brightens or glow expands. Mouse out, verify it returns to normal.
    -   **Drag Start/Active**: Click and drag a knob. Verify indicator dot/value arc significantly increases glow/brightness. Verify optional scaling if implemented. Release drag, verify it returns to hover state (if still hovering) or normal.
    -   **Value Intensity**: Drag a knob from min to max. Verify its value arc color becomes more saturated/shifts hue as designed. Verify optional fill opacity changes if implemented.
    -   Verify `HapticFeedback.lightImpact()` on drag start and end.
2.  **Sliders (`_HolographicSliderPainter`)**:
    -   **Hover**: Mouse over a slider. Verify thumb/active track subtly brightens or glows. Mouse out, verify return to normal.
    -   **Drag Start/Active**: Click and drag a slider thumb. Verify thumb becomes more prominent (glow/scale). Verify optional track pulsing. Release, verify return to appropriate state.
    -   **Value Intensity**: Drag a slider from min to max. Verify active track color changes saturation/hue. Verify optional thumb glow/brightness changes. Verify optional track background transparency changes.
    -   Verify `HapticFeedback.lightImpact()` on drag start and end.
3.  **XY Pad (`_XYPadHolographicPainter`)**:
    -   **Hover**: Mouse over the XY Pad area. Verify cursor dot/crosshairs appear or increase default brightness. Mouse out, verify return to normal/dimmed state.
    -   **Drag Start/Active**: Click and drag on the XY Pad. Verify cursor dot significantly increases size/glow. Verify crosshairs become brighter/thicker.
    -   **Value-Based Reactivity**:
        -   Drag cursor horizontally. Verify subtle color shift of cursor dot/glow based on X position.
        -   (If implemented) Drag cursor vertically. Verify Y-axis parameter intensity reflected in vertical crosshair.
        -   Drag cursor to extreme corners. Verify grid line opacity subtly decreases.

## VII. Panel State Persistence (Conceptual Manual Test)

1.  **Initial State**: Launch the application. Observe the default panel layout and default XY Pad musical settings (e.g., Chromatic, C).
2.  **Modify Layout & Settings**:
    -   Move several panels to new positions.
    -   Resize some panels.
    -   Collapse one panel.
    -   Hide a panel in the vault.
    -   Change the XY Pad's X-axis Root Note and Scale (e.g., to G Major).
3.  **Trigger Save (Conceptual - current state of implementation)**:
    -   Acknowledge that `_savePanelLayout()` is primarily called on MIDI changes, vault interactions, and initial default layout.
    -   For a manual test, one might need to trigger one of these, or conceptually assume a "save layout" button exists, or rely on the `onPanEnd` for drag/resize and collapse button presses if those `_savePanelLayout` calls were successfully integrated.
    -   *(Self-correction: The subtask description implies the save calls are mostly in place now. This test should verify if they work as expected after those interactions.)*
    -   Perform an action that should trigger a save (e.g., drag a panel and release, collapse a panel, close a panel to vault).
4.  **Restart Application (Conceptual)**:
    -   Close and reopen the application (simulated, as we can't actually restart it here).
    -   The `_loadPanelLayout()` method should be called during `initState`.
5.  **Verify Restoration**:
    -   Verify panels appear in their modified positions, sizes, collapse states, and visibility (including vault state).
    -   Verify the XY Pad's X-axis Root Note and Scale are restored to what was set in step 2 (e.g., G Major).
    -   Verify the `SynthParametersModel` reflects these loaded XY Pad settings.
6.  **Test Corrupted/No Data**:
    -   (If possible with tooling) Simulate clearing `shared_preferences` or providing invalid data.
    -   Verify the application falls back to the default layout (`_initializePanels()`) without crashing.
    -   Verify the default layout is then saved.

## VIII. Robust FFI Callback (`UiMidiEventService`)

1.  **Internal Change Verification**:
    -   Note: This is primarily an internal architecture change. The existing MIDI control test cases (Section II) should still pass.
    -   The key verification is that MIDI CC messages sent on Channel 16 correctly manipulate panel states (visibility, position, size, collapse, vault toggle) as before.
    -   (Optional, for developers) Add logging within `_staticHandleUiControlMidiMessage` to confirm it's publishing to `UiMidiEventService`.
    -   Add logging within `_InteractiveDraggableSynthState._handleUiControlEventFromStream` to confirm it's receiving and processing events from the service.

This update adds comprehensive test cases for the newly implemented features and refactorings.
```
