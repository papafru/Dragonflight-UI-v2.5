# Milestone 3B — Modern player / target status-bar treatments

Development scope: **decorative graphics only**. The Player and Target modules still own all status-bar values, mana/rage/energy colors, level/name text, healing predictions, class portraits, elite/rare/boss artwork, combat/rest effects, mouse events and frame movement.

## Design
- `modules/unit/skins.lua` uses the already available bar references from `Setup.healthBar` and `Setup.manaBar`.
- Each bar receives a **one-pixel modern outline** and a subtle charcoal background texture, both hidden when Modern Dark isn't selected.
- Border colors are taken from the existing shared Modern Dark palette in `DFRL.themeUI`. Health outlines use the full accent; resources use a muted version.
- Decorative frames are mouse-inert and parented to the corresponding status bar. This means the renderer follows frame movement/scaling and automatically disappears when the status bar is hidden.
- No new configuration storage, module registrations, or third-party dependencies.
- Appearance refresh uses the existing theme listener. New layers are created once per unit and shown/hidden on theme switch. Fantasy and Existing Appearance leave the original visual artwork unmodified.

## Safety checkpoints
- Player unit skin registration occurs only after `PLAYER_ENTERING_WORLD` creates its status bars and registers the original Player callbacks.
- Target unit skin registration occurs after Target's existing setup and callback registration. Module ordering is safe because all Lua source files are loaded before `DFRL:RunMods()`.
- Disabled Player/Target modules are not forced into existence.
- Dynamic target rare/elite/boss textures are untouched; all original status-bar health, power and healing functions remain unchanged.
- The renderer never calls `bar:Show()` or `bar:Hide()`, which would otherwise interfere with target power-type visibility.

## Testing
- Run `lua5.1 tests/theme_unit_skins.lua` for mocked unit-frame lifecycle, layering, reversibility, click-through, hidden resource bars, and no duplicate graphics.
- GitHub Actions reruns all earlier Lua regression suites and syntax checks.
- Real 1.18 client testing is required **before merge**. Capture Player and Target with Fantasy and Modern Dark selected, including a hostile, a friendly, and an elite/rare target if practical. Test frame movement, target acquisition/loss, party combat and relogging.
- This phase does **not** introduce a complete new unit-frame layout or remove portraits. Those changes require additional design/research and separate validation.
