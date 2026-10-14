# Edit Mode and Mouseover Keybinding Safety

This fix targets stock WoW 1.12 and the 1.18 client. It is isolated from main until real-client signoff.

## Edit Mode

- Reveal **movable Edit Mode handles** for every registered frame, including Target/Target of Target without active units, hidden bars, party frames and buff anchors. Unit-dependent Target/ToT use UIParent-owned preview handles so ordinary FrameXML hide events cannot make their handles flicker.
- The optional movable-frame list is sparse; use pairs rather than table.getn to register frames beyond missing entries.
- Save each frame's initial own visibility and restore it on exit. If the actual target/targettarget changes during the editing session, honor the current unit existence.
- Reassert temporary visibility for other registered frames, but **never force a fake Target or ToT to Show**. Their independent handles remain stable while FrameXML and Mini continue controlling actual unit visibility.
- Preserve the existing automatic enemy-castbar positioning exception and deliberately hidden castbar fill.
- Persist frame moves via the existing per-character DFRL_FRAMEPOS table. No new saved variables or NewMod entries.

## Mouseover Keybindings

- Right-click and left-click are never binding inputs (including modifier combinations); middle mouse and mouse wheel continue to work.
- **Escape over a hovered action button clears that action's current keybindings as a pending, reversible edit without leaving binding mode. Escape away from all buttons cancels the session and rolls back every pending edit.** Delete/Backspace also clears a hovered action.
- Live binding changes are provisional until Save Changes. Cancel, Escape, the /kb toggle, or an Edit Mode handoff roll back every changed key.
- Rollback uses an original per-key assignment journal, including unrelated actions displaced by collisions. First remove touched keys, then restore their original commands.
- Save Changes is disabled until the first edit; SaveBindings is invoked once only on explicit confirmation. A failed SaveBindings leaves the changes pending; a failed rollback is reported.
- Both keyboard-frame ESC and the menu's ToggleGameMenu ESC path use the same hover-aware behavior. A one-frame deduplication guard prevents a single physical Escape from clearing twice or opening the game menu after cancellation.

## Validation

- tests/editmode_preview.lua mocks initially hidden frames, optional list holes, event-driven visibility refresh, dragging, castbar exceptions, and cleanup when targets change. The movable overlays also display human-readable labels for frames, action bars, party members, buffs, minimap and extra addon frames.
- tests/editmode_keybind.lua mocks several binding edits, reassignment collisions, alternate bindings, cancellation, saving, save failure, right-click suppression, and both ESC routes.
- GitHub Actions validates Lua 5.1 syntax and the previous four regression suites alongside these tests.
- Real WoW 1.18 client testing is mandatory before merging this branch.

## Suggested client smoke test

Open the ESC menu without a target; enter Edit Mode. Confirm Target, Target of Target, and other registered hidden frame previews appear. Move the two target frames. ESC, reacquire a target, and confirm the actual unit frame is shown at its saved position.

Run /kb, hover action buttons, assign two new keys, press ESC and verify the originals return. Repeat and click Save Changes, reload, and verify persistence. Test Right-click, Delete, cancel button and a pre-existing key conflict. Lastly re-enter Edit Mode from keybinding mode and confirm that unsaved bindings are discarded.


## Video-based flicker regression (October 14)

The user's recording shows the Target of Target editor overlay alternating visible/hidden in **adjacent 60 fps frames** (the regular ToT update hides nonexistent targettarget units, while the editor was re-showing them every refresh). The actual parent unit frame must never be forced visible for drag editing without a real unit.

- Target and ToT now display independent UIParent-owned movable overlays whose anchor points follow the real frames, whether or not the native unit frames are visible.
- For these two unit-dependent frames, moving the overlay records the pixel delta and transfers that delta to the real frame on mouse-up (or edit exit), then restores the overlay's original relative anchors. This avoids cycles and click-only 10px jumps.
- The edit visibility poll doesn't re-show these unit frames, and repeated native hides don't affect the independent editor handles.
- Normal unit logic, skins, targeting, other registered edit overlays and saved frame positions remain intact.
- The mocked regression now checks eight repeated native hide/refresh cycles, persistent target and ToT handles, real target acquisition/loss, proxy movements and click-without-move stability.

## Remaining flicker beside the minimap

The subsequent in-game test confirmed that Target of Target no longer flickers, but a second native-visibility-driven element to the **left of the minimap** still flashes. The original video does not expose a readable label for that element; the relevant registered candidates are Blizzard buff buttons, temporary enchant buttons, and quest/timer anchors.

The same UIParent-owned independent editor-handle approach now covers `BuffButton0`, `BuffButton8`, `BuffButton16`, `BuffButton32`, `TempEnchant1`, `QuestTimerFrame`, and the addon-owned `DFRL.questframe`. Their native gameplay frames are not artificially re-shown by Edit Mode. The UI overlay remains visible and draggable, and moving it updates the underlying frame anchor through the already-tested delta transfer. Regular action bars, the special castbar handling and the existing Target/ToT placeholders are unchanged.

The extended Lua 5.1 mock tests verify repeated native hide updates, zero unexpected native Show calls, stable visible editor handles, temporary-enchant positioning and correct cleanup after leaving Edit Mode. Real-client footage is still required to verify the exact icon's flicker is gone before merging.
