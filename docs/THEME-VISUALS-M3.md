# Milestone 3 — Visual Themes: architecture and delivery plan

Status: planning/audit on `feature/theme-skins-m3`. No functional changes in this commit.

## Scope and principles

- Preserve all action-bar and unit-frame behavior, secure click behavior, spell state, text, bindings, saved positions, and module enablement. Skin code changes textures, draw layers and styling only.
- Keep existing **Dragonflight Fantasy** assets and placement as the unchanged baseline, including when the theme is set to `nil` (Use Existing Appearance).
- Introduce **Modern Dark** via non-destructive overlays and styleable graphic assets; switching back must restore all original visual objects and colors without reload.
- Implement new visuals as cohesive theme renderers driven by the established `DFRL.theme` selection. Never implement another `DFRL:NewMod` entry: the 24-toggle Modules grid is fixed.
- The existing `Restore Theme Defaults` confirmation remains the only way to clear per-theme appearance overrides. Theme switching is not a reset.
- Stay compatible with the stock 1.12/1.18 Lua UI API; test in the actual client at every graphics checkpoint. ClassicAPI and SuperWoW may later offer optional enhancements but must not become unnecessary dependencies.

## Source audit (merged Milestone 2 code)

- `modules/bars/bars.lua`: `Setup:ButtonBorderHighlight()` creates per-button overlays for each of eight button-type groups, using `border.blp`, around lines 281–305. `Setup:ButtonBackgroundsAndBorders()` creates 12 main-bar `HDActionBarBtn.tga`/`border.blp` textures around lines 262–279.
- `modules/bars/bars.lua`: `Setup:Run()` creates buttons and decorations; `DFRL:NewCallbacks("Bars", callbacks)` initializes callbacks later in the `PLAYER_ENTERING_WORLD` handler. Any skin initializer must run **after** those frames and original callbacks exist, near the end of that handler.
- `core/theme.lua`: `Theme:AddListener` and `Theme:Refresh` already notify of `fantasy`, `modern`, and `nil`. These are appropriate change notifications; no new saved-variable schema is needed for purely visual skins.
- `modules/unit/player.lua` and `modules/unit/target.lua`: player/target artwork and bars use existing texture files and dark-mode/color callbacks. Start with a reversible graphic layer rather than replacing health/mana logic.
- `modules/cast/cast.lua`: controls the bar texture, background, shadow and border; rendering is intertwined with cast/channel state. Implement its themed graphics separately without modifying cast timing or spell processing.
- `modules/map/map.lua`: creates minimap border, shadow and top panel, with existing color callbacks. Theme those decorative regions only after button and unit-frame skins are stable.
- `core/theme_ui.lua`: shared Preview cards render paired health/resource mockups. They use frame-local backdrops and named texture draw layers to avoid the legacy-client layering bug found in the Milestone 2 smoke tests.

## Incremental implementation checkpoints

### 3A — Action button skin

1. Add a dedicated `modules/bars/skins.lua` extension loaded via TOC; it must not register a `NewMod`.
2. Integrate it once, after action-bar initialization and callback registration, with a guarded/idempotent initializer.
3. Reuse the existing Dragonflight textures without modification when theme is `fantasy` or `nil`.
4. For `modern`, add a simple, legible, thin-border action-button appearance that does not intercept mouse or keyboard events. Avoid Retail-only texture sublevel calls.
5. Theme switching must restore baseline border/background visibility, including when reverting to Existing Appearance. Avoid modifying any action IDs, macro, keybind, cooldown or cast-state handlers.
6. Add mock-client tests for initialize-once, correct button groups, graphic visibility per theme, click-through, reversibility, and absent optional action buttons.
7. Test with the user's 1.18 client and compare Fantasy/Modern screenshots before proceeding.

### 3B — Player and target unit frames

- Introduce theme-specific **graphic surfaces only**, with consistent borders/accents and existing resource bar logic untouched.
- Validate combat glow, elite/rare/boss borders, player/target buffs, frame movement, low HP, and theme changes in combat.

### 3C — Cast bars and minimap

- Apply switchable cast-bar textures/borders without touching event handlers or cast/channel timing.
- Apply a non-obtrusive minimap treatment; preserve clicking, scrolling, tracking and addon buttons.

### 3D — Menus and shared theme assets

- Centralize accent colors and shared graphics in one style catalog; avoid duplicated hard-coded palettes.
- Skin shared settings windows and context/control panels, keeping tooltip readability and Escape behavior.

### 3E — Integration and release

- Run Lua 5.1 syntax and unit tests, regression suites from Milestones 1–2, and actual 1.18 client smoke tests.
- Test first launch, existing profiles, per-theme overrides, Restore Theme Defaults confirmation, Edit Mode, `/kb`, XPrep grid, Questie menu insertion, and `main`/development-branch transitions.
- Merge only after visual signoff. Keep development commits scoped; update screenshots and release notes at the final release stage.

## Guardrails

- **No profile migration and no additional SavedVariables** for the initial button-skin layer.
- New layers are created once and updated via direct texture/frame state changes, not recreated on every theme switch.
- Prefer named `BACKGROUND`, `ARTWORK`, `OVERLAY` layers and `EnableMouse(false)` on decorative frames. Avoid using unsupported texture sublevels or treating mock-only rendering as proof of in-client drawing.
- Never hide or modify another addon's action-bar buttons, action IDs, or handlers without explicit design and compatibility tests.
- A modern theme selected on a character with disabled Bars module must remain safe and not create orphan UI.

## Acceptance threshold

Milestone 3A is ready for client review only when the original appearance is pixel-identical for Fantasy and Existing Appearance, Modern Dark clearly changes button borders, live switching has no errors, and all prior Lua suites still pass.

