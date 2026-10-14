# Milestone 3C.2 — Modern Dark Square Minimap

**Status:** in development, visual signoff required. Separate PR from cast bars (3C.1).

## Design and behavior

- **Modern Dark starts square** using the Map module's existing `mapSquare` checkbox/mask callback. This is a theme-level appearance default; it never rewrites legacy profile data or position settings.
- The theme foundation catalogs `Map.mapSquare` with **Fantasy = false, Modern = true**. Changing the checkbox in one theme stores a validated, per-theme boolean override, so the player can still opt for a round Modern map or a square Fantasy map. 'Use Existing Appearance' retains the original profile setting.
- Keep the actual Minimap and existing native map mask, WorldMap click handlers, tracking and zoom controls. Do not replace/resize/scale the map, alter alpha setting, or interfere with surrounding addon buttons.
- In Modern Dark square mode, conceal the large square Dragonflight ornamental border and large minimap shadow using their alpha, while leaving the existing Map module responsible for the texture/mask. Render only a **1px graphite-blue rectangular border** anchored to the actual Minimap so it follows the current map size/scale.
- Replace the oversized ornamental header texture with a **flat charcoal backing exactly the bounds of the existing top panel**, with one restrained divider line. The zone text/time and their existing positioning, options and tooltip behavior remain untouched.
- Fantasy, Existing Appearance and a user-configured round Modern map restore the appropriate ornamental border/shadow and native map shape. The charcoal header is Modern-only and intentionally remains even if the user elects a round mask.
- Respect the Map profile shadow-opacity slider even while the Modern square suppresses the original shadow: record the last requested alpha and restore it when switching back. Map shadow show/hide remains under the original callbacks.

## Architecture

- One additional `modules/map/skins.lua` file, loaded after `modules/map/map.lua` in the TOC; no additional NewMod registration, SavedVariable, custom API or addon dependency.
- `InitMinimapSkin(Setup)` is called only after `Map` setup and callbacks have been registered. Existing `mapSquare` and `alphaShadow` callbacks notify the renderer to refresh safely when their options change.
- The renderer uses one theme listener, allocates six cosmetic textures exactly once, and never installs `OnUpdate` or intercepts minimap mouse handling.
- Only stock WoW 1.12 API signatures and drawing layers `OVERLAY`, `ARTWORK`, `BACKGROUND` are used.

## Tests and in-game verification

- Lua 5.1 syntax for theme, map and cosmetic renderer.
- Existing theme, unit-frame, Edit Mode and keybinding regression suites.
- New `tests/theme_minimap_skins.lua` loads real theme presets, extracts the real Map shape/shadow callbacks, validates theme defaults and independent per-theme overrides, exact mask/art/alpha restoration, shadow-setting persistence, idempotence, thin border geometry, map size invariance and callback wiring.
- **In-game test:** open Modern Dark and confirm square map, slim rim and charcoal header. Verify zone text/time, mouse clicks, mousewheel zoom, tracking, mail, addon collector and Edit Mode movement. Switch to Fantasy and Existing Appearance, then return to Modern. Change the Map square checkbox in Modern and verify override works; `/reload` while Modern is selected.

**Do not merge before screenshot approval and real-client smoke tests.**


## Zone and clock calibration (client screenshot follow-up)

The first 1.18 screenshot confirmed the square minimap and lean outline, but the green zone name was too close to the left edge of the charcoal header, and long names could extend into the clock. The legacy Map module placed both fontstrings independently without enforcing space between them.

- A **Modern-only adaptive header layout** adds 5 UI units of left breathing room to the configured `zoneTextX` and 4 to the right-hand clock margin, and lifts each label by 2 UI units, preserving the user's individual offset settings.
- The usable zone width is recalculated from the existing top panel's **actual width**, plus the current clock text width (24h or 12h) and a fixed separation. The zone's clickable button and fontstring share the bounded width, so text doesn't overlap the time display.
- For long zone names, the original FontString font family and color are preserved and the font size is reduced *only as necessary* down to 7 UI units, without replacing the actual zone text, its native updates, hover tooltip, or custom font configuration. A narrow user-configured header still clips within the reserved name area rather than covering the clock.
- Reflow happens on the existing Map clock refresh (every five seconds, only if the name, clock width or panel geometry changed) and after the existing font, position, width, height, clock format or visibility callbacks. No new `OnUpdate` handler is added.
- Switching to Fantasy or Existing Appearance restores the legacy zone/button widths, the selected normal font size and the original X/Y anchors of both labels. No saved variable schema or additional per-character state is introduced.
- The regression tests now model 24h and 12h times, narrow/wide headers, long text fitting, custom offsets, no texture allocation during reflow, and exact switching back to Fantasy.

**The client must confirm the zone text is legible and doesn't overlap the clock, including a longer zone name, before PR #7 is merged.**
