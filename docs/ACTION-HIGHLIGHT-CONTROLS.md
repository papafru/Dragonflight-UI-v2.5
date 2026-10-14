# Action Button Highlight Visibility and Black Palette

## User request

Add a Show Highlights option to the existing Bars > Mainbar appearance settings and offer pure black as a color for the existing Highlight Color picker. Changes should not affect button actions, cooldowns, usability, mouse input or previously saved palette choices.

## Implementation

- `Bars.highlightShow` is a normal checkbox directly before Highlight Color. Default = true; older profiles with a missing key continue to show highlights.
- Native action-button hover highlight textures retain the existing texture and their button identity. The checkbox updates only the highlight's alpha (0 when hidden, 1 when visible), without removing the texture or changing the button's click, cooldown or pressed states.
- Pure RGB black `(0,0,0)` is appended as **palette position 31**. The first 30 colors and their previous numeric indexes remain exactly the same. Slider maximum is calculated from the palette length, and the UI's theme-sync loop uses the actual per-slider count.
- ADD blending makes a black-tinted highlight invisible. When the user chooses black, the texture uses the 1.12-supported BLEND mode to show a subtle black/darkening hover effect, restoring ADD mode for all other palette colors.
- Modern Dark shares the highlight color with its line border. Turning the new checkbox off conceals the mouseover highlight but leaves the Modern border visible in a neutral graphite color; turning it on restores the selected color, including black. Fantasy keeps its existing ornate borders.
- The new boolean is whitelisted as a theme-owned appearance setting in the existing schema-1 theme system (true in both Fantasy and Modern Dark). Individual theme choices/overrides persist without touching raw profile data; Existing Appearance continues honoring its legacy profile.
- The Bars module sets up the original native highlights first. `modules/bars/skins.lua` registers its own subsequent Bars callbacks through `NewCallbacks`, so those callbacks now refresh *both* native highlight textures and Modern border tint. This fixes earlier color updates that only recolored the Modern border.

## Automated tests

- The existing action-skin test now checks black as actual zero RGB, black BLEND vs colored ADD, disabled native hover alpha, neutral Modern border, preserving color selection while disabled, re-enable, and Fantasy switching.
- A new Lua 5.1 GUI control test executes the real `CreateColour` function in a mock, checks the 31-color palette, exact index and RGB for black, old gold remains index 30, selected black survives recreated sliders, and theme-specific on/off + black overrides are isolated.
- CI includes syntax validation, all previous six regression suites, and the new palette/options tests.

## WoW 1.18 smoke test

1. In Bars > Mainbar, disable Show Highlights. Hover an action button in Fantasy and Modern; no hover glow should appear, but icons, clicks, hotkeys and cooldowns must continue working.
2. Re-enable, move Highlight Color to 31 (black) and hover a button. It should darken rather than show a colored glow; Modern border may also turn black.
3. Switch the color to red and verify the glow reappears, with ADD blending and no stale black tint.
4. Disable the checkbox, then change colors. Ensure the highlight stays hidden until re-enabled.
5. Set different choices in Modern/Fantasy, switch themes, and test `/reload` to confirm correct appearance persistence.

**Separate from draft PR #7 (minimap) and PR #6 (cast bars). Do not merge until user confirms in-game behavior.**
