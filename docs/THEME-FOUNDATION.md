# Theme foundation — Milestone 1

This branch introduces **theme state and appearance resolution**, not the first-run UI or new artwork. `main` remains unchanged until in-client review and merge.

## Architecture

- `core/theme.lua` is loaded after `core/core.lua`, before the addon's `ADDON_LOADED` initialization. It does **not** register a `DFRL:NewMod` entry (avoids overflow of the fixed 24-item Modules settings grid).
- `DFRL_THEME_STATE` is a **per-character** SavedVariable with `schema = 1`, `selected`, `needsChoice`, and separate `overrides.fantasy` / `overrides.modern` tables. It is independent of `DFRL_PROFILES` and `DFRL_FRAMEPOS`.
- Appearance is a **whitelisted virtual overlay** evaluated via `DFRL:GetTempDB()` and `DFRL:GetTempValue()`. Module states, layouts, frame scales, binds and general settings continue using raw profile values.
- `DFRL:SetTempDB()` and `SetTempDBNoCallback()` route supported appearance edits to the current theme's override bucket. When no theme is selected they preserve the exact legacy behavior. Color tables are copied defensively and malformed override values are ignored.
- Module callbacks receive resolved appearance values at registration, on ordinary changes, and via `Theme:Refresh()`. Theme selection/reset refreshes only whitelisted appearance callbacks.
- Existing characters with prior welcome completion or saved profile data are migrated to **neutral/preserve mode** (`selected = nil`, `needsChoice = false`). New characters start neutral with `needsChoice = true` for the Milestone 2 selector. **No automatic recoloring** occurs on update.
- The current Light/Dark legacy welcome page still exists on this foundation-only branch. Milestone 2 must replace its wholesale `TempDBForSwitching()` behavior with the new theme-selection flow before first-run themes are released.

## Public integration surface

`DFRL.theme:GetSelected()` returns `fantasy`, `modern`, or `nil` (neutral / preserve current profile).

`DFRL.theme:NeedsFirstRunChoice()` indicates whether Milestone 2 should open the initial selection screen.

`DFRL.theme:Select("fantasy" | "modern")` chooses a theme, persists the choice, and updates active appearance callbacks. Returns `false` for unknown theme IDs.

`DFRL.theme:RequestRestoreDefaults()` opens a **Yes/No Blizzard confirmation** dialog. Only confirming deletes the current theme's custom appearance overrides. It does not clear positions, profiles, binds, or overrides of the other theme. In Milestone 2, the mandatory *Restore Theme Defaults* button must call this method.

`DFRL.theme:Supports(module, key)` checks whether a property is owned by the theme overlay. To add new properties later, update both preset maps and regression tests. Never add behavior/position keys.

## Design constraints / future steps

- Existing visual output remains unchanged until the user explicitly selects a theme. The two palettes here are provisional values for the current engine; richer textures and skins belong to Milestone 3.
- Theme state is per character; existing *profile* behavior is unchanged.
- The legacy first-run dialog is replaced in Milestone 2; this commit is **not** a finished end-user theme feature.
- The old full-database reset also clears theme state. Ordinary *Restore Theme Defaults* does not.
- ClassicAPI/SuperWoW integration is deferred: this foundation uses only stock 1.12-compatible Lua/UI APIs.

## Verification

Run `lua5.1 tests/theme_foundation.lua` at the addon root. `texlua tests/theme_foundation.lua` also works for a basic development check. Automated tests simulate saved-variable restoration, callbacks, theme switching, override isolation, malformed values, and native confirmation. They do **not** replace final in-client 1.18 testing.
