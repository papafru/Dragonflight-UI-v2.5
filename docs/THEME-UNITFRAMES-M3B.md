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
