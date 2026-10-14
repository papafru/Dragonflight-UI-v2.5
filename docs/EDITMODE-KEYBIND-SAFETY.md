# Edit Mode and Mouseover Keybinding Safety

This fix targets stock WoW 1.12 and the 1.18 client. It is isolated from main until real-client signoff.

## Edit Mode

- Reveal every registered movable frame temporarily while editing, including Target/Target of Target without active units, hidden bars, party frames and movable buff anchors.
- The optional movable-frame list is sparse; use pairs rather than table.getn to register frames beyond missing entries.
- Save each frame's initial own visibility and restore it on exit. If the actual target/targettarget changes during the editing session, honor the current unit existence.
- Reassert temporary visibility after native target events, without changing the unit selection.
- Preserve the existing automatic enemy-castbar positioning exception and deliberately hidden castbar fill.
- Persist frame moves via the existing per-character DFRL_FRAMEPOS table. No new saved variables or NewMod entries.

## Mouseover Keybindings

- Right-click and left-click are never binding inputs (including modifier combinations); middle mouse and mouse wheel continue to work.
- Live binding changes are provisional until Save Changes. Cancel, Escape, the /kb toggle, or an Edit Mode handoff roll back every changed key.
- Rollback uses an original per-key assignment journal, including unrelated actions displaced by collisions. First remove touched keys, then restore their original commands.
- Delete/Backspace clears the hovered command as an unsaved edit.
- Save Changes is disabled until the first edit; SaveBindings is invoked once only on explicit confirmation. A failed SaveBindings leaves the changes pending; a failed rollback is reported.
- Both keyboard-frame ESC and the menu's ToggleGameMenu ESC path cancel. An automatically expiring guard prevents the same keypress from opening a second menu.

## Validation

- tests/editmode_preview.lua mocks initially hidden frames, optional list holes, event-driven visibility refresh, dragging, castbar exceptions, and cleanup when targets change.
- tests/editmode_keybind.lua mocks several binding edits, reassignment collisions, alternate bindings, cancellation, saving, save failure, right-click suppression, and both ESC routes.
- GitHub Actions validates Lua 5.1 syntax and the previous four regression suites alongside these tests.
- Real WoW 1.18 client testing is mandatory before merging this branch.

## Suggested client smoke test

Open the ESC menu without a target; enter Edit Mode. Confirm Target, Target of Target, and other registered hidden frame previews appear. Move the two target frames. ESC, reacquire a target, and confirm the actual unit frame is shown at its saved position.

Run /kb, hover action buttons, assign two new keys, press ESC and verify the originals return. Repeat and click Save Changes, reload, and verify persistence. Test Right-click, Delete, cancel button and a pre-existing key conflict. Lastly re-enter Edit Mode from keybinding mode and confirm that unsaved bindings are discarded.
