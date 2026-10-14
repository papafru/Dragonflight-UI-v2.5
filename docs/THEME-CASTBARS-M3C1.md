# Milestone 3C.1 — Cast Bars (Modern Dark)

**Status:** separate client-test branch, not approved for merge.

## Source audit

- `modules/cast/cast.lua` constructs a custom Player bar and owns SPELLCAST_START/STOP/FAILED/INTERRUPTED, channel events, fade/flash progress and left/right/center fill direction. `Setup.barTexture` is a dynamically sized texture (not a Blizzard StatusBar), and `Setup.flashTex` is recolored by event handlers. Skin code never changes those handlers or their coordinates.
- `modules/cast/target.lua` constructs an optional target caster that uses ShaguTweaks-provided UnitCastingInfo/UnitChannelInfo when available. It owns its polling, hide/show state, configured dimensions and auto-positioning; this skin leaves all those untouched.
- Both constructors create `backdrop`, `barTexture`, `borderframe`, `dropshadow` and `spark`. The Player constructor additionally has `flashTex` and a second spark. Target may have a spell icon that the skin must not move or hide.
- `core/theme.lua` has `theme:AddListener` for live Fantasy/Modern/Existing selection. The existing Cast color/dark-mode callbacks still tint the original graphical textures; replacing them or changing the configured `Cast.castColor` is out of scope.

## Implementation

- The new `modules/cast/skins.lua` is loaded by TOC after both Cast modules and registers an initializer, **not an extra NewMod**.
- After the original Cast/TargetCastbar callbacks are defined, each module calls `DFRL.InitCastbarSkin` with its already-created Setup table.
- On Modern Dark, replace the beveled dynamically-sized fill with stock WHITE8X8, add a soft fill-following charcoal tint and dark track, draw a single thin 1px outline, and flatten the Player flash texture while preserving the game's flash alpha/color animation.
- Conceal the ornate background/border/shadow by *alpha only*. This prevents profile callback Show/Hide changes from tearing the new appearance, while preserving the original region visibility for Fantasy.
- Snapshot original backdrop/border/shadow alpha and fill/flash textures **once** and restore them in Fantasy and Existing Appearance. Keep all dimensions, text anchors, spell icon, spark, bar fill animation, vertex colors, event registration, progress/interrupt state, and positional saved variables unchanged.
- The listener is installed once, initial module registration is idempotent, and optional Target castbar absence is safe.

## CI and in-game acceptance

- Lua 5.1 syntax for the original and new module files.
- All prior six regression suites (theme foundation, selection, actions, unit frames, Edit Mode preview, transactional keybinds).
- New cast skin tests check exact original textures/alpha restored, both cast types, no allocation on repeated theme switch, runtime color/progress unaffected, correct integration order and optional components.
- In 1.18, cast a friendly Player spell and confirm progress text/timing, success flash, and interrupted/failed state. If available, enable target casting with ShaguTweaks and verify its optional icon, auto-positioning and color.
- Live switch **Modern Dark → Fantasy → Existing Appearance** and verify the original bar artwork without reload; then `/reload` while Modern Dark is selected.

**Minimap styling is separate 3C.2 work.** Its round/square mask settings, overlay panel, collector addon buttons, mousewheel zoom and map clicks are not modified by the cast skin.
