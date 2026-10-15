# Milestone 2 — Theme Selection Interface

## Included in this branch

- Fresh-install welcome panel with two large **in-client drawn** visual previews: **Dragonflight Fantasy** and **Modern Dark**. These previews are illustrative UI mockups using Blizzard stock textures (not screenshot assets or full Milestone 3 skins).
- Selection is staged in the welcome page: clicking a card marks it, while **Continue** commits the choice. Continue is disabled until a card is selected.
- A permanent **Themes** tab at the bottom of the existing config tab list, leaving all old tab indices unchanged. The tab allows immediate switching, reverting to **Existing Appearance**, and **Restore Theme Defaults** with the Milestone 1 native Yes/No confirmation.
- No additional \`DFRL:NewMod\` registration; the existing 24-toggle Modules grid is untouched.
- The old first-run Light/Dark implementation is removed. It used to replace the full temporary profile and could discard unrelated settings. It is not used anymore.
- The theme state stays per-character in \`DFRL_THEME_STATE\` (schema 1); no migration version bump and no changes to \`DFRL_FRAMEPOS\`.
- The configuration panel synchronizes sliders and other inputs **without writing back rounded values** or re-firing all configuration callbacks. This prevents a \`0.85\` preset from being silently stored as \`0.9\` when opening/switching the Themes tab.
- The new shared UI rendering is in \`core/theme_ui.lua\`; first-run controls are in \`core/theme_welcome.lua\`; settings integration is in \`modules/gui/themes.lua\`.

## Architecture

The GUI creates its Themes tab from the already-initialized \`Gui-base\` module, with the Theme Settings initializer registered when source files load. It does not add a new module switch. The base tab vertical spacing is adjusted to fit 16 tabs without changing existing tab IDs.

Theme selection sends appearance callbacks for the existing whitelisted keys, synchronizes the legacy settings panel in a *write-suppressed* scope, and notifies UI observers. If no theme is selected, appearance resolves from the player's original profile, including after reverting from a chosen theme.

## Tests

- \`lua5.1 tests/theme_foundation.lua\` — 53 baseline assertions.
- \`lua5.1 tests/theme_selection.lua\` — 35 UI-event mock assertions.
- \`lua5.1 tests/syntax_check.lua\` — parses eight relevant Lua source files.
- GitHub Actions independently runs Lua 5.1 syntax checks and both regression suites.
- In-game client tests remain mandatory before merge. Check a new-character/clean-state selector, an existing character without an unsolicited welcome, switching themes through Settings, cancel/confirm resets, reloading, and reverting to Existing Appearance.

## Manual client test note

On an existing character, temporarily preview the first-run window using:
\`/run DFRL.theme.state.needsChoice = true; DFRL.ShowThemeWelcome()\`
This deliberately changes a per-character test flag; **click Continue** to restore the completion state. For a truly fresh-character migration test, back up WTF and test on a character with no prior Dragonflight UI v2.5 settings.

Do not merge into stable \`main\` until the user's 1.18 client test succeeds.
