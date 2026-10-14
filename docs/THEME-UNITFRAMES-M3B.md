# Milestone 3B — Portrait-free rectangular Modern Dark frames

This revision replaces the original bar-only treatment after the user's real
1.18 client screenshot showed that the circular Dragonflight portraits and
ornate backing clashed with the new outlines. The requested Modern Dark look is
**minimal, rectangular and without portraits**.

## Implementation
- The shared renderer remains `modules/unit/skins.lua`; Player and Target still supply their existing health and mana bars after initialization. No new module entry, profile migration, character-specific settings, or optional client dependency is introduced.
- In Modern Dark only, the original portrait and decorative frame graphics are made transparent with **saved original alpha values**, not destroyed or unregistered. Switching to Fantasy or Existing Appearance restores each exact alpha, including any original non-default opacity.
- The original portrait models remain active internally. Original Player/Target art callbacks, dynamic rare/elite texture changes, statuses and combat events are never replaced.
- A compact charcoal rectangle is anchored around the existing status bars and follows the user's frame positions/scaling. A muted thin border and horizontal accent rule visually unify the health/resource segments.
- Unit names and levels are moved into the rectangle's header. Their prior anchors, text colors and name alignment are captured on entering Modern Dark and restored on leaving. No text values or underlying font settings are replaced.
- Because the ornate Target classification border is invisible in Modern Dark, a small text badge shows **RARE**, **ELITE**, **RARE ELITE** or **BOSS**, updated on target change. The original rare/elite art texture continues updating underneath and reappears when Fantasy is restored.
- Existing status bar fill values, textures, animation updates, color reactions, heal prediction, mana/rage/energy handling, portrait updating and mouse/click scripts remain untouched. Target resource bar visibility is never forced.
- Decorations use `BACKGROUND` / `OVERLAY` drawing layers available in 1.12. New frames disable mouse interaction. No unsupported texture sublevels.

## Review/testing
- The Lua regression test `tests/theme_unit_skins.lua` simulates target/player initialization ordering, rarity changes and targeting loss, non-default alpha and text-style restoration, hidden resource bars, repeated theme selection, and unchanged gameplay handlers.
- Independent GitHub CI reruns previous foundation, Theme UI and button-skin regression suites plus Lua 5.1 syntax and the unit-frame tests.
- Still requires an in-game screenshot of **both** Modern Dark rectangular Player/Target frames, alongside switching to Fantasy and Existing Appearance, and a real classification event to establish compatibility.
- Do **not** merge until the revised look and behavior are approved in WoW 1.18. Preserve stable `main`.

## Limitations
- This is a visual composition, not a new unit frame system. It does not change the saved location of the underlying Player/Target frames or status bars. Header width still follows the existing fixed-width bars.
- Legacy combat/rest animations are still controlled by the original Player module and require separate inspection during in-game combat; this implementation does not suppress their game-state feedback.


## Legacy-region compatibility revision

The October 14 in-client screenshot of the initial rectangular revision exposed
two remaining mismatches: the actual `TargetPortrait` was still visible
beside the rectangle, and the `PlayerPVPIcon` was floating at its old
Dragonflight position.

- Vanilla FrameXML may expose the live portrait as `PlayerPortrait`
  or `TargetPortrait` rather than (or as well as) the frame's
  `portrait` field. The renderer now collects distinct owned and
  global portrait/art references, deduplicating identical objects.
- Legacy art and portraits are hidden as well as made transparent, and original
  visibility/alpha is captured and restored on returning to Fantasy or Existing
  Appearance. Portrait update and faction events reassert concealment while
  Modern is active without replacing the client's own art update functions.
- Live PvP icons are managed separately. Their anchors and dimensions are
  captured; Modern positions them as compact badges just to the right of each
  rectangle. Their show/hide state is **not** changed, so actual PvP status
  continues to be controlled by Blizzard/fruUI's PVPIcon module. Fantasy
  restores the original anchor and dimensions exactly.
- `TargetFrameNameBackground` (a legacy decorative region) is
  also suppressed without touching reaction-color logic.
- The expanded mock tests use separate named `TargetPortrait` /
  `PlayerPortrait` objects and live PvP icons rather than relying
  on `owner.portrait` alone. They check repeats, event-driven
  reappearance, visible/hidden icon status, and exact restoration.

The target's buff/debuff icons remain active and anchored by its native aura
handler. We have **not** overridden those aura APIs solely for visual polish.

Do not merge until the user's real 1.18 client verifies both portrait removal
and PvP icon placement.


## Flat status bars and single-border correction

The latest client screenshot showed two distinct problems:

1. The original `healthDF2.tga` texture is beveled and glossy, inconsistent with the clean Modern Dark rectangle.
2. The existing 30px health bar and resource bar (beginning 24px below
   the health top) **overlap by 6px**. Individual modern outlines created
   stacked horizontal lines and crossed the resource-bar text.

In **Modern Dark only**, the renderer now:

- Replaces the existing `bar.fill` texture with stock
  `Interface\\Buttons\\WHITE8X8`, producing flat status-bar fills.
- Preserves the original dynamic `SetFillColor()` behavior for
  hostile/friendly/player class color and resource types; existing status-bar
  animation logic remains responsible for updates.
- Uses a charcoal tint on the existing `bar.bg` rather than
  layering another backdrop and inner border.
- Adjusts the health bar from 30px to 22px; the resource bar retains 12px.
  This resolves the 6px overlap and leaves a 2px gap.
- Removes the redundant per-bar outline frames. There is only one rectangular
  outer border and one divider below the header.
- Temporarily switches `bar.cutoutTexture` to the flat texture,
  so new damage-cutout animations match the modern fill.
- Captures and restores each bar's original fill texture, cutout texture,
  background color/alpha and height when returning to Fantasy/Existing
  Appearance, calling the existing `bar:Update()` to refresh fill
  size without changing health or power values.

The CI unit tests assert geometry, exact restoration, preservation of dynamic
reaction colors, target resource visibility, and the absence of duplicated
artwork allocations during repeated theme switching.

**Important:** Modern Dark flat-bar styling must be confirmed visually in
the actual WoW 1.18 client before merging PR #4.


## Combat-glow and bar-finish refinement

The next WoW client screenshot showed that the original circular combat pulse
still appeared to the left of the new rectangular Player frame. It also showed
very saturated flat bars against the muted charcoal panel.

- The original `Player` module creates a portrait-centered red
  `Setup.combatOverlay`, a similarly centered resting overlay,
  and an independent `restingAnimation` flipbook. The initializer
  now passes these existing references to the unit-frame renderer.
- When Modern Dark is enabled, the *effect parent frames* inherit alpha zero.
  This is deliberately different from changing the child texture's opacity,
  which combat/resting OnUpdate animations would immediately overwrite.
  Their original frame alphas are captured once and restored on Fantasy or
  Existing Appearance. No combat OnUpdate handler, event binding, or status
  logic is replaced.
- A slim left border on the rectangular Player panel switches from the
  normal cool-muted border to a restrained red accent while the player is
  in combat; state is updated by the existing vanilla combat entry/exit
  events. Gameplay effects continue internally and are restored for Fantasy.
- Status bars remain flat, retaining native class/reaction/power color
  updates and the current damage cutout system. A low-opacity graphite
  **fill-tracking** tint (rather than a full-width overlay) softens highly
  saturated health/power colors without interfering with the native fill
  texture or color values.
- The Modern health bar is 20px and the resource bar 10px, with a 4px gap
  between their legacy top anchors. The header and only outer border remain
  fixed. Fantasy restores 30px health/12px resource geometry exactly.
- Regression tests simulate repeatedly changing combat texture opacity,
  entering/leaving combat, resting-frame changes, original animation parent
  alpha restoration, and the tint's attachment to the animated fill width.

Actual 1.18-client visual signoff is still required before merging PR #4.


## Unified Player / Target / Target of Target design

The next review expands Modern Dark to the `Mini` module's real Target of Target (ToT) bars. The Mini module keeps all targettarget data, font/text handling, debuffs, interaction and scale settings; the existing `modules/unit/skins.lua` renderer now understands the `tot` unit in addition to Player/Target.

- Initialization happens only after `Mini:Run()` creates `totHealthBar` and `totManaBar`. No additional `NewMod` entry, no second renderer, and no extra SavedVariables.
- ToT's portrait and ornate background are reversibly suppressed, while the name moves into a compact rectangle and the original Debuff anchors/handlers are preserved. The icon art and text/position restore when Fantasy or Existing Appearance is selected.
- The ToT health/power tracks expand from 60 to 86 pixels in Modern Dark, with 16px / 8px heights and a 3px visual gap. The original bar width, height and relative resource-bar anchors are restored exactly.
- Modern Dark now reduces outer border saturation and uses muted graphitic tracks and a 36%-opacity fill-tracking charcoal tint. Native health reaction/class colors, mana/rage/energy values, animations and user-selected text numbers continue to update the underlying fill.
- For Target or ToT units lacking a power bar, `Style:UpdateLayout(unit)` anchors the rectangle's bottom directly to health instead of an invisible resource frame. The rectangle expands again when resource becomes visible. It is invoked after the existing Target event handler and after Mini's `TargetofTarget_Update` processing, avoiding a separate polling loop.
- The original named ToT portrait may be updated by FrameXML even after theme selection. `UpdateLayout` reasserts Modern-only suppression without replacing original portrait event callbacks.
- Reuse theme switch /reset behavior; Fantasy and Existing Appearance return both ToT and original Player/Target visuals, including ToT width and resource bar anchor.

### Additional tests

The mocked Lua 5.1 tests now create the actual Mini-style ToT frame and its independently anchored status bars. They assert three-unit theme switching, ToT artwork suppression/restoration, compact bar dimensions, name anchor restoration, dynamic panels for no-resource Target/ToT, and original Mini bar anchors after returning to Fantasy. The real 1.18 client still must validate ToT positioning and debuffs before PR #4 is merged.
